"""Isolated checks; these do not establish live MySQL connectivity."""

import tempfile
import unittest
from pathlib import Path
from unittest.mock import MagicMock, patch

from fastapi.testclient import TestClient
from sqlalchemy.exc import OperationalError

from backend.config import ConfigurationError, Settings
from backend.database import create_database_engine
from backend.main import create_app


class ConfigurationTests(unittest.TestCase):
    def load(self, contents, environ=None):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / ".env"
            path.write_text(contents, encoding="utf-8")
            return Settings.load(path, environ={} if environ is None else environ)

    def test_missing_fields_report_names_without_values(self):
        with self.assertRaises(ConfigurationError) as caught:
            self.load("DB_PASSWORD=private-token\n")
        self.assertIn("DB_HOST", str(caught.exception))
        self.assertNotIn("private-token", str(caught.exception))

    def test_password_special_characters_and_environment_precedence(self):
        settings = self.load(
            "DB_HOST=localhost\nDB_PORT=3306\nDB_USER=test\n"
            "DB_PASSWORD='a@b:# /${LITERAL}'\nDB_NAME=testdb\n",
            {"DB_PORT": "3307"},
        )
        self.assertEqual(settings.port, 3307)
        self.assertEqual(settings.password, "a@b:# /${LITERAL}")
        self.assertNotIn(settings.password, repr(settings))
        engine = create_database_engine(settings)
        try:
            self.assertEqual(engine.url.password, settings.password)
            self.assertEqual(engine.url.drivername, "mysql+pymysql")
        finally:
            engine.dispose()

    def test_invalid_ports_do_not_echo_input(self):
        for port in ("sensitive-value", "0", "65536"):
            with self.subTest(port=port), self.assertRaises(ConfigurationError) as caught:
                self.load(
                    f"DB_HOST=localhost\nDB_PORT={port}\nDB_USER=test\n"
                    "DB_PASSWORD=\nDB_NAME=testdb\n"
                )
            self.assertEqual(str(caught.exception), "DB_PORT must be an integer from 1 to 65535.")


class HealthTests(unittest.TestCase):
    def test_health_connection_cleanup_and_shutdown(self):
        engine = MagicMock()
        with patch("backend.main.Settings.load"), patch(
            "backend.main.create_database_engine", return_value=engine
        ):
            with TestClient(create_app()) as client:
                self.assertEqual(client.get("/health").json(), {"status": "ok"})
                engine.connect.assert_not_called()
                response = client.get("/health/db")
                self.assertEqual(response.status_code, 200)
                self.assertEqual(response.json(), {"status": "ok", "database": "connected"})
                engine.connect.return_value.__exit__.assert_called_once()
            engine.dispose.assert_called_once()

    def test_database_failure_is_sanitized_and_liveness_stays_ok(self):
        engine = MagicMock()
        engine.connect.side_effect = OperationalError(
            "SELECT 1", {}, Exception("private-password and private-host")
        )
        with patch("backend.main.Settings.load"), patch(
            "backend.main.create_database_engine", return_value=engine
        ):
            with TestClient(create_app()) as client:
                response = client.get("/health/db")
                self.assertEqual(response.status_code, 503)
                self.assertEqual(response.json(), {"status": "error", "database": "unavailable"})
                self.assertNotIn("private", response.text)
                self.assertEqual(client.get("/health").status_code, 200)
            engine.dispose.assert_called_once()

    def test_missing_configuration_stops_startup(self):
        with patch("backend.main.Settings.load", side_effect=ConfigurationError("Missing DB_HOST")):
            with self.assertRaises(ConfigurationError):
                with TestClient(create_app()):
                    pass

    def test_query_failure_returns_connection_to_pool(self):
        engine = MagicMock()
        connection = engine.connect.return_value.__enter__.return_value
        connection.execute.side_effect = OperationalError("SELECT 1", {}, Exception("private"))
        # A real connection context manager propagates errors after cleanup.
        engine.connect.return_value.__exit__.return_value = False
        with patch("backend.main.Settings.load"), patch(
            "backend.main.create_database_engine", return_value=engine
        ):
            with TestClient(create_app()) as client:
                self.assertEqual(client.get("/health/db").status_code, 503)
                engine.connect.return_value.__exit__.assert_called_once()
            engine.dispose.assert_called_once()


if __name__ == "__main__":
    unittest.main()

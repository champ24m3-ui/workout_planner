"""Isolated HTTP/SQL interaction checks; no connection to the real demo database."""

import unittest
from contextlib import contextmanager
from unittest.mock import MagicMock, patch

from fastapi.testclient import TestClient
from sqlalchemy.exc import OperationalError

from backend.main import create_app


BASE = {
    "profile_id": 9, "user_id": 42, "fitness_level": "Beginner",
    "primary_goal": "Build muscle", "workout_location": "Home",
    "days_per_week": 3, "minutes_per_session": 60,
}
CREATE = {key: value for key, value in BASE.items() if key not in ("profile_id", "user_id")}


@contextmanager
def client_with_database(*results, commit_error=False):
    engine = MagicMock()
    connection = MagicMock()
    engine.connect.return_value.__enter__.return_value = connection
    engine.connect.return_value.__exit__.return_value = False
    engine.begin.return_value.__enter__.return_value = connection
    engine.begin.return_value.__exit__.return_value = False
    if commit_error:
        engine.begin.return_value.__exit__.side_effect = OperationalError(
            "COMMIT", {}, Exception("private credentials")
        )
    connection.execute.side_effect = results
    with patch("backend.main.Settings.load"), patch(
        "backend.main.create_database_engine", return_value=engine
    ):
        with TestClient(create_app()) as client:
            yield client, engine, connection


def user_result(value=42):
    result = MagicMock()
    result.scalar_one_or_none.return_value = value
    return result


def profile_result(value):
    result = MagicMock()
    result.mappings.return_value.one_or_none.return_value = value
    return result


class ProfileTests(unittest.TestCase):
    def test_get_demo_profile_and_no_password_exposure(self):
        with client_with_database(user_result(), profile_result(BASE)) as (client, engine, conn):
            response = client.get("/profile?user_id=999")
            self.assertEqual(response.status_code, 200)
            self.assertEqual(response.json(), BASE)
            self.assertEqual(conn.execute.call_args_list[0].args[1], {"email": "demo@gmail.com"})
            self.assertEqual(conn.execute.call_args_list[1].args[1], {"user_id": 42})
            self.assertNotIn("password", response.text)
            engine.begin.assert_not_called()
            engine.connect.return_value.__exit__.assert_called_once()

    def test_get_preserves_existing_nullable_and_legacy_values(self):
        existing = {**BASE, "fitness_level": "Legacy value", "minutes_per_session": None}
        with client_with_database(user_result(), profile_result(existing)) as (client, _, __):
            self.assertEqual(client.get("/profile").json(), existing)

    def test_missing_demo_user_and_profile(self):
        for method in ("get", "patch"):
            with self.subTest(method=method):
                with client_with_database(user_result(None)) as (client, _, conn):
                    response = (client.get("/profile") if method == "get"
                                else client.patch("/profile", json={"days_per_week": 4}))
                    self.assertEqual(response.status_code, 404)
                    self.assertEqual(response.json()["detail"], "Demo user not found.")
                    self.assertEqual(conn.execute.call_count, 1)
        with client_with_database(user_result(), profile_result(None)) as (client, _, __):
            self.assertEqual(client.get("/profile").status_code, 404)

    def test_partial_patch_keeps_omitted_fields_and_targets_demo(self):
        latest = {**BASE, "days_per_week": 5}
        with client_with_database(
            user_result(), profile_result(BASE), MagicMock(), profile_result(latest)
        ) as (client, engine, conn):
            response = client.patch("/profile", json={"days_per_week": 5})
            self.assertEqual(response.status_code, 200)
            self.assertEqual(response.json(), latest)
            calls = conn.execute.call_args_list
            self.assertIn("FOR UPDATE", str(calls[0].args[0]))
            self.assertEqual(str(calls[2].args[0]),
                             "UPDATE user_profiles SET days_per_week = :days_per_week WHERE user_id = :user_id")
            self.assertEqual(calls[2].args[1], {"user_id": 42, "days_per_week": 5})
            self.assertEqual(engine.begin.return_value.__exit__.call_args.args, (None, None, None))

    def test_create_missing_profile_with_all_fields(self):
        with client_with_database(
            user_result(), profile_result(None), MagicMock(), profile_result(BASE)
        ) as (client, _, conn):
            response = client.patch("/profile", json=CREATE)
            self.assertEqual(response.status_code, 200)
            self.assertEqual(response.json(), BASE)
            query, parameters = conn.execute.call_args_list[2].args
            self.assertIn("INSERT INTO user_profiles", str(query))
            self.assertNotIn("stretch_recommendation", str(query))
            self.assertNotIn("height_cm", str(query))
            self.assertEqual(parameters, {"user_id": 42, **CREATE})

    def test_incomplete_creation_has_no_write_and_exits_with_error(self):
        with client_with_database(user_result(), profile_result(None)) as (client, engine, conn):
            response = client.patch("/profile", json={"days_per_week": 4})
            self.assertEqual(response.status_code, 422)
            self.assertEqual(len(response.json()["detail"]["missing_fields"]), 4)
            self.assertEqual(conn.execute.call_count, 2)
            self.assertIsNotNone(engine.begin.return_value.__exit__.call_args.args[0])

    def test_invalid_requests_never_access_database(self):
        invalid = [
            {}, {"fitness_level": "Expert"}, {"primary_goal": "Unknown"},
            {"workout_location": "Park"}, {"days_per_week": 0},
            {"days_per_week": 8}, {"days_per_week": True},
            {"days_per_week": "3"}, {"days_per_week": 2.5},
            {"minutes_per_session": 0}, {"minutes_per_session": -1},
            {"minutes_per_session": 2147483648}, {"minutes_per_session": False},
            {"minutes_per_session": "60"}, {"minutes_per_session": 1.5},
            {"user_id": 999}, {"email": "other@example.com"},
            {"stretch_recommendation": True}, {"height_cm": 170},
            {"primary_goal": "Build muscle", "unexpected": "value"},
            *[{name: None} for name in CREATE],
        ]
        with client_with_database() as (client, engine, _):
            for payload in invalid:
                with self.subTest(payload=payload):
                    self.assertEqual(client.patch("/profile", json=payload).status_code, 422)
            engine.begin.assert_not_called()
            engine.connect.assert_not_called()

    def test_all_approved_values_and_numeric_boundaries(self):
        values = {
            "fitness_level": ("Beginner", "Intermediate", "Advanced"),
            "primary_goal": ("Build muscle", "Lose fat", "General fitness"),
            "workout_location": ("Home", "Gym"),
            "days_per_week": (1, 7), "minutes_per_session": (1, 2147483647),
        }
        for field, choices in values.items():
            for value in choices:
                latest = {**BASE, field: value}
                with self.subTest(field=field, value=value), client_with_database(
                    user_result(), profile_result(BASE), MagicMock(), profile_result(latest)
                ) as (client, _, __):
                    response = client.patch("/profile", json={field: value})
                    self.assertEqual(response.status_code, 200)
                    self.assertEqual(response.json(), latest)

    def test_database_failures_are_sanitized_and_transaction_exits_with_error(self):
        for stage in range(4):
            results = [user_result(), profile_result(BASE), MagicMock(), profile_result(BASE)]
            results[stage] = OperationalError("private SQL", {}, Exception("private credentials"))
            with self.subTest(stage=stage), client_with_database(*results) as (client, engine, _):
                response = client.patch("/profile", json={"days_per_week": 4})
                self.assertEqual(response.status_code, 503)
                self.assertEqual(response.json(), {"detail": "Database unavailable."})
                self.assertNotIn("private", response.text)
                self.assertIsNotNone(engine.begin.return_value.__exit__.call_args.args[0])
                self.assertEqual(client.get("/health").status_code, 200)

    def test_commit_failure_does_not_return_success(self):
        with client_with_database(
            user_result(), profile_result(BASE), MagicMock(), profile_result(BASE), commit_error=True
        ) as (client, _, __):
            response = client.patch("/profile", json={"days_per_week": 4})
            self.assertEqual(response.status_code, 503)
            self.assertNotIn("private", response.text)

    def test_read_failure_and_connection_failure_are_sanitized(self):
        error = OperationalError("private SQL", {}, Exception("private credentials"))
        with client_with_database(user_result(), error) as (client, engine, _):
            self.assertEqual(client.get("/profile").status_code, 503)
            engine.connect.return_value.__exit__.assert_called_once()
        with client_with_database() as (client, engine, _):
            engine.connect.side_effect = error
            engine.begin.side_effect = error
            self.assertEqual(client.get("/profile").status_code, 503)
            self.assertEqual(client.patch("/profile", json=CREATE).status_code, 503)


if __name__ == "__main__":
    unittest.main()

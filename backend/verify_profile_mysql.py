"""Disposable real-MySQL checks: python -m backend.verify_profile_mysql.

Creates a uniquely named database with the two exact profile-related baseline
tables, tests in-process HTTP against it, then drops only that owned database.
Never imports the destructive baseline script or changes the configured database.
"""

import hashlib
import io
import json
import re
import sys
import unittest
import uuid
from concurrent.futures import ThreadPoolExecutor
from contextlib import contextmanager
from dataclasses import replace
from pathlib import Path
from threading import Barrier, Event, Lock
from unittest.mock import patch

from fastapi.testclient import TestClient
from sqlalchemy import event, text
from sqlalchemy.exc import OperationalError

from backend.config import Settings
from backend.database import create_database_engine
from backend.main import create_app
from backend.verify_live import snapshot


ROOT = Path(__file__).resolve().parents[1]
PROFILE = {
    "fitness_level": "Beginner", "primary_goal": "Build muscle",
    "workout_location": "Home", "days_per_week": 3, "minutes_per_session": 60,
}


def source_snapshot(engine):
    result = snapshot(engine)
    with engine.connect() as connection:
        rows = connection.execute(text(
            "SELECT p.* FROM user_profiles p JOIN users u ON u.user_id=p.user_id "
            "WHERE u.email=:email ORDER BY p.profile_id"
        ), {"email": "demo@gmail.com"}).all()
    result["demo_profile_sha256"] = hashlib.sha256(
        json.dumps([list(row) for row in rows], default=str).encode("utf-8")
    ).hexdigest()
    return result


@contextmanager
def fail_after_write(engine, operation):
    """Inject an application error AFTER real MySQL accepts the write."""
    observed = []

    def after_write(connection, cursor, statement, parameters, context, many):
        if statement.lstrip().upper().startswith(operation + " INTO USER_PROFILES") or (
            operation == "UPDATE" and statement.lstrip().upper().startswith("UPDATE USER_PROFILES")
        ):
            observed.append(True)
            raise OperationalError("injected failure after write", {}, Exception("test fault"))

    event.listen(engine, "after_cursor_execute", after_write)
    try:
        yield observed
    finally:
        event.remove(engine, "after_cursor_execute", after_write)


class ProfileMySQLTests(unittest.TestCase):
    engine = None
    client = None

    def setUp(self):
        with self.engine.begin() as connection:
            connection.execute(text("DELETE FROM user_profiles"))
            connection.execute(text("DELETE FROM users"))
            connection.execute(text(
                "INSERT INTO users (name,email) VALUES ('Fixture demo','demo@gmail.com')"
            ))
            self.user_id = connection.execute(text(
                "SELECT user_id FROM users WHERE email='demo@gmail.com'"
            )).scalar_one()

    def rows(self):
        with self.engine.connect() as connection:
            return [dict(row) for row in connection.execute(text(
                "SELECT * FROM user_profiles ORDER BY profile_id"
            )).mappings()]

    def create_profile(self):
        response = self.client.patch("/profile", json=PROFILE)
        self.assertEqual(response.status_code, 200)
        return response.json()

    def test_missing_user_is_404_without_account_creation(self):
        with self.engine.begin() as connection:
            connection.execute(text("DELETE FROM users"))
        self.assertEqual(self.client.get("/profile").status_code, 404)
        self.assertEqual(self.client.patch("/profile", json=PROFILE).status_code, 404)
        with self.engine.connect() as connection:
            self.assertEqual(connection.execute(text("SELECT COUNT(*) FROM users")).scalar_one(), 0)

    def test_missing_profile_and_complete_creation(self):
        self.assertEqual(self.client.get("/profile").status_code, 404)
        incomplete = self.client.patch("/profile", json={"days_per_week": 4})
        self.assertEqual(incomplete.status_code, 422)
        self.assertEqual(len(incomplete.json()["detail"]["missing_fields"]), 4)
        self.assertEqual(self.rows(), [])
        created = self.create_profile()
        self.assertEqual(created["user_id"], self.user_id)
        for name, value in PROFILE.items():
            self.assertEqual(created[name], value)
        self.assertEqual(self.client.get("/profile").json(), created)
        row = self.rows()[0]
        self.assertIsNone(row["gender"])
        self.assertIsNone(row["birth_date"])
        self.assertIsNone(row["height_cm"])
        self.assertEqual(row["stretch_recommendation"], 0)

    def test_partial_update_preserves_hidden_fields_and_other_user(self):
        self.create_profile()
        with self.engine.begin() as connection:
            connection.execute(text(
                "UPDATE user_profiles SET gender='fixture', birth_date='2000-01-01', "
                "height_cm=170.25, stretch_recommendation=TRUE WHERE user_id=:user_id"
            ), {"user_id": self.user_id})
            connection.execute(text(
                "INSERT INTO users(name,email) VALUES ('Other fixture','other@example.test')"
            ))
            connection.execute(text(
                "INSERT INTO user_profiles(user_id,days_per_week,minutes_per_session) "
                "SELECT user_id,2,30 FROM users WHERE email='other@example.test'"
            ))
        before = self.rows()
        response = self.client.patch("/profile", json={"days_per_week": 4})
        self.assertEqual(response.status_code, 200)
        expected = [dict(row) for row in before]
        for row in expected:
            if row["user_id"] == self.user_id:
                row["days_per_week"] = 4
        self.assertEqual(self.rows(), expected)
        self.assertEqual(self.client.get("/profile").json(), response.json())

    def test_insert_failure_rolls_back_real_write(self):
        with fail_after_write(self.engine, "INSERT") as observed:
            response = self.client.patch("/profile", json=PROFILE)
        self.assertTrue(observed)
        self.assertEqual(response.status_code, 503)
        self.assertEqual(response.json(), {"detail": "Database unavailable."})
        self.assertEqual(self.rows(), [])
        self.assertEqual(self.client.get("/profile").status_code, 404)

    def test_update_failure_rolls_back_real_write(self):
        self.create_profile()
        before = self.rows()
        with fail_after_write(self.engine, "UPDATE") as observed:
            response = self.client.patch("/profile", json={"minutes_per_session": 45})
        self.assertTrue(observed)
        self.assertEqual(response.status_code, 503)
        self.assertEqual(self.rows(), before)
        self.assertEqual(self.client.get("/profile").json()["minutes_per_session"], 60)

    def test_invalid_update_leaves_real_data_unchanged(self):
        self.create_profile()
        before = self.rows()
        response = self.client.patch("/profile", json={"days_per_week": 8})
        self.assertEqual(response.status_code, 422)
        self.assertEqual(self.rows(), before)

    def test_concurrent_first_creation_serializes_to_one_profile(self):
        barrier = Barrier(2)
        guard = Lock()
        second_attempt = Event()
        counts = {"attempts": 0, "returned": 0}

        def before_lock(connection, cursor, statement, parameters, context, many):
            if "FROM users WHERE email" in statement and "FOR UPDATE" in statement:
                with guard:
                    counts["attempts"] += 1
                    if counts["attempts"] == 2:
                        second_attempt.set()

        def after_lock(connection, cursor, statement, parameters, context, many):
            if "FROM users WHERE email" in statement and "FOR UPDATE" in statement:
                with guard:
                    counts["returned"] += 1
                    first = counts["returned"] == 1
                if first and not second_attempt.wait(timeout=4):
                    raise RuntimeError("Second request did not attempt its lock in time.")

        def request_profile(payload):
            barrier.wait(timeout=10)
            response = self.client.patch("/profile", json=payload)
            return payload, response.status_code, response.json()

        event.listen(self.engine, "before_cursor_execute", before_lock)
        event.listen(self.engine, "after_cursor_execute", after_lock)
        try:
            with ThreadPoolExecutor(max_workers=2) as workers:
                futures = [workers.submit(request_profile, payload) for payload in (
                    {**PROFILE, "days_per_week": 2, "minutes_per_session": 30},
                    {**PROFILE, "days_per_week": 5, "minutes_per_session": 45},
                )]
                responses = [future.result(timeout=20) for future in futures]
        finally:
            event.remove(self.engine, "before_cursor_execute", before_lock)
            event.remove(self.engine, "after_cursor_execute", after_lock)
        self.assertEqual(counts, {"attempts": 2, "returned": 2})
        for payload, status, body in responses:
            self.assertEqual(status, 200)
            for name, value in payload.items():
                self.assertEqual(body[name], value)
        self.assertEqual(len(self.rows()), 1)
        self.assertEqual(len({body["profile_id"] for _, _, body in responses}), 1)
        final = self.client.get("/profile").json()
        self.assertIn(final, [body for _, _, body in responses])


def main():
    name = "swp_profile_test_" + uuid.uuid4().hex
    report = {
        "passed": False, "tests_run": 0,
        "method": "in-process HTTP with real MySQL in a disposable two-table database",
        "rollback_method": "injected application failure after real INSERT/UPDATE execution",
        "test_database": name, "test_database_removed": False,
        "source_schema_seed_and_demo_unchanged": False,
    }
    source_engine = test_engine = None
    owned = False
    before = None
    try:
        settings = Settings.load()
        if name == settings.database or not re.fullmatch(r"swp_profile_test_[0-9a-f]{32}", name):
            raise RuntimeError("Invalid disposable database name.")
        source_engine = create_database_engine(settings)
        before = source_snapshot(source_engine)
        schema = (ROOT / "database" / "Project_add_Equipment.sql").read_text(encoding="utf-8-sig")
        statements = []
        for table in ("users", "user_profiles"):
            match = re.search(r"CREATE TABLE " + table + r"\s*\(.*?\);", schema, re.DOTALL)
            if match is None:
                raise RuntimeError("Missing fixture table definition.")
            statements.append(match.group(0))
        # No IF NOT EXISTS: ownership is credited only for a newly created DB.
        with source_engine.connect() as connection:
            connection.exec_driver_sql(f"CREATE DATABASE `{name}`")
            owned = True
        test_engine = create_database_engine(replace(settings, database=name))
        with test_engine.connect() as connection:
            for statement in statements:
                connection.exec_driver_sql(statement)
            engines = connection.execute(text(
                "SELECT ENGINE FROM information_schema.TABLES WHERE TABLE_SCHEMA=:name"
            ), {"name": name}).scalars().all()
            if len(engines) != 2 or any(value.upper() != "INNODB" for value in engines):
                raise RuntimeError("Transactional fixture tables must use InnoDB.")
        ProfileMySQLTests.engine = test_engine
        # Redirect only app engine creation to the owned fixture; production
        # configuration, .env and the already running Uvicorn are unchanged.
        with patch("backend.main.create_database_engine", return_value=test_engine):
            with TestClient(create_app()) as client:
                ProfileMySQLTests.client = client
                suite = unittest.defaultTestLoader.loadTestsFromTestCase(ProfileMySQLTests)
                result = unittest.TextTestRunner(stream=io.StringIO(), verbosity=2).run(suite)
        report.update({
            "tests_run": result.testsRun,
            "test_checks_passed": result.wasSuccessful(),
            "failed_tests": [test.id().rsplit(".", 1)[-1] for test, _ in result.failures],
            "error_tests": [test.id().rsplit(".", 1)[-1] for test, _ in result.errors],
        })
    except Exception:
        # Never print raw driver/URL errors or test tracebacks containing secrets.
        report["error"] = "Check local dependencies, MySQL access, CREATE/DROP database privileges, and source schema."
    finally:
        if test_engine is not None:
            test_engine.dispose()
        if owned and source_engine is not None:
            try:
                # name was minted here, validated, and successfully created here.
                with source_engine.connect() as connection:
                    connection.exec_driver_sql(f"DROP DATABASE `{name}`")
                report["test_database_removed"] = True
            except Exception:
                report["cleanup_error"] = "Disposable database cleanup failed; remove only the named test database."
        if before is not None and source_engine is not None:
            try:
                report["source_schema_seed_and_demo_unchanged"] = before == source_snapshot(source_engine)
            except Exception:
                report["source_check_error"] = "Could not verify source snapshot after tests."
        if source_engine is not None:
            source_engine.dispose()
    report["passed"] = bool(
        report.get("test_checks_passed") and report["tests_run"] == 7
        and report["test_database_removed"] and report["source_schema_seed_and_demo_unchanged"]
    )
    directory = ROOT / "backend" / "test-results"
    directory.mkdir(exist_ok=True)
    destination = directory / (name + ".json")
    destination.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    report["report_file"] = str(destination.relative_to(ROOT))
    print(json.dumps(report, indent=2))
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    sys.exit(main())

"""Read-only integration check using the real .env and in-process HTTP client.

Run from the project root: python -m backend.verify_live
Only hashes/counts and the MySQL version are printed; never row values or secrets.
This does not replace a real Uvicorn/network check or Task 1.5 acceptance.
"""

import hashlib
import json
import sys

from fastapi.testclient import TestClient
from sqlalchemy import inspect, text

from backend.config import ConfigurationError, Settings
from backend.database import create_database_engine
from backend.main import create_app


def snapshot(engine):
    with engine.connect() as connection:
        tables = sorted(inspect(connection).get_table_names())
        schema = []
        for table in tables:
            quoted = engine.dialect.identifier_preparer.quote_identifier(table)
            schema.append(connection.execute(text(f"SHOW CREATE TABLE {quoted}")).one()[1])
        seed = {}
        for table, key in (("equipment", "equipment_id"), ("exercises", "exercise_id")):
            digest = hashlib.sha256()
            count = 0
            for row in connection.execute(text(f"SELECT * FROM {table} ORDER BY {key}")):
                digest.update(json.dumps(list(row), default=str, ensure_ascii=False).encode("utf-8"))
                digest.update(b"\n")
                count += 1
            seed[table] = {"count": count, "sha256": digest.hexdigest()}
        return {
            "table_count": len(tables),
            "schema_sha256": hashlib.sha256("\n".join(schema).encode("utf-8")).hexdigest(),
            "seed": seed,
        }


def main():
    engine = None
    try:
        engine = create_database_engine(Settings.load())
        before = snapshot(engine)
        with engine.connect() as connection:
            version = connection.execute(text("SELECT VERSION()")).scalar_one()
        with TestClient(create_app()) as client:
            health = client.get("/health")
            database_health = client.get("/health/db")
            docs = client.get("/docs")
        after = snapshot(engine)
        passed = (
            health.status_code == 200 and health.json() == {"status": "ok"}
            and database_health.status_code == 200
            and database_health.json() == {"status": "ok", "database": "connected"}
            and docs.status_code == 200 and before == after
        )
        print(json.dumps({
            "passed": passed,
            "method": "in-process HTTP with real MySQL; no Uvicorn/network verification",
            "mysql_version": version,
            "health_http_status": health.status_code,
            "database_health_http_status": database_health.status_code,
            "docs_http_status": docs.status_code,
            "schema_and_seed_unchanged": before == after,
            "snapshot": after,
        }, indent=2))
        return 0 if passed else 1
    except ConfigurationError as error:
        print(str(error), file=sys.stderr)
        return 1
    except Exception:
        # Avoid printing connection URLs, credentials or database row values.
        print("Verification failed. Check local configuration, MySQL access and installed dependencies.", file=sys.stderr)
        return 1
    finally:
        if engine is not None:
            engine.dispose()


if __name__ == "__main__":
    raise SystemExit(main())

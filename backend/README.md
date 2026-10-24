# Backend — Foundation and demo Profile API

Implemented: synchronous FastAPI + SQLAlchemy + PyMySQL, local configuration,
liveness/readiness endpoints, connection disposal at shutdown, and the Task 2.2
demo Profile API. No ORM models, schema initialization, migrations, or seeding
are included. Task 2.1 is locally accepted; Task 2.2 isolated suite passed (18 tests, user-supplied summary); live GET /profile returned 200 with demo data supplied by the user; Codex verified live PATCH/readback and invalid-value rejection; the user-run seven-check MySQL suite passed with a saved JSON report; Task 2.2 is complete for local demo scope.

## Task 2.1 verification evidence and limits

On 2026-10-18 the user reported successful installation through VS Code CMD in the
existing root `.venv` and a successful `backend.verify_live` result. The complete
JSON was not supplied; its overall pass flag was reported by the user.

The user then supplied these actual curl responses from Uvicorn on loopback:

| Route | Supplied HTTP status | Supplied body |
| --- | --- | --- |
| `/health` | 200 OK | `{"status":"ok"}` |
| `/health/db` | 200 OK | `{"status":"ok","database":"connected"}` |

Response timestamps were 2026-10-18 15:23:46 and 15:24:13 GMT respectively.
These demonstrate successful real HTTP and MySQL connectivity on the user's
machine. Codex did not execute Python because of its environment access limit.
The user subsequently reported that `python -m unittest discover -s backend/tests -v`
returned `OK`. This covers isolated missing-config, failure-response, special-character
password and cleanup checks; it is user-reported, with no full test log supplied.
Task 2.1 is complete for local foundation scope. SQL T01–T14 passing is also
user-reported and was not independently repeated by this task.

## Setup in PowerShell

For a new clone on a teammate's computer, first follow
[TEAM_SETUP.md](../docs/TEAM_SETUP.md) to create that machine's environment,
prepare its own MySQL database, and create its local `.env`. The existing-environment
instructions below apply when a root `.venv` already exists. Dependencies remain
unpinned; this handoff does not establish a validated environment on another machine.

Run from the project root through VS Code CMD or PowerShell, using the existing
root virtual environment. There is no need to recreate it or reinstall Python.

```powershell
.\.venv\Scripts\python.exe --version
# Use the existing virtual environment at the project root; do not recreate it.
.\.venv\Scripts\python.exe -m pip install -r backend/requirements-dev.txt
```

Requirements are deliberately not pinned to unverified versions. After successful
installation and checks, record the resolved versions before claiming a validated
dependency baseline. `PyMySQL[rsa]` includes support for MySQL SHA-2 authentication.

The existing `backend/.env` is preserved. Fill in all five DB_* keys shown in
`.env.example`. An explicitly empty password is supported if that is how the
local database account is configured. The other fields must be nonempty; port
must be an integer between 1 and 65535. Use the existing baseline database.

The file is loaded relative to the backend code, with UTF-8 BOM support. Process
environment variables override file values. `${...}` expansion is disabled to
preserve literal passwords. Follow python-dotenv quoting rules for special
characters; keep the file local and never include it in screenshots or reports.

## Check and run

```powershell
# Isolated tests: fake connections; does not prove MySQL connectivity.
.\.venv\Scripts\python.exe -m unittest discover -s backend/tests -v

# Real MySQL, in-process HTTP; read-only schema and seed comparison.
.\.venv\Scripts\python.exe -m backend.verify_live

# Actual HTTP server, loopback only. Stop with Ctrl+C.
.\.venv\Scripts\python.exe -m uvicorn backend.main:app --host 127.0.0.1 --port 8000
```

From a second PowerShell window:

```powershell
Invoke-RestMethod http://127.0.0.1:8000/health
Invoke-RestMethod http://127.0.0.1:8000/health/db
```

Swagger UI: <http://127.0.0.1:8000/docs>.

| Request | Successful response | Failure behavior |
| --- | --- | --- |
| `GET /health` | 200 `{"status":"ok"}` | Does not query MySQL |
| `GET /health/db` | 200 `{"status":"ok","database":"connected"}` | 503 `{"status":"error","database":"unavailable"}` |

Missing/invalid configuration stops startup with field names only. With valid
configuration but unavailable MySQL, the app starts and liveness remains available;
the database endpoint returns 503. Engine connections are lazy. Each DB check
uses a context manager that returns its connection to the pool and rolls back its
read transaction; shutdown disposes the pool. All synchronous DB work is handled
outside the async event loop. Connection, read, write, and pool waits are bounded.

`verify_live` compares SHOW CREATE TABLE output and hashed equipment/exercise rows
before and after health requests. It prints no row contents. Concurrent database
changes can make comparison fail. It does not validate all database constraints,
all user data, Task 1.5 results, or a real HTTP network connection.

Implementation references: [FastAPI lifespan](https://fastapi.tiangolo.com/advanced/events/),
[SQLAlchemy engine configuration](https://docs.sqlalchemy.org/en/20/core/engines.html),
[python-dotenv](https://bbc2.github.io/python-dotenv/).

## Task 2.2 — Demo Profile API

Implemented `GET /profile` and `PATCH /profile` using the existing demo user
found by email `demo@gmail.com`. This is local demo mode without authentication.
Run Uvicorn on loopback as above. The server selects the demo user; body keys
such as `user_id` are rejected. Query parameters do not select another user.

Both routes return `profile_id`, `user_id`, `fitness_level`, `primary_goal`,
`workout_location`, `days_per_week`, and `minutes_per_session`.
PATCH accepts the five editable fields only. Omitted fields are preserved;
nulls, unknown keys, an empty object, invalid enums, numeric strings, booleans,
and fractional numeric values return 422. GET preserves existing NULLs/legacy
text. See [complete contract and allowed values](../docs/BACKEND_SPEC.md#task-22--approved-demo-profile-contract).

GET returns 404 if the demo user/profile is absent. PATCH returns 404 for a
missing demo user. If the user exists but has no profile, PATCH requires all
five editable fields and returns 422 if any are missing; otherwise it creates
the profile and returns 200. No account is automatically created. Database
errors return generic 503 responses. Other profile fields are preserved on
update and use database defaults/NULLs on creation.

The isolated suite is in `tests/test_profile.py`; run the existing discovery
command from the project root. After Codex's interpreter attempt failed with
`Access is denied`, the user supplied `Ran 18 tests in 0.974s` and `OK` for
the isolated discovery suite (7 foundation tests and 11 profile tests).
No per-test log was supplied; Codex did not execute the suite. The user also
supplied Swagger `GET /profile` HTTP 200 with profile/user IDs 1/1, Beginner,
Build muscle, Home, 3 days/week, and 60 minutes/session, confirming the local
live read path. Codex subsequently verified live days-only PATCH/readback
4 → 5 → 4, duration remaining 1, and rejection of days 8 with 422 and unchanged
returned data. The earlier duration change from 60 to 1 was not reproduced;
the user subsequently confirmed 60 minutes. Codex PATCHed only
minutes_per_session and verified GET at 4 days/week and 60 minutes/session,
with other returned fields unchanged. The user subsequently ran the disposable
MySQL suite: all seven checks passed, including creation, fault-injected rollback,
and concurrent first creation. Codex reviewed the saved JSON result. Task 2.2
is complete for local demo scope.
The read-only `backend.verify_live`
command checks health/schema/seed only; it does not test profile routes.

After starting Uvicorn, read the demo profile in a second PowerShell window:

```powershell
Invoke-RestMethod http://127.0.0.1:8000/profile
```

Example partial update (writes the demo's `days_per_week`):

```powershell
Invoke-RestMethod http://127.0.0.1:8000/profile -Method Patch `
  -ContentType 'application/json' -Body '{"days_per_week":3}'
Invoke-RestMethod http://127.0.0.1:8000/profile
```

Confirm the response and subsequent GET show the saved value while other
fields remain unchanged. Also check an invalid value, such as 8 days, returns
422 and leaves the profile unchanged. To test missing-user/profile creation,
rollback, and concurrent first creation, use a separately prepared isolated
database fixture; do not delete the existing demo profile or reset the baseline.
Complete first-creation payload:

```json
{
  "fitness_level": "Beginner",
  "primary_goal": "Build muscle",
  "workout_location": "Home",
  "days_per_week": 3,
  "minutes_per_session": 60
}
```

Implementation references: [Pydantic validators](https://docs.pydantic.dev/latest/concepts/validators/)
and [SQLAlchemy transaction contexts](https://docs.sqlalchemy.org/en/20/core/connections.html#connect-and-begin-once-from-the-engine).

## Task 2.2 — Disposable MySQL acceptance checks

Run from the project root in VS Code CMD (the existing Uvicorn server can stay
running; this command uses a separate in-process app and database):

```bat
.venv\Scripts\python.exe -m backend.verify_profile_mysql
```

This command uses the existing local configuration without printing credentials.
The MySQL account must be able to CREATE/DROP a temporary database. It creates a
unique `swp_profile_test_<random>` database, loads only the exact `users` and
`user_profiles` CREATE TABLE definitions from the baseline SQL, requires InnoDB,
and inserts synthetic fixtures. It never executes the baseline DROP DATABASE,
imports the master seed, or edits the configured database. Its cleanup drops
only the unique database successfully created by this invocation. If cleanup
fails, the report identifies that disposable name for manual cleanup.

Seven checks cover missing demo user, missing profile/incomplete/complete creation,
partial updates preserving hidden fields and another user's profile, rollback
of real INSERT and UPDATE operations after injected application failures,
invalid-write preservation, and overlapping first-creation requests. The
concurrency check coordinates two request threads so the second attempts its
user-row lock while the first holds it. Both must succeed with one profile row.
The rollback checks simulate application failure after SQL execution; they do
not simulate a real server outage or failed commit.

The command compares hashes of the configured database's schema, equipment,
exercises, and demo profile before/after. It emits sanitized JSON and saves a
report under `backend/test-results/` (ignored by Git). Expected overall success:
`passed: true`, `tests_run: 7`, `test_database_removed: true`, and
`source_schema_seed_and_demo_unchanged: true`. Avoid concurrent edits to source
seed/profile data during this snapshot comparison.

Status: user-run suite passed all seven checks. Codex reviewed the matching
saved report `test-results/swp_profile_test_36c3f3b5752b4878ab6f52491e5b0705.json`:
`passed: true`, `test_checks_passed: true`, no failed/error tests,
`test_database_removed: true`, and `source_schema_seed_and_demo_unchanged: true`.
Codex did not execute Python. These are real-MySQL, in-process HTTP checks;
the existing separate live HTTP evidence covers GET/PATCH/readback and invalid
input. Task 2.2 is accepted for local demo scope, without production authentication,
real server outage/commit-failure testing, or full application acceptance.

References: [SQLAlchemy cursor events](https://docs.sqlalchemy.org/en/20/core/events.html#sqlalchemy.events.ConnectionEvents.after_cursor_execute)
and [MySQL locking reads](https://dev.mysql.com/doc/refman/8.0/en/innodb-locking-reads.html).

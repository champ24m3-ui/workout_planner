# Backend specification — Phase 2 planning baseline

Original SQL baseline date: 2026-10-18 (Asia/Bangkok). Current update: Task 2.1 is complete locally from user-run validation: live check passed, unittest OK, and real HTTP/MySQL responses supplied. Task 2.2 demo Profile API is implemented; the user supplied an 18-test OK summary; live GET /profile returned 200 with demo data supplied by the user; Codex verified live PATCH/readback and invalid-value rejection; the user-run seven-check MySQL suite passed with a saved JSON report; Task 2.2 is complete for local demo scope; Tasks 2.3–2.5 are not started.

## Current Task 2.1 implementation

Update (2026-10-18): the user authorized Python + FastAPI + SQLAlchemy + MySQL,
using synchronous PyMySQL. Code is implemented in `backend/`. The user installed
dependencies using the root `.venv`, reported `backend.verify_live` passed, and
supplied real Uvicorn HTTP 200 responses for both health routes on 2026-10-18.
The database response was `{"status":"ok","database":"connected"}`. Codex did
not execute Python. The user subsequently reported isolated unittest results `OK`,
covering configuration/failure/cleanup checks. Full test logs were not supplied.
Task 2.1 is complete for local foundation scope; production acceptance is not claimed.

Approved routes: `GET /health` returns 200 `{"status":"ok"}` without querying
MySQL; `GET /health/db` runs `SELECT 1` and returns 200
`{"status":"ok","database":"connected"}` or a sanitized 503
`{"status":"error","database":"unavailable"}`. Missing configuration stops
startup. Valid configuration with unavailable MySQL allows liveness to remain
available. Shutdown disposes the engine; query context managers clean up connections.

Configuration uses the five DB_* names below, `backend/.env`, process-environment
overrides, literal password handling and SQLAlchemy `URL.create`. No schema
creation/seeding or domain APIs are included. Requirements remain unpinned until
installation and validation establish actual resolved versions. See
[setup, contracts and checks](../backend/README.md).

The foundation description above records Task 2.1's original scope. Task 2.2
below adds the demo Profile API; it does not change that prior validation evidence.

## Task 2.2 — Approved demo profile contract

Confirmed by the user on 2026-10-20. Implemented in `backend/profile.py` and
registered by `backend/main.py`. The user supplied the isolated discovery
summary `Ran 18 tests in 0.974s` and `OK`, covering the foundation/profile
suite. No per-test log was supplied; Codex did not execute Python. Real Profile
API GET was subsequently confirmed by user-supplied Swagger HTTP 200 output
with demo profile/user IDs 1/1 and the expected five profile values. Codex then
verified live PATCH/readback (days 4 → 5 → 4, duration remaining 1 and other
returned fields unchanged) and invalid days 8 returning 422 without a data
change. The earlier 60-to-1 duration change was not reproduced and remains
unexplained. The user subsequently requested 60 minutes; Codex updated only
minutes_per_session and verified GET at 4 days/week and 60 minutes/session,
with other returned fields unchanged. The user-run real-MySQL suite then passed
all seven checks, including creation, rollback after injected post-write errors,
and overlapping first creation. Codex reviewed the saved JSON report, including
successful cleanup and unchanged source hashes. Task 2.2 is complete for local
demo scope; no production authentication or outage acceptance is claimed.

- Identity: resolve the existing user by `demo@gmail.com` on every request;
  no hard-coded numeric ID, caller-selected user, account creation, or login.
- `GET /profile`: 200 with the demo profile; 404 if the demo user or profile
  does not exist. It does not create or update data.
- `PATCH /profile`: 200 with the latest profile, including first creation.
  Existing profiles accept a nonempty subset of the five editable fields.
  Missing profiles require all five fields; incomplete creation returns 422
  without a write. Missing demo user returns 404 without creating an account.
- Response fields: `profile_id`, `user_id`, and the five editable fields.
  GET and PATCH responses preserve existing SQL NULLs/legacy text in unchanged
  fields; no password, account metadata, or unrelated profile fields are exposed.
- Other profile fields (gender, birth date, height, stretch flag) cannot be
  edited through this API. Updates preserve them; creation leaves them to
  existing database defaults/NULLs. Unknown body keys, empty bodies, invalid
  values, and explicitly supplied nulls return 422. Omitted keys are unchanged.
- Allowed PATCH values are exact and case-sensitive:

| Field | Accepted value |
| --- | --- |
| `primary_goal` | `Build muscle`, `Lose fat`, `General fitness` |
| `fitness_level` | `Beginner`, `Intermediate`, `Advanced` |
| `workout_location` | `Home`, `Gym` |
| `days_per_week` | JSON integer 1–7 |
| `minutes_per_session` | JSON integer 1–2147483647 (existing signed SQL INT limit) |

Numeric strings, booleans, and fractional numbers are rejected. These allowed
values are approved API rules, not new SQL enums or schema constraints.
Standard validation failures use FastAPI's 422 detail list; incomplete first
creation uses a 422 detail object with `message` and `missing_fields`.
404 responses use `{"detail":"Demo user not found."}` or
`{"detail":"Profile not found."}`. Database failures use sanitized
503 `{"detail":"Database unavailable."}` with no raw driver errors.

PATCH uses a single `engine.begin()` transaction and locks the resolved demo
user with `FOR UPDATE` to serialize requests through this endpoint, including
first creation. Only allowlisted column names enter SQL; all values are bound
parameters. Readback validation happens before commit and success is returned
after commit. Transaction/connection contexts handle rollback and cleanup.
Real MySQL transaction and concurrent first-creation checks passed in the
user-run suite. These checks are implemented in `backend/verify_profile_mysql.py`, a
seven-check disposable MySQL runner. It uses real connections and in-process
HTTP, with an injected application error after actual writes for rollback checks
and two overlapping requests for first-creation checks. No production failure
or network test is implied. The saved user-run report records all seven checks
passed, test database removed, and unchanged source hashes. Codex reviewed the
report but did not execute Python. See [evidence, instructions and cleanup boundaries](../backend/README.md#task-22--disposable-mysql-acceptance-checks).

The isolated tests cover HTTP contracts with fake database results, invalid
values, demo identity, missing records, allowed SQL writes, transaction context
exit on errors, and sanitized query/commit failures. They do not prove real
MySQL persistence, rollback, or locking. See [manual checks](../backend/README.md#task-22--demo-profile-api).

The sections labeled original or proposed below preserve the earlier planning
baseline; the current updates supersede them for Tasks 2.1 and 2.2.

## Original implementation status and origin

There is no accepted backend implementation in this baseline. Phase 2 restarts from zero after documentation is complete. The referenced discussion proposes **Python + FastAPI + SQLAlchemy + MySQL**. These are planned technologies; the SQL proves the database structure, not an installed Python environment, framework version, driver, API, or connection configuration.

No HTTP routes, request/response schemas, authentication policy, dependency versions, or deployment commands are finalized by the uploaded SQL. Do not claim a route works or supply a fictitious backend startup command. Ask for missing details when authorizing the relevant implementation task.

## Task boundaries

| Task | Planned responsibility | Status |
| --- | --- | --- |
| 2.1 | Clean FastAPI setup and database configuration/connection lifecycle | Complete locally: user-reported unittest OK/live check pass, supplied HTTP/MySQL success |
| 2.2 | Demo Profile API using users and user_profiles | Implemented; isolated suite passed (18 tests, user-supplied summary); live GET /profile 200 confirmed from user-supplied output; live PATCH/readback and invalid-value rejection verified by Codex; seven real-MySQL checks passed (saved user-run report); Task 2.2 complete for local demo scope |
| 2.3 | Equipment/exercise API using the current catalog and user selections | Not started |
| 2.4 | Program API using programs and program_exercises | Not started |
| 2.5 | Session/set-log API using workout_sessions and set_logs | Not started |

These responsibilities follow the planning outline in the referenced discussion. Detailed operations, paths, and acceptance examples still require task-level agreement. Body measurements, exercise preferences, and custom exercise writes must use existing tables if requested; their precise API scope is not silently added to this outline.

## Suggested organization for review when Task 2.1 begins

The following is a proposed layout, not a list of existing files or completed work:

```text
backend/
  main.py          # application entry point
  database.py      # configuration, engine/session lifecycle
  .env.example    # placeholder connection configuration
  requirements.txt
  tests/          # relevant checks as implementation is added
```

Add ORM models, request/response schemas, routes, and service modules only as authorized tasks require them. Folder naming, package layout, database driver, sync/async approach, Python version, and dependency versions should be settled before dependent setup work. Do not generate models for entities outside the 11-table baseline.

## Configuration contract to confirm

The prior discussion uses DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, and DB_NAME. Confirm these names and the real local connection settings when implementing Task 2.1. DB_NAME must address the existing `smart_workout_planner` baseline; host, port, username, and password are environment-specific. Do not assume root access or share actual secrets.

The future .env.example should contain placeholders and no credentials. Keep .env out of version control. Construct connection configuration without exposing or corrupting passwords containing special characters. Missing configuration and unavailable MySQL should produce clear errors without leaking secrets. Do not import the destructive SQL as part of initialization.

## Database integration requirements

Read DATABASE.md and DATA_DICTIONARY.md, then map the existing schema faithfully. Preserve all primary/foreign keys, unique constraints, DECIMAL precision/scale, NULL semantics, and server defaults. Do not use ORM model creation or migrations to replace the final SQL without explicit authorization. Seed IDs are not fixed API constants.

Use explicit session cleanup and rollback on failure. Keep related writes atomic. Query the existing equipment/exercise masters rather than maintaining a second hard-coded master list. Count checks such as 301 apply to the supplied pristine seed, not to every future production database.

## Rules for future operations

| Operation area | Required behavior / limit |
| --- | --- |
| Profiles | Respect optional fields; positive height and minutes; days_per_week 1–7; do not invent a full enum list from the demo |
| Body measurements | Positive required weight_kg; preserve measurement history if this API is authorized |
| User equipment | Unique user/equipment pairs; Bodyweight is an explicit equipment row in the demo, not an implicit universal selection |
| Exercise candidates | Match selected equipment; include NULL creator or current-user creator; do not equate candidates with recommendations |
| Preferences | Only favorite/excluded; unique user/exercise pair; Task 1.5 candidates currently do not apply exclusions |
| Programs | Validate date order and owner; preserve optional first target_weight; positive day/exercise order, sets and rep ranges |
| Sessions | Validate user and optional program ownership; ordered start/end datetimes; permit NULL program_id |
| Set logs | Validate session ownership; if planned, match exercise and program association; permit NULL planned link; nonnegative actual_reps, load/rest/RIR; RPE 1–10 |

Authentication and authorization remain undecided; these validation requirements do not themselves define how the current user is authenticated. Do not expose production user-data operations until that contract is established.

## Decisions the SQL cannot supply

- Exact API methods, paths, payloads, response shape, pagination, error format, and partial-update semantics.
- Identity/authentication, account lifecycle, and custom-exercise deletion/provenance policy.
- Full allowed vocabularies for profile/program fields and units for target_weight/actual_weight.
- Time zone handling for naive DATE/DATETIME fields and conventions for duration/distance exercises represented with rep ranges 1–1.
- Generation, exclusion/favorite ranking, stretch-selection, fatigue, and adaptive load/progression rules.

Ask before implementing behavior that depends on these choices. A schema gap is not permission to add a column or table.

## Validation expectations once implementation is authorized

Task 2.1 should establish application startup, clear missing-config behavior, actual database connectivity, safe connection cleanup, and evidence that initialization leaves schema and seed untouched. Later tasks need validation and ownership tests, nullable/ad hoc scenarios, atomic failure handling, and API contract checks appropriate to their changes. None of these checks have been run or passed as part of this documentation baseline.

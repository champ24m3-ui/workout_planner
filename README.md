# Smart Workout Planner

Smart Workout Planner's final goal is to become a **complete user-facing application** for personalized workout planning and workout logging. The database and Backend API are foundations for delivering that application; they are intermediate milestones rather than the final deliverable.

The intended development path is:

**Database → Backend API → Workout Logic → Frontend Application → Integration → Testing → Demo/Deployment**

The finished application should let users manage their workout profile and available equipment, receive and view workout programs, and record workout sessions and set results through a usable frontend connected to the backend and database. Detailed workout rules, frontend technology, and demo/deployment arrangements will be agreed before their implementation. See the [project specification](docs/PROJECT_SPEC.md) and [full development roadmap](docs/ROADMAP.md).

Baseline date: 2026-10-18 (Asia/Bangkok). Source: `Project_add_Equipment.sql`, including embedded Tasks 1.4 and 1.5. Phase 1 SQL implementation is complete in source; the user reports T01–T14 passed, but saved results were not independently reviewed here. Task 2.1 is complete for the local foundation scope: the user reports live verification passed and unittest returned OK, and supplied successful real HTTP/MySQL responses. Task 2.2 demo Profile API is implemented; the user supplied an 18-test OK summary; live GET /profile returned 200 with demo data supplied by the user; Codex verified live PATCH/readback and invalid-value rejection; the user-run seven-check MySQL suite passed with a saved JSON report; Task 2.2 is complete for local demo scope; Tasks 2.3–2.5 are not started.

## Read before making changes

Read this file and every document below before editing SQL or implementing backend work:

1. [Project scope](docs/PROJECT_SPEC.md)
2. [Database baseline](docs/DATABASE.md)
3. [Data dictionary](docs/DATA_DICTIONARY.md)
4. [Backend specification](docs/BACKEND_SPEC.md)
5. [Roadmap and evidence](docs/ROADMAP.md)
6. [Coding rules](docs/CODING_RULES.md)
7. [Changelog](docs/CHANGELOG.md)

The attached final SQL is the source of truth for table structure, constraints, equipment names, exercise metadata, and equipment mappings. The current user request controls scope. Earlier experimental Phase 2 files or chat suggestions are not evidence of completed backend work. Ask before proceeding whenever information needed for a decision is insufficient.

## Current state

| Area | Evidence-backed status |
| --- | --- |
| Task 1.1 — schema | Complete in source: exactly 11 CREATE TABLE statements |
| Task 1.2 — equipment | Complete in source: 22 master rows |
| Task 1.3 — exercises | Complete in source: 301 system rows |
| Task 1.4 — mock data | Complete in source: demo user, profile, exactly two equipment choices |
| Task 1.5 — test queries | Complete in source: T01–T14 plus inspection queries; live PASS results unavailable |
| Phase 2 — backend | Task 2.1 complete locally from user-run validation; Task 2.2 demo Profile API implemented; isolated suite passed (18 tests, user-supplied summary); live GET /profile 200 confirmed from user-supplied output; live PATCH/readback and invalid-value rejection verified by Codex; seven real-MySQL checks passed (saved user-run report); Task 2.2 complete for local demo scope; Tasks 2.3–2.5 not started |

This project stores workout profiles, available equipment, exercises, preferences, programs, sessions, and set results. Current APIs cover health and the demo profile. Recommendation logic, authentication, remaining domain APIs, and the frontend are not implemented.

## Working with a teammate

Clone this repository and follow the [new-machine and collaboration guide](docs/TEAM_SETUP.md).
Each developer uses their own local `backend/.env`, Python virtual environment,
and development MySQL database. Git does not synchronize database contents.
Existing environments should be reused; a new clone creates its own `.venv`.
Dependencies are currently unpinned, so matching code alone does not establish
matching environments or a successful run on another machine.

AI assistants start with [AGENTS.md](AGENTS.md); Claude Code starts with
[CLAUDE.md](CLAUDE.md), which points to the same shared rules. Current work and
test evidence live in the repository documents, rather than only in chat history.

## Repository contents

```text
README.md
.gitignore
AGENTS.md                   # shared instructions for coding agents
CLAUDE.md                   # Claude Code entry point
Project_add_Equipment.sql   # retained original copy; same bytes as database/ copy
backend/
  README.md
  __init__.py
  main.py
  config.py
  database.py
  profile.py
  .env.example              # placeholders only; each machine creates .env locally
  requirements.txt
  requirements-dev.txt
  verify_live.py
  verify_profile_mysql.py
  tests/
    __init__.py
    test_foundation.py
    test_profile.py
database/
  Project_add_Equipment.sql  # unchanged source, includes Tasks 1.4 and 1.5
docs/
  PROJECT_SPEC.md
  DATABASE.md
  DATA_DICTIONARY.md
  ROADMAP.md
  CHANGELOG.md
  CODING_RULES.md
  BACKEND_SPEC.md
  TEAM_SETUP.md
```

Keep these paths when cloning or copying the project. Use `database/Project_add_Equipment.sql` as the baseline reference; the root copy is retained unchanged, not a second migration to execute. The `database/` copy preserves the uploaded file byte for byte. See [backend setup and verification](backend/README.md). Local `.env`, `.venv`, test results, caches and editor settings are excluded from Git. Historical saved test reports mentioned below are local evidence and are not included in the repository upload; the documented prior acceptance is not a test result for a new clone.

## Database setup and validation

**The full SQL starts with `DROP DATABASE IF EXISTS smart_workout_planner`. It destroys any existing database with that name.** Do not run it automatically against an existing database. Use an explicitly selected disposable database environment and obtain permission before replacing real data.

The SQL's Task 1.4 comment specifies MySQL 8.0.16+. Confirm the actual server version and connection settings before execution. Open the complete file in a SQL client configured to stop on errors, and run its statements in order in one connection so session variables survive. The actual order is schema → equipment → exercise seed → final validation → Task 1.4 → Task 1.5. Comments referring to separate Task 1.4/1.5 filenames are historical; both sections are embedded in this file.

Task 1.4 uses an explicit transaction. If it errors before COMMIT, stop and ROLLBACK; the script does not provide an automatic exception handler. The preceding database creation and seed are not wrapped by that transaction. A Task 1.5 FAIL appears in a result set and does not itself raise a SQL error. Review every T01–T14 result, including all 14 T12 mapping rows and both T14 equipment rows.

Expected pristine baseline: 11 base tables, 22 equipment, 301 system exercises; one demo user and profile; two demo equipment links; 92 equipment-eligible system exercises (43 Bodyweight + 49 Dumbbell). Exact-count checks describe this seed before additional data. See [validation details](docs/ROADMAP.md).

## Verification supplied with these documents

Static inspection confirmed all schema definitions, all 301 exercise rows, 22 equipment rows, the 14 reference mappings, nonduplicate seed names, valid seed rep ranges, and the 43/49 eligibility counts. These are source checks, not MySQL result sets. No database was dropped, imported, or modified; no backend was started or tested.

Source SHA-256: `6b9459a2169880d535137d1b0c563bd558c00fcc5b3c4839553cd89702db36a1`.

## Task 2.2 — Demo Profile API

Implemented `GET /profile` and `PATCH /profile` for the existing user found by
`demo@gmail.com`. The approved contract covers fitness level, goal, location,
days per week, and minutes per session. PATCH updates only supplied fields;
creating a missing profile requires all five fields. This is a local demo mode
without login or caller-selected user IDs. No schema or master seed changes.

Status: implemented; the user supplied `Ran 18 tests in 0.974s` followed by
`OK` for the isolated discovery suite. Codex did not execute the suite; no
per-test log was supplied. The user also supplied a Swagger `GET /profile`
response: HTTP 200 with demo profile/user IDs 1/1, Beginner, Build muscle, Home,
3 days/week, and 60 minutes/session. This verifies the local live read path
from the supplied output. Codex subsequently verified the live API by reading
4 days/1 minute, PATCHing only days to 5, and reading back 5 days/1 minute.
Other returned fields stayed unchanged. An 8-day PATCH returned 422 without
changing returned data. Days were restored to 4 and GET matched the initial
response. The earlier 60-to-1-minute change is unexplained; it was not reproduced.
The user then requested 60 minutes; Codex PATCHed only minutes_per_session and
verified GET at 4 days/week and 60 minutes/session with other returned fields
unchanged.
The user subsequently ran the seven-check real-MySQL suite successfully; Codex
reviewed its saved JSON report. Missing-user/profile creation, hidden-field and
other-user preservation, rollback after injected post-write errors, invalid
writes, and overlapping first creation passed. The temporary database was removed
and source schema/seed/demo hashes were unchanged. Task 2.2 is complete for the
local demo scope; production authentication and full application acceptance are
outside this scope. See [evidence and rerun instructions](backend/README.md#task-22--disposable-mysql-acceptance-checks).
See [contract and manual checks](backend/README.md#task-22--demo-profile-api).

## Task 2.1 — Foundation implementation and prior validation

The user authorized FastAPI + SQLAlchemy + PyMySQL against the existing MySQL database.
Implemented `GET /health` (liveness) and `GET /health/db` (read-only `SELECT 1`,
sanitized 503 on connection failure). That Task 2.1 delivery changed no schema
or seed data; the separately authorized Task 2.2 routes are described above.

The user installed dependencies through VS Code CMD using the existing root `.venv`
and reported `backend.verify_live` passed. On 2026-10-18 the user supplied real
Uvicorn HTTP responses: `/health` returned 200 `{"status":"ok"}` and `/health/db`
returned 200 `{"status":"ok","database":"connected"}`. This establishes the
successful local application/database path. The user subsequently reported the
isolated unittest command returned `OK`, covering configuration, database failure
and cleanup. Codex did not execute Python; full unittest/live-check logs were not
supplied. Task 2.1 is complete within this local scope, without production acceptance.
See [backend instructions](backend/README.md). The earlier documentation-only
verification section describes the original SQL baseline.

## Original starting instruction (historical)

Example instruction for Codex:

> Read README.md and all seven documents in docs/ first. Start Task 2.1 only from a clean backend baseline. Keep the existing 11-table schema and all current seed data. Ask before making a decision for which information is insufficient. Report implementation and validation separately.

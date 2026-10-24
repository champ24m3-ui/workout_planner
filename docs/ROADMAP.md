# Roadmap and validation evidence

Original SQL baseline date: 2026-10-18 (Asia/Bangkok), including embedded Tasks 1.4 and 1.5. Phase 1 is complete in source, with T01–T14 passing reported by the user. Current Phase 2 status: Task 2.1 complete locally from user-run validation, including unittest OK, live-check pass and supplied HTTP/MySQL responses. Task 2.2 demo Profile API is implemented; the user supplied an 18-test OK summary; live GET /profile returned 200 with demo data supplied by the user; Codex verified live PATCH/readback and invalid-value rejection; the user-run seven-check MySQL suite passed with a saved JSON report; Task 2.2 is complete for local demo scope; Tasks 2.3–2.5 are not started.

## Final goal and intended development path

Smart Workout Planner's final goal is a **complete user-facing application** for personalized workout planning and workout logging. Database and Backend API completion are intermediate milestones. Project completion requires a usable frontend connected to workout logic, APIs, and persistent data, followed by integrated application validation and an agreed demo/deployment handoff.

The intended development path, clarified on 2026-10-20, is:

**Database → Backend API → Workout Logic → Frontend Application → Integration → Testing → Demo/Deployment**

| Stage | Intended outcome | Current status |
| --- | --- | --- |
| Database | Existing schema, equipment/exercise seed, mock data, and SQL validation queries | Phase 1 complete in source; user reports T01–T14 passed; result sets not independently reviewed |
| Backend API | Application setup and APIs for profiles, equipment/exercises, programs, sessions, and set logs | Task 2.1 complete locally; Task 2.2 implemented; isolated suite passed (18 tests, user-supplied summary); live GET /profile 200 confirmed from user-supplied output; live PATCH/readback and invalid-value rejection verified by Codex; seven real-MySQL checks passed (saved user-run report); Task 2.2 complete for local demo scope; Tasks 2.3–2.5 not started |
| Workout Logic | Agreed rules for personalized exercise selection and workout program generation | Not started; rules require clarification |
| Frontend Application | User interface for profile/equipment setup, workout programs, and session/set logging | Not started; UI design and frontend technology require agreement |
| Integration | Connect frontend flows to the Backend API, workout logic, and database | Not started for the complete application; Task 2.1 already verifies local backend/database connectivity |
| Testing | Validate complete user journeys, data persistence, error handling, and agreed application acceptance criteria | Full application testing not started; existing SQL and Task 2.1 checks retain their recorded scope |
| Demo/Deployment | Prepare and demonstrate or deploy the tested application in an agreed environment, with setup/run instructions | Not started; target environment and handoff criteria require agreement |

This sequence describes the overall delivery path. Relevant tests accompany implementation throughout development; the Testing stage validates the integrated application. Existing Phase 1 and Phase 2 task numbers remain unchanged. Detailed later-stage tasks and acceptance criteria will be agreed before implementation.

## Repository handoff — 2026-10-24

Retained the existing backend/database/docs layout, added shared agent
instructions (`AGENTS.md`, `CLAUDE.md`) and a
[new-machine collaboration guide](TEAM_SETUP.md), expanded the repository tree,
and excluded machine-specific editor files. This prepares the existing source
for the GitHub repository; it does not start Task 2.3 or change API/database
behavior. Dependency versions remain unpinned. New-machine installation and
runtime acceptance must be checked on that machine; prior evidence below is
unchanged. Original SQL copies retain their recorded SHA-256.

## Status definitions

**Complete in source** means the requested SQL implementation exists in the uploaded final file and was inspected. It does not claim that the SQL has been executed successfully. **Not started** means the relevant task or stage has no credited implementation. A saved query containing PASS/FAIL expressions is not a saved PASS result.

## Phase 1 — Database foundation

Phase 1 is complete at the SQL-source level for Tasks 1.1–1.5. The user reports T01–T14 passed; full result sets have not been independently reviewed. The table below records the original SQL-source review limits. Task 2.1 local backend validation is recorded separately under Phase 2 and does not establish full SQL constraint or application acceptance.

| Task | Status | Source evidence | Verification limit |
| --- | --- | --- | --- |
| 1.1 Create tables | Complete in source | 11 CREATE TABLE definitions, FKs, checks, unique keys | No live DDL import or constraint enforcement test |
| 1.2 Seed equipment | Complete in source | 22 equipment rows; lookup variables by equipment_name | Counts checked statically |
| 1.3 Seed exercises | Complete in source | 301 system rows; all mappings resolve; no duplicate seed names; valid positive rep ranges | Seed not imported into MySQL here |
| 1.4 Mock data | Complete in source | Transactional demo user/profile/equipment upsert and demo-only equipment cleanup | Re-run and rollback behavior inspected, not executed |
| 1.5 Test queries | Complete in source | T01–T14, profile/equipment inspection and candidate queries | All live PASS/FAIL outputs remain unverified |

## Task 1.5 acceptance checklist

| Check | Expected pristine baseline | Evidence in this review |
| --- | --- | --- |
| T01_tables | 11 base tables | 11 definitions counted |
| T02_equipment | 22 rows | 22 source tuples counted |
| T03_system_exercises | 301 rows with NULL creator | 301 source tuples checked |
| T04_demo_user | One row for demo@gmail.com | Upsert and unique email inspected |
| T05_demo_profile | One profile for demo user | Upsert and unique user_id inspected |
| T06_demo_equipment | Two links | Two inserts and cleanup inspected |
| T07_profile_values | Beginner / Build muscle / Home / 3 / 60 / FALSE | Source values inspected |
| T08_equipment_names | Bodyweight and Dumbbell, one each | Source values inspected |
| T09_duplicate_system_names | Zero duplicate-name groups | No duplicate seed names statically |
| T10_missing_equipment | Zero missing references | All source mappings resolve |
| T11_rep_ranges | Zero nonpositive or reversed ranges | All seed ranges checked; SQL predicate permits NULLs |
| T12_mapping | Every one of 14 expected mappings PASS | All 14 source mappings checked |
| T13_eligible_system_count | 92 | 43 + 49 source rows |
| T14_eligible_by_equipment | Bodyweight 43; Dumbbell 49 | Source distribution checked |

The initial FINAL VALIDATION block additionally shows tables, equipment, exercise counts/distribution, missing equipment, rep-range violations, duplicate names, and important mappings. It precedes the demo section. Later inspection queries show demo profile/equipment, equipment candidates restricted to system/own custom rows, and counts by equipment.

Before claiming runtime acceptance, execute only in an approved disposable environment as described in README.md, retain the server version and all result sets, verify every expected row is present, and record failures. These queries do not cover negative constraint tests, program ownership, API contracts, or recommendation quality. Do not reset an existing database just to refresh baseline counts.

## Phase 2 — Backend implementation and validation

Current update (2026-10-20): Task 2.2 implements the approved demo-only
`GET /profile` and `PATCH /profile`, field validation, partial updates, complete
first creation, transaction cleanup, and sanitized database errors. Added isolated
tests in `backend/tests/test_profile.py`. After Codex's interpreter attempt
failed with `Access is denied`, the user supplied the discovery result:
`Ran 18 tests in 0.974s` and `OK` (7 foundation tests and 11 profile tests).
The isolated suite passed on this user-supplied summary; no per-test log was
supplied and Codex did not run it. The user subsequently supplied Swagger
`GET /profile` HTTP 200 with profile/user IDs 1/1, Beginner, Build muscle, Home,
3 days/week, and 60 minutes/session. This confirms the local live read path
from supplied output. Codex later verified live PATCH persistence via subsequent
GET, preservation of all omitted response fields, and rejection of 8 days with
422 and unchanged data. The user subsequently ran the seven-check real-MySQL
suite with `passed: true`, no failed/error tests, successful temporary-database
cleanup, and unchanged source hashes. Codex reviewed the saved JSON report.
Task 2.2 is complete within local demo scope; Tasks 2.3–2.5 are not started.

The user subsequently supplied PATCH /profile HTTP 200 with days_per_week 4
and minutes_per_session 1 (previous GET showed 60 minutes). The user then supplied
the generated curl showing only days_per_week 4. Codex read the live API at
4 days/1 minute, PATCHed days only to 5, verified GET at 5 days/1 minute with
other returned fields unchanged, rejected an 8-day PATCH with 422, verified no
change, restored days to 4, and confirmed GET exactly matched the initial
response. The earlier duration change was not reproduced and its origin remains
unknown. The user subsequently explicitly requested 60 minutes. Codex PATCHed
only minutes_per_session to 60 and verified it with GET; days remained 4 and
all other returned fields were unchanged. Current demo availability is 4 days
per week and 60 minutes per session. These checks do not independently inspect MySQL or
profile fields absent from the API response.

The remaining database checks were completed using the automated runner:
`python -m backend.verify_profile_mysql` (see
[run instructions](../backend/README.md#task-22--disposable-mysql-acceptance-checks)).
It prepares exact baseline users/profile tables in a new uniquely named test
database, runs seven real-MySQL/in-process HTTP checks including fault-injected
rollback and coordinated concurrent creation, removes its own test database,
and compares source schema/seed/demo hashes. Codex could not execute Python,
but the user ran it and supplied a successful seven-test JSON result. Codex
also read the matching saved report at
`backend/test-results/swp_profile_test_36c3f3b5752b4878ab6f52491e5b0705.json`.
It records `passed: true`, `test_checks_passed: true`, no failed/error tests,
`test_database_removed: true`, and `source_schema_seed_and_demo_unchanged: true`.
This establishes real-MySQL, in-process HTTP acceptance for these cases.
Rollback was tested using injected application failures after real SQL writes;
server outages and commit failures were not tested against real MySQL.

### Task 2.1 prior local acceptance

Current update (2026-10-18): the user authorized clean Task 2.1 implementation and
reports the SQL T01–T14 checks passed. That SQL result is user-reported; no result
sets were independently reviewed here. The documentation-baseline statements
above describe the earlier review.

Task 2.1 now includes configuration, a synchronous SQLAlchemy/PyMySQL engine,
FastAPI lifespan cleanup, `GET /health`, `GET /health/db`, isolated tests, and a
read-only live verification command. The existing `.env` was not overwritten.
No table, seed, or domain API was changed. Codex cannot execute the user's Python
in its environment. The user installed dependencies through VS Code CMD in the
existing root `.venv` and reported `backend.verify_live` passed. The complete JSON
was not supplied. Actual curl responses were supplied on 2026-10-18:
`GET /health` returned HTTP 200 with `{"status":"ok"}` and `GET /health/db`
returned HTTP 200 with `{"status":"ok","database":"connected"}`, served by
Uvicorn. This verifies local HTTP and MySQL success paths. The user subsequently
reported `unittest discover -s backend/tests -v` returned `OK`, covering isolated
failure/config/cleanup checks. Full unittest and live-check output was not supplied;
Codex did not execute these commands. Local Task 2.1 acceptance is complete on this
evidence; no production acceptance is claimed. See [run instructions](../backend/README.md).

The following sequence keeps the original task boundaries. Task 2.2 was separately authorized by the user's contract confirmation. Tasks 2.3–2.5 have not been started or authorized by that confirmation.

| Task | Intended scope | Status | Acceptance needed when authorized |
| --- | --- | --- | --- |
| 2.1 FastAPI setup | Clean project setup, configuration, connection lifecycle | Complete locally from user-run validation | User reports unittest OK and live check passed; real HTTP 200 outputs supplied; full unittest/live-check logs not supplied |
| 2.2 Profile API | Demo profile read/update and complete first creation against existing fields | Complete for local demo scope | 18 isolated tests (user summary), live HTTP GET/PATCH/readback and invalid-value checks by Codex, seven real-MySQL checks (reviewed saved user-run report); no production acceptance |
| 2.3 Equipment & Exercise API | Catalog, user equipment, equipment candidates | Not started | Preserve seed; system/own visibility; agree custom-exercise and preference operations |
| 2.4 Program API | Program and ordered exercise prescriptions | Not started | Agree generation versus CRUD scope; validate ownership, order, dates, nullable first load |
| 2.5 Session & Set Log API | Session and actual-set operations | Not started | Validate session owner, program consistency, planned/ad hoc sets, ranges and NULL semantics |

Detailed endpoint paths, contracts, dependency versions, authentication, error responses, and test fixtures must be agreed when the relevant task is started. A table existing in Phase 1 does not complete its Phase 2 API.

## Later-stage planning and completion

Workout Logic, Frontend Application, Integration, Testing, and Demo/Deployment are planned parts of the final application goal. Recommendation and adaptive progression rules, frontend design, integration contracts, application acceptance criteria, and the demo/deployment environment require detailed requirements before their implementation. No additional numbered phases or delivery dates are assigned by this update.

The project remains in progress after database or Backend API completion. Final completion requires the agreed user flows to work through the integrated application, supporting test evidence, and a successful demo/deployment handoff against the agreed criteria. Local Task 2.1 and Task 2.2 acceptance is limited to the backend foundation and demo Profile API; it does not establish full application or production acceptance.

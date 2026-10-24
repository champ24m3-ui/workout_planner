# Changelog

## 2026-10-24 — Prepare GitHub repository and teammate handoff

Retained existing backend source, tests, requirements, both identical SQL copies,
and project documents for the repository at champ24m3-ui/workout_planner.
Added AGENTS.md and CLAUDE.md to direct coding assistants to shared rules, and
docs/TEAM_SETUP.md with Windows clone/setup, per-machine .env/venv/MySQL,
database reset boundaries, existing verification commands, and branch/PR workflow.
Updated README.md with the current repository tree and handoff links,
backend/README.md with new-clone instructions, docs/ROADMAP.md with this
documentation milestone, and .gitignore for machine-specific editor/OS files.

Validation scope: static checks of included paths, local Markdown link targets,
ignored secrets/local artifacts, and unchanged SHA-256 of both SQL copies.
No application source, requirements, local .env, virtual environment, schema,
seed or live database data was changed. No runtime tests, database imports,
package installations or new-machine validation were performed for this
documentation/repository handoff. Dependencies remain unpinned. Tasks 2.3–2.5
remain not started; prior local acceptance evidence is preserved, and generated
test reports remain local/ignored rather than being published.

## 2026-10-20 — Complete Task 2.2 local demo acceptance

The user supplied a successful backend.verify_profile_mysql result: passed true,
tests_run 7, test_checks_passed true, no failed/error tests, test database
removed, and source schema/seed/demo unchanged. Codex independently read the
matching saved JSON at backend/test-results/
swp_profile_test_36c3f3b5752b4878ab6f52491e5b0705.json and verified those fields.
Codex did not execute Python or repeat the MySQL tests.

This closes the pending missing-user/profile creation, preservation of hidden
fields/another user's profile, post-write fault-injected INSERT/UPDATE rollback,
invalid-write, and overlapping first-creation checks. Together with the prior
18-test isolated summary and directly checked live HTTP GET/PATCH/readback,
Task 2.2 is complete for the agreed local demo scope. The test database was
removed by the user-run command and compared source data was unchanged.
Real server outage/commit-failure behavior, production authentication, and full
application acceptance are not claimed. Tasks 2.3–2.5 remain not started.

Updated README.md, backend/README.md, PROJECT_SPEC.md, BACKEND_SPEC.md,
ROADMAP.md, DATABASE.md, DATA_DICTIONARY.md, and CODING_RULES.md to close stale
pending status while preserving historical evidence. Checked report fields,
current-state consistency, and local Markdown links. No application code,
credentials, environment, schema, seed, or live profile data changed in this turn.

## 2026-10-20 — Prepare isolated MySQL checks for remaining Task 2.2 acceptance

The user authorized continuation of the remaining missing-record, rollback,
and concurrent-creation verification. Added backend/verify_profile_mysql.py:
it creates an owned random-name test database, loads only the exact baseline
users/user_profiles definitions, requires InnoDB, and runs seven in-process
HTTP tests with real MySQL. Tests include creation/missing-user behavior,
hidden-field and other-user preservation, rollback after injected errors
following real INSERT/UPDATE, invalid writes, and overlapping first creation.

The runner never executes the baseline reset or seeds. It compares source
schema/equipment/exercise/demo hashes before/after, drops only its newly created
database, and saves sanitized JSON under backend/test-results/. Added that
generated-report directory to .gitignore. Updated README.md, backend/README.md,
ROADMAP.md, and BACKEND_SPEC.md with the command, scope, cleanup behavior,
required database privileges, and evidence limits. Application code, local
credentials, original SQL, virtual environment, and live demo data are unchanged.

Verification: static review of fixture SQL extraction, test count, cleanup
ownership guard, source SQL hashes, documentation links, and unchanged live
demo availability. Attempted the new runner via the existing .venv; Python
could not start (`Access is denied`). MySQL Shell discovery did not provide a
usable alternative runner. No temporary test database was created by these
attempts, and no new acceptance pass is claimed. Actual seven-check JSON output
is still needed; Task 2.2 acceptance remains pending for these checks.

## 2026-10-20 — Set demo session duration to 60 minutes as requested

The user explicitly requested 60 minutes per workout session. Codex sent live
PATCH /profile with only `{"minutes_per_session":60}` and then GET /profile.
Both responses showed 60 minutes; profile/user IDs 1/1, Beginner, Build muscle,
Home, and days_per_week 4 were unchanged from the pre-update GET. The current
demo availability is 4 days/week, 60 minutes/session.

Updated README.md, backend/README.md, BACKEND_SPEC.md, and ROADMAP.md to record
the verified value and remove the pending duration-clarification item. Verified
the live API response and unchanged other returned fields, and checked local
Markdown link targets. This was an authorized demo profile data update; no
application code, schema, master seed, credentials, or environment changes.
The earlier unexpected duration change remains unexplained; separate creation,
database rollback, and concurrency checks remain pending. No unittest rerun
was needed for this data/documentation-only update.

## 2026-10-20 — Verify live partial update, readback, and invalid-value rejection

The user supplied the generated PATCH curl with only `days_per_week: 4`,
resolving the missing-payload question. Reviewed backend/profile.py and main.py:
PATCH builds its write from explicitly supplied, allowlisted fields only.

Codex directly reached the running local HTTP API. Initial GET returned
profile/user IDs 1/1, Beginner, Build muscle, Home, 4 days, and 1 minute.
PATCHing only days to 5 and a subsequent GET both returned 5 days/1 minute;
all other returned fields matched the initial response. PATCH days 8 returned
422; subsequent GET matched the prior response. In a finally block, restored
days to 4 and confirmed final GET exactly matched the initial response.

This directly validates the local live partial update/readback and invalid-value
rejection paths. It does not independently inspect MySQL, hidden profile fields,
database rollback, missing-record creation, or concurrent requests. The earlier
60-to-1-minute change was not reproduced and cannot be attributed from available
evidence. Duration remains 1 pending clarification; no automatic correction was
made. No code/schema/seed/credential changes were needed. The demo's days were
temporarily changed for the check and restored to their starting value.

Updated README.md, backend/README.md, PROJECT_SPEC.md, BACKEND_SPEC.md,
ROADMAP.md, DATABASE.md, DATA_DICTIONARY.md, and CODING_RULES.md with live-check
results and remaining limits. Checked local Markdown links and current-state
wording. Tasks 2.3–2.5 remain not started.

## 2026-10-20 — Record PATCH 200 with duration change requiring clarification

The user supplied PATCH /profile HTTP 200 with profile/user IDs 1/1, Beginner,
Build muscle, Home, days_per_week 4, and minutes_per_session 1. The earlier GET
showed days_per_week 3 and minutes_per_session 60. The suggested PATCH body
contained only days_per_week, but the actual executed payload has not been
supplied. Record the successful response without claiming preservation of
omitted fields or diagnosing an API defect. Exact request payload and subsequent
GET readback remain needed. Updated ROADMAP.md with this evidence limit;
Task 2.2 live acceptance remains pending. No code or live data was changed by
Codex; this was a documentation update based on user-supplied output only.

## 2026-10-20 — Record successful live GET /profile

After reporting successful server/Swagger access, the user supplied HTTP 200
and this response from GET /profile:

```json
{
  "profile_id": 1,
  "user_id": 1,
  "fitness_level": "Beginner",
  "primary_goal": "Build muscle",
  "workout_location": "Home",
  "days_per_week": 3,
  "minutes_per_session": 60
}
```

This confirms the local live demo-profile read path from user-supplied output;
Codex did not execute the request or directly inspect MySQL. These observed IDs
are not implementation constants. Together with the prior 18-test OK summary,
this advances Task 2.2 validation, while PATCH/write persistence, invalid-write
preservation, and isolated-database creation/rollback/concurrency checks remain
pending. Tasks 2.3–2.5 remain not started.

Updated README.md, backend/README.md, PROJECT_SPEC.md, ROADMAP.md,
BACKEND_SPEC.md, DATABASE.md, DATA_DICTIONARY.md, and CODING_RULES.md to reflect
the live GET evidence and remaining write checks. Verification here: reviewed
the supplied response, searched current documentation status, and checked local
Markdown link targets. No code, credentials, schema, seed, or live data changed.

## 2026-10-20 — Record successful isolated foundation/profile suite

The user supplied the discovery summary `Ran 18 tests in 0.974s` followed by
`OK`, matching the 7 foundation and 11 profile test methods in source. Record
the isolated suite as passed from this user-supplied summary. No per-test log
was supplied and Codex did not execute Python. The prior interpreter failure
remains historical; it no longer means the user's isolated suite is untested.

Updated README.md, backend/README.md, PROJECT_SPEC.md, BACKEND_SPEC.md,
ROADMAP.md, DATABASE.md, DATA_DICTIONARY.md, and CODING_RULES.md to distinguish
isolated-suite success from pending real Profile API HTTP/MySQL validation.
Task 2.2 live acceptance still needs read/write persistence and appropriate
isolated-database missing-record, rollback, and concurrency checks. Tasks
2.3–2.5 remain not started. No code, credentials, environment, schema, seed,
or live data was changed. Verification here: source test-count comparison,
documentation consistency search, and local Markdown link checks only.

## 2026-10-20 — Implement Task 2.2 demo Profile API; runtime validation pending

The user confirmed demo identity (`demo@gmail.com`), GET/PATCH `/profile`,
the five editable fields and their allowed values, and full first creation
when the existing demo user has no profile. Added `backend/profile.py` and
registered its router in `backend/main.py`. Responses include profile/user IDs
and the five fields; no account secrets or unrelated profile fields are exposed.

GET is read-only. PATCH preserves omitted/other fields, rejects unknown keys,
empty bodies, explicit nulls, invalid enums and noninteger/out-of-range values,
and requires all five fields for creation. It resolves the demo user by email,
uses bound SQL values and allowlisted columns, locks the user during a single
write transaction, validates readback before commit, and sanitizes SQL errors.
No login, caller-selected user, automatic account creation, schema change,
seed reset, or Task 2.3 work is included.

Added `backend/tests/test_profile.py` with isolated HTTP/fake-database tests for
approved values, validation, partial writes, missing records, demo scoping,
transaction context cleanup, and query/commit errors. Updated README.md,
backend/README.md, PROJECT_SPEC.md, BACKEND_SPEC.md, ROADMAP.md, DATABASE.md,
DATA_DICTIONARY.md, and CODING_RULES.md with current status, the approved
contract, evidence limits, or manual validation instructions.

Verification: reviewed schema/SQL and code, checked Markdown links, status
consistency, and unchanged SQL source hashes. Attempted
`.\.venv\Scripts\python.exe -m unittest discover -s backend/tests -v`, but
the interpreter could not start: its Store Python target returned
`Access is denied`. No tests passed in this session and no real Profile API
HTTP/MySQL persistence, rollback, or concurrency checks were run. Task 2.2
implementation is delivered with runtime acceptance pending. Existing Task 2.1
results do not validate the new routes. Credentials, virtual environment,
database schema, seed files, and live data were not changed by this session.

## 2026-10-20 — Clarify final application goal and synchronize documentation

Updated README.md, PROJECT_SPEC.md, and ROADMAP.md to state that the final goal
is a complete user-facing application and record the intended development path:
Database → Backend API → Workout Logic → Frontend Application → Integration →
Testing → Demo/Deployment. Added planned outcomes and current status for the
later stages without claiming implementation or assigning new phase numbers.

Corrected stale current-state statements in PROJECT_SPEC.md, DATABASE.md,
DATA_DICTIONARY.md, and CODING_RULES.md to reflect recorded local Task 2.1
completion while keeping Tasks 2.2–2.5 not started. Clarified the original
Phase 1 review limits in ROADMAP.md and the documentation maintenance rule in
CODING_RULES.md, explicitly including documentation-only tasks and consistency
checks before handoff. This entry also records the application-goal update
that was initially delivered without a changelog entry.

Verification: static review of the changed Markdown, exact development-path
checks in the three goal documents, local Markdown link checks, and a search
for obsolete current-state Phase 2 statements. Historical changelog entries and
explicitly labeled original backend planning records are retained. No runtime
tests were run; no application code, credentials, environment, schema, or data
was changed. Existing validation evidence and its limits remain unchanged.

## 2026-10-18 — Close Task 2.1 local acceptance from user-run tests

The user reported that the instructed unittest discovery command returned `OK`.
Together with the earlier reported live-check pass and supplied real Uvicorn
HTTP 200 responses, this completes Task 2.1 within the local foundation scope.
Full unittest/live-check logs were not supplied; Codex did not execute Python.
Updated current status in README, backend README, ROADMAP and BACKEND_SPEC.
No application code, `.env`, virtual environment, schema or data was changed.
Tasks 2.2–2.5 remain not started. Historical entries below retain their earlier
evidence limits. No production, browser or domain API acceptance is claimed.

## 2026-10-18 — User supplied live HTTP/MySQL success evidence

After dependency setup in VS Code CMD, the user reported the live verification
command returned true; full JSON output was not supplied. The user subsequently
provided curl output from Uvicorn: `/health` returned HTTP 200 with
`{"status":"ok"}` at 15:23:46 GMT; `/health/db` returned HTTP 200 with
`{"status":"ok","database":"connected"}` at 15:24:13 GMT. These establish
successful real local HTTP and MySQL connectivity from the user's environment.

Updated README, backend README, ROADMAP and BACKEND_SPEC with that evidence.
Isolated config/failure/cleanup tests have no supplied result and remain pending.
Codex did not execute Python, alter `.env` or `.venv`, or change database structure
or data. Tasks 2.2–2.5 remain not started.

## 2026-10-18 — Align TestClient dependency with installed Starlette

Inspected installed package files without executing Python: FastAPI 0.145.0,
Starlette 1.8.0. Starlette TestClient prefers `httpx2`, with deprecated `httpx`
fallback; neither client's dist-info directory was present during inspection.
The user's live-check traceback stopped on that missing optional dependency,
before reaching configuration or MySQL. Changed `requirements-dev.txt` to
`httpx2`, consistent with the installed source and official Starlette TestClient
documentation. Updated backend run commands to use the existing root `.venv`.
No Python was executed, no packages installed by this session, and no `.env`,
virtual environment, database structure or data was modified. Runtime recheck
must be performed through the user's VS Code CMD.

## 2026-10-18 — Task 2.1 backend implementation; validation pending

Added `backend/config.py`, `database.py`, `main.py`, package markers, placeholder
`.env.example`, runtime/dev requirements, isolated foundation tests, a read-only
`verify_live.py` command, and backend setup instructions. Expanded `.gitignore`
for local Python artifacts. Preserved the user-filled `backend/.env` unchanged.

Implemented `GET /health` and `GET /health/db`, explicit configuration checks,
literal special-character passwords through `URL.create`, bounded connection/pool
waits, connection cleanup and engine disposal. Database health failures return a
generic 503 without raw driver errors. No schema, seed, or Task 2.2 API changes.

Verification: inspected source and interpreter discovery only. Store Python 3.13
was found through the registry; execution returned `Access is denied` and neither
`python` nor `py` was available on PATH. No virtual environment, dependency install,
automated test run, Uvicorn startup, or live database check was completed. The user
reports SQL T01–T14 passed; this is not an independently repeated result. Updated
README, ROADMAP and BACKEND_SPEC to distinguish implementation from acceptance.

## 2026-10-18 — Documentation baseline after Phase 1 SQL

Created README.md and seven documents under docs/ from the final uploaded `Project_add_Equipment.sql`. Included an unchanged source copy under database/ for reproducibility.

Recorded the final observed state: 11 tables, 22 equipment master rows, 301 system exercises, embedded Task 1.4 demo setup, and embedded Task 1.5 T01–T14 plus inspection queries. Documented exact nullability, defaults, constraints, relationships, all equipment values, all exercise tuples, and 14 reference mappings.

Static checks verified source counts, seed-name uniqueness, equipment lookup resolution, positive ordered rep ranges, and demo equipment eligibility (Bodyweight 43, Dumbbell 49, total 92). No SQL was executed against MySQL. No database or seed data was changed. No backend code was created, reused, run, or credited as complete.

Phase 1 Tasks 1.1–1.5 are complete in source; runtime acceptance is unverified. Phase 2 and Tasks 2.1–2.5 are Not started and will begin from a clean baseline when separately requested.

Source SHA-256: `6b9459a2169880d535137d1b0c563bd558c00fcc5b3c4839553cd89702db36a1`.

## Historical boundary

The source describes itself as V1 / CLEAN VERSION. Earlier discussion mentions equipment corrections, but the supplied file does not establish a reliable chronological migration history. This changelog records the final state rather than inventing prior releases or migration dates. Preserve mappings as supplied, including Bodyweight mappings for some weighted movements and the current Svend Press / Meadows Row / Weighted Crunch choices.

## Future entries

For each implemented task, add its date, scope, concrete changes, affected files, actual validation, and unresolved limitations. Update ROADMAP.md only when supported by implementation and evidence. Keep planned work separate from delivered changes.

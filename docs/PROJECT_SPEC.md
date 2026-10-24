# Project specification

Original SQL baseline date: 2026-10-18 (Asia/Bangkok). Source: `Project_add_Equipment.sql`, read in full including embedded Tasks 1.4 and 1.5. Phase 1 SQL implementation is complete in source; the user reports T01–T14 passed, but saved results were not independently reviewed here. Task 2.1 is complete for the local foundation scope from user-run validation and supplied HTTP/MySQL responses. Task 2.2 demo Profile API is implemented; the user supplied an 18-test OK summary; live GET /profile returned 200 with demo data supplied by the user; Codex verified live PATCH/readback and invalid-value rejection; the user-run seven-check MySQL suite passed with a saved JSON report; Task 2.2 is complete for local demo scope; Tasks 2.3–2.5 are not started. Application goal and development path clarified on 2026-10-20.

## Purpose and evidence boundary

Smart Workout Planner's final goal is to become a **complete user-facing application** for personalized workout planning using profile information and available equipment, with workout programs and workout logging. The database and Backend API are foundations within that product, and completing them alone does not complete the project.

The intended development path is:

**Database → Backend API → Workout Logic → Frontend Application → Integration → Testing → Demo/Deployment**

The intended user experience is to manage a workout profile and available equipment, receive and view a workout program, and record sessions and actual set results through the frontend application. Integration must connect these user flows to the Backend API, workout logic, and persistent database. The final delivery includes testing the integrated application and preparing it for demonstration or deployment in an agreed environment.

The current implementation consists of the SQL/database foundation, project documentation, the locally validated Task 2.1 backend foundation, and the Task 2.2 demo Profile API with an 18-test OK summary supplied by the user and live GET /profile 200 confirmed from user-supplied output; live PATCH/readback and invalid-value rejection verified by Codex; seven real-MySQL checks passed (saved user-run report); Task 2.2 complete for local demo scope. This document distinguishes existing storage and backend capabilities from planned application behavior; workout logic and the frontend have not been implemented.

## SQL-backed domain scope

| Capability supported by storage | Existing tables | What is evidenced |
| --- | --- | --- |
| User identity and profile | users, user_profiles | Unique email; optional one-to-one profile; workout availability and goal fields |
| Weight history | body_measurements | Timestamped positive body weight per user |
| Equipment inventory | equipment, user_equipment | 22 equipment types; unique user/equipment pair |
| Exercise catalog and custom ownership | exercises | 301 system exercises; one required equipment per exercise; nullable creator |
| Favorites and exclusions | user_exercise_preferences | One favorite/excluded value per user/exercise |
| Workout program structure | programs, program_exercises | Program dates; day/exercise ordering; set, rep, load, effort, rest targets |
| Sessions and actual sets | workout_sessions, set_logs | Optional program association; planned or ad hoc exercise logs; actual effort and completion |

Task 1.4 populates only users, user_profiles, and user_equipment. It does not populate measurements, preferences, programs, planned exercises, sessions, or set logs. Those six tables are defined but have no sample rows inserted by this SQL.

## Demonstrated selection behavior

Task 1.5 joins user_equipment to exercises by equipment_id and limits candidates to system exercises or exercises created by the selected user. The fixed demo owns Bodyweight and Dumbbell and has 92 eligible system exercises. This is an equipment candidate query, not a complete workout recommendation. It does not filter exclusions, fitness level, goal, fatigue, schedule, or stretch preference.

## Planned application scope

Phase 2 uses Python + FastAPI + SQLAlchemy + MySQL for the Backend API. Task 2.1 setup is complete locally. Task 2.2 implements the agreed demo Profile API; the user supplied an 18-test OK summary, with live GET /profile 200 confirmed from user-supplied output; live PATCH/readback and invalid-value rejection verified by Codex; seven real-MySQL checks passed (saved user-run report); Task 2.2 complete for local demo scope. Equipment/exercise APIs, program APIs, and session/set-log APIs (Tasks 2.3–2.5) remain not started. Storage already supports these domains, but the remaining HTTP contracts, authentication, generation rules, adaptive progression, and deployment have not been established by SQL.

### Approved Task 2.2 scope

The user confirmed demo identity via `demo@gmail.com`, `GET /profile`, and
`PATCH /profile`. Editable values are `primary_goal` (`Build muscle`, `Lose fat`,
`General fitness`), `fitness_level` (`Beginner`, `Intermediate`, `Advanced`),
`workout_location` (`Home`, `Gym`), integer `days_per_week` (1–7), and positive
integer `minutes_per_session` within the existing SQL INT range. GET returns
404 for a missing profile. PATCH creates one only with all five fields present;
otherwise it updates supplied fields and preserves the rest. No account creation,
login, or editing of other profile fields is included. See the detailed
[API contract](BACKEND_SPEC.md#task-22--approved-demo-profile-contract).

After the Backend API, the planned stages are Workout Logic, Frontend Application, Integration, Testing, and Demo/Deployment, as described in the [roadmap](ROADMAP.md). These stages are part of the intended final product. Their detailed rules, UI design, technology choices, acceptance criteria, and delivery environment require clarification before dependent implementation. This documentation update records the product direction without starting those implementation tasks.

Before implementing recommendation or adaptive behavior, ask the user for the intended rules: exercise selection, volume, frequency, first-load handling, progression, fatigue handling, and stretch treatment. Do not convert seed categories into an invented scoring algorithm.

## Fixed baseline boundaries

- Preserve all 11 tables and their current fields, nullability, defaults, keys, checks, and relationships.
- Preserve current equipment names, categories, exercise names, rep ranges, fatigue labels, stretch flags, and mappings, including mappings that look unusual.
- Do not add entities, including `progress_analysis`, an exercise/equipment junction table, roles, or authentication tables, without explicit approval.
- An exercise has one required equipment_id in the baseline. Do not reinterpret it as a complete multi-item equipment requirement.
- `target_weight = NULL` supports an unknown first load. `actual_weight = NULL` is allowed. Neither means zero by default.
- `set_logs.program_exercise_id = NULL` supports ad hoc exercises; `workout_sessions.program_id = NULL` supports sessions without an associated program.

## Decisions requiring clarification when relevant

The SQL does not establish a complete vocabulary for fitness_level, primary_goal, workout_location, focus_area, program_type, or status. Task 2.2 now establishes API vocabularies for the first three fields and a demo-only identity/route/error contract as documented above. Production authentication, later-task contracts, time zone handling, duration/distance logging, user-deletion policy for custom exercises, and duplicate-name policy for future custom rows remain undecided. Ask before dependent implementation; keep these unknowns explicit rather than adding schema or inventing product requirements.

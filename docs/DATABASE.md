# Database baseline

Original SQL baseline date: 2026-10-18 (Asia/Bangkok). Source: `Project_add_Equipment.sql`, read in full including embedded Tasks 1.4 and 1.5. Phase 1 SQL implementation is complete in source; the user reports T01–T14 passed, but saved results were not independently reviewed here. Task 2.1 is complete for the local backend foundation scope from user-run validation and supplied HTTP/MySQL responses; Task 2.2 demo Profile API is implemented; the user supplied an 18-test OK summary; live GET /profile returned 200 with demo data supplied by the user; Codex verified live PATCH/readback and invalid-value rejection; the user-run seven-check MySQL suite passed with a saved JSON report; Task 2.2 is complete for local demo scope; Tasks 2.3–2.5 are not started. Database details below retain their SQL-source evidence limits. See [current project progress](ROADMAP.md).

## Source identity and layout

Source: [unchanged final SQL](../database/Project_add_Equipment.sql), 1266 lines.

SHA-256: `6b9459a2169880d535137d1b0c563bd558c00fcc5b3c4839553cd89702db36a1`.

Database name: `smart_workout_planner`. MySQL 8.0.16+ is specified in the supplied Task 1.4 comment. The SQL does not explicitly declare a storage engine, charset, or collation; do not claim those were configured. Confirm the actual environment before import.

| Section | Source lines |
| --- | --- |
| Schema | 17–394 |
| Equipment seed and ID lookups | 399–584 |
| Exercise seed | 588–979 |
| Final validation | 980–1079 |
| Task 1.4 | 1080–1129 |
| Task 1.5 | 1130–1266 |

## Tables

| Table | Purpose | DDL source lines |
| --- | --- | --- |
| `users` | User identity; password_hash is optional in the database. | 17–23 |
| `user_profiles` | At most one profile per user; absence of a profile is allowed. | 30–65 |
| `body_measurements` | Time series of body-weight measurements. | 72–84 |
| `equipment` | Equipment master catalog. | 91–95 |
| `user_equipment` | User-owned or available equipment links. | 102–117 |
| `exercises` | System and user-created exercise catalog. | 124–168 |
| `user_exercise_preferences` | Per-user favorite or excluded exercise. | 175–196 |
| `programs` | User workout-program header. | 203–228 |
| `program_exercises` | Ordered exercise prescriptions inside program days. | 235–293 |
| `workout_sessions` | User workout occurrence; program association is optional. | 300–325 |
| `set_logs` | Actual per-set results, including ad hoc exercise sets. | 332–391 |

## Relationships and delete actions

Each row below describes a child foreign key. A required FK means every child needs a parent, not that every parent must have children. Only user_profiles.user_id is also UNIQUE, making users → profiles 1 to 0..1. All other parent → child relationships are 1 to 0..many; nullable FKs permit a child without that association.

| Child field | Parent field | Nullable | ON DELETE |
| --- | --- | --- | --- |
| `user_profiles.user_id` | `users.user_id` | No | CASCADE |
| `body_measurements.user_id` | `users.user_id` | No | CASCADE |
| `user_equipment.user_id` | `users.user_id` | No | CASCADE |
| `user_equipment.equipment_id` | `equipment.equipment_id` | No | CASCADE |
| `exercises.equipment_id` | `equipment.equipment_id` | No | Not specified; no cascade declared |
| `exercises.created_by_user_id` | `users.user_id` | Yes | SET NULL |
| `user_exercise_preferences.user_id` | `users.user_id` | No | CASCADE |
| `user_exercise_preferences.exercise_id` | `exercises.exercise_id` | No | CASCADE |
| `programs.user_id` | `users.user_id` | No | CASCADE |
| `program_exercises.program_id` | `programs.program_id` | No | CASCADE |
| `program_exercises.exercise_id` | `exercises.exercise_id` | No | Not specified; no cascade declared |
| `workout_sessions.user_id` | `users.user_id` | No | CASCADE |
| `workout_sessions.program_id` | `programs.program_id` | Yes | SET NULL |
| `set_logs.session_id` | `workout_sessions.session_id` | No | CASCADE |
| `set_logs.program_exercise_id` | `program_exercises.program_exercise_id` | Yes | SET NULL |
| `set_logs.exercise_id` | `exercises.exercise_id` | No | Not specified; no cascade declared |

## Important constraints and gaps

- All 11 primary keys are auto-increment INTs. Do not hard-code their numeric values.
- Unique keys: users.email, user_profiles.user_id, equipment.equipment_name, user_equipment(user_id, equipment_id), user_exercise_preferences(user_id, exercise_id), program_exercises(program_id, day_order, exercise_order).
- Exercise names are not UNIQUE in DDL. The seed has no duplicate names; validation queries inspect duplicates but do not create a constraint.
- CHECK constraints enforce positive height and weight, availability bounds, valid rep ranges, positive ordering and target sets, nonnegative loads/rest/reps where specified, RPE 1–10, RIR >= 0, and ordered dates/times. Exact expressions appear in the data dictionary.
- BOOLEAN columns have defaults but remain nullable. Defaults also do not make created_at, measured_at, or programs.status NOT NULL.
- No uniqueness constraint prevents repeated set_number within a session/exercise. No maximum RIR, cross-field RPE/RIR consistency check, or fixed status vocabulary is declared.
- Foreign keys do not ensure a session's program belongs to its user, or that a set's program_exercise belongs to the session program and matches its exercise_id. A future backend must validate these associations before writes.
- Deleting a custom exercise's creator sets created_by_user_id to NULL. Queries interpret NULL as system-default, so this can blur provenance after user deletion. Preserve the schema and clarify deletion policy before exposing that operation.
- Deleting programs cascades their program_exercises and sets workout_sessions.program_id to NULL; deleting a program_exercise sets related set_logs.program_exercise_id to NULL. The remaining log still has exercise_id. Do not assume deleting a program deletes all history.

## Equipment master and exercise distribution

The category and count below are extracted from the source, not a live database. Every listed equipment type has at least one seeded exercise.

| Equipment name | Category | System exercises |
| --- | --- | ---: |
| Bodyweight | None | 43 |
| Dumbbell | Free Weight | 49 |
| Barbell | Free Weight | 45 |
| Cable Machine | Machine | 39 |
| Smith Machine | Machine | 8 |
| Kettlebell | Free Weight | 6 |
| Resistance Band | Free Weight | 7 |
| Pull-up Bar | Calisthenics | 11 |
| Yoga Mat | Accessory | 31 |
| Machine | Machine | 32 |
| Trap Bar | Free Weight | 2 |
| Battle Rope | Conditioning | 1 |
| Sled | Conditioning | 2 |
| Medicine Ball | Accessory | 2 |
| Foam Roller | Accessory | 6 |
| TRX | Suspension Trainer | 7 |
| EZ Bar | Free Weight | 3 |
| Weight Plate | Free Weight | 1 |
| Ab Wheel | Accessory | 1 |
| Landmine | Free Weight | 3 |
| Tire | Conditioning | 1 |
| Plyo Box | Accessory | 1 |

Total: **22 equipment, 301 system exercises**, including **37 stretch-flagged rows**. All seed creators are NULL.

## Task 1.5 reference mappings

| Exercise | Equipment |
| --- | --- |
| Machine Chest Press | Machine |
| Leg Press | Machine |
| Trap Bar Deadlift | Trap Bar |
| Battle Ropes | Battle Rope |
| Sled Push | Sled |
| Medicine Ball Slam | Medicine Ball |
| Foam Rolling (Quads) | Foam Roller |
| TRX Row | TRX |
| EZ-Bar Curl | EZ Bar |
| Plate Front Raise | Weight Plate |
| Ab Wheel Rollout | Ab Wheel |
| Landmine Press | Landmine |
| Tire Flip | Tire |
| Box Jump | Plyo Box |

## Mock-data behavior (Task 1.4)

The demo lookup uses email `demo@gmail.com`; the inserted name is `Demo beginner`, and password_hash is NULL. The inserted profile has gender, birth_date, and height_cm NULL; fitness_level `Beginner`, primary_goal `Build muscle`, workout_location `Home`, days_per_week 3, minutes_per_session 60, and stretch_recommendation FALSE.

The section resolves equipment by name, starts a transaction, upserts the user and profile, upserts Bodyweight and Dumbbell links, deletes this demo's other equipment links, then commits. Re-running just this section restores those six specified profile settings and those two equipment choices. It updates the user's name but does not reset an existing password_hash, gender, birth_date, or height_cm. It does not recreate the database or modify equipment/exercise masters. Re-running the entire combined file does recreate the database.

## Import and test discipline

The opening DROP DATABASE is destructive. Use only an approved disposable environment; never execute this file as an application startup routine or migration. Keep one connection for all session variables. Stop on SQL errors. Task 1.4's comment instructs ROLLBACK on error; it is not an implemented automatic error handler. Review all PASS/FAIL result sets manually or with a future runner that actually fails on FAIL rows. Live MySQL execution has not been verified for this baseline.

Task 1.5 is read-only with respect to persistent data, although it changes connection variables. Its exact-count tests apply before extra seed/custom data. Its rep-range predicate does not report NULL rep bounds, which the DDL permits. Passing those queries would not prove all CHECK/FK behavior or application ownership rules.

## Complete exercise seed inventory

This catalog is transcribed programmatically from every source tuple, in source order. Source order is not an ID contract. Preserve these values; use the original SQL for reseeding. `creator` is NULL for all 301 rows.

| Exercise | Muscle group | Mechanics | SFR category | Rep min | Rep max | Is stretch | Equipment |
| --- | --- | --- | --- | ---: | ---: | ---: | --- |
| Barbell Bench Press | Chest | Compound | High Fatigue | 5 | 10 | 0 | Barbell |
| Dumbbell Bench Press | Chest | Compound | Moderate Fatigue | 8 | 12 | 0 | Dumbbell |
| Barbell Incline Bench Press | Chest | Compound | High Fatigue | 6 | 10 | 0 | Barbell |
| Dumbbell Incline Bench Press | Chest | Compound | Moderate Fatigue | 8 | 12 | 0 | Dumbbell |
| Barbell Decline Bench Press | Chest | Compound | High Fatigue | 6 | 10 | 0 | Barbell |
| Dumbbell Decline Bench Press | Chest | Compound | Moderate Fatigue | 8 | 12 | 0 | Dumbbell |
| Push-up | Chest | Compound | Low Fatigue | 10 | 25 | 0 | Bodyweight |
| Decline Push-up | Chest | Compound | Low Fatigue | 10 | 20 | 0 | Bodyweight |
| Incline Push-up | Chest | Compound | Low Fatigue | 10 | 30 | 0 | Bodyweight |
| Weighted Push-up | Chest | Compound | Moderate Fatigue | 8 | 15 | 0 | Bodyweight |
| Dumbbell Flyes | Chest | Isolation | Low Fatigue | 10 | 15 | 0 | Dumbbell |
| Incline Dumbbell Flyes | Chest | Isolation | Low Fatigue | 10 | 15 | 0 | Dumbbell |
| Decline Dumbbell Flyes | Chest | Isolation | Low Fatigue | 10 | 15 | 0 | Dumbbell |
| Cable Crossover (High to Low) | Chest | Isolation | Low Fatigue | 12 | 20 | 0 | Cable Machine |
| Cable Crossover (Low to High) | Chest | Isolation | Low Fatigue | 12 | 20 | 0 | Cable Machine |
| Cable Crossover (Mid-Chest) | Chest | Isolation | Low Fatigue | 12 | 20 | 0 | Cable Machine |
| Machine Chest Press | Chest | Compound | Moderate Fatigue | 8 | 12 | 0 | Machine |
| Incline Machine Chest Press | Chest | Compound | Moderate Fatigue | 8 | 12 | 0 | Machine |
| Decline Machine Chest Press | Chest | Compound | Moderate Fatigue | 8 | 12 | 0 | Machine |
| Pec Deck Machine | Chest | Isolation | Low Fatigue | 12 | 15 | 0 | Machine |
| Smith Machine Bench Press | Chest | Compound | Moderate Fatigue | 6 | 10 | 0 | Smith Machine |
| Smith Machine Incline Press | Chest | Compound | Moderate Fatigue | 8 | 12 | 0 | Smith Machine |
| Smith Machine Decline Press | Chest | Compound | Moderate Fatigue | 8 | 12 | 0 | Smith Machine |
| Floor Press (Barbell) | Chest | Compound | High Fatigue | 5 | 10 | 0 | Barbell |
| Floor Press (Dumbbell) | Chest | Compound | Moderate Fatigue | 8 | 12 | 0 | Dumbbell |
| Svend Press | Chest | Isolation | Low Fatigue | 15 | 20 | 0 | Dumbbell |
| Dumbbell Pullover | Chest | Compound | Moderate Fatigue | 10 | 15 | 0 | Dumbbell |
| Guillotine Press | Chest | Compound | High Fatigue | 8 | 12 | 0 | Barbell |
| Hex Press (Dumbbell) | Chest | Compound | Moderate Fatigue | 10 | 15 | 0 | Dumbbell |
| Barbell Deadlift | Back | Compound | Very High Fatigue | 3 | 6 | 0 | Barbell |
| Sumo Deadlift | Back | Compound | Very High Fatigue | 3 | 6 | 0 | Barbell |
| Romanian Deadlift (RDL) | Back | Compound | High Fatigue | 6 | 10 | 0 | Barbell |
| Stiff-Legged Deadlift | Back | Compound | High Fatigue | 6 | 10 | 0 | Barbell |
| Trap Bar Deadlift | Back | Compound | Very High Fatigue | 5 | 8 | 0 | Trap Bar |
| Pull-up | Back | Compound | Moderate Fatigue | 5 | 15 | 0 | Pull-up Bar |
| Weighted Pull-up | Back | Compound | High Fatigue | 5 | 8 | 0 | Pull-up Bar |
| Chin-up | Back | Compound | Moderate Fatigue | 5 | 15 | 0 | Pull-up Bar |
| Weighted Chin-up | Back | Compound | High Fatigue | 5 | 8 | 0 | Pull-up Bar |
| Wide-Grip Pull-up | Back | Compound | Moderate Fatigue | 5 | 12 | 0 | Pull-up Bar |
| Barbell Bent-Over Row | Back | Compound | High Fatigue | 6 | 10 | 0 | Barbell |
| Pendlay Row | Back | Compound | High Fatigue | 5 | 8 | 0 | Barbell |
| Yates Row | Back | Compound | High Fatigue | 8 | 12 | 0 | Barbell |
| Dumbbell Single-Arm Row | Back | Compound | Moderate Fatigue | 8 | 12 | 0 | Dumbbell |
| Dumbbell Bent-Over Row (Two Arms) | Back | Compound | Moderate Fatigue | 8 | 12 | 0 | Dumbbell |
| Renegade Row | Back | Compound | Moderate Fatigue | 10 | 15 | 0 | Dumbbell |
| Chest-Supported Dumbbell Row | Back | Compound | Moderate Fatigue | 8 | 12 | 0 | Dumbbell |
| Meadows Row | Back | Compound | Moderate Fatigue | 8 | 12 | 0 | Barbell |
| T-Bar Row | Back | Compound | High Fatigue | 8 | 12 | 0 | Machine |
| Lat Pulldown (Wide Grip) | Back | Compound | Moderate Fatigue | 8 | 12 | 0 | Cable Machine |
| Lat Pulldown (Close Grip) | Back | Compound | Moderate Fatigue | 8 | 12 | 0 | Cable Machine |
| Lat Pulldown (Reverse Grip) | Back | Compound | Moderate Fatigue | 8 | 12 | 0 | Cable Machine |
| Lat Pulldown (V-Bar) | Back | Compound | Moderate Fatigue | 8 | 12 | 0 | Cable Machine |
| Seated Cable Row (V-Bar) | Back | Compound | Moderate Fatigue | 10 | 15 | 0 | Cable Machine |
| Seated Cable Row (Wide Grip) | Back | Compound | Moderate Fatigue | 10 | 15 | 0 | Cable Machine |
| Machine Row (Seated) | Back | Compound | Moderate Fatigue | 8 | 12 | 0 | Machine |
| Machine Row (High) | Back | Compound | Moderate Fatigue | 8 | 12 | 0 | Machine |
| Straight-Arm Pulldown | Back | Isolation | Low Fatigue | 12 | 15 | 0 | Cable Machine |
| Cable Face Pull (High to Low) | Back | Isolation | Low Fatigue | 12 | 15 | 0 | Cable Machine |
| Cable Shrug | Back | Isolation | Low Fatigue | 10 | 15 | 0 | Cable Machine |
| Barbell Shrug | Back | Isolation | Moderate Fatigue | 8 | 15 | 0 | Barbell |
| Dumbbell Shrug | Back | Isolation | Moderate Fatigue | 10 | 15 | 0 | Dumbbell |
| Smith Machine Shrug | Back | Isolation | Moderate Fatigue | 10 | 15 | 0 | Smith Machine |
| Hex Bar Shrug | Back | Isolation | Moderate Fatigue | 8 | 15 | 0 | Trap Bar |
| Good Morning (Barbell) | Back | Compound | High Fatigue | 8 | 12 | 0 | Barbell |
| Good Morning (Seated) | Back | Compound | Moderate Fatigue | 10 | 15 | 0 | Barbell |
| Back Extension (Hyperextension) | Back | Isolation | Low Fatigue | 10 | 15 | 0 | Bodyweight |
| Weighted Back Extension | Back | Isolation | Moderate Fatigue | 8 | 12 | 0 | Bodyweight |
| Reverse Hyper | Back | Isolation | Moderate Fatigue | 10 | 15 | 0 | Machine |
| Rack Pull | Back | Compound | High Fatigue | 4 | 8 | 0 | Barbell |
| Inverted Row (Bodyweight) | Back | Compound | Low Fatigue | 10 | 20 | 0 | Bodyweight |
| Weighted Inverted Row | Back | Compound | Moderate Fatigue | 8 | 15 | 0 | Bodyweight |
| Superman | Back | Isolation | Low Fatigue | 15 | 20 | 0 | Bodyweight |
| Seal Row (Barbell) | Back | Compound | Moderate Fatigue | 8 | 12 | 0 | Barbell |
| Seal Row (Dumbbell) | Back | Compound | Moderate Fatigue | 10 | 15 | 0 | Dumbbell |
| Barbell Squat | Legs | Compound | Very High Fatigue | 5 | 8 | 0 | Barbell |
| Front Squat | Legs | Compound | High Fatigue | 5 | 8 | 0 | Barbell |
| Box Squat | Legs | Compound | High Fatigue | 4 | 8 | 0 | Barbell |
| Zercher Squat | Legs | Compound | High Fatigue | 5 | 8 | 0 | Barbell |
| Overhead Squat | Legs | Compound | High Fatigue | 5 | 8 | 0 | Barbell |
| Hack Squat (Machine) | Legs | Compound | High Fatigue | 8 | 12 | 0 | Machine |
| Leg Press | Legs | Compound | High Fatigue | 8 | 15 | 0 | Machine |
| Single-Leg Press | Legs | Compound | Moderate Fatigue | 8 | 12 | 0 | Machine |
| Pendulum Squat | Legs | Compound | High Fatigue | 8 | 12 | 0 | Machine |
| Smith Machine Squat | Legs | Compound | Moderate Fatigue | 6 | 10 | 0 | Smith Machine |
| Dumbbell Lunge | Legs | Compound | Moderate Fatigue | 10 | 20 | 0 | Dumbbell |
| Barbell Lunge | Legs | Compound | High Fatigue | 8 | 15 | 0 | Barbell |
| Walking Lunge (Dumbbell) | Legs | Compound | Moderate Fatigue | 10 | 20 | 0 | Dumbbell |
| Reverse Lunge (Barbell) | Legs | Compound | High Fatigue | 8 | 12 | 0 | Barbell |
| Reverse Lunge (Dumbbell) | Legs | Compound | Moderate Fatigue | 8 | 15 | 0 | Dumbbell |
| Bulgarian Split Squat (Dumbbell) | Legs | Compound | High Fatigue | 8 | 12 | 0 | Dumbbell |
| Bulgarian Split Squat (Barbell) | Legs | Compound | Very High Fatigue | 6 | 10 | 0 | Barbell |
| Bulgarian Split Squat (Smith Machine) | Legs | Compound | High Fatigue | 8 | 12 | 0 | Smith Machine |
| Kettlebell Goblet Squat | Legs | Compound | Moderate Fatigue | 8 | 15 | 0 | Kettlebell |
| Dumbbell Goblet Squat | Legs | Compound | Moderate Fatigue | 8 | 15 | 0 | Dumbbell |
| Step-Up (Dumbbell) | Legs | Compound | Moderate Fatigue | 8 | 15 | 0 | Dumbbell |
| Step-Up (Barbell) | Legs | Compound | High Fatigue | 8 | 12 | 0 | Barbell |
| Leg Extension | Legs | Isolation | Low Fatigue | 10 | 15 | 0 | Machine |
| Single-Leg Extension | Legs | Isolation | Low Fatigue | 10 | 15 | 0 | Machine |
| Seated Leg Curl | Legs | Isolation | Low Fatigue | 10 | 15 | 0 | Machine |
| Lying Leg Curl | Legs | Isolation | Low Fatigue | 10 | 15 | 0 | Machine |
| Standing Single-Leg Curl | Legs | Isolation | Low Fatigue | 10 | 15 | 0 | Machine |
| Nordic Hamstring Curl | Legs | Isolation | Moderate Fatigue | 5 | 10 | 0 | Bodyweight |
| Glute-Ham Raise (GHR) | Legs | Compound | Moderate Fatigue | 8 | 15 | 0 | Machine |
| Barbell Hip Thrust | Legs | Compound | High Fatigue | 8 | 12 | 0 | Barbell |
| Dumbbell Hip Thrust | Legs | Compound | Moderate Fatigue | 10 | 15 | 0 | Dumbbell |
| Machine Hip Thrust | Legs | Compound | Moderate Fatigue | 8 | 12 | 0 | Machine |
| Single-Leg Hip Thrust (Bodyweight) | Legs | Compound | Low Fatigue | 10 | 20 | 0 | Bodyweight |
| Single-Leg Hip Thrust (Dumbbell) | Legs | Compound | Moderate Fatigue | 10 | 15 | 0 | Dumbbell |
| Glute Bridge | Legs | Isolation | Low Fatigue | 15 | 20 | 0 | Bodyweight |
| Weighted Glute Bridge | Legs | Isolation | Moderate Fatigue | 10 | 15 | 0 | Barbell |
| Cable Pull-Through | Legs | Compound | Low Fatigue | 12 | 15 | 0 | Cable Machine |
| Kettlebell Swing | Legs | Compound | Moderate Fatigue | 15 | 20 | 0 | Kettlebell |
| Standing Calf Raise (Machine) | Legs | Isolation | Low Fatigue | 15 | 20 | 0 | Machine |
| Standing Calf Raise (Dumbbell) | Legs | Isolation | Low Fatigue | 15 | 20 | 0 | Dumbbell |
| Standing Calf Raise (Bodyweight) | Legs | Isolation | No Fatigue | 20 | 30 | 0 | Bodyweight |
| Seated Calf Raise (Machine) | Legs | Isolation | Low Fatigue | 12 | 20 | 0 | Machine |
| Donkey Calf Raise | Legs | Isolation | Low Fatigue | 15 | 20 | 0 | Machine |
| Leg Press Calf Raise | Legs | Isolation | Low Fatigue | 15 | 20 | 0 | Machine |
| Tibialis Raise (Bodyweight) | Legs | Isolation | No Fatigue | 15 | 25 | 0 | Bodyweight |
| Sissy Squat | Legs | Compound | Moderate Fatigue | 10 | 15 | 0 | Bodyweight |
| Machine Hip Abductor | Legs | Isolation | Low Fatigue | 12 | 20 | 0 | Machine |
| Machine Hip Adductor | Legs | Isolation | Low Fatigue | 12 | 20 | 0 | Machine |
| Cable Hip Abduction | Legs | Isolation | Low Fatigue | 12 | 15 | 0 | Cable Machine |
| Cable Hip Adduction | Legs | Isolation | Low Fatigue | 12 | 15 | 0 | Cable Machine |
| Banded Lateral Walk | Legs | Isolation | Low Fatigue | 15 | 20 | 0 | Resistance Band |
| Clamshell (Bodyweight) | Legs | Isolation | No Fatigue | 15 | 25 | 0 | Bodyweight |
| Clamshell (Banded) | Legs | Isolation | Low Fatigue | 15 | 20 | 0 | Resistance Band |
| Pistol Squat | Legs | Compound | High Fatigue | 5 | 10 | 0 | Bodyweight |
| Assisted Pistol Squat | Legs | Compound | Moderate Fatigue | 8 | 12 | 0 | Bodyweight |
| Skater Squat | Legs | Compound | Moderate Fatigue | 8 | 12 | 0 | Bodyweight |
| Jefferson Curl | Legs | Isolation | Low Fatigue | 10 | 15 | 0 | Barbell |
| Good Morning (Smith Machine) | Legs | Compound | Moderate Fatigue | 10 | 15 | 0 | Smith Machine |
| Landmine Squat | Legs | Compound | Moderate Fatigue | 8 | 12 | 0 | Landmine |
| Landmine Reverse Lunge | Legs | Compound | Moderate Fatigue | 8 | 12 | 0 | Landmine |
| Copenhagen Plank | Legs | Static | Low Fatigue | 1 | 1 | 0 | Bodyweight |
| Sumo Squat (Dumbbell) | Legs | Compound | Moderate Fatigue | 10 | 15 | 0 | Dumbbell |
| Sumo Squat (Barbell) | Legs | Compound | High Fatigue | 6 | 10 | 0 | Barbell |
| Cable Kickback | Legs | Isolation | Low Fatigue | 12 | 20 | 0 | Cable Machine |
| Overhead Press (Barbell) | Shoulders | Compound | High Fatigue | 6 | 10 | 0 | Barbell |
| Dumbbell Shoulder Press | Shoulders | Compound | Moderate Fatigue | 8 | 12 | 0 | Dumbbell |
| Machine Shoulder Press | Shoulders | Compound | Moderate Fatigue | 8 | 12 | 0 | Machine |
| Smith Machine Shoulder Press | Shoulders | Compound | Moderate Fatigue | 8 | 12 | 0 | Smith Machine |
| Arnold Press | Shoulders | Compound | Moderate Fatigue | 8 | 12 | 0 | Dumbbell |
| Push Press | Shoulders | Compound | High Fatigue | 4 | 8 | 0 | Barbell |
| Dumbbell Lateral Raise | Shoulders | Isolation | Low Fatigue | 12 | 20 | 0 | Dumbbell |
| Cable Lateral Raise | Shoulders | Isolation | Low Fatigue | 12 | 20 | 0 | Cable Machine |
| Machine Lateral Raise | Shoulders | Isolation | Low Fatigue | 12 | 20 | 0 | Machine |
| Leaning Cable Lateral Raise | Shoulders | Isolation | Low Fatigue | 10 | 15 | 0 | Cable Machine |
| Egyptian Cable Lateral Raise | Shoulders | Isolation | Low Fatigue | 10 | 15 | 0 | Cable Machine |
| Seated Dumbbell Lateral Raise | Shoulders | Isolation | Low Fatigue | 12 | 20 | 0 | Dumbbell |
| Dumbbell Front Raise | Shoulders | Isolation | Low Fatigue | 10 | 15 | 0 | Dumbbell |
| Cable Front Raise | Shoulders | Isolation | Low Fatigue | 10 | 15 | 0 | Cable Machine |
| Barbell Front Raise | Shoulders | Isolation | Low Fatigue | 10 | 15 | 0 | Barbell |
| Plate Front Raise | Shoulders | Isolation | Low Fatigue | 10 | 20 | 0 | Weight Plate |
| Reverse Pec Deck | Shoulders | Isolation | Low Fatigue | 12 | 20 | 0 | Machine |
| Face Pull | Shoulders | Isolation | Low Fatigue | 12 | 15 | 0 | Cable Machine |
| Dumbbell Rear Delt Row | Shoulders | Compound | Moderate Fatigue | 10 | 15 | 0 | Dumbbell |
| Bent-Over Dumbbell Rear Delt Raise | Shoulders | Isolation | Low Fatigue | 12 | 20 | 0 | Dumbbell |
| Cable Rear Delt Fly | Shoulders | Isolation | Low Fatigue | 12 | 20 | 0 | Cable Machine |
| Upright Row (Barbell) | Shoulders | Compound | Moderate Fatigue | 8 | 12 | 0 | Barbell |
| Upright Row (Dumbbell) | Shoulders | Compound | Moderate Fatigue | 10 | 15 | 0 | Dumbbell |
| Upright Row (Cable) | Shoulders | Compound | Moderate Fatigue | 10 | 15 | 0 | Cable Machine |
| Landmine Press | Shoulders | Compound | Moderate Fatigue | 8 | 12 | 0 | Landmine |
| Barbell Curl | Biceps | Isolation | Moderate Fatigue | 8 | 12 | 0 | Barbell |
| EZ-Bar Curl | Biceps | Isolation | Moderate Fatigue | 8 | 12 | 0 | EZ Bar |
| Dumbbell Alternate Curl | Biceps | Isolation | Low Fatigue | 10 | 15 | 0 | Dumbbell |
| Dumbbell Hammer Curl | Biceps | Isolation | Low Fatigue | 10 | 15 | 0 | Dumbbell |
| Cross-Body Hammer Curl | Biceps | Isolation | Low Fatigue | 10 | 15 | 0 | Dumbbell |
| Cable Bicep Curl | Biceps | Isolation | Low Fatigue | 12 | 20 | 0 | Cable Machine |
| Rope Cable Curl | Biceps | Isolation | Low Fatigue | 12 | 20 | 0 | Cable Machine |
| Preacher Curl (Barbell) | Biceps | Isolation | Low Fatigue | 8 | 12 | 0 | Barbell |
| Preacher Curl (Dumbbell) | Biceps | Isolation | Low Fatigue | 10 | 15 | 0 | Dumbbell |
| Machine Preacher Curl | Biceps | Isolation | Low Fatigue | 10 | 15 | 0 | Machine |
| Concentration Curl | Biceps | Isolation | Low Fatigue | 10 | 15 | 0 | Dumbbell |
| Spider Curl | Biceps | Isolation | Low Fatigue | 10 | 15 | 0 | Dumbbell |
| Incline Dumbbell Curl | Biceps | Isolation | Low Fatigue | 10 | 15 | 0 | Dumbbell |
| Reverse Curl (Barbell) | Biceps | Isolation | Moderate Fatigue | 10 | 15 | 0 | Barbell |
| Reverse Curl (Cable) | Biceps | Isolation | Low Fatigue | 12 | 15 | 0 | Cable Machine |
| Zottman Curl | Biceps | Isolation | Low Fatigue | 10 | 15 | 0 | Dumbbell |
| High Cable Curl | Biceps | Isolation | Low Fatigue | 12 | 15 | 0 | Cable Machine |
| Bayesian Curl | Biceps | Isolation | Low Fatigue | 12 | 20 | 0 | Cable Machine |
| Close-Grip Bench Press | Triceps | Compound | High Fatigue | 6 | 10 | 0 | Barbell |
| Triceps Rope Pushdown | Triceps | Isolation | Low Fatigue | 10 | 15 | 0 | Cable Machine |
| Triceps V-Bar Pushdown | Triceps | Isolation | Low Fatigue | 10 | 15 | 0 | Cable Machine |
| Triceps Straight Bar Pushdown | Triceps | Isolation | Low Fatigue | 10 | 15 | 0 | Cable Machine |
| Reverse-Grip Triceps Pushdown | Triceps | Isolation | Low Fatigue | 12 | 15 | 0 | Cable Machine |
| Overhead Triceps Extension (Dumbbell) | Triceps | Isolation | Low Fatigue | 10 | 15 | 0 | Dumbbell |
| Overhead Triceps Extension (Cable) | Triceps | Isolation | Low Fatigue | 12 | 15 | 0 | Cable Machine |
| Overhead Triceps Extension (EZ-Bar) | Triceps | Isolation | Moderate Fatigue | 8 | 12 | 0 | EZ Bar |
| Skullcrushers (EZ-Bar) | Triceps | Isolation | Moderate Fatigue | 8 | 12 | 0 | EZ Bar |
| Skullcrushers (Dumbbell) | Triceps | Isolation | Low Fatigue | 10 | 15 | 0 | Dumbbell |
| Triceps Kickback (Dumbbell) | Triceps | Isolation | Low Fatigue | 12 | 15 | 0 | Dumbbell |
| Triceps Kickback (Cable) | Triceps | Isolation | Low Fatigue | 12 | 15 | 0 | Cable Machine |
| Dips (Bodyweight) | Triceps | Compound | Moderate Fatigue | 8 | 15 | 0 | Bodyweight |
| Weighted Dips | Triceps | Compound | High Fatigue | 5 | 10 | 0 | Bodyweight |
| Machine Dips | Triceps | Compound | Moderate Fatigue | 8 | 15 | 0 | Machine |
| Bench Dips | Triceps | Compound | Low Fatigue | 10 | 20 | 0 | Bodyweight |
| Tate Press | Triceps | Isolation | Low Fatigue | 10 | 15 | 0 | Dumbbell |
| JM Press | Triceps | Compound | Moderate Fatigue | 8 | 12 | 0 | Barbell |
| Katana Extension | Triceps | Isolation | Low Fatigue | 12 | 20 | 0 | Cable Machine |
| Cross-Body Triceps Extension | Triceps | Isolation | Low Fatigue | 12 | 20 | 0 | Cable Machine |
| Crunch | Core | Isolation | Low Fatigue | 15 | 25 | 0 | Bodyweight |
| Weighted Crunch | Core | Isolation | Moderate Fatigue | 10 | 15 | 0 | Barbell |
| Sit-up | Core | Compound | Low Fatigue | 15 | 25 | 0 | Bodyweight |
| Decline Sit-up | Core | Compound | Moderate Fatigue | 10 | 20 | 0 | Bodyweight |
| Plank | Core | Static | Low Fatigue | 1 | 1 | 0 | Bodyweight |
| Weighted Plank | Core | Static | Moderate Fatigue | 1 | 1 | 0 | Barbell |
| Side Plank | Core | Static | Low Fatigue | 1 | 1 | 0 | Bodyweight |
| Hanging Leg Raise | Core | Compound | Moderate Fatigue | 10 | 20 | 0 | Pull-up Bar |
| Hanging Knee Raise | Core | Compound | Low Fatigue | 10 | 20 | 0 | Pull-up Bar |
| Captain's Chair Leg Raise | Core | Compound | Low Fatigue | 10 | 20 | 0 | Machine |
| Lying Leg Raise | Core | Isolation | Low Fatigue | 15 | 20 | 0 | Bodyweight |
| Cable Crunch | Core | Isolation | Low Fatigue | 12 | 20 | 0 | Cable Machine |
| Machine Crunch | Core | Isolation | Low Fatigue | 12 | 20 | 0 | Machine |
| Ab Wheel Rollout | Core | Compound | Moderate Fatigue | 8 | 15 | 0 | Ab Wheel |
| Russian Twist | Core | Isolation | Low Fatigue | 20 | 30 | 0 | Bodyweight |
| Weighted Russian Twist | Core | Isolation | Moderate Fatigue | 15 | 25 | 0 | Kettlebell |
| Bicycle Crunch | Core | Isolation | Low Fatigue | 20 | 30 | 0 | Bodyweight |
| Flutter Kicks | Core | Isolation | Low Fatigue | 20 | 30 | 0 | Bodyweight |
| V-up | Core | Compound | Moderate Fatigue | 10 | 20 | 0 | Bodyweight |
| Toe Touches | Core | Isolation | Low Fatigue | 15 | 20 | 0 | Bodyweight |
| Woodchopper (Cable) | Core | Compound | Low Fatigue | 12 | 15 | 0 | Cable Machine |
| Woodchopper (Dumbbell) | Core | Compound | Low Fatigue | 12 | 15 | 0 | Dumbbell |
| Pallof Press | Core | Static | Low Fatigue | 1 | 1 | 0 | Cable Machine |
| Bird Dog | Core | Static | Low Fatigue | 10 | 15 | 0 | Bodyweight |
| Dead Bug | Core | Isolation | Low Fatigue | 10 | 15 | 0 | Bodyweight |
| Hollow Body Hold | Core | Static | Moderate Fatigue | 1 | 1 | 0 | Bodyweight |
| Dragon Flag | Core | Compound | High Fatigue | 5 | 10 | 0 | Bodyweight |
| Windshield Wipers | Core | Isolation | Moderate Fatigue | 10 | 20 | 0 | Bodyweight |
| Farmer's Walk | Core | Compound | High Fatigue | 1 | 1 | 0 | Dumbbell |
| Suitcase Carry | Core | Compound | Moderate Fatigue | 1 | 1 | 0 | Dumbbell |
| Turkish Get-Up | Full Body | Compound | High Fatigue | 1 | 5 | 0 | Kettlebell |
| Kettlebell Snatch | Full Body | Compound | High Fatigue | 5 | 10 | 0 | Kettlebell |
| Kettlebell Clean and Press | Full Body | Compound | High Fatigue | 5 | 10 | 0 | Kettlebell |
| Barbell Clean | Full Body | Compound | Very High Fatigue | 3 | 5 | 0 | Barbell |
| Barbell Power Clean | Full Body | Compound | Very High Fatigue | 3 | 5 | 0 | Barbell |
| Barbell Snatch | Full Body | Compound | Very High Fatigue | 1 | 3 | 0 | Barbell |
| Muscle-Up | Full Body | Compound | High Fatigue | 3 | 8 | 0 | Pull-up Bar |
| Front Lever | Core | Static | High Fatigue | 1 | 1 | 0 | Pull-up Bar |
| Back Lever | Core | Static | High Fatigue | 1 | 1 | 0 | Pull-up Bar |
| Human Flag | Core | Static | High Fatigue | 1 | 1 | 0 | Pull-up Bar |
| L-Sit | Core | Static | Moderate Fatigue | 1 | 1 | 0 | Bodyweight |
| Burpee | Full Body | Compound | High Fatigue | 10 | 20 | 0 | Bodyweight |
| Mountain Climber | Core | Compound | Low Fatigue | 20 | 40 | 0 | Bodyweight |
| Box Jump | Legs | Compound | Moderate Fatigue | 5 | 10 | 0 | Plyo Box |
| Battle Ropes | Full Body | Compound | High Fatigue | 1 | 1 | 0 | Battle Rope |
| Sled Push | Full Body | Compound | High Fatigue | 1 | 1 | 0 | Sled |
| Sled Pull | Full Body | Compound | High Fatigue | 1 | 1 | 0 | Sled |
| Tire Flip | Full Body | Compound | High Fatigue | 5 | 10 | 0 | Tire |
| Wall Ball | Full Body | Compound | Moderate Fatigue | 10 | 20 | 0 | Medicine Ball |
| Medicine Ball Slam | Full Body | Compound | Moderate Fatigue | 10 | 20 | 0 | Medicine Ball |
| Chest Stretch | Chest | Static | No Fatigue | 1 | 1 | 1 | Yoga Mat |
| Doorway Chest Stretch | Chest | Static | No Fatigue | 1 | 1 | 1 | Yoga Mat |
| Upper Back Stretch | Back | Static | No Fatigue | 1 | 1 | 1 | Yoga Mat |
| Child's Pose | Back | Static | No Fatigue | 1 | 1 | 1 | Yoga Mat |
| Cat-Cow | Back | Static | No Fatigue | 1 | 1 | 1 | Yoga Mat |
| Lat Stretch | Back | Static | No Fatigue | 1 | 1 | 1 | Yoga Mat |
| Hamstring Stretch | Legs | Static | No Fatigue | 1 | 1 | 1 | Yoga Mat |
| Seated Forward Bend | Legs | Static | No Fatigue | 1 | 1 | 1 | Yoga Mat |
| Standing Hamstring Stretch | Legs | Static | No Fatigue | 1 | 1 | 1 | Yoga Mat |
| Quad Stretch | Legs | Static | No Fatigue | 1 | 1 | 1 | Yoga Mat |
| Lying Quad Stretch | Legs | Static | No Fatigue | 1 | 1 | 1 | Yoga Mat |
| Calf Stretch | Legs | Static | No Fatigue | 1 | 1 | 1 | Yoga Mat |
| Downward Dog | Legs | Static | No Fatigue | 1 | 1 | 1 | Yoga Mat |
| Glute Stretch | Legs | Static | No Fatigue | 1 | 1 | 1 | Yoga Mat |
| Figure Four Stretch | Legs | Static | No Fatigue | 1 | 1 | 1 | Yoga Mat |
| Pigeon Pose | Legs | Static | No Fatigue | 1 | 1 | 1 | Yoga Mat |
| Butterfly Stretch | Legs | Static | No Fatigue | 1 | 1 | 1 | Yoga Mat |
| Hip Flexor Stretch | Legs | Static | No Fatigue | 1 | 1 | 1 | Yoga Mat |
| Kneeling Lunge Stretch | Legs | Static | No Fatigue | 1 | 1 | 1 | Yoga Mat |
| Shoulder Stretch | Shoulders | Static | No Fatigue | 1 | 1 | 1 | Yoga Mat |
| Cross-Body Shoulder Stretch | Shoulders | Static | No Fatigue | 1 | 1 | 1 | Yoga Mat |
| Triceps Stretch | Triceps | Static | No Fatigue | 1 | 1 | 1 | Yoga Mat |
| Overhead Triceps Stretch | Triceps | Static | No Fatigue | 1 | 1 | 1 | Yoga Mat |
| Biceps Stretch | Biceps | Static | No Fatigue | 1 | 1 | 1 | Yoga Mat |
| Wrist Flexor Stretch | Arms | Static | No Fatigue | 1 | 1 | 1 | Yoga Mat |
| Wrist Extensor Stretch | Arms | Static | No Fatigue | 1 | 1 | 1 | Yoga Mat |
| Neck Stretch (Side to Side) | Neck | Static | No Fatigue | 1 | 1 | 1 | Yoga Mat |
| Neck Stretch (Up and Down) | Neck | Static | No Fatigue | 1 | 1 | 1 | Yoga Mat |
| Cobra Pose | Core | Static | No Fatigue | 1 | 1 | 1 | Yoga Mat |
| Sphinx Pose | Core | Static | No Fatigue | 1 | 1 | 1 | Yoga Mat |
| Thoracic Extension | Back | Static | No Fatigue | 1 | 1 | 1 | Yoga Mat |
| Foam Rolling (Quads) | Legs | Static | No Fatigue | 1 | 1 | 1 | Foam Roller |
| Foam Rolling (Hamstrings) | Legs | Static | No Fatigue | 1 | 1 | 1 | Foam Roller |
| Foam Rolling (Calves) | Legs | Static | No Fatigue | 1 | 1 | 1 | Foam Roller |
| Foam Rolling (IT Band) | Legs | Static | No Fatigue | 1 | 1 | 1 | Foam Roller |
| Foam Rolling (Upper Back) | Back | Static | No Fatigue | 1 | 1 | 1 | Foam Roller |
| Foam Rolling (Lats) | Back | Static | No Fatigue | 1 | 1 | 1 | Foam Roller |
| Resistance Band Pull-Apart | Shoulders | Isolation | Low Fatigue | 15 | 25 | 0 | Resistance Band |
| Banded Side Step | Legs | Isolation | Low Fatigue | 15 | 20 | 0 | Resistance Band |
| Banded Glute Bridge | Legs | Isolation | Low Fatigue | 15 | 20 | 0 | Resistance Band |
| Banded Squat | Legs | Compound | Moderate Fatigue | 10 | 15 | 0 | Resistance Band |
| Banded Push-up | Chest | Compound | Moderate Fatigue | 10 | 15 | 0 | Resistance Band |
| TRX Row | Back | Compound | Low Fatigue | 10 | 15 | 0 | TRX |
| TRX Push-up | Chest | Compound | Low Fatigue | 10 | 15 | 0 | TRX |
| TRX Squat | Legs | Compound | Low Fatigue | 10 | 15 | 0 | TRX |
| TRX Lunge | Legs | Compound | Low Fatigue | 10 | 15 | 0 | TRX |
| TRX Y-Fly | Shoulders | Isolation | Low Fatigue | 10 | 15 | 0 | TRX |
| TRX Triceps Extension | Triceps | Isolation | Low Fatigue | 10 | 15 | 0 | TRX |
| TRX Biceps Curl | Biceps | Isolation | Low Fatigue | 10 | 15 | 0 | TRX |
| Jumping Jacks | Full Body | Compound | Low Fatigue | 20 | 50 | 0 | Bodyweight |

# Data dictionary

Original SQL baseline date: 2026-10-18 (Asia/Bangkok). Source: `Project_add_Equipment.sql`, read in full including embedded Tasks 1.4 and 1.5. Phase 1 SQL implementation is complete in source; the user reports T01–T14 passed, but saved results were not independently reviewed here. Task 2.1 is complete for the local backend foundation scope from user-run validation and supplied HTTP/MySQL responses; Task 2.2 demo Profile API is implemented; the user supplied an 18-test OK summary; live GET /profile returned 200 with demo data supplied by the user; Codex verified live PATCH/readback and invalid-value rejection; the user-run seven-check MySQL suite passed with a saved JSON report; Task 2.2 is complete for local demo scope; Tasks 2.3–2.5 are not started. Field definitions below describe the unchanged SQL baseline. See [current project progress](ROADMAP.md).

## Conventions

Types, nullability, defaults, and constraints below are taken from the DDL. All primary keys are auto-increment INTs and implicitly NOT NULL. All fields without NOT NULL or a primary key remain nullable, even when they have a default. A dash in Default means no explicit DEFAULT clause, not an application fallback. DECIMAL values must retain declared precision and scale; do not silently substitute floating-point calculations for stored values.

Field meanings follow names and source comments. RPE means rating of perceived exertion; RIR means repetitions in reserve. The SQL defines ranges but no conversion between them. The SFR field stores fatigue labels; no stimulus-to-fatigue calculation is implemented. Weight_kg explicitly names kilograms; target_weight and actual_weight do not explicitly declare a unit. Confirm their API unit before implementation.

For each table, exact table-level constraints are reproduced after its column table. Inline primary and unique constraints are included in the column Key column. No extra enum or business constraint is implied.

Task 2.2's approved API vocabularies and write validation are documented in
[BACKEND_SPEC.md](BACKEND_SPEC.md#task-22--approved-demo-profile-contract).
The SQL remains nullable and does not define these vocabularies as database enums;
the field descriptions below refer to SQL constraints rather than API rules.

## users

User identity; password_hash is optional in the database. Source DDL: lines 17–23.

| Field | SQL type | Nullable | Default | Key / generation | Meaning |
| --- | --- | --- | --- | --- | --- |
| `user_id` | `INT` | No | — | PK, AUTO_INCREMENT | Generated identifier for this users row. |
| `name` | `VARCHAR(100)` | No | — | — | User display name. |
| `email` | `VARCHAR(100)` | No | — | UNIQUE | User email and demo lookup key; UNIQUE. |
| `password_hash` | `VARCHAR(255)` | Yes | — | — | Optional password hash; demo inserts NULL. No authentication implementation is evidenced. |
| `created_at` | `DATETIME` | Yes | `CURRENT_TIMESTAMP` | — | User creation datetime; default CURRENT_TIMESTAMP. |

## user_profiles

At most one profile per user; absence of a profile is allowed. Source DDL: lines 30–65.

| Field | SQL type | Nullable | Default | Key / generation | Meaning |
| --- | --- | --- | --- | --- | --- |
| `profile_id` | `INT` | No | — | PK, AUTO_INCREMENT | Generated identifier for this user_profiles row. |
| `user_id` | `INT` | No | — | UNIQUE, FK | Reference to the associated users row. |
| `gender` | `VARCHAR(20)` | Yes | — | — | Optional gender text; vocabulary unspecified. |
| `birth_date` | `DATE` | Yes | — | — | Optional date of birth. |
| `height_cm` | `DECIMAL(5,2)` | Yes | — | — | Height in centimetres; positive when present. |
| `fitness_level` | `VARCHAR(50)` | Yes | — | — | Fitness-level text; demo uses Beginner. No full allowed-value list is defined. |
| `primary_goal` | `VARCHAR(50)` | Yes | — | — | Goal text; demo uses Build muscle. No full allowed-value list is defined. |
| `workout_location` | `VARCHAR(50)` | Yes | — | — | Workout-location text; demo uses Home. No full allowed-value list is defined. |
| `days_per_week` | `INT` | Yes | — | — | Available workout days per week; 1–7 when present. |
| `minutes_per_session` | `INT` | Yes | — | — | Available session duration in minutes; positive when present. |
| `stretch_recommendation` | `BOOLEAN` | Yes | `FALSE` | — | Profile flag for stretch recommendation; default FALSE; algorithm unspecified. |

Exact table-level constraints:

```sql
FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
CHECK ( height_cm IS NULL OR height_cm > 0 )
CHECK ( days_per_week IS NULL OR days_per_week BETWEEN 1 AND 7 )
CHECK ( minutes_per_session IS NULL OR minutes_per_session > 0 )
```

## body_measurements

Time series of body-weight measurements. Source DDL: lines 72–84.

| Field | SQL type | Nullable | Default | Key / generation | Meaning |
| --- | --- | --- | --- | --- | --- |
| `measurement_id` | `INT` | No | — | PK, AUTO_INCREMENT | Generated identifier for this body_measurements row. |
| `user_id` | `INT` | No | — | FK | Reference to the associated users row. |
| `measured_at` | `DATETIME` | Yes | `CURRENT_TIMESTAMP` | — | Measurement datetime; default CURRENT_TIMESTAMP. |
| `weight_kg` | `DECIMAL(5,2)` | No | — | — | Body weight in kilograms; required and positive. |

Exact table-level constraints:

```sql
FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
CHECK (weight_kg > 0)
```

## equipment

Equipment master catalog. Source DDL: lines 91–95.

| Field | SQL type | Nullable | Default | Key / generation | Meaning |
| --- | --- | --- | --- | --- | --- |
| `equipment_id` | `INT` | No | — | PK, AUTO_INCREMENT | Generated identifier for this equipment row. |
| `equipment_name` | `VARCHAR(100)` | No | — | UNIQUE | Unique equipment master name; exact spelling is significant. |
| `category` | `VARCHAR(50)` | Yes | — | — | Equipment category label; source values listed in DATABASE.md. |

## user_equipment

User-owned or available equipment links. Source DDL: lines 102–117.

| Field | SQL type | Nullable | Default | Key / generation | Meaning |
| --- | --- | --- | --- | --- | --- |
| `user_equipment_id` | `INT` | No | — | PK, AUTO_INCREMENT | Generated identifier for this user_equipment row. |
| `user_id` | `INT` | No | — | FK | Reference to the associated users row. |
| `equipment_id` | `INT` | No | — | FK | Reference to the associated equipment row. |

Exact table-level constraints:

```sql
FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
FOREIGN KEY (equipment_id) REFERENCES equipment(equipment_id) ON DELETE CASCADE
UNIQUE (user_id, equipment_id)
```

## exercises

System and user-created exercise catalog. Source DDL: lines 124–168.

| Field | SQL type | Nullable | Default | Key / generation | Meaning |
| --- | --- | --- | --- | --- | --- |
| `exercise_id` | `INT` | No | — | PK, AUTO_INCREMENT | Generated identifier for this exercises row. |
| `exercise_name` | `VARCHAR(100)` | No | — | — | Exercise display/catalog name; not UNIQUE in DDL. |
| `muscle_group` | `VARCHAR(50)` | Yes | — | — | Seed muscle-group label; not a separate entity or enum. |
| `mechanics` | `VARCHAR(50)` | Yes | — | — | Exercise mechanics label; seed uses Compound, Isolation, Static. |
| `sfr_category` | `VARCHAR(50)` | Yes | — | — | Fatigue category text used by the seed; no numeric scoring formula is defined. |
| `optimal_rep_min` | `INT` | Yes | — | — | Optional lower catalog rep bound; positive when present. |
| `optimal_rep_max` | `INT` | Yes | — | — | Optional upper catalog rep bound; positive and >= min when both present. |
| `is_stretch` | `BOOLEAN` | Yes | `FALSE` | — | Exercise stretch flag; default FALSE. Foam rolling rows also use TRUE. |
| `equipment_id` | `INT` | No | — | FK | Reference to the associated equipment row. |
| `created_by_user_id` | `INT` | Yes | — | FK | Creator FK to users; NULL means system default by source convention. ON DELETE SET NULL. |

Exact table-level constraints:

```sql
FOREIGN KEY (equipment_id) REFERENCES equipment(equipment_id)
FOREIGN KEY (created_by_user_id) REFERENCES users(user_id) ON DELETE SET NULL
CHECK ( optimal_rep_min IS NULL OR optimal_rep_min > 0 )
CHECK ( optimal_rep_max IS NULL OR optimal_rep_max > 0 )
CHECK ( optimal_rep_min IS NULL OR optimal_rep_max IS NULL OR optimal_rep_min <= optimal_rep_max )
```

## user_exercise_preferences

Per-user favorite or excluded exercise. Source DDL: lines 175–196.

| Field | SQL type | Nullable | Default | Key / generation | Meaning |
| --- | --- | --- | --- | --- | --- |
| `preference_id` | `INT` | No | — | PK, AUTO_INCREMENT | Generated identifier for this user_exercise_preferences row. |
| `user_id` | `INT` | No | — | FK | Reference to the associated users row. |
| `exercise_id` | `INT` | No | — | FK | Reference to the associated exercises row. |
| `preference_type` | `VARCHAR(20)` | No | — | — | Required favorite or excluded; constrained by CHECK. |

Exact table-level constraints:

```sql
FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
FOREIGN KEY (exercise_id) REFERENCES exercises(exercise_id) ON DELETE CASCADE
UNIQUE (user_id, exercise_id)
CHECK ( preference_type IN ('favorite', 'excluded') )
```

## programs

User workout-program header. Source DDL: lines 203–228.

| Field | SQL type | Nullable | Default | Key / generation | Meaning |
| --- | --- | --- | --- | --- | --- |
| `program_id` | `INT` | No | — | PK, AUTO_INCREMENT | Generated identifier for this programs row. |
| `user_id` | `INT` | No | — | FK | Reference to the associated users row. |
| `program_name` | `VARCHAR(100)` | No | — | — | Required program display name. |
| `focus_area` | `VARCHAR(50)` | Yes | — | — | Optional program focus text; vocabulary unspecified. |
| `program_type` | `VARCHAR(50)` | Yes | — | — | Optional program-type text; vocabulary unspecified. |
| `start_date` | `DATE` | Yes | — | — | Optional program start date. |
| `end_date` | `DATE` | Yes | — | — | Optional program end date; cannot precede start when both present. |
| `status` | `VARCHAR(20)` | Yes | `'ACTIVE'` | — | Optional program status; default ACTIVE; no enum/check restricts other labels. |

Exact table-level constraints:

```sql
FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
CHECK ( end_date IS NULL OR start_date IS NULL OR end_date >= start_date )
```

## program_exercises

Ordered exercise prescriptions inside program days. Source DDL: lines 235–293.

| Field | SQL type | Nullable | Default | Key / generation | Meaning |
| --- | --- | --- | --- | --- | --- |
| `program_exercise_id` | `INT` | No | — | PK, AUTO_INCREMENT | Generated identifier for this program_exercises row. |
| `program_id` | `INT` | No | — | FK | Reference to the associated programs row. |
| `exercise_id` | `INT` | No | — | FK | Reference to the associated exercises row. |
| `day_order` | `INT` | No | — | — | Positive program day position; not explicitly a weekday number. |
| `exercise_order` | `INT` | No | — | — | Positive exercise position within a program day. |
| `target_sets` | `INT` | No | — | — | Required positive prescribed set count. |
| `rep_min` | `INT` | No | — | — | Required positive prescribed lower rep bound. |
| `rep_max` | `INT` | No | — | — | Required prescribed upper rep bound; >= rep_min. |
| `target_weight` | `DECIMAL(5,2)` | Yes | — | — | Optional prescribed load; NULL for an unknown first baseline; >= 0 when present. Unit not explicitly declared in SQL. |
| `target_rpe` | `DECIMAL(3,1)` | Yes | — | — | Optional prescribed rating of perceived exertion; 1–10. |
| `target_rest_seconds` | `INT` | Yes | — | — | Optional prescribed rest duration in seconds; >= 0. |

Exact table-level constraints:

```sql
FOREIGN KEY (program_id) REFERENCES programs(program_id) ON DELETE CASCADE
FOREIGN KEY (exercise_id) REFERENCES exercises(exercise_id)
CHECK (day_order > 0)
CHECK (exercise_order > 0)
CHECK (target_sets > 0)
CHECK (rep_min > 0)
CHECK (rep_max >= rep_min)
CHECK ( target_weight IS NULL OR target_weight >= 0 )
CHECK ( target_rpe IS NULL OR target_rpe BETWEEN 1 AND 10 )
CHECK ( target_rest_seconds IS NULL OR target_rest_seconds >= 0 )
UNIQUE ( program_id, day_order, exercise_order )
```

## workout_sessions

User workout occurrence; program association is optional. Source DDL: lines 300–325.

| Field | SQL type | Nullable | Default | Key / generation | Meaning |
| --- | --- | --- | --- | --- | --- |
| `session_id` | `INT` | No | — | PK, AUTO_INCREMENT | Generated identifier for this workout_sessions row. |
| `user_id` | `INT` | No | — | FK | Reference to the associated users row. |
| `program_id` | `INT` | Yes | — | FK | Optional associated program; NULL supports an unassociated session; ON DELETE SET NULL. |
| `session_date` | `DATE` | No | — | — | Required calendar date of workout session. |
| `start_time` | `DATETIME` | Yes | — | — | Optional session start datetime. |
| `end_time` | `DATETIME` | Yes | — | — | Optional session end datetime; >= start when both present. |

Exact table-level constraints:

```sql
FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
FOREIGN KEY (program_id) REFERENCES programs(program_id) ON DELETE SET NULL
CHECK ( end_time IS NULL OR start_time IS NULL OR end_time >= start_time )
```

## set_logs

Actual per-set results, including ad hoc exercise sets. Source DDL: lines 332–391.

| Field | SQL type | Nullable | Default | Key / generation | Meaning |
| --- | --- | --- | --- | --- | --- |
| `set_log_id` | `INT` | No | — | PK, AUTO_INCREMENT | Generated identifier for this set_logs row. |
| `session_id` | `INT` | No | — | FK | Reference to the associated workout_sessions row. |
| `program_exercise_id` | `INT` | Yes | — | FK | Optional planned exercise link; NULL supports an exercise outside a program; ON DELETE SET NULL. |
| `exercise_id` | `INT` | No | — | FK | Reference to the associated exercises row. |
| `set_number` | `INT` | No | — | — | Required positive set ordinal; not UNIQUE in DDL. |
| `actual_weight` | `DECIMAL(5,2)` | Yes | — | — | Optional actual load, e.g. NULL for Push-up/Pull-up; >= 0 when present. Unit not explicitly declared in SQL. |
| `actual_reps` | `INT` | No | — | — | Required actual repetitions; zero is allowed. |
| `rpe` | `DECIMAL(3,1)` | Yes | — | — | Optional actual rating of perceived exertion; 1–10. |
| `rir` | `INT` | Yes | — | — | Optional repetitions in reserve; integer >= 0; no upper limit or RPE conversion is declared. |
| `actual_rest_seconds` | `INT` | Yes | — | — | Optional actual rest duration in seconds; >= 0. |
| `completed` | `BOOLEAN` | Yes | `TRUE` | — | Optional set-completion flag; default TRUE. |

Exact table-level constraints:

```sql
FOREIGN KEY (session_id) REFERENCES workout_sessions(session_id) ON DELETE CASCADE
FOREIGN KEY (program_exercise_id) REFERENCES program_exercises(program_exercise_id) ON DELETE SET NULL
FOREIGN KEY (exercise_id) REFERENCES exercises(exercise_id)
CHECK (set_number > 0)
CHECK ( actual_weight IS NULL OR actual_weight >= 0 )
CHECK (actual_reps >= 0)
CHECK ( rpe IS NULL OR rpe BETWEEN 1 AND 10 )
CHECK ( rir IS NULL OR rir >= 0 )
CHECK ( actual_rest_seconds IS NULL OR actual_rest_seconds >= 0 )
```

## Observed values versus allowed values

- `muscle_group` seed values: `Arms`, `Back`, `Biceps`, `Chest`, `Core`, `Full Body`, `Legs`, `Neck`, `Shoulders`, `Triceps`. These are observed seed values, not a DDL enum.
- `mechanics` seed values: `Compound`, `Isolation`, `Static`. These are observed seed values, not a DDL enum.
- `sfr_category` seed values: `High Fatigue`, `Low Fatigue`, `Moderate Fatigue`, `No Fatigue`, `Very High Fatigue`. These are observed seed values, not a DDL enum.
- `fitness_level = Beginner`, `primary_goal = Build muscle`, and `workout_location = Home` are demo values, not a complete allowed vocabulary.
- `preference_type` is actually restricted by CHECK to `favorite` or `excluded`.
- `programs.status` defaults to `ACTIVE`; no allowed-status list is supplied.
- Rep bounds `1,1` appear for static holds, carries, stretches, and conditioning. They do not define duration or distance units. No duration/distance column exists in this schema; ask before designing that behavior.

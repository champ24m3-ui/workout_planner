-- =========================================================
-- SMART WORKOUT PLANNER DATABASE - V1
-- CLEAN VERSION
-- =========================================================

DROP DATABASE IF EXISTS smart_workout_planner;

CREATE DATABASE smart_workout_planner;

USE smart_workout_planner;


-- =========================================================
-- 1. USERS
-- =========================================================

CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);


-- =========================================================
-- 2. USER PROFILES
-- =========================================================

CREATE TABLE user_profiles (
    profile_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,

    gender VARCHAR(20),
    birth_date DATE,
    height_cm DECIMAL(5,2),

    fitness_level VARCHAR(50),
    primary_goal VARCHAR(50),
    workout_location VARCHAR(50),

    days_per_week INT,
    minutes_per_session INT,

    stretch_recommendation BOOLEAN DEFAULT FALSE,

    FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE,

    CHECK (
        height_cm IS NULL
        OR height_cm > 0
    ),

    CHECK (
        days_per_week IS NULL
        OR days_per_week BETWEEN 1 AND 7
    ),

    CHECK (
        minutes_per_session IS NULL
        OR minutes_per_session > 0
    )
);


-- =========================================================
-- 3. BODY MEASUREMENTS
-- =========================================================

CREATE TABLE body_measurements (
    measurement_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,

    measured_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    weight_kg DECIMAL(5,2) NOT NULL,

    FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE,

    CHECK (weight_kg > 0)
);


-- =========================================================
-- 4. EQUIPMENT
-- =========================================================

CREATE TABLE equipment (
    equipment_id INT AUTO_INCREMENT PRIMARY KEY,
    equipment_name VARCHAR(100) NOT NULL UNIQUE,
    category VARCHAR(50)
);


-- =========================================================
-- 5. USER EQUIPMENT
-- =========================================================

CREATE TABLE user_equipment (
    user_equipment_id INT AUTO_INCREMENT PRIMARY KEY,

    user_id INT NOT NULL,
    equipment_id INT NOT NULL,

    FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE,

    FOREIGN KEY (equipment_id)
        REFERENCES equipment(equipment_id)
        ON DELETE CASCADE,

    UNIQUE (user_id, equipment_id)
);


-- =========================================================
-- 6. EXERCISES
-- =========================================================

CREATE TABLE exercises (
    exercise_id INT AUTO_INCREMENT PRIMARY KEY,

    exercise_name VARCHAR(100) NOT NULL,

    muscle_group VARCHAR(50),

    mechanics VARCHAR(50),

    sfr_category VARCHAR(50),

    optimal_rep_min INT,
    optimal_rep_max INT,

    is_stretch BOOLEAN DEFAULT FALSE,

    equipment_id INT NOT NULL,

    -- NULL = System Default
    -- มีค่า = User สร้างเอง
    created_by_user_id INT NULL,

    FOREIGN KEY (equipment_id)
        REFERENCES equipment(equipment_id),

    FOREIGN KEY (created_by_user_id)
        REFERENCES users(user_id)
        ON DELETE SET NULL,

    CHECK (
        optimal_rep_min IS NULL
        OR optimal_rep_min > 0
    ),

    CHECK (
        optimal_rep_max IS NULL
        OR optimal_rep_max > 0
    ),

    CHECK (
        optimal_rep_min IS NULL
        OR optimal_rep_max IS NULL
        OR optimal_rep_min <= optimal_rep_max
    )
);


-- =========================================================
-- 7. USER EXERCISE PREFERENCES
-- =========================================================

CREATE TABLE user_exercise_preferences (
    preference_id INT AUTO_INCREMENT PRIMARY KEY,

    user_id INT NOT NULL,
    exercise_id INT NOT NULL,

    preference_type VARCHAR(20) NOT NULL,

    FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE,

    FOREIGN KEY (exercise_id)
        REFERENCES exercises(exercise_id)
        ON DELETE CASCADE,

    UNIQUE (user_id, exercise_id),

    CHECK (
        preference_type IN ('favorite', 'excluded')
    )
);


-- =========================================================
-- 8. PROGRAMS
-- =========================================================

CREATE TABLE programs (
    program_id INT AUTO_INCREMENT PRIMARY KEY,

    user_id INT NOT NULL,

    program_name VARCHAR(100) NOT NULL,

    focus_area VARCHAR(50),

    program_type VARCHAR(50),

    start_date DATE,
    end_date DATE,

    status VARCHAR(20) DEFAULT 'ACTIVE',

    FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE,

    CHECK (
        end_date IS NULL
        OR start_date IS NULL
        OR end_date >= start_date
    )
);


-- =========================================================
-- 9. PROGRAM EXERCISES
-- =========================================================

CREATE TABLE program_exercises (
    program_exercise_id INT AUTO_INCREMENT PRIMARY KEY,

    program_id INT NOT NULL,
    exercise_id INT NOT NULL,

    day_order INT NOT NULL,
    exercise_order INT NOT NULL,

    target_sets INT NOT NULL,

    rep_min INT NOT NULL,
    rep_max INT NOT NULL,

    -- ครั้งแรกยังไม่มี baseline น้ำหนัก
    target_weight DECIMAL(5,2) NULL,

    target_rpe DECIMAL(3,1),

    target_rest_seconds INT,

    FOREIGN KEY (program_id)
        REFERENCES programs(program_id)
        ON DELETE CASCADE,

    FOREIGN KEY (exercise_id)
        REFERENCES exercises(exercise_id),

    CHECK (day_order > 0),

    CHECK (exercise_order > 0),

    CHECK (target_sets > 0),

    CHECK (rep_min > 0),

    CHECK (rep_max >= rep_min),

    CHECK (
        target_weight IS NULL
        OR target_weight >= 0
    ),

    CHECK (
        target_rpe IS NULL
        OR target_rpe BETWEEN 1 AND 10
    ),

    CHECK (
        target_rest_seconds IS NULL
        OR target_rest_seconds >= 0
    ),

    UNIQUE (
        program_id,
        day_order,
        exercise_order
    )
);


-- =========================================================
-- 10. WORKOUT SESSIONS
-- =========================================================

CREATE TABLE workout_sessions (
    session_id INT AUTO_INCREMENT PRIMARY KEY,

    user_id INT NOT NULL,

    program_id INT NULL,

    session_date DATE NOT NULL,

    start_time DATETIME,
    end_time DATETIME,

    FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE,

    FOREIGN KEY (program_id)
        REFERENCES programs(program_id)
        ON DELETE SET NULL,

    CHECK (
        end_time IS NULL
        OR start_time IS NULL
        OR end_time >= start_time
    )
);


-- =========================================================
-- 11. SET LOGS
-- =========================================================

CREATE TABLE set_logs (
    set_log_id INT AUTO_INCREMENT PRIMARY KEY,

    session_id INT NOT NULL,

    -- NULL = ท่านอก Program
    program_exercise_id INT NULL,

    exercise_id INT NOT NULL,

    set_number INT NOT NULL,

    -- NULL ได้ เช่น Push-up / Pull-up
    actual_weight DECIMAL(5,2) NULL,

    actual_reps INT NOT NULL,

    rpe DECIMAL(3,1),

    rir INT,

    actual_rest_seconds INT,

    completed BOOLEAN DEFAULT TRUE,

    FOREIGN KEY (session_id)
        REFERENCES workout_sessions(session_id)
        ON DELETE CASCADE,

    FOREIGN KEY (program_exercise_id)
        REFERENCES program_exercises(program_exercise_id)
        ON DELETE SET NULL,

    FOREIGN KEY (exercise_id)
        REFERENCES exercises(exercise_id),

    CHECK (set_number > 0),

    CHECK (
        actual_weight IS NULL
        OR actual_weight >= 0
    ),

    CHECK (actual_reps >= 0),

    CHECK (
        rpe IS NULL
        OR rpe BETWEEN 1 AND 10
    ),

    CHECK (
        rir IS NULL
        OR rir >= 0
    ),

    CHECK (
        actual_rest_seconds IS NULL
        OR actual_rest_seconds >= 0
    )
);


-- =========================================================
-- TASK 1.2 / 1.3
-- EQUIPMENT MASTER DATA
-- =========================================================

INSERT INTO equipment (equipment_name, category) VALUES
('Bodyweight', 'None'),
('Dumbbell', 'Free Weight'),
('Barbell', 'Free Weight'),
('Cable Machine', 'Machine'),
('Smith Machine', 'Machine'),
('Kettlebell', 'Free Weight'),
('Resistance Band', 'Free Weight'),
('Pull-up Bar', 'Calisthenics'),
('Yoga Mat', 'Accessory'),
('Machine', 'Machine'),
('Trap Bar', 'Free Weight'),
('Battle Rope', 'Conditioning'),
('Sled', 'Conditioning'),
('Medicine Ball', 'Accessory'),
('Foam Roller', 'Accessory'),
('TRX', 'Suspension Trainer'),
('EZ Bar', 'Free Weight'),
('Weight Plate', 'Free Weight'),
('Ab Wheel', 'Accessory'),
('Landmine', 'Free Weight'),
('Tire', 'Conditioning'),
('Plyo Box', 'Accessory');


-- =========================================================
-- เก็บ Equipment ID ไว้ในตัวแปร
-- =========================================================

SET @bodyweight_id =
(
    SELECT equipment_id
    FROM equipment
    WHERE equipment_name = 'Bodyweight'
);

SET @dumbbell_id =
(
    SELECT equipment_id
    FROM equipment
    WHERE equipment_name = 'Dumbbell'
);

SET @barbell_id =
(
    SELECT equipment_id
    FROM equipment
    WHERE equipment_name = 'Barbell'
);

SET @cable_machine_id =
(
    SELECT equipment_id
    FROM equipment
    WHERE equipment_name = 'Cable Machine'
);

SET @smith_machine_id =
(
    SELECT equipment_id
    FROM equipment
    WHERE equipment_name = 'Smith Machine'
);

SET @kettlebell_id =
(
    SELECT equipment_id
    FROM equipment
    WHERE equipment_name = 'Kettlebell'
);

SET @resistance_band_id =
(
    SELECT equipment_id
    FROM equipment
    WHERE equipment_name = 'Resistance Band'
);

SET @pullup_bar_id =
(
    SELECT equipment_id
    FROM equipment
    WHERE equipment_name = 'Pull-up Bar'
);

SET @yoga_mat_id =
(
    SELECT equipment_id
    FROM equipment
    WHERE equipment_name = 'Yoga Mat'
);

SET @machine_id =
(
    SELECT equipment_id
    FROM equipment
    WHERE equipment_name = 'Machine'
);

SET @trap_bar_id =
(
    SELECT equipment_id
    FROM equipment
    WHERE equipment_name = 'Trap Bar'
);

SET @battle_rope_id =
(
    SELECT equipment_id
    FROM equipment
    WHERE equipment_name = 'Battle Rope'
);

SET @sled_id =
(
    SELECT equipment_id
    FROM equipment
    WHERE equipment_name = 'Sled'
);

SET @medicine_ball_id =
(
    SELECT equipment_id
    FROM equipment
    WHERE equipment_name = 'Medicine Ball'
);

SET @foam_roller_id =
(
    SELECT equipment_id
    FROM equipment
    WHERE equipment_name = 'Foam Roller'
);

SET @trx_id =
(
    SELECT equipment_id
    FROM equipment
    WHERE equipment_name = 'TRX'
);

SET @ez_bar_id =
(
    SELECT equipment_id
    FROM equipment
    WHERE equipment_name = 'EZ Bar'
);

SET @weight_plate_id =
(
    SELECT equipment_id
    FROM equipment
    WHERE equipment_name = 'Weight Plate'
);

SET @ab_wheel_id =
(
    SELECT equipment_id
    FROM equipment
    WHERE equipment_name = 'Ab Wheel'
);

SET @landmine_id =
(
    SELECT equipment_id
    FROM equipment
    WHERE equipment_name = 'Landmine'
);

SET @tire_id =
(
    SELECT equipment_id
    FROM equipment
    WHERE equipment_name = 'Tire'
);

SET @plyo_box_id =
(
    SELECT equipment_id
    FROM equipment
    WHERE equipment_name = 'Plyo Box'
);


-- =========================================================
-- TASK 1.3
-- EXERCISE SEED DATA
-- =========================================================

INSERT INTO exercises (
    exercise_name,
    muscle_group,
    mechanics,
    sfr_category,
    optimal_rep_min,
    optimal_rep_max,
    is_stretch,
    equipment_id,
    created_by_user_id
) VALUES

-- =========================
-- CHEST
-- =========================

('Barbell Bench Press', 'Chest', 'Compound', 'High Fatigue', 5, 10, 0, @barbell_id, NULL),
('Dumbbell Bench Press', 'Chest', 'Compound', 'Moderate Fatigue', 8, 12, 0, @dumbbell_id, NULL),
('Barbell Incline Bench Press', 'Chest', 'Compound', 'High Fatigue', 6, 10, 0, @barbell_id, NULL),
('Dumbbell Incline Bench Press', 'Chest', 'Compound', 'Moderate Fatigue', 8, 12, 0, @dumbbell_id, NULL),
('Barbell Decline Bench Press', 'Chest', 'Compound', 'High Fatigue', 6, 10, 0, @barbell_id, NULL),
('Dumbbell Decline Bench Press', 'Chest', 'Compound', 'Moderate Fatigue', 8, 12, 0, @dumbbell_id, NULL),
('Push-up', 'Chest', 'Compound', 'Low Fatigue', 10, 25, 0, @bodyweight_id, NULL),
('Decline Push-up', 'Chest', 'Compound', 'Low Fatigue', 10, 20, 0, @bodyweight_id, NULL),
('Incline Push-up', 'Chest', 'Compound', 'Low Fatigue', 10, 30, 0, @bodyweight_id, NULL),
('Weighted Push-up', 'Chest', 'Compound', 'Moderate Fatigue', 8, 15, 0, @bodyweight_id, NULL),
('Dumbbell Flyes', 'Chest', 'Isolation', 'Low Fatigue', 10, 15, 0, @dumbbell_id, NULL),
('Incline Dumbbell Flyes', 'Chest', 'Isolation', 'Low Fatigue', 10, 15, 0, @dumbbell_id, NULL),
('Decline Dumbbell Flyes', 'Chest', 'Isolation', 'Low Fatigue', 10, 15, 0, @dumbbell_id, NULL),
('Cable Crossover (High to Low)', 'Chest', 'Isolation', 'Low Fatigue', 12, 20, 0, @cable_machine_id, NULL),
('Cable Crossover (Low to High)', 'Chest', 'Isolation', 'Low Fatigue', 12, 20, 0, @cable_machine_id, NULL),
('Cable Crossover (Mid-Chest)', 'Chest', 'Isolation', 'Low Fatigue', 12, 20, 0, @cable_machine_id, NULL),
('Machine Chest Press', 'Chest', 'Compound', 'Moderate Fatigue', 8, 12, 0, @machine_id, NULL),
('Incline Machine Chest Press', 'Chest', 'Compound', 'Moderate Fatigue', 8, 12, 0, @machine_id, NULL),
('Decline Machine Chest Press', 'Chest', 'Compound', 'Moderate Fatigue', 8, 12, 0, @machine_id, NULL),
('Pec Deck Machine', 'Chest', 'Isolation', 'Low Fatigue', 12, 15, 0, @machine_id, NULL),
('Smith Machine Bench Press', 'Chest', 'Compound', 'Moderate Fatigue', 6, 10, 0, @smith_machine_id, NULL),
('Smith Machine Incline Press', 'Chest', 'Compound', 'Moderate Fatigue', 8, 12, 0, @smith_machine_id, NULL),
('Smith Machine Decline Press', 'Chest', 'Compound', 'Moderate Fatigue', 8, 12, 0, @smith_machine_id, NULL),
('Floor Press (Barbell)', 'Chest', 'Compound', 'High Fatigue', 5, 10, 0, @barbell_id, NULL),
('Floor Press (Dumbbell)', 'Chest', 'Compound', 'Moderate Fatigue', 8, 12, 0, @dumbbell_id, NULL),
('Svend Press', 'Chest', 'Isolation', 'Low Fatigue', 15, 20, 0, @dumbbell_id, NULL),
('Dumbbell Pullover', 'Chest', 'Compound', 'Moderate Fatigue', 10, 15, 0, @dumbbell_id, NULL),
('Guillotine Press', 'Chest', 'Compound', 'High Fatigue', 8, 12, 0, @barbell_id, NULL),
('Hex Press (Dumbbell)', 'Chest', 'Compound', 'Moderate Fatigue', 10, 15, 0, @dumbbell_id, NULL),


-- =========================
-- BACK
-- =========================

('Barbell Deadlift', 'Back', 'Compound', 'Very High Fatigue', 3, 6, 0, @barbell_id, NULL),
('Sumo Deadlift', 'Back', 'Compound', 'Very High Fatigue', 3, 6, 0, @barbell_id, NULL),
('Romanian Deadlift (RDL)', 'Back', 'Compound', 'High Fatigue', 6, 10, 0, @barbell_id, NULL),
('Stiff-Legged Deadlift', 'Back', 'Compound', 'High Fatigue', 6, 10, 0, @barbell_id, NULL),
('Trap Bar Deadlift', 'Back', 'Compound', 'Very High Fatigue', 5, 8, 0, @trap_bar_id, NULL),
('Pull-up', 'Back', 'Compound', 'Moderate Fatigue', 5, 15, 0, @pullup_bar_id, NULL),
('Weighted Pull-up', 'Back', 'Compound', 'High Fatigue', 5, 8, 0, @pullup_bar_id, NULL),
('Chin-up', 'Back', 'Compound', 'Moderate Fatigue', 5, 15, 0, @pullup_bar_id, NULL),
('Weighted Chin-up', 'Back', 'Compound', 'High Fatigue', 5, 8, 0, @pullup_bar_id, NULL),
('Wide-Grip Pull-up', 'Back', 'Compound', 'Moderate Fatigue', 5, 12, 0, @pullup_bar_id, NULL),
('Barbell Bent-Over Row', 'Back', 'Compound', 'High Fatigue', 6, 10, 0, @barbell_id, NULL),
('Pendlay Row', 'Back', 'Compound', 'High Fatigue', 5, 8, 0, @barbell_id, NULL),
('Yates Row', 'Back', 'Compound', 'High Fatigue', 8, 12, 0, @barbell_id, NULL),
('Dumbbell Single-Arm Row', 'Back', 'Compound', 'Moderate Fatigue', 8, 12, 0, @dumbbell_id, NULL),
('Dumbbell Bent-Over Row (Two Arms)', 'Back', 'Compound', 'Moderate Fatigue', 8, 12, 0, @dumbbell_id, NULL),
('Renegade Row', 'Back', 'Compound', 'Moderate Fatigue', 10, 15, 0, @dumbbell_id, NULL),
('Chest-Supported Dumbbell Row', 'Back', 'Compound', 'Moderate Fatigue', 8, 12, 0, @dumbbell_id, NULL),
('Meadows Row', 'Back', 'Compound', 'Moderate Fatigue', 8, 12, 0, @barbell_id, NULL),
('T-Bar Row', 'Back', 'Compound', 'High Fatigue', 8, 12, 0, @machine_id, NULL),
('Lat Pulldown (Wide Grip)', 'Back', 'Compound', 'Moderate Fatigue', 8, 12, 0, @cable_machine_id, NULL),
('Lat Pulldown (Close Grip)', 'Back', 'Compound', 'Moderate Fatigue', 8, 12, 0, @cable_machine_id, NULL),
('Lat Pulldown (Reverse Grip)', 'Back', 'Compound', 'Moderate Fatigue', 8, 12, 0, @cable_machine_id, NULL),
('Lat Pulldown (V-Bar)', 'Back', 'Compound', 'Moderate Fatigue', 8, 12, 0, @cable_machine_id, NULL),
('Seated Cable Row (V-Bar)', 'Back', 'Compound', 'Moderate Fatigue', 10, 15, 0, @cable_machine_id, NULL),
('Seated Cable Row (Wide Grip)', 'Back', 'Compound', 'Moderate Fatigue', 10, 15, 0, @cable_machine_id, NULL),
('Machine Row (Seated)', 'Back', 'Compound', 'Moderate Fatigue', 8, 12, 0, @machine_id, NULL),
('Machine Row (High)', 'Back', 'Compound', 'Moderate Fatigue', 8, 12, 0, @machine_id, NULL),
('Straight-Arm Pulldown', 'Back', 'Isolation', 'Low Fatigue', 12, 15, 0, @cable_machine_id, NULL),
('Cable Face Pull (High to Low)', 'Back', 'Isolation', 'Low Fatigue', 12, 15, 0, @cable_machine_id, NULL),
('Cable Shrug', 'Back', 'Isolation', 'Low Fatigue', 10, 15, 0, @cable_machine_id, NULL),
('Barbell Shrug', 'Back', 'Isolation', 'Moderate Fatigue', 8, 15, 0, @barbell_id, NULL),
('Dumbbell Shrug', 'Back', 'Isolation', 'Moderate Fatigue', 10, 15, 0, @dumbbell_id, NULL),
('Smith Machine Shrug', 'Back', 'Isolation', 'Moderate Fatigue', 10, 15, 0, @smith_machine_id, NULL),
('Hex Bar Shrug', 'Back', 'Isolation', 'Moderate Fatigue', 8, 15, 0, @trap_bar_id, NULL),
('Good Morning (Barbell)', 'Back', 'Compound', 'High Fatigue', 8, 12, 0, @barbell_id, NULL),
('Good Morning (Seated)', 'Back', 'Compound', 'Moderate Fatigue', 10, 15, 0, @barbell_id, NULL),
('Back Extension (Hyperextension)', 'Back', 'Isolation', 'Low Fatigue', 10, 15, 0, @bodyweight_id, NULL),
('Weighted Back Extension', 'Back', 'Isolation', 'Moderate Fatigue', 8, 12, 0, @bodyweight_id, NULL),
('Reverse Hyper', 'Back', 'Isolation', 'Moderate Fatigue', 10, 15, 0, @machine_id, NULL),
('Rack Pull', 'Back', 'Compound', 'High Fatigue', 4, 8, 0, @barbell_id, NULL),
('Inverted Row (Bodyweight)', 'Back', 'Compound', 'Low Fatigue', 10, 20, 0, @bodyweight_id, NULL),
('Weighted Inverted Row', 'Back', 'Compound', 'Moderate Fatigue', 8, 15, 0, @bodyweight_id, NULL),
('Superman', 'Back', 'Isolation', 'Low Fatigue', 15, 20, 0, @bodyweight_id, NULL),
('Seal Row (Barbell)', 'Back', 'Compound', 'Moderate Fatigue', 8, 12, 0, @barbell_id, NULL),
('Seal Row (Dumbbell)', 'Back', 'Compound', 'Moderate Fatigue', 10, 15, 0, @dumbbell_id, NULL),


-- =========================
-- LEGS
-- =========================

('Barbell Squat', 'Legs', 'Compound', 'Very High Fatigue', 5, 8, 0, @barbell_id, NULL),
('Front Squat', 'Legs', 'Compound', 'High Fatigue', 5, 8, 0, @barbell_id, NULL),
('Box Squat', 'Legs', 'Compound', 'High Fatigue', 4, 8, 0, @barbell_id, NULL),
('Zercher Squat', 'Legs', 'Compound', 'High Fatigue', 5, 8, 0, @barbell_id, NULL),
('Overhead Squat', 'Legs', 'Compound', 'High Fatigue', 5, 8, 0, @barbell_id, NULL),
('Hack Squat (Machine)', 'Legs', 'Compound', 'High Fatigue', 8, 12, 0, @machine_id, NULL),
('Leg Press', 'Legs', 'Compound', 'High Fatigue', 8, 15, 0, @machine_id, NULL),
('Single-Leg Press', 'Legs', 'Compound', 'Moderate Fatigue', 8, 12, 0, @machine_id, NULL),
('Pendulum Squat', 'Legs', 'Compound', 'High Fatigue', 8, 12, 0, @machine_id, NULL),
('Smith Machine Squat', 'Legs', 'Compound', 'Moderate Fatigue', 6, 10, 0, @smith_machine_id, NULL),
('Dumbbell Lunge', 'Legs', 'Compound', 'Moderate Fatigue', 10, 20, 0, @dumbbell_id, NULL),
('Barbell Lunge', 'Legs', 'Compound', 'High Fatigue', 8, 15, 0, @barbell_id, NULL),
('Walking Lunge (Dumbbell)', 'Legs', 'Compound', 'Moderate Fatigue', 10, 20, 0, @dumbbell_id, NULL),
('Reverse Lunge (Barbell)', 'Legs', 'Compound', 'High Fatigue', 8, 12, 0, @barbell_id, NULL),
('Reverse Lunge (Dumbbell)', 'Legs', 'Compound', 'Moderate Fatigue', 8, 15, 0, @dumbbell_id, NULL),
('Bulgarian Split Squat (Dumbbell)', 'Legs', 'Compound', 'High Fatigue', 8, 12, 0, @dumbbell_id, NULL),
('Bulgarian Split Squat (Barbell)', 'Legs', 'Compound', 'Very High Fatigue', 6, 10, 0, @barbell_id, NULL),
('Bulgarian Split Squat (Smith Machine)', 'Legs', 'Compound', 'High Fatigue', 8, 12, 0, @smith_machine_id, NULL),
('Kettlebell Goblet Squat', 'Legs', 'Compound', 'Moderate Fatigue', 8, 15, 0, @kettlebell_id, NULL),
('Dumbbell Goblet Squat', 'Legs', 'Compound', 'Moderate Fatigue', 8, 15, 0, @dumbbell_id, NULL),
('Step-Up (Dumbbell)', 'Legs', 'Compound', 'Moderate Fatigue', 8, 15, 0, @dumbbell_id, NULL),
('Step-Up (Barbell)', 'Legs', 'Compound', 'High Fatigue', 8, 12, 0, @barbell_id, NULL),
('Leg Extension', 'Legs', 'Isolation', 'Low Fatigue', 10, 15, 0, @machine_id, NULL),
('Single-Leg Extension', 'Legs', 'Isolation', 'Low Fatigue', 10, 15, 0, @machine_id, NULL),
('Seated Leg Curl', 'Legs', 'Isolation', 'Low Fatigue', 10, 15, 0, @machine_id, NULL),
('Lying Leg Curl', 'Legs', 'Isolation', 'Low Fatigue', 10, 15, 0, @machine_id, NULL),
('Standing Single-Leg Curl', 'Legs', 'Isolation', 'Low Fatigue', 10, 15, 0, @machine_id, NULL),
('Nordic Hamstring Curl', 'Legs', 'Isolation', 'Moderate Fatigue', 5, 10, 0, @bodyweight_id, NULL),
('Glute-Ham Raise (GHR)', 'Legs', 'Compound', 'Moderate Fatigue', 8, 15, 0, @machine_id, NULL),
('Barbell Hip Thrust', 'Legs', 'Compound', 'High Fatigue', 8, 12, 0, @barbell_id, NULL),
('Dumbbell Hip Thrust', 'Legs', 'Compound', 'Moderate Fatigue', 10, 15, 0, @dumbbell_id, NULL),
('Machine Hip Thrust', 'Legs', 'Compound', 'Moderate Fatigue', 8, 12, 0, @machine_id, NULL),
('Single-Leg Hip Thrust (Bodyweight)', 'Legs', 'Compound', 'Low Fatigue', 10, 20, 0, @bodyweight_id, NULL),
('Single-Leg Hip Thrust (Dumbbell)', 'Legs', 'Compound', 'Moderate Fatigue', 10, 15, 0, @dumbbell_id, NULL),
('Glute Bridge', 'Legs', 'Isolation', 'Low Fatigue', 15, 20, 0, @bodyweight_id, NULL),
('Weighted Glute Bridge', 'Legs', 'Isolation', 'Moderate Fatigue', 10, 15, 0, @barbell_id, NULL),
('Cable Pull-Through', 'Legs', 'Compound', 'Low Fatigue', 12, 15, 0, @cable_machine_id, NULL),
('Kettlebell Swing', 'Legs', 'Compound', 'Moderate Fatigue', 15, 20, 0, @kettlebell_id, NULL),
('Standing Calf Raise (Machine)', 'Legs', 'Isolation', 'Low Fatigue', 15, 20, 0, @machine_id, NULL),
('Standing Calf Raise (Dumbbell)', 'Legs', 'Isolation', 'Low Fatigue', 15, 20, 0, @dumbbell_id, NULL),
('Standing Calf Raise (Bodyweight)', 'Legs', 'Isolation', 'No Fatigue', 20, 30, 0, @bodyweight_id, NULL),
('Seated Calf Raise (Machine)', 'Legs', 'Isolation', 'Low Fatigue', 12, 20, 0, @machine_id, NULL),
('Donkey Calf Raise', 'Legs', 'Isolation', 'Low Fatigue', 15, 20, 0, @machine_id, NULL),
('Leg Press Calf Raise', 'Legs', 'Isolation', 'Low Fatigue', 15, 20, 0, @machine_id, NULL),
('Tibialis Raise (Bodyweight)', 'Legs', 'Isolation', 'No Fatigue', 15, 25, 0, @bodyweight_id, NULL),
('Sissy Squat', 'Legs', 'Compound', 'Moderate Fatigue', 10, 15, 0, @bodyweight_id, NULL),
('Machine Hip Abductor', 'Legs', 'Isolation', 'Low Fatigue', 12, 20, 0, @machine_id, NULL),
('Machine Hip Adductor', 'Legs', 'Isolation', 'Low Fatigue', 12, 20, 0, @machine_id, NULL),
('Cable Hip Abduction', 'Legs', 'Isolation', 'Low Fatigue', 12, 15, 0, @cable_machine_id, NULL),
('Cable Hip Adduction', 'Legs', 'Isolation', 'Low Fatigue', 12, 15, 0, @cable_machine_id, NULL),
('Banded Lateral Walk', 'Legs', 'Isolation', 'Low Fatigue', 15, 20, 0, @resistance_band_id, NULL),
('Clamshell (Bodyweight)', 'Legs', 'Isolation', 'No Fatigue', 15, 25, 0, @bodyweight_id, NULL),
('Clamshell (Banded)', 'Legs', 'Isolation', 'Low Fatigue', 15, 20, 0, @resistance_band_id, NULL),
('Pistol Squat', 'Legs', 'Compound', 'High Fatigue', 5, 10, 0, @bodyweight_id, NULL),
('Assisted Pistol Squat', 'Legs', 'Compound', 'Moderate Fatigue', 8, 12, 0, @bodyweight_id, NULL),
('Skater Squat', 'Legs', 'Compound', 'Moderate Fatigue', 8, 12, 0, @bodyweight_id, NULL),
('Jefferson Curl', 'Legs', 'Isolation', 'Low Fatigue', 10, 15, 0, @barbell_id, NULL),
('Good Morning (Smith Machine)', 'Legs', 'Compound', 'Moderate Fatigue', 10, 15, 0, @smith_machine_id, NULL),
('Landmine Squat', 'Legs', 'Compound', 'Moderate Fatigue', 8, 12, 0, @landmine_id, NULL),
('Landmine Reverse Lunge', 'Legs', 'Compound', 'Moderate Fatigue', 8, 12, 0, @landmine_id, NULL),
('Copenhagen Plank', 'Legs', 'Static', 'Low Fatigue', 1, 1, 0, @bodyweight_id, NULL),
('Sumo Squat (Dumbbell)', 'Legs', 'Compound', 'Moderate Fatigue', 10, 15, 0, @dumbbell_id, NULL),
('Sumo Squat (Barbell)', 'Legs', 'Compound', 'High Fatigue', 6, 10, 0, @barbell_id, NULL),
('Cable Kickback', 'Legs', 'Isolation', 'Low Fatigue', 12, 20, 0, @cable_machine_id, NULL),


-- =========================
-- SHOULDERS
-- =========================

('Overhead Press (Barbell)', 'Shoulders', 'Compound', 'High Fatigue', 6, 10, 0, @barbell_id, NULL),
('Dumbbell Shoulder Press', 'Shoulders', 'Compound', 'Moderate Fatigue', 8, 12, 0, @dumbbell_id, NULL),
('Machine Shoulder Press', 'Shoulders', 'Compound', 'Moderate Fatigue', 8, 12, 0, @machine_id, NULL),
('Smith Machine Shoulder Press', 'Shoulders', 'Compound', 'Moderate Fatigue', 8, 12, 0, @smith_machine_id, NULL),
('Arnold Press', 'Shoulders', 'Compound', 'Moderate Fatigue', 8, 12, 0, @dumbbell_id, NULL),
('Push Press', 'Shoulders', 'Compound', 'High Fatigue', 4, 8, 0, @barbell_id, NULL),
('Dumbbell Lateral Raise', 'Shoulders', 'Isolation', 'Low Fatigue', 12, 20, 0, @dumbbell_id, NULL),
('Cable Lateral Raise', 'Shoulders', 'Isolation', 'Low Fatigue', 12, 20, 0, @cable_machine_id, NULL),
('Machine Lateral Raise', 'Shoulders', 'Isolation', 'Low Fatigue', 12, 20, 0, @machine_id, NULL),
('Leaning Cable Lateral Raise', 'Shoulders', 'Isolation', 'Low Fatigue', 10, 15, 0, @cable_machine_id, NULL),
('Egyptian Cable Lateral Raise', 'Shoulders', 'Isolation', 'Low Fatigue', 10, 15, 0, @cable_machine_id, NULL),
('Seated Dumbbell Lateral Raise', 'Shoulders', 'Isolation', 'Low Fatigue', 12, 20, 0, @dumbbell_id, NULL),
('Dumbbell Front Raise', 'Shoulders', 'Isolation', 'Low Fatigue', 10, 15, 0, @dumbbell_id, NULL),
('Cable Front Raise', 'Shoulders', 'Isolation', 'Low Fatigue', 10, 15, 0, @cable_machine_id, NULL),
('Barbell Front Raise', 'Shoulders', 'Isolation', 'Low Fatigue', 10, 15, 0, @barbell_id, NULL),
('Plate Front Raise', 'Shoulders', 'Isolation', 'Low Fatigue', 10, 20, 0, @weight_plate_id, NULL),
('Reverse Pec Deck', 'Shoulders', 'Isolation', 'Low Fatigue', 12, 20, 0, @machine_id, NULL),
('Face Pull', 'Shoulders', 'Isolation', 'Low Fatigue', 12, 15, 0, @cable_machine_id, NULL),
('Dumbbell Rear Delt Row', 'Shoulders', 'Compound', 'Moderate Fatigue', 10, 15, 0, @dumbbell_id, NULL),
('Bent-Over Dumbbell Rear Delt Raise', 'Shoulders', 'Isolation', 'Low Fatigue', 12, 20, 0, @dumbbell_id, NULL),
('Cable Rear Delt Fly', 'Shoulders', 'Isolation', 'Low Fatigue', 12, 20, 0, @cable_machine_id, NULL),
('Upright Row (Barbell)', 'Shoulders', 'Compound', 'Moderate Fatigue', 8, 12, 0, @barbell_id, NULL),
('Upright Row (Dumbbell)', 'Shoulders', 'Compound', 'Moderate Fatigue', 10, 15, 0, @dumbbell_id, NULL),
('Upright Row (Cable)', 'Shoulders', 'Compound', 'Moderate Fatigue', 10, 15, 0, @cable_machine_id, NULL),
('Landmine Press', 'Shoulders', 'Compound', 'Moderate Fatigue', 8, 12, 0, @landmine_id, NULL),


-- =========================
-- BICEPS
-- =========================

('Barbell Curl', 'Biceps', 'Isolation', 'Moderate Fatigue', 8, 12, 0, @barbell_id, NULL),
('EZ-Bar Curl', 'Biceps', 'Isolation', 'Moderate Fatigue', 8, 12, 0, @ez_bar_id, NULL),
('Dumbbell Alternate Curl', 'Biceps', 'Isolation', 'Low Fatigue', 10, 15, 0, @dumbbell_id, NULL),
('Dumbbell Hammer Curl', 'Biceps', 'Isolation', 'Low Fatigue', 10, 15, 0, @dumbbell_id, NULL),
('Cross-Body Hammer Curl', 'Biceps', 'Isolation', 'Low Fatigue', 10, 15, 0, @dumbbell_id, NULL),
('Cable Bicep Curl', 'Biceps', 'Isolation', 'Low Fatigue', 12, 20, 0, @cable_machine_id, NULL),
('Rope Cable Curl', 'Biceps', 'Isolation', 'Low Fatigue', 12, 20, 0, @cable_machine_id, NULL),
('Preacher Curl (Barbell)', 'Biceps', 'Isolation', 'Low Fatigue', 8, 12, 0, @barbell_id, NULL),
('Preacher Curl (Dumbbell)', 'Biceps', 'Isolation', 'Low Fatigue', 10, 15, 0, @dumbbell_id, NULL),
('Machine Preacher Curl', 'Biceps', 'Isolation', 'Low Fatigue', 10, 15, 0, @machine_id, NULL),
('Concentration Curl', 'Biceps', 'Isolation', 'Low Fatigue', 10, 15, 0, @dumbbell_id, NULL),
('Spider Curl', 'Biceps', 'Isolation', 'Low Fatigue', 10, 15, 0, @dumbbell_id, NULL),
('Incline Dumbbell Curl', 'Biceps', 'Isolation', 'Low Fatigue', 10, 15, 0, @dumbbell_id, NULL),
('Reverse Curl (Barbell)', 'Biceps', 'Isolation', 'Moderate Fatigue', 10, 15, 0, @barbell_id, NULL),
('Reverse Curl (Cable)', 'Biceps', 'Isolation', 'Low Fatigue', 12, 15, 0, @cable_machine_id, NULL),
('Zottman Curl', 'Biceps', 'Isolation', 'Low Fatigue', 10, 15, 0, @dumbbell_id, NULL),
('High Cable Curl', 'Biceps', 'Isolation', 'Low Fatigue', 12, 15, 0, @cable_machine_id, NULL),
('Bayesian Curl', 'Biceps', 'Isolation', 'Low Fatigue', 12, 20, 0, @cable_machine_id, NULL),


-- =========================
-- TRICEPS
-- =========================

('Close-Grip Bench Press', 'Triceps', 'Compound', 'High Fatigue', 6, 10, 0, @barbell_id, NULL),
('Triceps Rope Pushdown', 'Triceps', 'Isolation', 'Low Fatigue', 10, 15, 0, @cable_machine_id, NULL),
('Triceps V-Bar Pushdown', 'Triceps', 'Isolation', 'Low Fatigue', 10, 15, 0, @cable_machine_id, NULL),
('Triceps Straight Bar Pushdown', 'Triceps', 'Isolation', 'Low Fatigue', 10, 15, 0, @cable_machine_id, NULL),
('Reverse-Grip Triceps Pushdown', 'Triceps', 'Isolation', 'Low Fatigue', 12, 15, 0, @cable_machine_id, NULL),
('Overhead Triceps Extension (Dumbbell)', 'Triceps', 'Isolation', 'Low Fatigue', 10, 15, 0, @dumbbell_id, NULL),
('Overhead Triceps Extension (Cable)', 'Triceps', 'Isolation', 'Low Fatigue', 12, 15, 0, @cable_machine_id, NULL),
('Overhead Triceps Extension (EZ-Bar)', 'Triceps', 'Isolation', 'Moderate Fatigue', 8, 12, 0, @ez_bar_id, NULL),
('Skullcrushers (EZ-Bar)', 'Triceps', 'Isolation', 'Moderate Fatigue', 8, 12, 0, @ez_bar_id, NULL),
('Skullcrushers (Dumbbell)', 'Triceps', 'Isolation', 'Low Fatigue', 10, 15, 0, @dumbbell_id, NULL),
('Triceps Kickback (Dumbbell)', 'Triceps', 'Isolation', 'Low Fatigue', 12, 15, 0, @dumbbell_id, NULL),
('Triceps Kickback (Cable)', 'Triceps', 'Isolation', 'Low Fatigue', 12, 15, 0, @cable_machine_id, NULL),
('Dips (Bodyweight)', 'Triceps', 'Compound', 'Moderate Fatigue', 8, 15, 0, @bodyweight_id, NULL),
('Weighted Dips', 'Triceps', 'Compound', 'High Fatigue', 5, 10, 0, @bodyweight_id, NULL),
('Machine Dips', 'Triceps', 'Compound', 'Moderate Fatigue', 8, 15, 0, @machine_id, NULL),
('Bench Dips', 'Triceps', 'Compound', 'Low Fatigue', 10, 20, 0, @bodyweight_id, NULL),
('Tate Press', 'Triceps', 'Isolation', 'Low Fatigue', 10, 15, 0, @dumbbell_id, NULL),
('JM Press', 'Triceps', 'Compound', 'Moderate Fatigue', 8, 12, 0, @barbell_id, NULL),
('Katana Extension', 'Triceps', 'Isolation', 'Low Fatigue', 12, 20, 0, @cable_machine_id, NULL),
('Cross-Body Triceps Extension', 'Triceps', 'Isolation', 'Low Fatigue', 12, 20, 0, @cable_machine_id, NULL),


-- =========================
-- CORE
-- =========================

('Crunch', 'Core', 'Isolation', 'Low Fatigue', 15, 25, 0, @bodyweight_id, NULL),
('Weighted Crunch', 'Core', 'Isolation', 'Moderate Fatigue', 10, 15, 0, @barbell_id, NULL),
('Sit-up', 'Core', 'Compound', 'Low Fatigue', 15, 25, 0, @bodyweight_id, NULL),
('Decline Sit-up', 'Core', 'Compound', 'Moderate Fatigue', 10, 20, 0, @bodyweight_id, NULL),
('Plank', 'Core', 'Static', 'Low Fatigue', 1, 1, 0, @bodyweight_id, NULL),
('Weighted Plank', 'Core', 'Static', 'Moderate Fatigue', 1, 1, 0, @barbell_id, NULL),
('Side Plank', 'Core', 'Static', 'Low Fatigue', 1, 1, 0, @bodyweight_id, NULL),
('Hanging Leg Raise', 'Core', 'Compound', 'Moderate Fatigue', 10, 20, 0, @pullup_bar_id, NULL),
('Hanging Knee Raise', 'Core', 'Compound', 'Low Fatigue', 10, 20, 0, @pullup_bar_id, NULL),
('Captain''s Chair Leg Raise', 'Core', 'Compound', 'Low Fatigue', 10, 20, 0, @machine_id, NULL),
('Lying Leg Raise', 'Core', 'Isolation', 'Low Fatigue', 15, 20, 0, @bodyweight_id, NULL),
('Cable Crunch', 'Core', 'Isolation', 'Low Fatigue', 12, 20, 0, @cable_machine_id, NULL),
('Machine Crunch', 'Core', 'Isolation', 'Low Fatigue', 12, 20, 0, @machine_id, NULL),
('Ab Wheel Rollout', 'Core', 'Compound', 'Moderate Fatigue', 8, 15, 0, @ab_wheel_id, NULL),
('Russian Twist', 'Core', 'Isolation', 'Low Fatigue', 20, 30, 0, @bodyweight_id, NULL),
('Weighted Russian Twist', 'Core', 'Isolation', 'Moderate Fatigue', 15, 25, 0, @kettlebell_id, NULL),
('Bicycle Crunch', 'Core', 'Isolation', 'Low Fatigue', 20, 30, 0, @bodyweight_id, NULL),
('Flutter Kicks', 'Core', 'Isolation', 'Low Fatigue', 20, 30, 0, @bodyweight_id, NULL),
('V-up', 'Core', 'Compound', 'Moderate Fatigue', 10, 20, 0, @bodyweight_id, NULL),
('Toe Touches', 'Core', 'Isolation', 'Low Fatigue', 15, 20, 0, @bodyweight_id, NULL),
('Woodchopper (Cable)', 'Core', 'Compound', 'Low Fatigue', 12, 15, 0, @cable_machine_id, NULL),
('Woodchopper (Dumbbell)', 'Core', 'Compound', 'Low Fatigue', 12, 15, 0, @dumbbell_id, NULL),
('Pallof Press', 'Core', 'Static', 'Low Fatigue', 1, 1, 0, @cable_machine_id, NULL),
('Bird Dog', 'Core', 'Static', 'Low Fatigue', 10, 15, 0, @bodyweight_id, NULL),
('Dead Bug', 'Core', 'Isolation', 'Low Fatigue', 10, 15, 0, @bodyweight_id, NULL),
('Hollow Body Hold', 'Core', 'Static', 'Moderate Fatigue', 1, 1, 0, @bodyweight_id, NULL),
('Dragon Flag', 'Core', 'Compound', 'High Fatigue', 5, 10, 0, @bodyweight_id, NULL),
('Windshield Wipers', 'Core', 'Isolation', 'Moderate Fatigue', 10, 20, 0, @bodyweight_id, NULL),
('Farmer''s Walk', 'Core', 'Compound', 'High Fatigue', 1, 1, 0, @dumbbell_id, NULL),
('Suitcase Carry', 'Core', 'Compound', 'Moderate Fatigue', 1, 1, 0, @dumbbell_id, NULL),


-- =========================
-- FULL BODY / CONDITIONING
-- =========================

('Turkish Get-Up', 'Full Body', 'Compound', 'High Fatigue', 1, 5, 0, @kettlebell_id, NULL),
('Kettlebell Snatch', 'Full Body', 'Compound', 'High Fatigue', 5, 10, 0, @kettlebell_id, NULL),
('Kettlebell Clean and Press', 'Full Body', 'Compound', 'High Fatigue', 5, 10, 0, @kettlebell_id, NULL),
('Barbell Clean', 'Full Body', 'Compound', 'Very High Fatigue', 3, 5, 0, @barbell_id, NULL),
('Barbell Power Clean', 'Full Body', 'Compound', 'Very High Fatigue', 3, 5, 0, @barbell_id, NULL),
('Barbell Snatch', 'Full Body', 'Compound', 'Very High Fatigue', 1, 3, 0, @barbell_id, NULL),
('Muscle-Up', 'Full Body', 'Compound', 'High Fatigue', 3, 8, 0, @pullup_bar_id, NULL),
('Front Lever', 'Core', 'Static', 'High Fatigue', 1, 1, 0, @pullup_bar_id, NULL),
('Back Lever', 'Core', 'Static', 'High Fatigue', 1, 1, 0, @pullup_bar_id, NULL),
('Human Flag', 'Core', 'Static', 'High Fatigue', 1, 1, 0, @pullup_bar_id, NULL),
('L-Sit', 'Core', 'Static', 'Moderate Fatigue', 1, 1, 0, @bodyweight_id, NULL),
('Burpee', 'Full Body', 'Compound', 'High Fatigue', 10, 20, 0, @bodyweight_id, NULL),
('Mountain Climber', 'Core', 'Compound', 'Low Fatigue', 20, 40, 0, @bodyweight_id, NULL),
('Box Jump', 'Legs', 'Compound', 'Moderate Fatigue', 5, 10, 0, @plyo_box_id, NULL),
('Battle Ropes', 'Full Body', 'Compound', 'High Fatigue', 1, 1, 0, @battle_rope_id, NULL),
('Sled Push', 'Full Body', 'Compound', 'High Fatigue', 1, 1, 0, @sled_id, NULL),
('Sled Pull', 'Full Body', 'Compound', 'High Fatigue', 1, 1, 0, @sled_id, NULL),
('Tire Flip', 'Full Body', 'Compound', 'High Fatigue', 5, 10, 0, @tire_id, NULL),
('Wall Ball', 'Full Body', 'Compound', 'Moderate Fatigue', 10, 20, 0, @medicine_ball_id, NULL),
('Medicine Ball Slam', 'Full Body', 'Compound', 'Moderate Fatigue', 10, 20, 0, @medicine_ball_id, NULL),


-- =========================
-- STRETCH
-- =========================

('Chest Stretch', 'Chest', 'Static', 'No Fatigue', 1, 1, 1, @yoga_mat_id, NULL),
('Doorway Chest Stretch', 'Chest', 'Static', 'No Fatigue', 1, 1, 1, @yoga_mat_id, NULL),
('Upper Back Stretch', 'Back', 'Static', 'No Fatigue', 1, 1, 1, @yoga_mat_id, NULL),
('Child''s Pose', 'Back', 'Static', 'No Fatigue', 1, 1, 1, @yoga_mat_id, NULL),
('Cat-Cow', 'Back', 'Static', 'No Fatigue', 1, 1, 1, @yoga_mat_id, NULL),
('Lat Stretch', 'Back', 'Static', 'No Fatigue', 1, 1, 1, @yoga_mat_id, NULL),
('Hamstring Stretch', 'Legs', 'Static', 'No Fatigue', 1, 1, 1, @yoga_mat_id, NULL),
('Seated Forward Bend', 'Legs', 'Static', 'No Fatigue', 1, 1, 1, @yoga_mat_id, NULL),
('Standing Hamstring Stretch', 'Legs', 'Static', 'No Fatigue', 1, 1, 1, @yoga_mat_id, NULL),
('Quad Stretch', 'Legs', 'Static', 'No Fatigue', 1, 1, 1, @yoga_mat_id, NULL),
('Lying Quad Stretch', 'Legs', 'Static', 'No Fatigue', 1, 1, 1, @yoga_mat_id, NULL),
('Calf Stretch', 'Legs', 'Static', 'No Fatigue', 1, 1, 1, @yoga_mat_id, NULL),
('Downward Dog', 'Legs', 'Static', 'No Fatigue', 1, 1, 1, @yoga_mat_id, NULL),
('Glute Stretch', 'Legs', 'Static', 'No Fatigue', 1, 1, 1, @yoga_mat_id, NULL),
('Figure Four Stretch', 'Legs', 'Static', 'No Fatigue', 1, 1, 1, @yoga_mat_id, NULL),
('Pigeon Pose', 'Legs', 'Static', 'No Fatigue', 1, 1, 1, @yoga_mat_id, NULL),
('Butterfly Stretch', 'Legs', 'Static', 'No Fatigue', 1, 1, 1, @yoga_mat_id, NULL),
('Hip Flexor Stretch', 'Legs', 'Static', 'No Fatigue', 1, 1, 1, @yoga_mat_id, NULL),
('Kneeling Lunge Stretch', 'Legs', 'Static', 'No Fatigue', 1, 1, 1, @yoga_mat_id, NULL),
('Shoulder Stretch', 'Shoulders', 'Static', 'No Fatigue', 1, 1, 1, @yoga_mat_id, NULL),
('Cross-Body Shoulder Stretch', 'Shoulders', 'Static', 'No Fatigue', 1, 1, 1, @yoga_mat_id, NULL),
('Triceps Stretch', 'Triceps', 'Static', 'No Fatigue', 1, 1, 1, @yoga_mat_id, NULL),
('Overhead Triceps Stretch', 'Triceps', 'Static', 'No Fatigue', 1, 1, 1, @yoga_mat_id, NULL),
('Biceps Stretch', 'Biceps', 'Static', 'No Fatigue', 1, 1, 1, @yoga_mat_id, NULL),
('Wrist Flexor Stretch', 'Arms', 'Static', 'No Fatigue', 1, 1, 1, @yoga_mat_id, NULL),
('Wrist Extensor Stretch', 'Arms', 'Static', 'No Fatigue', 1, 1, 1, @yoga_mat_id, NULL),
('Neck Stretch (Side to Side)', 'Neck', 'Static', 'No Fatigue', 1, 1, 1, @yoga_mat_id, NULL),
('Neck Stretch (Up and Down)', 'Neck', 'Static', 'No Fatigue', 1, 1, 1, @yoga_mat_id, NULL),
('Cobra Pose', 'Core', 'Static', 'No Fatigue', 1, 1, 1, @yoga_mat_id, NULL),
('Sphinx Pose', 'Core', 'Static', 'No Fatigue', 1, 1, 1, @yoga_mat_id, NULL),
('Thoracic Extension', 'Back', 'Static', 'No Fatigue', 1, 1, 1, @yoga_mat_id, NULL),


-- =========================
-- FOAM ROLLER
-- =========================

('Foam Rolling (Quads)', 'Legs', 'Static', 'No Fatigue', 1, 1, 1, @foam_roller_id, NULL),
('Foam Rolling (Hamstrings)', 'Legs', 'Static', 'No Fatigue', 1, 1, 1, @foam_roller_id, NULL),
('Foam Rolling (Calves)', 'Legs', 'Static', 'No Fatigue', 1, 1, 1, @foam_roller_id, NULL),
('Foam Rolling (IT Band)', 'Legs', 'Static', 'No Fatigue', 1, 1, 1, @foam_roller_id, NULL),
('Foam Rolling (Upper Back)', 'Back', 'Static', 'No Fatigue', 1, 1, 1, @foam_roller_id, NULL),
('Foam Rolling (Lats)', 'Back', 'Static', 'No Fatigue', 1, 1, 1, @foam_roller_id, NULL),


-- =========================
-- RESISTANCE BAND
-- =========================

('Resistance Band Pull-Apart', 'Shoulders', 'Isolation', 'Low Fatigue', 15, 25, 0, @resistance_band_id, NULL),
('Banded Side Step', 'Legs', 'Isolation', 'Low Fatigue', 15, 20, 0, @resistance_band_id, NULL),
('Banded Glute Bridge', 'Legs', 'Isolation', 'Low Fatigue', 15, 20, 0, @resistance_band_id, NULL),
('Banded Squat', 'Legs', 'Compound', 'Moderate Fatigue', 10, 15, 0, @resistance_band_id, NULL),
('Banded Push-up', 'Chest', 'Compound', 'Moderate Fatigue', 10, 15, 0, @resistance_band_id, NULL),


-- =========================
-- TRX
-- =========================

('TRX Row', 'Back', 'Compound', 'Low Fatigue', 10, 15, 0, @trx_id, NULL),
('TRX Push-up', 'Chest', 'Compound', 'Low Fatigue', 10, 15, 0, @trx_id, NULL),
('TRX Squat', 'Legs', 'Compound', 'Low Fatigue', 10, 15, 0, @trx_id, NULL),
('TRX Lunge', 'Legs', 'Compound', 'Low Fatigue', 10, 15, 0, @trx_id, NULL),
('TRX Y-Fly', 'Shoulders', 'Isolation', 'Low Fatigue', 10, 15, 0, @trx_id, NULL),
('TRX Triceps Extension', 'Triceps', 'Isolation', 'Low Fatigue', 10, 15, 0, @trx_id, NULL),
('TRX Biceps Curl', 'Biceps', 'Isolation', 'Low Fatigue', 10, 15, 0, @trx_id, NULL),


-- =========================
-- FINAL
-- =========================

('Jumping Jacks', 'Full Body', 'Compound', 'Low Fatigue', 20, 50, 0, @bodyweight_id, NULL);


-- =========================================================
-- FINAL VALIDATION
-- =========================================================


-- 1. ต้องมี 11 Tables
SHOW TABLES;


-- 2. ตรวจ Equipment ทั้งหมด
SELECT *
FROM equipment
ORDER BY equipment_id;


-- 3. ตรวจจำนวน Exercise ทั้งหมด
SELECT COUNT(*) AS total_exercises
FROM exercises;


-- 4. ดูจำนวน Exercise ตาม Equipment
SELECT
    eq.equipment_name,
    COUNT(e.exercise_id) AS total_exercises
FROM equipment eq
LEFT JOIN exercises e
    ON e.equipment_id = eq.equipment_id
GROUP BY
    eq.equipment_id,
    eq.equipment_name
ORDER BY
    total_exercises DESC,
    eq.equipment_name;


-- 5. ตรวจ Exercise ที่หา Equipment ไม่เจอ
-- ต้องได้ 0 rows

SELECT
    e.exercise_id,
    e.exercise_name
FROM exercises e
LEFT JOIN equipment eq
    ON e.equipment_id = eq.equipment_id
WHERE eq.equipment_id IS NULL;


-- 6. ตรวจ Rep Range
-- ต้องได้ 0 rows

SELECT
    exercise_id,
    exercise_name,
    optimal_rep_min,
    optimal_rep_max
FROM exercises
WHERE optimal_rep_min <= 0
   OR optimal_rep_max <= 0
   OR optimal_rep_min > optimal_rep_max;


-- 7. ตรวจ Exercise Name ซ้ำ
-- ต้องได้ 0 rows

SELECT
    exercise_name,
    COUNT(*) AS duplicate_count
FROM exercises
GROUP BY exercise_name
HAVING COUNT(*) > 1;


-- 8. ตรวจ Mapping สำคัญ

SELECT
    e.exercise_name,
    eq.equipment_name
FROM exercises e
JOIN equipment eq
    ON e.equipment_id = eq.equipment_id
WHERE e.exercise_name IN (
    'Machine Chest Press',
    'Leg Press',
    'Trap Bar Deadlift',
    'Battle Ropes',
    'Sled Push',
    'Medicine Ball Slam',
    'Foam Rolling (Quads)',
    'TRX Row',
    'EZ-Bar Curl',
    'Plate Front Raise',
    'Ab Wheel Rollout',
    'Landmine Press',
    'Tire Flip',
    'Box Jump'
)
ORDER BY e.exercise_name;

select *
from exercises;

-- Task 1.4: run AFTER Project_add_Equipment.sql, in one connection.
-- MySQL 8.0.16+; run the whole file. Stop on SQL errors and ROLLBACK.
-- No CREATE/DROP DATABASE, master-data changes, or new entities.
-- Re-running restores this demo's profile and its two equipment choices.
USE smart_workout_planner;

SET @demo_email = 'demo@gmail.com';
-- A missing or duplicate master name must fail, rather than silently skip rows.
SET @demo_bodyweight_id = (
    SELECT equipment_id FROM equipment WHERE equipment_name = 'Bodyweight'
);
SET @demo_dumbbell_id = (
    SELECT equipment_id FROM equipment WHERE equipment_name = 'Dumbbell'
);

START TRANSACTION;

INSERT INTO users (name, email, password_hash)
VALUES ('Demo beginner', @demo_email, NULL)
ON DUPLICATE KEY UPDATE name = 'Demo beginner';

SET @demo_user_id = (SELECT user_id FROM users WHERE email = @demo_email);

INSERT INTO user_profiles (
    user_id, gender, birth_date, height_cm, fitness_level, primary_goal,
    workout_location, days_per_week, minutes_per_session, stretch_recommendation
) VALUES (
    @demo_user_id, NULL, NULL, NULL, 'Beginner', 'Build muscle',
    'Home', 3, 60, FALSE
)
ON DUPLICATE KEY UPDATE
    fitness_level = 'Beginner',
    primary_goal = 'Build muscle',
    workout_location = 'Home',
    days_per_week = 3,
    minutes_per_session = 60,
    stretch_recommendation = FALSE;

-- NOT NULL prevents a missing equipment lookup from being accepted.
INSERT INTO user_equipment (user_id, equipment_id)
VALUES (@demo_user_id, @demo_bodyweight_id), (@demo_user_id, @demo_dumbbell_id)
ON DUPLICATE KEY UPDATE user_id = @demo_user_id;

-- Match the friend's intended setup: this demo owns exactly these two types.
DELETE FROM user_equipment
WHERE user_id = @demo_user_id
  AND equipment_id NOT IN (@demo_bodyweight_id, @demo_dumbbell_id);

COMMIT;

-- Task 1.5: read-only checks AFTER 01_task_1_4_mock_data.sql.
-- Run the whole file, in one connection. PASS/FAIL is shown in result sets.
-- Exact baseline counts describe the supplied Clean Version, before extra data.
USE smart_workout_planner;
SET @demo_email = 'demo@gmail.com';
SET @demo_user_id = (SELECT user_id FROM users WHERE email = @demo_email);

-- T01: baseline. IDs themselves do not need to start at 1.
SELECT 'T01_tables' AS test_name, 11 AS expected,
       COUNT(*) AS actual, IF(COUNT(*) = 11, 'PASS', 'FAIL') AS result
FROM information_schema.tables
WHERE table_schema = DATABASE() AND table_type = 'BASE TABLE'
UNION ALL
SELECT 'T02_equipment', 22, COUNT(*), IF(COUNT(*) = 22, 'PASS', 'FAIL')
FROM equipment
UNION ALL
SELECT 'T03_system_exercises', 301, COUNT(*), IF(COUNT(*) = 301, 'PASS', 'FAIL')
FROM exercises WHERE created_by_user_id IS NULL
UNION ALL
SELECT 'T04_demo_user', 1, COUNT(*), IF(COUNT(*) = 1, 'PASS', 'FAIL')
FROM users WHERE email = @demo_email
UNION ALL
SELECT 'T05_demo_profile', 1, COUNT(*), IF(COUNT(*) = 1, 'PASS', 'FAIL')
FROM user_profiles WHERE user_id = @demo_user_id
UNION ALL
SELECT 'T06_demo_equipment', 2, COUNT(*), IF(COUNT(*) = 2, 'PASS', 'FAIL')
FROM user_equipment WHERE user_id = @demo_user_id;

SELECT 'T07_profile_values' AS test_name,
       IF(COUNT(*) = 1, 'PASS', 'FAIL') AS result
FROM user_profiles
WHERE user_id = @demo_user_id AND fitness_level = 'Beginner'
  AND primary_goal = 'Build muscle' AND workout_location = 'Home'
  AND days_per_week = 3 AND minutes_per_session = 60
  AND stretch_recommendation = FALSE;

SELECT 'T08_equipment_names' AS test_name,
       IF(COUNT(*) = 2
          AND SUM(eq.equipment_name = 'Bodyweight') = 1
          AND SUM(eq.equipment_name = 'Dumbbell') = 1, 'PASS', 'FAIL') AS result
FROM user_equipment ue
JOIN equipment eq ON eq.equipment_id = ue.equipment_id
WHERE ue.user_id = @demo_user_id;

-- T09: name uniqueness. DISTINCT exercise_id cannot detect duplicate names.
SELECT 'T09_duplicate_system_names' AS test_name, COUNT(*) AS violations,
       IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result
FROM (
    SELECT exercise_name FROM exercises WHERE created_by_user_id IS NULL
    GROUP BY exercise_name HAVING COUNT(*) > 1
) duplicates;

SELECT 'T10_missing_equipment' AS test_name, COUNT(*) AS violations,
       IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result
FROM exercises e LEFT JOIN equipment eq ON eq.equipment_id = e.equipment_id
WHERE eq.equipment_id IS NULL;

SELECT 'T11_rep_ranges' AS test_name, COUNT(*) AS violations,
       IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result
FROM exercises
WHERE optimal_rep_min <= 0 OR optimal_rep_max <= 0
   OR optimal_rep_min > optimal_rep_max;

-- T12: missing, duplicated, and incorrect mappings all fail.
SELECT 'T12_mapping' AS test_name, m.exercise_name,
       m.equipment_name AS expected_equipment,
       GROUP_CONCAT(eq.equipment_name ORDER BY eq.equipment_name) AS actual_equipment,
       IF(COUNT(e.exercise_id) = 1 AND
          SUM(eq.equipment_name = m.equipment_name) = 1, 'PASS', 'FAIL') AS result
FROM (
    SELECT 'Machine Chest Press' AS exercise_name, 'Machine' AS equipment_name
    UNION ALL SELECT 'Leg Press', 'Machine'
    UNION ALL SELECT 'Trap Bar Deadlift', 'Trap Bar'
    UNION ALL SELECT 'Battle Ropes', 'Battle Rope'
    UNION ALL SELECT 'Sled Push', 'Sled'
    UNION ALL SELECT 'Medicine Ball Slam', 'Medicine Ball'
    UNION ALL SELECT 'Foam Rolling (Quads)', 'Foam Roller'
    UNION ALL SELECT 'TRX Row', 'TRX'
    UNION ALL SELECT 'EZ-Bar Curl', 'EZ Bar'
    UNION ALL SELECT 'Plate Front Raise', 'Weight Plate'
    UNION ALL SELECT 'Ab Wheel Rollout', 'Ab Wheel'
    UNION ALL SELECT 'Landmine Press', 'Landmine'
    UNION ALL SELECT 'Tire Flip', 'Tire'
    UNION ALL SELECT 'Box Jump', 'Plyo Box'
) m
LEFT JOIN exercises e ON e.exercise_name = m.exercise_name
                        AND e.created_by_user_id IS NULL
LEFT JOIN equipment eq ON eq.equipment_id = e.equipment_id
GROUP BY m.exercise_name, m.equipment_name
ORDER BY m.exercise_name;

-- T13: fixed reference counts for the supplied 301 system exercises.
SELECT 'T13_eligible_system_count' AS test_name, 92 AS expected,
       COUNT(*) AS actual, IF(COUNT(*) = 92, 'PASS', 'FAIL') AS result
FROM user_equipment ue
JOIN exercises e ON e.equipment_id = ue.equipment_id
WHERE ue.user_id = @demo_user_id AND e.created_by_user_id IS NULL;

SELECT 'T14_eligible_by_equipment' AS test_name, eq.equipment_name,
       COUNT(e.exercise_id) AS actual,
       IF(eq.equipment_name = 'Bodyweight', 43, 49) AS expected,
       IF(COUNT(e.exercise_id) = IF(eq.equipment_name = 'Bodyweight', 43, 49),
          'PASS', 'FAIL') AS result
FROM equipment eq
LEFT JOIN user_equipment ue ON ue.equipment_id = eq.equipment_id
                            AND ue.user_id = @demo_user_id
LEFT JOIN exercises e ON e.equipment_id = ue.equipment_id
                        AND e.created_by_user_id IS NULL
WHERE eq.equipment_name IN ('Bodyweight', 'Dumbbell')
GROUP BY eq.equipment_id, eq.equipment_name;

-- Review the mock profile and equipment, preserving the friend's inspection.
SELECT u.user_id, u.name, u.email, p.fitness_level, p.primary_goal,
       p.workout_location, p.days_per_week, p.minutes_per_session,
       p.stretch_recommendation
FROM users u JOIN user_profiles p ON p.user_id = u.user_id
WHERE u.email = @demo_email;

SELECT eq.equipment_id, eq.equipment_name
FROM user_equipment ue JOIN equipment eq ON eq.equipment_id = ue.equipment_id
WHERE ue.user_id = @demo_user_id ORDER BY eq.equipment_name;

-- Equipment-based candidates only, not a complete workout recommendation.
-- Include system exercises and this user's custom exercises only.
SELECT e.exercise_id, e.exercise_name, e.muscle_group, e.is_stretch,
       eq.equipment_name
FROM user_equipment ue
JOIN exercises e ON e.equipment_id = ue.equipment_id
JOIN equipment eq ON eq.equipment_id = e.equipment_id
WHERE ue.user_id = @demo_user_id
  AND (e.created_by_user_id IS NULL OR e.created_by_user_id = @demo_user_id)
ORDER BY e.muscle_group, e.exercise_name;

SELECT eq.equipment_name, COUNT(e.exercise_id) AS exercise_count
FROM equipment eq LEFT JOIN exercises e ON e.equipment_id = eq.equipment_id
GROUP BY eq.equipment_id, eq.equipment_name
ORDER BY exercise_count DESC, eq.equipment_name;

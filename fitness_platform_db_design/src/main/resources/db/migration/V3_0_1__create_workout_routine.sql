-- Fitness Platform / Product V3
-- Reusable workout templates. When a routine is placed into a Plan version, targets are copied into immutable plan-version tables.

CREATE TABLE workout_routine (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id             BIGINT UNSIGNED NOT NULL,
    name                VARCHAR(200) NOT NULL,
    category            VARCHAR(100) NULL,
    note                VARCHAR(2000) NULL,
    status              VARCHAR(32) NOT NULL DEFAULT 'ACTIVE',
    row_version         BIGINT UNSIGNED NOT NULL DEFAULT 0,
    created_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    KEY idx_workout_routine_user_status (user_id, status, updated_at),

    CONSTRAINT fk_workout_routine_user
        FOREIGN KEY (user_id) REFERENCES app_user(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_workout_routine_status CHECK (status IN ('ACTIVE', 'ARCHIVED'))
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE workout_routine_exercise (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    routine_id          BIGINT UNSIGNED NOT NULL,
    exercise_id         BIGINT UNSIGNED NOT NULL,
    sort_order          INT UNSIGNED NOT NULL,
    note                VARCHAR(1000) NULL,
    created_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    UNIQUE KEY uk_routine_exercise_order (routine_id, sort_order),
    KEY idx_routine_exercise_exercise (exercise_id),

    CONSTRAINT fk_routine_exercise_routine
        FOREIGN KEY (routine_id) REFERENCES workout_routine(id)
        ON DELETE CASCADE ON UPDATE RESTRICT,
    CONSTRAINT fk_routine_exercise_exercise
        FOREIGN KEY (exercise_id) REFERENCES exercise(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE workout_routine_set_target (
    id                      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    routine_exercise_id     BIGINT UNSIGNED NOT NULL,
    set_order               INT UNSIGNED NOT NULL,
    target_weight_kg        DECIMAL(10,3) NULL,
    target_reps_min         INT UNSIGNED NULL,
    target_reps_max         INT UNSIGNED NULL,
    target_duration_seconds INT UNSIGNED NULL,
    target_distance_m       DECIMAL(12,3) NULL,
    target_rpe              DECIMAL(4,1) NULL,
    target_rir              DECIMAL(4,1) NULL,
    set_type                VARCHAR(32) NULL,
    note                    VARCHAR(500) NULL,

    PRIMARY KEY (id),
    UNIQUE KEY uk_routine_set_order (routine_exercise_id, set_order),

    CONSTRAINT fk_routine_set_exercise
        FOREIGN KEY (routine_exercise_id) REFERENCES workout_routine_exercise(id)
        ON DELETE CASCADE ON UPDATE RESTRICT,
    CONSTRAINT ck_routine_set_reps_range CHECK (
        target_reps_min IS NULL OR target_reps_max IS NULL OR target_reps_max >= target_reps_min
    )
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci;

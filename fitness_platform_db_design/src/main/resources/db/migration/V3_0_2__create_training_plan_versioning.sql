-- Fitness Platform / Product V3
-- Plan identity + immutable plan versions + versioned schedule items/targets.

CREATE TABLE training_plan (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id             BIGINT UNSIGNED NOT NULL,
    name                VARCHAR(200) NOT NULL,
    category            VARCHAR(100) NULL,
    status              VARCHAR(32) NOT NULL DEFAULT 'DRAFT',
    current_version_no  INT UNSIGNED NOT NULL DEFAULT 0,
    row_version         BIGINT UNSIGNED NOT NULL DEFAULT 0,
    created_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    KEY idx_training_plan_user_status (user_id, status, updated_at),

    CONSTRAINT fk_training_plan_user
        FOREIGN KEY (user_id) REFERENCES app_user(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_training_plan_status CHECK (status IN ('DRAFT', 'ACTIVE', 'PAUSED', 'COMPLETED', 'ARCHIVED'))
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE training_plan_version (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    plan_id             BIGINT UNSIGNED NOT NULL,
    version_no          INT UNSIGNED NOT NULL,
    name_snapshot       VARCHAR(200) NOT NULL,
    category_snapshot   VARCHAR(100) NULL,
    goal_snapshot       VARCHAR(1000) NULL,
    schedule_type       VARCHAR(32) NOT NULL,
    cycle_length_days   INT UNSIGNED NULL,
    start_date          DATE NULL,
    end_date            DATE NULL,
    note_snapshot       VARCHAR(2000) NULL,
    created_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    UNIQUE KEY uk_training_plan_version (plan_id, version_no),
    KEY idx_training_plan_version_range (plan_id, start_date, end_date),

    CONSTRAINT fk_training_plan_version_plan
        FOREIGN KEY (plan_id) REFERENCES training_plan(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_training_plan_version_schedule_type CHECK (schedule_type IN ('REPEATING_CYCLE', 'WEEKLY', 'DATE_SPECIFIC')),
    CONSTRAINT ck_training_plan_version_date_range CHECK (end_date IS NULL OR start_date IS NULL OR end_date >= start_date),
    CONSTRAINT ck_training_plan_version_cycle CHECK (
        (schedule_type = 'DATE_SPECIFIC' AND cycle_length_days IS NULL) OR
        (schedule_type IN ('REPEATING_CYCLE', 'WEEKLY') AND cycle_length_days IS NOT NULL AND cycle_length_days > 0)
    )
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Immutable plan versions. Editing a plan creates a new version instead of rewriting historical semantics.';

CREATE TABLE training_plan_schedule_item (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    plan_version_id     BIGINT UNSIGNED NOT NULL,
    source_routine_id   BIGINT UNSIGNED NULL,
    cycle_day_no        INT UNSIGNED NULL,
    specific_date       DATE NULL,
    item_type           VARCHAR(32) NOT NULL,
    title               VARCHAR(200) NULL,
    category            VARCHAR(100) NULL,
    sort_order          INT UNSIGNED NOT NULL DEFAULT 0,
    created_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    KEY idx_plan_schedule_item_cycle (plan_version_id, cycle_day_no, sort_order),
    KEY idx_plan_schedule_item_date (plan_version_id, specific_date, sort_order),

    CONSTRAINT fk_plan_schedule_item_version
        FOREIGN KEY (plan_version_id) REFERENCES training_plan_version(id)
        ON DELETE CASCADE ON UPDATE RESTRICT,
    CONSTRAINT fk_plan_schedule_item_routine
        FOREIGN KEY (source_routine_id) REFERENCES workout_routine(id)
        ON DELETE SET NULL ON UPDATE RESTRICT,
    CONSTRAINT ck_plan_schedule_item_type CHECK (item_type IN ('WORKOUT', 'REST')),
    CONSTRAINT ck_plan_schedule_item_locator CHECK (cycle_day_no IS NOT NULL OR specific_date IS NOT NULL)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE training_plan_item_exercise (
    id                          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    schedule_item_id            BIGINT UNSIGNED NOT NULL,
    exercise_id                 BIGINT UNSIGNED NOT NULL,
    exercise_name_snapshot      VARCHAR(200) NOT NULL,
    exercise_category_snapshot  VARCHAR(100) NULL,
    primary_muscle_snapshot     VARCHAR(100) NULL,
    sort_order                  INT UNSIGNED NOT NULL,
    note                        VARCHAR(1000) NULL,

    PRIMARY KEY (id),
    UNIQUE KEY uk_plan_item_exercise_order (schedule_item_id, sort_order),
    KEY idx_plan_item_exercise_exercise (exercise_id),

    CONSTRAINT fk_plan_item_exercise_schedule
        FOREIGN KEY (schedule_item_id) REFERENCES training_plan_schedule_item(id)
        ON DELETE CASCADE ON UPDATE RESTRICT,
    CONSTRAINT fk_plan_item_exercise_exercise
        FOREIGN KEY (exercise_id) REFERENCES exercise(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE training_plan_item_set_target (
    id                      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    plan_item_exercise_id   BIGINT UNSIGNED NOT NULL,
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
    UNIQUE KEY uk_plan_item_set_order (plan_item_exercise_id, set_order),

    CONSTRAINT fk_plan_item_set_exercise
        FOREIGN KEY (plan_item_exercise_id) REFERENCES training_plan_item_exercise(id)
        ON DELETE CASCADE ON UPDATE RESTRICT,
    CONSTRAINT ck_plan_item_set_reps_range CHECK (
        target_reps_min IS NULL OR target_reps_max IS NULL OR target_reps_max >= target_reps_min
    )
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci;

-- Fitness Platform / Product V3
-- Actual workout facts, independent from plan targets.

CREATE TABLE workout_session (
    id                          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id                     BIGINT UNSIGNED NOT NULL,
    source_type                 VARCHAR(32) NOT NULL DEFAULT 'FREE',
    source_scheduled_workout_id BIGINT UNSIGNED NULL,
    title                       VARCHAR(200) NULL,
    category                    VARCHAR(100) NULL,
    started_at                  DATETIME(3) NOT NULL COMMENT 'UTC instant.',
    ended_at                    DATETIME(3) NULL COMMENT 'UTC instant.',
    business_date               DATE NOT NULL,
    note                        VARCHAR(2000) NULL,
    status                      VARCHAR(32) NOT NULL DEFAULT 'IN_PROGRESS',
    deleted_at                  DATETIME(3) NULL,
    row_version                 BIGINT UNSIGNED NOT NULL DEFAULT 0,
    created_at                  DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at                  DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    UNIQUE KEY uk_workout_session_schedule (source_scheduled_workout_id),
    KEY idx_workout_session_user_day (user_id, business_date, status, deleted_at),
    KEY idx_workout_session_user_start (user_id, started_at),

    CONSTRAINT fk_workout_session_user
        FOREIGN KEY (user_id) REFERENCES app_user(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_workout_session_schedule
        FOREIGN KEY (source_scheduled_workout_id) REFERENCES scheduled_workout(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_workout_session_source CHECK (source_type IN ('FREE', 'PLAN')),
    CONSTRAINT ck_workout_session_status CHECK (status IN ('IN_PROGRESS', 'COMPLETED', 'CANCELLED')),
    CONSTRAINT ck_workout_session_time CHECK (ended_at IS NULL OR ended_at >= started_at)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE workout_session_exercise (
    id                              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    session_id                      BIGINT UNSIGNED NOT NULL,
    exercise_id                     BIGINT UNSIGNED NOT NULL,
    source_plan_item_exercise_id    BIGINT UNSIGNED NULL,
    exercise_name_snapshot          VARCHAR(200) NOT NULL,
    exercise_category_snapshot      VARCHAR(100) NULL,
    primary_muscle_snapshot         VARCHAR(100) NULL,
    tracking_type_snapshot          VARCHAR(32) NOT NULL,
    load_volume_applicable_snapshot TINYINT(1) NOT NULL DEFAULT 0,
    sort_order                      INT UNSIGNED NOT NULL,
    note                            VARCHAR(1000) NULL,

    PRIMARY KEY (id),
    UNIQUE KEY uk_session_exercise_order (session_id, sort_order),
    KEY idx_session_exercise_exercise_session (exercise_id, session_id),
    KEY idx_session_exercise_plan_source (source_plan_item_exercise_id),

    CONSTRAINT fk_session_exercise_session
        FOREIGN KEY (session_id) REFERENCES workout_session(id)
        ON DELETE CASCADE ON UPDATE RESTRICT,
    CONSTRAINT fk_session_exercise_exercise
        FOREIGN KEY (exercise_id) REFERENCES exercise(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_session_exercise_plan_source
        FOREIGN KEY (source_plan_item_exercise_id) REFERENCES training_plan_item_exercise(id)
        ON DELETE SET NULL ON UPDATE RESTRICT
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE workout_set (
    id                          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    session_exercise_id         BIGINT UNSIGNED NOT NULL,
    source_plan_set_target_id   BIGINT UNSIGNED NULL,
    set_order                   INT UNSIGNED NOT NULL,
    weight_kg                   DECIMAL(10,3) NULL,
    reps                        INT UNSIGNED NULL,
    duration_seconds            INT UNSIGNED NULL,
    distance_m                  DECIMAL(12,3) NULL,
    rpe                         DECIMAL(4,1) NULL,
    rir                         DECIMAL(4,1) NULL,
    set_type                    VARCHAR(32) NULL,
    note                        VARCHAR(500) NULL,
    completed                   TINYINT(1) NOT NULL DEFAULT 1,
    created_at                  DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at                  DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    UNIQUE KEY uk_workout_set_order (session_exercise_id, set_order),
    KEY idx_workout_set_plan_source (source_plan_set_target_id),
    KEY idx_workout_set_completed (session_exercise_id, completed, set_order),

    CONSTRAINT fk_workout_set_session_exercise
        FOREIGN KEY (session_exercise_id) REFERENCES workout_session_exercise(id)
        ON DELETE CASCADE ON UPDATE RESTRICT,
    CONSTRAINT fk_workout_set_plan_source
        FOREIGN KEY (source_plan_set_target_id) REFERENCES training_plan_item_set_target(id)
        ON DELETE SET NULL ON UPDATE RESTRICT,
    CONSTRAINT ck_workout_set_weight CHECK (weight_kg IS NULL OR weight_kg >= 0),
    CONSTRAINT ck_workout_set_distance CHECK (distance_m IS NULL OR distance_m >= 0)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Actual workout set facts. Planned target links are optional and never overwrite actual values.';

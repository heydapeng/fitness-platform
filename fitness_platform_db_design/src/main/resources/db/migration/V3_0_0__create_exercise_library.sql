-- Fitness Platform / Product V3
-- Exercise definitions. Historical workout facts snapshot mutable exercise presentation fields.

CREATE TABLE exercise (
    id                      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    owner_user_id           BIGINT UNSIGNED NULL,
    source_type             VARCHAR(32) NOT NULL DEFAULT 'SYSTEM',
    name                    VARCHAR(200) NOT NULL,
    normalized_name         VARCHAR(200) NOT NULL,
    name_en                 VARCHAR(200) NULL,
    normalized_name_en      VARCHAR(200) NULL,
    primary_muscle          VARCHAR(100) NULL,
    secondary_muscles_json  JSON NULL,
    equipment               VARCHAR(100) NULL,
    category                VARCHAR(100) NULL,
    tracking_type           VARCHAR(32) NOT NULL DEFAULT 'MIXED',
    load_volume_applicable  TINYINT(1) NOT NULL DEFAULT 0,
    description             VARCHAR(2000) NULL,
    status                  VARCHAR(32) NOT NULL DEFAULT 'ACTIVE',
    row_version             BIGINT UNSIGNED NOT NULL DEFAULT 0,
    created_at              DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at              DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    KEY idx_exercise_status_name (status, normalized_name),
    KEY idx_exercise_name_en (status, normalized_name_en),
    KEY idx_exercise_muscle_category (primary_muscle, category, status),
    KEY idx_exercise_owner (owner_user_id, status, normalized_name),

    CONSTRAINT fk_exercise_owner
        FOREIGN KEY (owner_user_id) REFERENCES app_user(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_exercise_status CHECK (status IN ('ACTIVE', 'INACTIVE')),
    CONSTRAINT ck_exercise_tracking_type CHECK (tracking_type IN ('WEIGHT_REPS', 'REPS_ONLY', 'DURATION', 'DISTANCE', 'MIXED'))
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Exercise catalog; owner_user_id is set for user custom exercises.';

CREATE TABLE exercise_alias (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    exercise_id         BIGINT UNSIGNED NOT NULL,
    alias               VARCHAR(200) NOT NULL,
    normalized_alias    VARCHAR(200) NOT NULL,
    language_code       VARCHAR(16) NULL,
    created_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    UNIQUE KEY uk_exercise_alias (exercise_id, normalized_alias),
    KEY idx_exercise_alias_normalized (normalized_alias, exercise_id),

    CONSTRAINT fk_exercise_alias_exercise
        FOREIGN KEY (exercise_id) REFERENCES exercise(id)
        ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci;

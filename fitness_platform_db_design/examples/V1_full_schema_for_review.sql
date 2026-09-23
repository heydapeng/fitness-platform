-- Consolidated V1 schema for review only.
-- DO NOT place this file in Flyway migration folder together with the individual V1_0_x files.
-- Use the individual migrations in src/main/resources/db/migration for real deployments.


-- ============================================================================
-- V1_0_0__create_app_user.sql
-- ============================================================================
-- Fitness Platform / Product V1
-- User account and basic profile.
-- MySQL 8.0.16+ recommended so CHECK constraints are enforced.

CREATE TABLE app_user (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    email               VARCHAR(254) NOT NULL,
    password_hash       VARCHAR(255) NOT NULL,
    role                VARCHAR(32) NOT NULL DEFAULT 'USER',
    status              VARCHAR(32) NOT NULL DEFAULT 'ACTIVE',
    timezone_id         VARCHAR(64) NOT NULL DEFAULT 'UTC',
    row_version         BIGINT UNSIGNED NOT NULL DEFAULT 0,
    created_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    UNIQUE KEY uk_app_user_email (email),
    KEY idx_app_user_status (status),

    CONSTRAINT ck_app_user_role CHECK (role IN ('USER', 'ADMIN')),
    CONSTRAINT ck_app_user_status CHECK (status IN ('ACTIVE', 'DISABLED'))
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci
  COMMENT='User account. Email is normalized to lower-case by the service before persistence.';

-- ============================================================================
-- V1_0_1__create_food_catalog.sql
-- ============================================================================
-- Fitness Platform / Product V1
-- Food category and structured food catalog.

CREATE TABLE food_category (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    code                VARCHAR(64) NOT NULL,
    display_name        VARCHAR(100) NOT NULL,
    status              VARCHAR(32) NOT NULL DEFAULT 'ACTIVE',
    sort_order          INT NOT NULL DEFAULT 0,
    created_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    UNIQUE KEY uk_food_category_code (code),
    KEY idx_food_category_status_sort (status, sort_order),

    CONSTRAINT ck_food_category_status CHECK (status IN ('ACTIVE', 'INACTIVE'))
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Food category dictionary. Product taxonomy can evolve independently from food records.';

-- PRD does not define a complete category taxonomy. Keep only a technical fallback.
INSERT INTO food_category(code, display_name, status, sort_order)
VALUES ('OTHER', 'Other', 'ACTIVE', 9999);

CREATE TABLE food (
    id                          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    category_id                 BIGINT UNSIGNED NOT NULL,
    name                        VARCHAR(200) NOT NULL,
    normalized_name             VARCHAR(200) NOT NULL,
    brand                       VARCHAR(200) NULL,
    normalized_brand            VARCHAR(200) NULL,
    calories_per_100g           DECIMAL(12,4) NOT NULL,
    protein_per_100g            DECIMAL(12,4) NOT NULL,
    carbs_per_100g              DECIMAL(12,4) NOT NULL,
    fat_per_100g                DECIMAL(12,4) NOT NULL,
    source_type                 VARCHAR(32) NOT NULL DEFAULT 'SYSTEM',
    status                      VARCHAR(32) NOT NULL DEFAULT 'ACTIVE',
    description                 VARCHAR(1000) NULL,
    row_version                 BIGINT UNSIGNED NOT NULL DEFAULT 0,
    created_at                  DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at                  DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    KEY idx_food_status_name (status, normalized_name),
    KEY idx_food_category_status (category_id, status),
    KEY idx_food_brand_status (normalized_brand, status),

    CONSTRAINT fk_food_category
        FOREIGN KEY (category_id) REFERENCES food_category(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_food_status CHECK (status IN ('ACTIVE', 'INACTIVE')),
    CONSTRAINT ck_food_calories_non_negative CHECK (calories_per_100g >= 0),
    CONSTRAINT ck_food_protein_non_negative CHECK (protein_per_100g >= 0),
    CONSTRAINT ck_food_carbs_non_negative CHECK (carbs_per_100g >= 0),
    CONSTRAINT ck_food_fat_non_negative CHECK (fat_per_100g >= 0)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Current food catalog values. Historical food records never recalculate from this table.';

-- ============================================================================
-- V1_0_2__create_nutrition_goal.sql
-- ============================================================================
-- Fitness Platform / Product V1
-- Optional nutrition targets with historical effective periods.

CREATE TABLE nutrition_goal (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id             BIGINT UNSIGNED NOT NULL,
    effective_date      DATE NOT NULL,
    end_date            DATE NULL COMMENT 'Inclusive end date. NULL means open-ended.',
    calories_target     DECIMAL(12,4) NULL,
    protein_target_g    DECIMAL(12,4) NULL,
    carbs_target_g      DECIMAL(12,4) NULL,
    fat_target_g        DECIMAL(12,4) NULL,
    note                VARCHAR(1000) NULL,
    row_version         BIGINT UNSIGNED NOT NULL DEFAULT 0,
    created_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    UNIQUE KEY uk_nutrition_goal_user_effective_date (user_id, effective_date),
    KEY idx_nutrition_goal_user_range (user_id, effective_date, end_date),

    CONSTRAINT fk_nutrition_goal_user
        FOREIGN KEY (user_id) REFERENCES app_user(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_nutrition_goal_date_range CHECK (end_date IS NULL OR end_date >= effective_date),
    CONSTRAINT ck_nutrition_goal_has_target CHECK (
        calories_target IS NOT NULL OR
        protein_target_g IS NOT NULL OR
        carbs_target_g IS NOT NULL OR
        fat_target_g IS NOT NULL
    ),
    CONSTRAINT ck_nutrition_goal_calories_positive CHECK (calories_target IS NULL OR calories_target > 0),
    CONSTRAINT ck_nutrition_goal_protein_positive CHECK (protein_target_g IS NULL OR protein_target_g > 0),
    CONSTRAINT ck_nutrition_goal_carbs_positive CHECK (carbs_target_g IS NULL OR carbs_target_g > 0),
    CONSTRAINT ck_nutrition_goal_fat_positive CHECK (fat_target_g IS NULL OR fat_target_g > 0)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Optional nutrition goals. Overlap between effective periods is prevented transactionally in the service layer.';

-- ============================================================================
-- V1_0_3__create_food_record.sql
-- ============================================================================
-- Fitness Platform / Product V1
-- Food intake facts and immutable-at-write nutrition snapshots.

CREATE TABLE food_record (
    id                              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id                         BIGINT UNSIGNED NOT NULL,
    food_id                         BIGINT UNSIGNED NOT NULL,

    -- Historical descriptive snapshots. These intentionally duplicate mutable Food fields
    -- so later analytics (V1.2) remains historically stable after food catalog edits.
    food_name_snapshot              VARCHAR(200) NOT NULL,
    food_brand_snapshot             VARCHAR(200) NULL,
    food_category_code_snapshot     VARCHAR(64) NOT NULL,
    food_source_type_snapshot       VARCHAR(32) NOT NULL,

    -- User-entered fact.
    amount_g                        DECIMAL(12,3) NOT NULL,
    occurred_at                     DATETIME(3) NOT NULL COMMENT 'UTC instant stored as DATETIME(3); app/session timezone must be UTC.',
    business_date                   DATE NOT NULL COMMENT 'Derived once from occurred_at + user timezone at write/edit time.',
    meal_type                       VARCHAR(32) NULL,
    note                            VARCHAR(1000) NULL,

    -- Per-100g snapshot used for deterministic recalculation when amount changes.
    calories_per_100g_snapshot      DECIMAL(12,4) NOT NULL,
    protein_per_100g_snapshot       DECIMAL(12,4) NOT NULL,
    carbs_per_100g_snapshot         DECIMAL(12,4) NOT NULL,
    fat_per_100g_snapshot           DECIMAL(12,4) NOT NULL,

    -- Actual calculated nutrition persisted as a fact for fast, stable aggregation.
    calories_actual                 DECIMAL(12,4) NOT NULL,
    protein_actual_g                DECIMAL(12,4) NOT NULL,
    carbs_actual_g                  DECIMAL(12,4) NOT NULL,
    fat_actual_g                    DECIMAL(12,4) NOT NULL,

    deleted_at                      DATETIME(3) NULL COMMENT 'Internal soft delete; V1 exposes no recycle bin.',
    row_version                     BIGINT UNSIGNED NOT NULL DEFAULT 0,
    created_at                      DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at                      DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    KEY idx_food_record_user_day_time (user_id, business_date, deleted_at, occurred_at),
    KEY idx_food_record_user_food_day (user_id, food_id, business_date),
    KEY idx_food_record_user_meal_day (user_id, meal_type, business_date),
    KEY idx_food_record_food_id (food_id),

    CONSTRAINT fk_food_record_user
        FOREIGN KEY (user_id) REFERENCES app_user(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_food_record_food
        FOREIGN KEY (food_id) REFERENCES food(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_food_record_amount_positive CHECK (amount_g > 0),
    CONSTRAINT ck_food_record_meal_type CHECK (
        meal_type IS NULL OR meal_type IN ('BREAKFAST', 'LUNCH', 'DINNER', 'SNACK')
    ),
    CONSTRAINT ck_food_record_calories_non_negative CHECK (calories_actual >= 0),
    CONSTRAINT ck_food_record_protein_non_negative CHECK (protein_actual_g >= 0),
    CONSTRAINT ck_food_record_carbs_non_negative CHECK (carbs_actual_g >= 0),
    CONSTRAINT ck_food_record_fat_non_negative CHECK (fat_actual_g >= 0)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Nutrition intake fact table. All dashboard/history/analytics queries must ignore deleted_at rows.';

-- ============================================================================
-- V1_0_4__create_idempotency_request.sql
-- ============================================================================
-- Fitness Platform / Product V1
-- Generic server-side idempotency primitive. Reused by V1.1 batch writes and V2 AI confirmation writes.

CREATE TABLE idempotency_request (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id             BIGINT UNSIGNED NOT NULL,
    operation_key       VARCHAR(100) NOT NULL,
    request_id          VARCHAR(128) NOT NULL,
    request_hash        CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT 'SHA-256 hex of canonical business request payload.',
    status              VARCHAR(32) NOT NULL DEFAULT 'PROCESSING',
    resource_type       VARCHAR(64) NULL,
    resource_id         VARCHAR(128) NULL,
    response_json       JSON NULL,
    error_code          VARCHAR(100) NULL,
    expires_at          DATETIME(3) NULL,
    created_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    UNIQUE KEY uk_idempotency_user_operation_request (user_id, operation_key, request_id),
    KEY idx_idempotency_expiry (expires_at),
    KEY idx_idempotency_status_created (status, created_at),

    CONSTRAINT fk_idempotency_user
        FOREIGN KEY (user_id) REFERENCES app_user(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_idempotency_status CHECK (status IN ('PROCESSING', 'SUCCEEDED', 'FAILED'))
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Server-side idempotency records. Same user + operation + request_id may create business data only once.';

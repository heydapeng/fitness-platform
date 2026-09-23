-- Fitness Platform full migration chain through V3.6 (review/rehearsal only).
-- DO NOT place this file in the Flyway migration directory together with the source migrations.
-- It intentionally preserves ALTER/UPDATE/trigger steps to show the exact forward-only path.

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


-- ============================================================================
-- V1_1_0__extend_food_sources_and_custom_food.sql
-- ============================================================================
-- Fitness Platform / Product V1.1
-- Third-party source metadata and user-owned custom foods.

ALTER TABLE food
    ADD COLUMN owner_user_id BIGINT UNSIGNED NULL AFTER id,
    ADD COLUMN source_provider VARCHAR(64) NULL AFTER source_type,
    ADD COLUMN source_external_id VARCHAR(191) NULL AFTER source_provider,
    ADD COLUMN source_updated_at DATETIME(3) NULL AFTER source_external_id,
    ADD COLUMN barcode VARCHAR(64) NULL AFTER source_updated_at,
    ADD KEY idx_food_owner_status_name (owner_user_id, status, normalized_name),
    ADD UNIQUE KEY uk_food_provider_external (source_provider, source_external_id),
    ADD KEY idx_food_barcode (barcode),
    ADD CONSTRAINT fk_food_owner_user
        FOREIGN KEY (owner_user_id) REFERENCES app_user(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT;

CREATE TABLE food_alias (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    food_id             BIGINT UNSIGNED NOT NULL,
    alias               VARCHAR(200) NOT NULL,
    normalized_alias    VARCHAR(200) NOT NULL,
    language_code       VARCHAR(16) NULL,
    source_type         VARCHAR(32) NOT NULL DEFAULT 'SYSTEM',
    created_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    UNIQUE KEY uk_food_alias_food_normalized (food_id, normalized_alias),
    KEY idx_food_alias_normalized (normalized_alias, food_id),

    CONSTRAINT fk_food_alias_food
        FOREIGN KEY (food_id) REFERENCES food(id)
        ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Search aliases for food resolution. Alias semantics do not alter nutrition facts.';

CREATE TABLE user_food_favorite (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id             BIGINT UNSIGNED NOT NULL,
    food_id             BIGINT UNSIGNED NOT NULL,
    created_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    UNIQUE KEY uk_user_food_favorite (user_id, food_id),
    KEY idx_user_food_favorite_created (user_id, created_at),
    KEY idx_user_food_favorite_food (food_id),

    CONSTRAINT fk_user_food_favorite_user
        FOREIGN KEY (user_id) REFERENCES app_user(id)
        ON DELETE CASCADE ON UPDATE RESTRICT,
    CONSTRAINT fk_user_food_favorite_food
        FOREIGN KEY (food_id) REFERENCES food(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Per-user food favorites.';


-- ============================================================================
-- V1_1_1__create_food_record_group.sql
-- ============================================================================
-- Fitness Platform / Product V1.1
-- Optional grouping for multi-food add/copy flows. V1.2 photos may attach to this group.

CREATE TABLE food_record_group (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id             BIGINT UNSIGNED NOT NULL,
    group_type          VARCHAR(32) NOT NULL DEFAULT 'BATCH',
    title               VARCHAR(200) NULL,
    occurred_at         DATETIME(3) NULL COMMENT 'Optional group-level UTC instant; item timestamps remain authoritative.',
    business_date       DATE NULL,
    meal_type           VARCHAR(32) NULL,
    note                VARCHAR(1000) NULL,
    created_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    KEY idx_food_record_group_user_day (user_id, business_date, created_at),

    CONSTRAINT fk_food_record_group_user
        FOREIGN KEY (user_id) REFERENCES app_user(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_food_record_group_type CHECK (group_type IN ('BATCH', 'MEAL', 'COPY')),
    CONSTRAINT ck_food_record_group_meal CHECK (
        meal_type IS NULL OR meal_type IN ('BREAKFAST', 'LUNCH', 'DINNER', 'SNACK')
    )
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Optional logical group of food records; individual food_record rows remain the facts.';

ALTER TABLE food_record
    ADD COLUMN group_id BIGINT UNSIGNED NULL AFTER food_id,
    ADD KEY idx_food_record_group (group_id),
    ADD CONSTRAINT fk_food_record_group
        FOREIGN KEY (group_id) REFERENCES food_record_group(id)
        ON DELETE SET NULL ON UPDATE RESTRICT;


-- ============================================================================
-- V1_2_0__create_food_photo.sql
-- ============================================================================
-- Fitness Platform / Product V1.2
-- Food photos are attachments, not nutrition facts.

CREATE TABLE food_photo (
    id                      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id                 BIGINT UNSIGNED NOT NULL,
    food_record_id          BIGINT UNSIGNED NULL,
    food_record_group_id    BIGINT UNSIGNED NULL,
    storage_provider        VARCHAR(32) NOT NULL DEFAULT 'S3_COMPATIBLE',
    object_key              VARCHAR(512) NOT NULL,
    original_filename       VARCHAR(255) NULL,
    mime_type               VARCHAR(100) NULL,
    size_bytes              BIGINT UNSIGNED NULL,
    sha256_hex              CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NULL,
    width_px                INT UNSIGNED NULL,
    height_px               INT UNSIGNED NULL,
    upload_status           VARCHAR(32) NOT NULL DEFAULT 'PENDING',
    uploaded_at             DATETIME(3) NULL,
    deleted_at              DATETIME(3) NULL,
    created_at              DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at              DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    UNIQUE KEY uk_food_photo_object_key (object_key),
    KEY idx_food_photo_user_created (user_id, created_at),
    KEY idx_food_photo_record (food_record_id),
    KEY idx_food_photo_group (food_record_group_id),

    CONSTRAINT fk_food_photo_user
        FOREIGN KEY (user_id) REFERENCES app_user(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_food_photo_record
        FOREIGN KEY (food_record_id) REFERENCES food_record(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_food_photo_group
        FOREIGN KEY (food_record_group_id) REFERENCES food_record_group(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_food_photo_target CHECK (
        (food_record_id IS NOT NULL AND food_record_group_id IS NULL) OR
        (food_record_id IS NULL AND food_record_group_id IS NOT NULL)
    ),
    CONSTRAINT ck_food_photo_upload_status CHECK (upload_status IN ('PENDING', 'READY', 'FAILED', 'DELETED'))
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Object-storage metadata for food record/group attachments.';


-- ============================================================================
-- V1_2_1__create_export_job.sql
-- ============================================================================
-- Fitness Platform / Product V1.2
-- Asynchronous export job metadata. QuerySpec remains a backend DTO and is stored as JSON only to reproduce a job.

CREATE TABLE export_job (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id             BIGINT UNSIGNED NOT NULL,
    request_id          VARCHAR(128) NOT NULL,
    export_scope        VARCHAR(32) NOT NULL,
    domain              VARCHAR(32) NOT NULL,
    format              VARCHAR(16) NOT NULL,
    include_photos      TINYINT(1) NOT NULL DEFAULT 0,
    query_spec_json     JSON NOT NULL,
    query_summary       VARCHAR(1000) NULL,
    status              VARCHAR(32) NOT NULL DEFAULT 'PENDING',
    result_object_key   VARCHAR(512) NULL,
    result_size_bytes   BIGINT UNSIGNED NULL,
    error_code          VARCHAR(100) NULL,
    error_message       VARCHAR(1000) NULL,
    started_at          DATETIME(3) NULL,
    finished_at         DATETIME(3) NULL,
    expires_at          DATETIME(3) NULL,
    created_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    UNIQUE KEY uk_export_job_user_request (user_id, request_id),
    KEY idx_export_job_user_created (user_id, created_at),
    KEY idx_export_job_status_created (status, created_at),
    KEY idx_export_job_expiry (expires_at),

    CONSTRAINT fk_export_job_user
        FOREIGN KEY (user_id) REFERENCES app_user(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_export_job_scope CHECK (export_scope IN ('CURRENT_RESULT', 'MY_DATA')),
    CONSTRAINT ck_export_job_domain CHECK (domain IN ('NUTRITION')),
    CONSTRAINT ck_export_job_format CHECK (format IN ('CSV', 'XLSX', 'ZIP')),
    CONSTRAINT ck_export_job_status CHECK (status IN ('PENDING', 'PROCESSING', 'SUCCEEDED', 'FAILED', 'EXPIRED'))
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Async export jobs. The exact QuerySpec used by analytics/export is persisted for reproducibility.';


-- ============================================================================
-- V2_0_0__create_ai_conversation_and_message.sql
-- ============================================================================
-- Fitness Platform / Product V2
-- Durable user-visible AI conversations/messages. Short-term semantic memory still lives in Redis.

CREATE TABLE ai_conversation (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id             BIGINT UNSIGNED NOT NULL,
    title               VARCHAR(200) NULL,
    status              VARCHAR(32) NOT NULL DEFAULT 'ACTIVE',
    last_message_at     DATETIME(3) NULL,
    created_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    KEY idx_ai_conversation_user_recent (user_id, status, last_message_at),

    CONSTRAINT fk_ai_conversation_user
        FOREIGN KEY (user_id) REFERENCES app_user(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_ai_conversation_status CHECK (status IN ('ACTIVE', 'ARCHIVED', 'DELETED'))
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Durable chat thread metadata for recent-conversation UI.';

CREATE TABLE ai_message (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    conversation_id     BIGINT UNSIGNED NOT NULL,
    role                VARCHAR(32) NOT NULL,
    content_type        VARCHAR(32) NOT NULL DEFAULT 'TEXT',
    content             LONGTEXT NULL,
    metadata_json       JSON NULL,
    created_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    KEY idx_ai_message_conversation_time (conversation_id, created_at, id),

    CONSTRAINT fk_ai_message_conversation
        FOREIGN KEY (conversation_id) REFERENCES ai_conversation(id)
        ON DELETE CASCADE ON UPDATE RESTRICT,
    CONSTRAINT ck_ai_message_role CHECK (role IN ('USER', 'ASSISTANT', 'TOOL', 'SYSTEM')),
    CONSTRAINT ck_ai_message_content_type CHECK (content_type IN ('TEXT', 'TOOL_RESULT', 'ACTION_PREVIEW', 'STATUS'))
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci
  COMMENT='User-visible conversation messages. Observability logs should not duplicate unnecessary sensitive message content.';


-- ============================================================================
-- V2_0_1__create_agent_trace.sql
-- ============================================================================
-- Fitness Platform / Product V2
-- Agent run and tool trace metadata.

CREATE TABLE ai_agent_run (
    id                      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id                 BIGINT UNSIGNED NOT NULL,
    conversation_id         BIGINT UNSIGNED NOT NULL,
    user_message_id         BIGINT UNSIGNED NULL,
    assistant_message_id    BIGINT UNSIGNED NULL,
    request_id              VARCHAR(128) NOT NULL,
    intent                  VARCHAR(64) NULL,
    status                  VARCHAR(32) NOT NULL DEFAULT 'STARTED',
    structured_output_json  JSON NULL COMMENT 'Sanitized structured output; do not store secrets.',
    error_code              VARCHAR(100) NULL,
    error_message           VARCHAR(1000) NULL,
    started_at              DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    completed_at            DATETIME(3) NULL,
    latency_ms              BIGINT UNSIGNED NULL,
    created_at              DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    UNIQUE KEY uk_ai_agent_run_user_request (user_id, request_id),
    KEY idx_ai_agent_run_conversation (conversation_id, created_at),
    KEY idx_ai_agent_run_status_created (status, created_at),

    CONSTRAINT fk_ai_agent_run_user
        FOREIGN KEY (user_id) REFERENCES app_user(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_ai_agent_run_conversation
        FOREIGN KEY (conversation_id) REFERENCES ai_conversation(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_ai_agent_run_user_message
        FOREIGN KEY (user_message_id) REFERENCES ai_message(id)
        ON DELETE SET NULL ON UPDATE RESTRICT,
    CONSTRAINT fk_ai_agent_run_assistant_message
        FOREIGN KEY (assistant_message_id) REFERENCES ai_message(id)
        ON DELETE SET NULL ON UPDATE RESTRICT,
    CONSTRAINT ck_ai_agent_run_status CHECK (status IN ('STARTED', 'RUNNING', 'WAITING_CONFIRMATION', 'SUCCEEDED', 'FAILED', 'CANCELLED'))
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci
  COMMENT='One end-to-end agent execution for traceability.';

CREATE TABLE ai_tool_call (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    agent_run_id        BIGINT UNSIGNED NOT NULL,
    tool_call_key       VARCHAR(128) NULL,
    tool_name           VARCHAR(128) NOT NULL,
    status              VARCHAR(32) NOT NULL DEFAULT 'STARTED',
    request_json        JSON NULL COMMENT 'Sanitized tool arguments.',
    response_json       JSON NULL COMMENT 'Sanitized tool result summary, not raw secrets.',
    resource_type       VARCHAR(64) NULL,
    resource_id         VARCHAR(128) NULL,
    error_code          VARCHAR(100) NULL,
    error_message       VARCHAR(1000) NULL,
    started_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    completed_at        DATETIME(3) NULL,
    latency_ms          BIGINT UNSIGNED NULL,

    PRIMARY KEY (id),
    KEY idx_ai_tool_call_run (agent_run_id, id),
    KEY idx_ai_tool_call_name_status (tool_name, status, started_at),

    CONSTRAINT fk_ai_tool_call_run
        FOREIGN KEY (agent_run_id) REFERENCES ai_agent_run(id)
        ON DELETE CASCADE ON UPDATE RESTRICT,
    CONSTRAINT ck_ai_tool_call_status CHECK (status IN ('STARTED', 'SUCCEEDED', 'FAILED', 'CANCELLED'))
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Per-tool execution trace inside an agent run.';


-- ============================================================================
-- V2_0_2__create_ai_action_audit.sql
-- ============================================================================
-- Fitness Platform / Product V2
-- Durable audit metadata for Preview -> Confirm -> Execute lifecycle.
-- The authoritative pending payload is stored in Redis as required by the PRD.

CREATE TABLE ai_action_audit (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    action_id           CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    user_id             BIGINT UNSIGNED NOT NULL,
    conversation_id     BIGINT UNSIGNED NOT NULL,
    agent_run_id        BIGINT UNSIGNED NULL,
    intent              VARCHAR(64) NOT NULL,
    preview_version     INT UNSIGNED NOT NULL DEFAULT 1,
    payload_digest      CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NULL,
    status              VARCHAR(32) NOT NULL DEFAULT 'PARSED',
    request_id          VARCHAR(128) NULL,
    resource_type       VARCHAR(64) NULL,
    resource_id         VARCHAR(128) NULL,
    expires_at          DATETIME(3) NULL,
    confirmed_at        DATETIME(3) NULL,
    executed_at         DATETIME(3) NULL,
    error_code          VARCHAR(100) NULL,
    error_message       VARCHAR(1000) NULL,
    created_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    UNIQUE KEY uk_ai_action_action_id (action_id),
    KEY idx_ai_action_user_created (user_id, created_at),
    KEY idx_ai_action_conversation (conversation_id, created_at),
    KEY idx_ai_action_status_expiry (status, expires_at),

    CONSTRAINT fk_ai_action_user
        FOREIGN KEY (user_id) REFERENCES app_user(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_ai_action_conversation
        FOREIGN KEY (conversation_id) REFERENCES ai_conversation(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_ai_action_agent_run
        FOREIGN KEY (agent_run_id) REFERENCES ai_agent_run(id)
        ON DELETE SET NULL ON UPDATE RESTRICT,
    CONSTRAINT ck_ai_action_status CHECK (
        status IN ('PARSED', 'RESOLVING', 'READY_FOR_CONFIRMATION', 'CONFIRMED', 'EXECUTING', 'SUCCEEDED', 'FAILED', 'CANCELLED')
    )
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Durable lifecycle/audit metadata. Redis stores short-lived pending action parameters.';


-- ============================================================================
-- V2_1_0__create_knowledge_metadata.sql
-- ============================================================================
-- Fitness Platform / Product V2.1
-- MySQL stores RAG document/chunk metadata and text; embeddings remain in a vector store.

CREATE TABLE knowledge_document (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    title               VARCHAR(500) NOT NULL,
    category            VARCHAR(100) NULL,
    topic               VARCHAR(200) NULL,
    source_name         VARCHAR(500) NULL,
    author              VARCHAR(300) NULL,
    language_code       VARCHAR(16) NULL,
    source_url          VARCHAR(1024) NULL,
    license_status      VARCHAR(64) NULL,
    created_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    KEY idx_knowledge_document_category_topic (category, topic),
    KEY idx_knowledge_document_title (title(191))
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Stable logical knowledge document identity.';

CREATE TABLE knowledge_document_version (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    document_id         BIGINT UNSIGNED NOT NULL,
    version_label       VARCHAR(64) NOT NULL,
    publish_date        DATE NULL,
    review_status       VARCHAR(32) NOT NULL DEFAULT 'DRAFT',
    effective_status    VARCHAR(32) NOT NULL DEFAULT 'INACTIVE',
    content_hash        CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NULL,
    source_object_key   VARCHAR(512) NULL,
    reviewed_by_user_id BIGINT UNSIGNED NULL,
    reviewed_at         DATETIME(3) NULL,
    created_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    UNIQUE KEY uk_knowledge_doc_version (document_id, version_label),
    KEY idx_knowledge_version_status (review_status, effective_status, created_at),

    CONSTRAINT fk_knowledge_version_document
        FOREIGN KEY (document_id) REFERENCES knowledge_document(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_knowledge_version_reviewer
        FOREIGN KEY (reviewed_by_user_id) REFERENCES app_user(id)
        ON DELETE SET NULL ON UPDATE RESTRICT,
    CONSTRAINT ck_knowledge_review_status CHECK (review_status IN ('DRAFT', 'REVIEWING', 'APPROVED', 'REJECTED')),
    CONSTRAINT ck_knowledge_effective_status CHECK (effective_status IN ('INACTIVE', 'ACTIVE', 'EXPIRED'))
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Versioned knowledge content; production retrieval should use APPROVED + ACTIVE versions.';

CREATE TABLE knowledge_chunk (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    document_version_id BIGINT UNSIGNED NOT NULL,
    chunk_index         INT UNSIGNED NOT NULL,
    heading             VARCHAR(500) NULL,
    topic               VARCHAR(200) NULL,
    content             MEDIUMTEXT NOT NULL,
    token_count         INT UNSIGNED NULL,
    content_hash        CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NULL,
    vector_store        VARCHAR(64) NULL,
    vector_ref          VARCHAR(255) NULL,
    embedding_model     VARCHAR(128) NULL,
    index_version       VARCHAR(64) NULL,
    status              VARCHAR(32) NOT NULL DEFAULT 'READY',
    created_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    UNIQUE KEY uk_knowledge_chunk_version_index (document_version_id, chunk_index),
    KEY idx_knowledge_chunk_index_version (index_version, status),
    KEY idx_knowledge_chunk_vector_ref (vector_store, vector_ref),

    CONSTRAINT fk_knowledge_chunk_version
        FOREIGN KEY (document_version_id) REFERENCES knowledge_document_version(id)
        ON DELETE CASCADE ON UPDATE RESTRICT,
    CONSTRAINT ck_knowledge_chunk_status CHECK (status IN ('PENDING', 'READY', 'FAILED', 'DISABLED'))
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci
  COMMENT='RAG chunk text and vector-store pointer. No vector blob is required in MySQL.';


-- ============================================================================
-- V2_1_1__create_rag_trace.sql
-- ============================================================================
-- Fitness Platform / Product V2.1
-- Retrieval/re-rank trace linked back to the V2 agent run.

CREATE TABLE rag_run (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    agent_run_id        BIGINT UNSIGNED NULL,
    original_query      TEXT NOT NULL,
    rewritten_query     TEXT NULL,
    index_version       VARCHAR(64) NULL,
    top_k               INT UNSIGNED NULL,
    relevance_threshold DECIMAL(8,6) NULL,
    status              VARCHAR(32) NOT NULL DEFAULT 'STARTED',
    error_code          VARCHAR(100) NULL,
    started_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    completed_at        DATETIME(3) NULL,
    latency_ms          BIGINT UNSIGNED NULL,

    PRIMARY KEY (id),
    KEY idx_rag_run_agent (agent_run_id, id),
    KEY idx_rag_run_status_started (status, started_at),

    CONSTRAINT fk_rag_run_agent
        FOREIGN KEY (agent_run_id) REFERENCES ai_agent_run(id)
        ON DELETE SET NULL ON UPDATE RESTRICT,
    CONSTRAINT ck_rag_run_status CHECK (status IN ('STARTED', 'SUCCEEDED', 'FAILED', 'NO_RELIABLE_RESULT'))
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci
  COMMENT='One RAG retrieval/rerank execution.';

CREATE TABLE rag_retrieval_item (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    rag_run_id          BIGINT UNSIGNED NOT NULL,
    chunk_id            BIGINT UNSIGNED NOT NULL,
    retrieval_rank      INT UNSIGNED NULL,
    retrieval_score     DECIMAL(10,8) NULL,
    rerank_rank         INT UNSIGNED NULL,
    rerank_score        DECIMAL(10,8) NULL,
    selected            TINYINT(1) NOT NULL DEFAULT 0,
    created_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    UNIQUE KEY uk_rag_retrieval_run_chunk (rag_run_id, chunk_id),
    KEY idx_rag_retrieval_selected (rag_run_id, selected, rerank_rank),

    CONSTRAINT fk_rag_retrieval_run
        FOREIGN KEY (rag_run_id) REFERENCES rag_run(id)
        ON DELETE CASCADE ON UPDATE RESTRICT,
    CONSTRAINT fk_rag_retrieval_chunk
        FOREIGN KEY (chunk_id) REFERENCES knowledge_chunk(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Chunks considered by retrieval/rerank and whether they were selected for answer composition.';


-- ============================================================================
-- V3_0_0__create_exercise_library.sql
-- ============================================================================
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


-- ============================================================================
-- V3_0_1__create_workout_routine.sql
-- ============================================================================
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


-- ============================================================================
-- V3_0_2__create_training_plan_versioning.sql
-- ============================================================================
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


-- ============================================================================
-- V3_0_3__create_scheduled_workout.sql
-- ============================================================================
-- Fitness Platform / Product V3
-- Concrete calendar projection from immutable plan versions.

CREATE TABLE scheduled_workout (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id             BIGINT UNSIGNED NOT NULL,
    plan_id             BIGINT UNSIGNED NOT NULL,
    plan_version_id     BIGINT UNSIGNED NOT NULL,
    schedule_item_id    BIGINT UNSIGNED NOT NULL,
    scheduled_date      DATE NOT NULL,
    title_snapshot      VARCHAR(200) NULL,
    category_snapshot   VARCHAR(100) NULL,
    item_type           VARCHAR(32) NOT NULL,
    status              VARCHAR(32) NOT NULL DEFAULT 'PLANNED',
    created_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    UNIQUE KEY uk_scheduled_workout_projection (plan_id, plan_version_id, schedule_item_id, scheduled_date),
    KEY idx_scheduled_workout_user_date (user_id, scheduled_date, status),
    KEY idx_scheduled_workout_plan_date (plan_id, scheduled_date),

    CONSTRAINT fk_scheduled_workout_user
        FOREIGN KEY (user_id) REFERENCES app_user(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_scheduled_workout_plan
        FOREIGN KEY (plan_id) REFERENCES training_plan(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_scheduled_workout_version
        FOREIGN KEY (plan_version_id) REFERENCES training_plan_version(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_scheduled_workout_item
        FOREIGN KEY (schedule_item_id) REFERENCES training_plan_schedule_item(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_scheduled_workout_type CHECK (item_type IN ('WORKOUT', 'REST')),
    CONSTRAINT ck_scheduled_workout_status CHECK (status IN ('PLANNED', 'COMPLETED', 'SKIPPED', 'CANCELLED'))
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Calendar projection. Missed items are not moved automatically.';


-- ============================================================================
-- V3_0_4__create_workout_session.sql
-- ============================================================================
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


-- ============================================================================
-- V3_5_0__add_training_analytics_indexes.sql
-- ============================================================================
-- Fitness Platform / Product V3.5
-- No new source-of-truth tables are required for first-release analytics.
-- Add read-path indexes only; PR/volume/frequency/completion remain derivable from raw facts.

CREATE INDEX idx_scheduled_workout_user_plan_date_status
    ON scheduled_workout(user_id, plan_id, scheduled_date, status);

CREATE INDEX idx_workout_session_category_day
    ON workout_session(user_id, category, business_date, status, deleted_at);

CREATE INDEX idx_session_exercise_snapshot_muscle
    ON workout_session_exercise(primary_muscle_snapshot, exercise_id, session_id);

-- V3.5 extends the existing Export Service to training data.
ALTER TABLE export_job
    DROP CHECK ck_export_job_domain,
    ADD CONSTRAINT ck_export_job_domain_v35 CHECK (domain IN ('NUTRITION', 'TRAINING', 'ALL'));


-- ============================================================================
-- V3_6_0__harden_core_ownership_and_time_context.sql
-- ============================================================================
-- Fitness Platform / Product V3.6 hardening
-- Cross-user ownership integrity for Nutrition attachments/groups, source invariants,
-- and write-time timezone provenance for business_date.
--
-- Run examples/V3_6_preflight_checks.sql before this migration on an existing database.

-- Food source semantics become database-enforced after V1.1.
ALTER TABLE food
    ADD CONSTRAINT ck_food_source_type_v36 CHECK (
        source_type IN ('SYSTEM', 'THIRD_PARTY', 'USER_CUSTOM')
    ),
    ADD CONSTRAINT ck_food_source_owner_v36 CHECK (
        (source_type = 'SYSTEM'
            AND owner_user_id IS NULL
            AND source_provider IS NULL
            AND source_external_id IS NULL)
        OR
        (source_type = 'THIRD_PARTY'
            AND owner_user_id IS NULL
            AND source_provider IS NOT NULL
            AND source_external_id IS NOT NULL)
        OR
        (source_type = 'USER_CUSTOM'
            AND owner_user_id IS NOT NULL
            AND source_provider IS NULL
            AND source_external_id IS NULL)
    );

-- Preserve the timezone that produced business_date for all new writes.
-- Nullable is intentional for legacy rows: backfilling from the user's *current* timezone
-- would fabricate historical provenance if the user has changed timezone since the record.
ALTER TABLE food_record
    ADD COLUMN business_timezone_id VARCHAR(64) NULL AFTER business_date;

ALTER TABLE food_record_group
    ADD COLUMN business_timezone_id VARCHAR(64) NULL AFTER business_date;

-- Composite parent keys allow MySQL to enforce that a child carrying user_id cannot
-- reference a resource owned by another user.
ALTER TABLE food_record_group
    ADD UNIQUE KEY uk_food_record_group_user_id (user_id, id);

ALTER TABLE food_record
    ADD UNIQUE KEY uk_food_record_user_id (user_id, id),
    ADD KEY idx_food_record_user_group (user_id, group_id),
    DROP FOREIGN KEY fk_food_record_group,
    ADD CONSTRAINT fk_food_record_group_owner_v36
        FOREIGN KEY (user_id, group_id)
        REFERENCES food_record_group(user_id, id)
        ON DELETE RESTRICT ON UPDATE RESTRICT;

ALTER TABLE food_photo
    ADD KEY idx_food_photo_user_record (user_id, food_record_id),
    ADD KEY idx_food_photo_user_group (user_id, food_record_group_id),
    DROP FOREIGN KEY fk_food_photo_record,
    DROP FOREIGN KEY fk_food_photo_group,
    ADD CONSTRAINT fk_food_photo_record_owner_v36
        FOREIGN KEY (user_id, food_record_id)
        REFERENCES food_record(user_id, id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    ADD CONSTRAINT fk_food_photo_group_owner_v36
        FOREIGN KEY (user_id, food_record_group_id)
        REFERENCES food_record_group(user_id, id)
        ON DELETE RESTRICT ON UPDATE RESTRICT;


-- ============================================================================
-- V3_6_1__harden_ai_relational_integrity.sql
-- ============================================================================
-- Fitness Platform / Product V3.6 hardening
-- Bind AI runs/actions/messages to one conversation owner and one conversation chain.

ALTER TABLE ai_conversation
    ADD UNIQUE KEY uk_ai_conversation_user_id (user_id, id);

ALTER TABLE ai_message
    ADD UNIQUE KEY uk_ai_message_conversation_id (conversation_id, id);

ALTER TABLE ai_agent_run
    ADD UNIQUE KEY uk_ai_agent_run_user_conversation_id (user_id, conversation_id, id),
    ADD KEY idx_ai_agent_run_conversation_user_message (conversation_id, user_message_id),
    ADD KEY idx_ai_agent_run_conversation_assistant_message (conversation_id, assistant_message_id),
    DROP FOREIGN KEY fk_ai_agent_run_conversation,
    DROP FOREIGN KEY fk_ai_agent_run_user_message,
    DROP FOREIGN KEY fk_ai_agent_run_assistant_message,
    ADD CONSTRAINT fk_ai_agent_run_conversation_owner_v36
        FOREIGN KEY (user_id, conversation_id)
        REFERENCES ai_conversation(user_id, id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    ADD CONSTRAINT fk_ai_agent_run_user_message_v36
        FOREIGN KEY (conversation_id, user_message_id)
        REFERENCES ai_message(conversation_id, id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    ADD CONSTRAINT fk_ai_agent_run_assistant_message_v36
        FOREIGN KEY (conversation_id, assistant_message_id)
        REFERENCES ai_message(conversation_id, id)
        ON DELETE RESTRICT ON UPDATE RESTRICT;

ALTER TABLE ai_action_audit
    ADD KEY idx_ai_action_user_conversation_run (user_id, conversation_id, agent_run_id),
    DROP FOREIGN KEY fk_ai_action_conversation,
    DROP FOREIGN KEY fk_ai_action_agent_run,
    ADD CONSTRAINT fk_ai_action_conversation_owner_v36
        FOREIGN KEY (user_id, conversation_id)
        REFERENCES ai_conversation(user_id, id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    ADD CONSTRAINT fk_ai_action_agent_run_chain_v36
        FOREIGN KEY (user_id, conversation_id, agent_run_id)
        REFERENCES ai_agent_run(user_id, conversation_id, id)
        ON DELETE RESTRICT ON UPDATE RESTRICT;


-- ============================================================================
-- V3_6_2__harden_training_relational_integrity.sql
-- ============================================================================
-- Fitness Platform / Product V3.6 hardening
-- Enforce training plan/version/schedule ownership and locator consistency.

ALTER TABLE exercise
    ADD CONSTRAINT ck_exercise_source_type_v36 CHECK (
        source_type IN ('SYSTEM', 'USER_CUSTOM')
    ),
    ADD CONSTRAINT ck_exercise_source_owner_v36 CHECK (
        (source_type = 'SYSTEM' AND owner_user_id IS NULL)
        OR
        (source_type = 'USER_CUSTOM' AND owner_user_id IS NOT NULL)
    );

ALTER TABLE training_plan
    ADD COLUMN current_version_id BIGINT UNSIGNED NULL AFTER status,
    ADD UNIQUE KEY uk_training_plan_user_id (user_id, id);

-- cycle_length_key is an ordinary integrity helper, not a business field.
-- 0 represents DATE_SPECIFIC's NULL cycle length so the composite FK below never skips
-- validation because of SQL NULL semantics.
ALTER TABLE training_plan_version
    ADD COLUMN cycle_length_key INT UNSIGNED NULL AFTER cycle_length_days;

UPDATE training_plan_version
SET cycle_length_key = COALESCE(cycle_length_days, 0);

ALTER TABLE training_plan_version
    MODIFY COLUMN cycle_length_key INT UNSIGNED NOT NULL,
    ADD UNIQUE KEY uk_training_plan_version_plan_id (plan_id, id),
    ADD UNIQUE KEY uk_training_plan_version_plan_id_no (plan_id, id, version_no),
    ADD UNIQUE KEY uk_training_plan_version_locator_signature (id, schedule_type, cycle_length_key),
    ADD CONSTRAINT ck_training_plan_version_no_positive_v36 CHECK (version_no > 0),
    ADD CONSTRAINT ck_training_plan_version_cycle_key_v36 CHECK (
        cycle_length_key = COALESCE(cycle_length_days, 0)
    ),
    ADD CONSTRAINT ck_training_plan_version_weekly_cycle_v36 CHECK (
        schedule_type <> 'WEEKLY' OR cycle_length_days = 7
    );

-- Backfill the new FK target without inventing a version. If legacy current_version_no is
-- inconsistent, the CHECK/FK added below intentionally causes migration failure after
-- preflight has identified the row.
UPDATE training_plan p
JOIN training_plan_version v
  ON v.plan_id = p.id
 AND v.version_no = p.current_version_no
SET p.current_version_id = v.id
WHERE p.current_version_no > 0;

ALTER TABLE training_plan
    ADD CONSTRAINT ck_training_plan_current_version_pair_v36 CHECK (
        (current_version_id IS NULL AND current_version_no = 0)
        OR
        (current_version_id IS NOT NULL AND current_version_no > 0)
    ),
    ADD CONSTRAINT fk_training_plan_current_version_v36
        FOREIGN KEY (id, current_version_id, current_version_no)
        REFERENCES training_plan_version(plan_id, id, version_no)
        ON DELETE RESTRICT ON UPDATE RESTRICT;

-- Snapshot the version locator semantics onto each schedule item so MySQL can validate
-- cycle/date semantics with row-local CHECK constraints.
ALTER TABLE training_plan_schedule_item
    ADD COLUMN schedule_type_snapshot VARCHAR(32) NULL AFTER source_routine_id,
    ADD COLUMN cycle_length_days_snapshot INT UNSIGNED NULL AFTER schedule_type_snapshot,
    ADD COLUMN cycle_length_key_snapshot INT UNSIGNED NULL AFTER cycle_length_days_snapshot;

UPDATE training_plan_schedule_item i
JOIN training_plan_version v ON v.id = i.plan_version_id
SET i.schedule_type_snapshot = v.schedule_type,
    i.cycle_length_days_snapshot = v.cycle_length_days,
    i.cycle_length_key_snapshot = COALESCE(v.cycle_length_days, 0);

ALTER TABLE training_plan_schedule_item
    MODIFY COLUMN schedule_type_snapshot VARCHAR(32) NOT NULL,
    MODIFY COLUMN cycle_length_key_snapshot INT UNSIGNED NOT NULL,
    ADD UNIQUE KEY uk_plan_schedule_item_version_id (plan_version_id, id),
    ADD UNIQUE KEY uk_plan_schedule_item_id_type (id, item_type),
    ADD KEY idx_plan_schedule_item_locator_signature (
        plan_version_id, schedule_type_snapshot, cycle_length_key_snapshot
    ),
    DROP FOREIGN KEY fk_plan_schedule_item_version,
    DROP CHECK ck_plan_schedule_item_locator,
    ADD CONSTRAINT fk_plan_schedule_item_locator_version_v36
        FOREIGN KEY (plan_version_id, schedule_type_snapshot, cycle_length_key_snapshot)
        REFERENCES training_plan_version(id, schedule_type, cycle_length_key)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    ADD CONSTRAINT ck_plan_schedule_item_cycle_key_v36 CHECK (
        cycle_length_key_snapshot = COALESCE(cycle_length_days_snapshot, 0)
    ),
    ADD CONSTRAINT ck_plan_schedule_item_locator_v36 CHECK (
        (
            schedule_type_snapshot = 'DATE_SPECIFIC'
            AND specific_date IS NOT NULL
            AND cycle_day_no IS NULL
            AND cycle_length_days_snapshot IS NULL
        )
        OR
        (
            schedule_type_snapshot IN ('REPEATING_CYCLE', 'WEEKLY')
            AND specific_date IS NULL
            AND cycle_day_no IS NOT NULL
            AND cycle_length_days_snapshot IS NOT NULL
            AND cycle_day_no >= 1
            AND cycle_day_no <= cycle_length_days_snapshot
        )
    ),
    ADD CONSTRAINT ck_plan_schedule_item_weekly_cycle_v36 CHECK (
        schedule_type_snapshot <> 'WEEKLY' OR cycle_length_days_snapshot = 7
    );

ALTER TABLE scheduled_workout
    ADD UNIQUE KEY uk_scheduled_workout_user_id (user_id, id),
    ADD UNIQUE KEY uk_scheduled_workout_user_id_type (user_id, id, item_type),
    ADD KEY idx_scheduled_workout_user_plan (user_id, plan_id),
    ADD KEY idx_scheduled_workout_plan_version (plan_id, plan_version_id),
    ADD KEY idx_scheduled_workout_version_item (plan_version_id, schedule_item_id),
    ADD KEY idx_scheduled_workout_item_type (schedule_item_id, item_type),
    DROP FOREIGN KEY fk_scheduled_workout_plan,
    DROP FOREIGN KEY fk_scheduled_workout_version,
    DROP FOREIGN KEY fk_scheduled_workout_item,
    ADD CONSTRAINT fk_scheduled_workout_plan_owner_v36
        FOREIGN KEY (user_id, plan_id)
        REFERENCES training_plan(user_id, id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    ADD CONSTRAINT fk_scheduled_workout_plan_version_v36
        FOREIGN KEY (plan_id, plan_version_id)
        REFERENCES training_plan_version(plan_id, id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    ADD CONSTRAINT fk_scheduled_workout_version_item_v36
        FOREIGN KEY (plan_version_id, schedule_item_id)
        REFERENCES training_plan_schedule_item(plan_version_id, id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    ADD CONSTRAINT fk_scheduled_workout_item_type_v36
        FOREIGN KEY (schedule_item_id, item_type)
        REFERENCES training_plan_schedule_item(id, item_type)
        ON DELETE RESTRICT ON UPDATE RESTRICT;

ALTER TABLE workout_session
    ADD COLUMN source_scheduled_item_type VARCHAR(32) NULL AFTER source_scheduled_workout_id,
    ADD COLUMN business_timezone_id VARCHAR(64) NULL AFTER business_date;

UPDATE workout_session ws
JOIN scheduled_workout sw ON sw.id = ws.source_scheduled_workout_id
SET ws.source_scheduled_item_type = sw.item_type
WHERE ws.source_scheduled_workout_id IS NOT NULL;

ALTER TABLE workout_session
    ADD KEY idx_workout_session_user_schedule_type (
        user_id, source_scheduled_workout_id, source_scheduled_item_type
    ),
    DROP FOREIGN KEY fk_workout_session_schedule,
    ADD CONSTRAINT fk_workout_session_schedule_owner_type_v36
        FOREIGN KEY (user_id, source_scheduled_workout_id, source_scheduled_item_type)
        REFERENCES scheduled_workout(user_id, id, item_type)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    ADD CONSTRAINT ck_workout_session_source_relation_v36 CHECK (
        (
            source_type = 'FREE'
            AND source_scheduled_workout_id IS NULL
            AND source_scheduled_item_type IS NULL
        )
        OR
        (
            source_type = 'PLAN'
            AND source_scheduled_workout_id IS NOT NULL
            AND source_scheduled_item_type = 'WORKOUT'
        )
    );


-- ============================================================================
-- V3_6_3__harden_rag_version_integrity.sql
-- ============================================================================
-- Fitness Platform / Product V3.6 hardening
-- Ensure at most one production-active approved version per knowledge document,
-- and freeze approved knowledge text while still allowing vector-index metadata refreshes.

ALTER TABLE knowledge_document_version
    ADD COLUMN active_approved_document_id BIGINT UNSIGNED
        GENERATED ALWAYS AS (
            CASE
                WHEN review_status = 'APPROVED' AND effective_status = 'ACTIVE'
                THEN document_id
                ELSE NULL
            END
        ) STORED,
    ADD UNIQUE KEY uk_knowledge_one_active_approved_version (active_approved_document_id),
    ADD CONSTRAINT ck_knowledge_active_requires_approved_v36 CHECK (
        effective_status <> 'ACTIVE' OR review_status = 'APPROVED'
    );

DELIMITER $$

CREATE TRIGGER trg_knowledge_version_freeze_after_approval_v36
BEFORE UPDATE ON knowledge_document_version
FOR EACH ROW
BEGIN
    IF OLD.review_status = 'APPROVED' THEN
        IF NOT (NEW.document_id <=> OLD.document_id)
           OR NOT (NEW.version_label <=> OLD.version_label)
           OR NOT (NEW.publish_date <=> OLD.publish_date)
           OR NOT (NEW.content_hash <=> OLD.content_hash)
           OR NOT (NEW.source_object_key <=> OLD.source_object_key)
           OR NOT (NEW.reviewed_by_user_id <=> OLD.reviewed_by_user_id)
           OR NOT (NEW.reviewed_at <=> OLD.reviewed_at)
           OR NEW.review_status <> 'APPROVED' THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Approved knowledge document version content/identity is immutable; create a new version instead';
        END IF;
    END IF;
END$$

CREATE TRIGGER trg_knowledge_version_block_delete_after_approval_v36
BEFORE DELETE ON knowledge_document_version
FOR EACH ROW
BEGIN
    IF OLD.review_status = 'APPROVED' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot delete an approved knowledge version; expire it instead';
    END IF;
END$$

CREATE TRIGGER trg_knowledge_chunk_block_insert_into_approved_v36
BEFORE INSERT ON knowledge_chunk
FOR EACH ROW
BEGIN
    DECLARE v_review_status VARCHAR(32);

    SELECT review_status
      INTO v_review_status
      FROM knowledge_document_version
     WHERE id = NEW.document_version_id;

    IF v_review_status = 'APPROVED' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot add chunks to an approved knowledge version; create a new version instead';
    END IF;
END$$

CREATE TRIGGER trg_knowledge_chunk_freeze_text_after_approval_v36
BEFORE UPDATE ON knowledge_chunk
FOR EACH ROW
BEGIN
    DECLARE v_old_review_status VARCHAR(32);
    DECLARE v_new_review_status VARCHAR(32);

    SELECT review_status
      INTO v_old_review_status
      FROM knowledge_document_version
     WHERE id = OLD.document_version_id;

    SELECT review_status
      INTO v_new_review_status
      FROM knowledge_document_version
     WHERE id = NEW.document_version_id;

    IF v_old_review_status = 'APPROVED' THEN
        IF NOT (NEW.document_version_id <=> OLD.document_version_id)
           OR NOT (NEW.chunk_index <=> OLD.chunk_index)
           OR NOT (NEW.heading <=> OLD.heading)
           OR NOT (NEW.topic <=> OLD.topic)
           OR NOT (NEW.content <=> OLD.content)
           OR NOT (NEW.token_count <=> OLD.token_count)
           OR NOT (NEW.content_hash <=> OLD.content_hash) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Approved knowledge chunk text is immutable; only index/vector metadata may change';
        END IF;
    END IF;

    IF NEW.document_version_id <> OLD.document_version_id
       AND v_new_review_status = 'APPROVED' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot move a chunk into an approved knowledge version';
    END IF;
END$$

CREATE TRIGGER trg_knowledge_chunk_block_delete_after_approval_v36
BEFORE DELETE ON knowledge_chunk
FOR EACH ROW
BEGIN
    DECLARE v_review_status VARCHAR(32);

    SELECT review_status
      INTO v_review_status
      FROM knowledge_document_version
     WHERE id = OLD.document_version_id;

    IF v_review_status = 'APPROVED' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot delete chunks from an approved knowledge version; expire the version instead';
    END IF;
END$$

DELIMITER ;



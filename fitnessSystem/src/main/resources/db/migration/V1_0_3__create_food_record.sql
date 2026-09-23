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

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

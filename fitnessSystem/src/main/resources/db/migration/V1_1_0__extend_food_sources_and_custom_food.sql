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

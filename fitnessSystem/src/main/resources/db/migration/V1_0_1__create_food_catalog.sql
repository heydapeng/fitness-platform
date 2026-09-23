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

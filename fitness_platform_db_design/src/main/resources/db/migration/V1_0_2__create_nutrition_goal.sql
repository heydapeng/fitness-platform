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

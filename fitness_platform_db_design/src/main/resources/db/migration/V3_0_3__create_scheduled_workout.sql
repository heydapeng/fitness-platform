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

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

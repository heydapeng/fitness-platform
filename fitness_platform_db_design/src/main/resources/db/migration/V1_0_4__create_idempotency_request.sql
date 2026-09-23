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

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

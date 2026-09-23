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

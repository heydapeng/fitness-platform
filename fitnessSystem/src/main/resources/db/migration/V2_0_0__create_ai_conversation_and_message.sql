-- Fitness Platform / Product V2
-- Durable user-visible AI conversations/messages. Short-term semantic memory still lives in Redis.

CREATE TABLE ai_conversation (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id             BIGINT UNSIGNED NOT NULL,
    title               VARCHAR(200) NULL,
    status              VARCHAR(32) NOT NULL DEFAULT 'ACTIVE',
    last_message_at     DATETIME(3) NULL,
    created_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    KEY idx_ai_conversation_user_recent (user_id, status, last_message_at),

    CONSTRAINT fk_ai_conversation_user
        FOREIGN KEY (user_id) REFERENCES app_user(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_ai_conversation_status CHECK (status IN ('ACTIVE', 'ARCHIVED', 'DELETED'))
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Durable chat thread metadata for recent-conversation UI.';

CREATE TABLE ai_message (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    conversation_id     BIGINT UNSIGNED NOT NULL,
    role                VARCHAR(32) NOT NULL,
    content_type        VARCHAR(32) NOT NULL DEFAULT 'TEXT',
    content             LONGTEXT NULL,
    metadata_json       JSON NULL,
    created_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    KEY idx_ai_message_conversation_time (conversation_id, created_at, id),

    CONSTRAINT fk_ai_message_conversation
        FOREIGN KEY (conversation_id) REFERENCES ai_conversation(id)
        ON DELETE CASCADE ON UPDATE RESTRICT,
    CONSTRAINT ck_ai_message_role CHECK (role IN ('USER', 'ASSISTANT', 'TOOL', 'SYSTEM')),
    CONSTRAINT ck_ai_message_content_type CHECK (content_type IN ('TEXT', 'TOOL_RESULT', 'ACTION_PREVIEW', 'STATUS'))
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci
  COMMENT='User-visible conversation messages. Observability logs should not duplicate unnecessary sensitive message content.';

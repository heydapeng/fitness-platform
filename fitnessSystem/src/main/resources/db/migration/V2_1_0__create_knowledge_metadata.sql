-- Fitness Platform / Product V2.1
-- MySQL stores RAG document/chunk metadata and text; embeddings remain in a vector store.

CREATE TABLE knowledge_document (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    title               VARCHAR(500) NOT NULL,
    category            VARCHAR(100) NULL,
    topic               VARCHAR(200) NULL,
    source_name         VARCHAR(500) NULL,
    author              VARCHAR(300) NULL,
    language_code       VARCHAR(16) NULL,
    source_url          VARCHAR(1024) NULL,
    license_status      VARCHAR(64) NULL,
    created_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    KEY idx_knowledge_document_category_topic (category, topic),
    KEY idx_knowledge_document_title (title(191))
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Stable logical knowledge document identity.';

CREATE TABLE knowledge_document_version (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    document_id         BIGINT UNSIGNED NOT NULL,
    version_label       VARCHAR(64) NOT NULL,
    publish_date        DATE NULL,
    review_status       VARCHAR(32) NOT NULL DEFAULT 'DRAFT',
    effective_status    VARCHAR(32) NOT NULL DEFAULT 'INACTIVE',
    content_hash        CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NULL,
    source_object_key   VARCHAR(512) NULL,
    reviewed_by_user_id BIGINT UNSIGNED NULL,
    reviewed_at         DATETIME(3) NULL,
    created_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    UNIQUE KEY uk_knowledge_doc_version (document_id, version_label),
    KEY idx_knowledge_version_status (review_status, effective_status, created_at),

    CONSTRAINT fk_knowledge_version_document
        FOREIGN KEY (document_id) REFERENCES knowledge_document(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_knowledge_version_reviewer
        FOREIGN KEY (reviewed_by_user_id) REFERENCES app_user(id)
        ON DELETE SET NULL ON UPDATE RESTRICT,
    CONSTRAINT ck_knowledge_review_status CHECK (review_status IN ('DRAFT', 'REVIEWING', 'APPROVED', 'REJECTED')),
    CONSTRAINT ck_knowledge_effective_status CHECK (effective_status IN ('INACTIVE', 'ACTIVE', 'EXPIRED'))
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Versioned knowledge content; production retrieval should use APPROVED + ACTIVE versions.';

CREATE TABLE knowledge_chunk (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    document_version_id BIGINT UNSIGNED NOT NULL,
    chunk_index         INT UNSIGNED NOT NULL,
    heading             VARCHAR(500) NULL,
    topic               VARCHAR(200) NULL,
    content             MEDIUMTEXT NOT NULL,
    token_count         INT UNSIGNED NULL,
    content_hash        CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NULL,
    vector_store        VARCHAR(64) NULL,
    vector_ref          VARCHAR(255) NULL,
    embedding_model     VARCHAR(128) NULL,
    index_version       VARCHAR(64) NULL,
    status              VARCHAR(32) NOT NULL DEFAULT 'READY',
    created_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    UNIQUE KEY uk_knowledge_chunk_version_index (document_version_id, chunk_index),
    KEY idx_knowledge_chunk_index_version (index_version, status),
    KEY idx_knowledge_chunk_vector_ref (vector_store, vector_ref),

    CONSTRAINT fk_knowledge_chunk_version
        FOREIGN KEY (document_version_id) REFERENCES knowledge_document_version(id)
        ON DELETE CASCADE ON UPDATE RESTRICT,
    CONSTRAINT ck_knowledge_chunk_status CHECK (status IN ('PENDING', 'READY', 'FAILED', 'DISABLED'))
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci
  COMMENT='RAG chunk text and vector-store pointer. No vector blob is required in MySQL.';

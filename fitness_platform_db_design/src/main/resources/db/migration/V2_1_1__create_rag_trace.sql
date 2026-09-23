-- Fitness Platform / Product V2.1
-- Retrieval/re-rank trace linked back to the V2 agent run.

CREATE TABLE rag_run (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    agent_run_id        BIGINT UNSIGNED NULL,
    original_query      TEXT NOT NULL,
    rewritten_query     TEXT NULL,
    index_version       VARCHAR(64) NULL,
    top_k               INT UNSIGNED NULL,
    relevance_threshold DECIMAL(8,6) NULL,
    status              VARCHAR(32) NOT NULL DEFAULT 'STARTED',
    error_code          VARCHAR(100) NULL,
    started_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    completed_at        DATETIME(3) NULL,
    latency_ms          BIGINT UNSIGNED NULL,

    PRIMARY KEY (id),
    KEY idx_rag_run_agent (agent_run_id, id),
    KEY idx_rag_run_status_started (status, started_at),

    CONSTRAINT fk_rag_run_agent
        FOREIGN KEY (agent_run_id) REFERENCES ai_agent_run(id)
        ON DELETE SET NULL ON UPDATE RESTRICT,
    CONSTRAINT ck_rag_run_status CHECK (status IN ('STARTED', 'SUCCEEDED', 'FAILED', 'NO_RELIABLE_RESULT'))
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci
  COMMENT='One RAG retrieval/rerank execution.';

CREATE TABLE rag_retrieval_item (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    rag_run_id          BIGINT UNSIGNED NOT NULL,
    chunk_id            BIGINT UNSIGNED NOT NULL,
    retrieval_rank      INT UNSIGNED NULL,
    retrieval_score     DECIMAL(10,8) NULL,
    rerank_rank         INT UNSIGNED NULL,
    rerank_score        DECIMAL(10,8) NULL,
    selected            TINYINT(1) NOT NULL DEFAULT 0,
    created_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    UNIQUE KEY uk_rag_retrieval_run_chunk (rag_run_id, chunk_id),
    KEY idx_rag_retrieval_selected (rag_run_id, selected, rerank_rank),

    CONSTRAINT fk_rag_retrieval_run
        FOREIGN KEY (rag_run_id) REFERENCES rag_run(id)
        ON DELETE CASCADE ON UPDATE RESTRICT,
    CONSTRAINT fk_rag_retrieval_chunk
        FOREIGN KEY (chunk_id) REFERENCES knowledge_chunk(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Chunks considered by retrieval/rerank and whether they were selected for answer composition.';

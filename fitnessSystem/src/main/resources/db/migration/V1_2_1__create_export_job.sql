-- Fitness Platform / Product V1.2
-- Asynchronous export job metadata. QuerySpec remains a backend DTO and is stored as JSON only to reproduce a job.

CREATE TABLE export_job (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id             BIGINT UNSIGNED NOT NULL,
    request_id          VARCHAR(128) NOT NULL,
    export_scope        VARCHAR(32) NOT NULL,
    domain              VARCHAR(32) NOT NULL,
    format              VARCHAR(16) NOT NULL,
    include_photos      TINYINT(1) NOT NULL DEFAULT 0,
    query_spec_json     JSON NOT NULL,
    query_summary       VARCHAR(1000) NULL,
    status              VARCHAR(32) NOT NULL DEFAULT 'PENDING',
    result_object_key   VARCHAR(512) NULL,
    result_size_bytes   BIGINT UNSIGNED NULL,
    error_code          VARCHAR(100) NULL,
    error_message       VARCHAR(1000) NULL,
    started_at          DATETIME(3) NULL,
    finished_at         DATETIME(3) NULL,
    expires_at          DATETIME(3) NULL,
    created_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    UNIQUE KEY uk_export_job_user_request (user_id, request_id),
    KEY idx_export_job_user_created (user_id, created_at),
    KEY idx_export_job_status_created (status, created_at),
    KEY idx_export_job_expiry (expires_at),

    CONSTRAINT fk_export_job_user
        FOREIGN KEY (user_id) REFERENCES app_user(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_export_job_scope CHECK (export_scope IN ('CURRENT_RESULT', 'MY_DATA')),
    CONSTRAINT ck_export_job_domain CHECK (domain IN ('NUTRITION')),
    CONSTRAINT ck_export_job_format CHECK (format IN ('CSV', 'XLSX', 'ZIP')),
    CONSTRAINT ck_export_job_status CHECK (status IN ('PENDING', 'PROCESSING', 'SUCCEEDED', 'FAILED', 'EXPIRED'))
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Async export jobs. The exact QuerySpec used by analytics/export is persisted for reproducibility.';

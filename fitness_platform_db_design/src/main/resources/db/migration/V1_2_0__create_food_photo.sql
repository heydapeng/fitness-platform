-- Fitness Platform / Product V1.2
-- Food photos are attachments, not nutrition facts.

CREATE TABLE food_photo (
    id                      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id                 BIGINT UNSIGNED NOT NULL,
    food_record_id          BIGINT UNSIGNED NULL,
    food_record_group_id    BIGINT UNSIGNED NULL,
    storage_provider        VARCHAR(32) NOT NULL DEFAULT 'S3_COMPATIBLE',
    object_key              VARCHAR(512) NOT NULL,
    original_filename       VARCHAR(255) NULL,
    mime_type               VARCHAR(100) NULL,
    size_bytes              BIGINT UNSIGNED NULL,
    sha256_hex              CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NULL,
    width_px                INT UNSIGNED NULL,
    height_px               INT UNSIGNED NULL,
    upload_status           VARCHAR(32) NOT NULL DEFAULT 'PENDING',
    uploaded_at             DATETIME(3) NULL,
    deleted_at              DATETIME(3) NULL,
    created_at              DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at              DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    UNIQUE KEY uk_food_photo_object_key (object_key),
    KEY idx_food_photo_user_created (user_id, created_at),
    KEY idx_food_photo_record (food_record_id),
    KEY idx_food_photo_group (food_record_group_id),

    CONSTRAINT fk_food_photo_user
        FOREIGN KEY (user_id) REFERENCES app_user(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_food_photo_record
        FOREIGN KEY (food_record_id) REFERENCES food_record(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_food_photo_group
        FOREIGN KEY (food_record_group_id) REFERENCES food_record_group(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_food_photo_target CHECK (
        (food_record_id IS NOT NULL AND food_record_group_id IS NULL) OR
        (food_record_id IS NULL AND food_record_group_id IS NOT NULL)
    ),
    CONSTRAINT ck_food_photo_upload_status CHECK (upload_status IN ('PENDING', 'READY', 'FAILED', 'DELETED'))
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Object-storage metadata for food record/group attachments.';

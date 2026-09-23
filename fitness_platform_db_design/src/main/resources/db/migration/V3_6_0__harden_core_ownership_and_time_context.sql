-- Fitness Platform / Product V3.6 hardening
-- Cross-user ownership integrity for Nutrition attachments/groups, source invariants,
-- and write-time timezone provenance for business_date.
--
-- Run examples/V3_6_preflight_checks.sql before this migration on an existing database.

-- Food source semantics become database-enforced after V1.1.
ALTER TABLE food
    ADD CONSTRAINT ck_food_source_type_v36 CHECK (
        source_type IN ('SYSTEM', 'THIRD_PARTY', 'USER_CUSTOM')
    ),
    ADD CONSTRAINT ck_food_source_owner_v36 CHECK (
        (source_type = 'SYSTEM'
            AND owner_user_id IS NULL
            AND source_provider IS NULL
            AND source_external_id IS NULL)
        OR
        (source_type = 'THIRD_PARTY'
            AND owner_user_id IS NULL
            AND source_provider IS NOT NULL
            AND source_external_id IS NOT NULL)
        OR
        (source_type = 'USER_CUSTOM'
            AND owner_user_id IS NOT NULL
            AND source_provider IS NULL
            AND source_external_id IS NULL)
    );

-- Preserve the timezone that produced business_date for all new writes.
-- Nullable is intentional for legacy rows: backfilling from the user's *current* timezone
-- would fabricate historical provenance if the user has changed timezone since the record.
ALTER TABLE food_record
    ADD COLUMN business_timezone_id VARCHAR(64) NULL AFTER business_date;

ALTER TABLE food_record_group
    ADD COLUMN business_timezone_id VARCHAR(64) NULL AFTER business_date;

-- Composite parent keys allow MySQL to enforce that a child carrying user_id cannot
-- reference a resource owned by another user.
ALTER TABLE food_record_group
    ADD UNIQUE KEY uk_food_record_group_user_id (user_id, id);

ALTER TABLE food_record
    ADD UNIQUE KEY uk_food_record_user_id (user_id, id),
    ADD KEY idx_food_record_user_group (user_id, group_id),
    DROP FOREIGN KEY fk_food_record_group,
    ADD CONSTRAINT fk_food_record_group_owner_v36
        FOREIGN KEY (user_id, group_id)
        REFERENCES food_record_group(user_id, id)
        ON DELETE RESTRICT ON UPDATE RESTRICT;

ALTER TABLE food_photo
    ADD KEY idx_food_photo_user_record (user_id, food_record_id),
    ADD KEY idx_food_photo_user_group (user_id, food_record_group_id),
    DROP FOREIGN KEY fk_food_photo_record,
    DROP FOREIGN KEY fk_food_photo_group,
    ADD CONSTRAINT fk_food_photo_record_owner_v36
        FOREIGN KEY (user_id, food_record_id)
        REFERENCES food_record(user_id, id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    ADD CONSTRAINT fk_food_photo_group_owner_v36
        FOREIGN KEY (user_id, food_record_group_id)
        REFERENCES food_record_group(user_id, id)
        ON DELETE RESTRICT ON UPDATE RESTRICT;

-- Fitness Platform / Product V3.6 hardening
-- Enforce training plan/version/schedule ownership and locator consistency.

ALTER TABLE exercise
    ADD CONSTRAINT ck_exercise_source_type_v36 CHECK (
        source_type IN ('SYSTEM', 'USER_CUSTOM')
    ),
    ADD CONSTRAINT ck_exercise_source_owner_v36 CHECK (
        (source_type = 'SYSTEM' AND owner_user_id IS NULL)
        OR
        (source_type = 'USER_CUSTOM' AND owner_user_id IS NOT NULL)
    );

ALTER TABLE training_plan
    ADD COLUMN current_version_id BIGINT UNSIGNED NULL AFTER status,
    ADD UNIQUE KEY uk_training_plan_user_id (user_id, id);

-- cycle_length_key is an ordinary integrity helper, not a business field.
-- 0 represents DATE_SPECIFIC's NULL cycle length so the composite FK below never skips
-- validation because of SQL NULL semantics.
ALTER TABLE training_plan_version
    ADD COLUMN cycle_length_key INT UNSIGNED NULL AFTER cycle_length_days;

UPDATE training_plan_version
SET cycle_length_key = COALESCE(cycle_length_days, 0);

ALTER TABLE training_plan_version
    MODIFY COLUMN cycle_length_key INT UNSIGNED NOT NULL,
    ADD UNIQUE KEY uk_training_plan_version_plan_id (plan_id, id),
    ADD UNIQUE KEY uk_training_plan_version_plan_id_no (plan_id, id, version_no),
    ADD UNIQUE KEY uk_training_plan_version_locator_signature (id, schedule_type, cycle_length_key),
    ADD CONSTRAINT ck_training_plan_version_no_positive_v36 CHECK (version_no > 0),
    ADD CONSTRAINT ck_training_plan_version_cycle_key_v36 CHECK (
        cycle_length_key = COALESCE(cycle_length_days, 0)
    ),
    ADD CONSTRAINT ck_training_plan_version_weekly_cycle_v36 CHECK (
        schedule_type <> 'WEEKLY' OR cycle_length_days = 7
    );

-- Backfill the new FK target without inventing a version. If legacy current_version_no is
-- inconsistent, the CHECK/FK added below intentionally causes migration failure after
-- preflight has identified the row.
UPDATE training_plan p
JOIN training_plan_version v
  ON v.plan_id = p.id
 AND v.version_no = p.current_version_no
SET p.current_version_id = v.id
WHERE p.current_version_no > 0;

ALTER TABLE training_plan
    ADD CONSTRAINT ck_training_plan_current_version_pair_v36 CHECK (
        (current_version_id IS NULL AND current_version_no = 0)
        OR
        (current_version_id IS NOT NULL AND current_version_no > 0)
    ),
    ADD CONSTRAINT fk_training_plan_current_version_v36
        FOREIGN KEY (id, current_version_id, current_version_no)
        REFERENCES training_plan_version(plan_id, id, version_no)
        ON DELETE RESTRICT ON UPDATE RESTRICT;

-- Snapshot the version locator semantics onto each schedule item so MySQL can validate
-- cycle/date semantics with row-local CHECK constraints.
ALTER TABLE training_plan_schedule_item
    ADD COLUMN schedule_type_snapshot VARCHAR(32) NULL AFTER source_routine_id,
    ADD COLUMN cycle_length_days_snapshot INT UNSIGNED NULL AFTER schedule_type_snapshot,
    ADD COLUMN cycle_length_key_snapshot INT UNSIGNED NULL AFTER cycle_length_days_snapshot;

UPDATE training_plan_schedule_item i
JOIN training_plan_version v ON v.id = i.plan_version_id
SET i.schedule_type_snapshot = v.schedule_type,
    i.cycle_length_days_snapshot = v.cycle_length_days,
    i.cycle_length_key_snapshot = COALESCE(v.cycle_length_days, 0);

ALTER TABLE training_plan_schedule_item
    MODIFY COLUMN schedule_type_snapshot VARCHAR(32) NOT NULL,
    MODIFY COLUMN cycle_length_key_snapshot INT UNSIGNED NOT NULL,
    ADD UNIQUE KEY uk_plan_schedule_item_version_id (plan_version_id, id),
    ADD UNIQUE KEY uk_plan_schedule_item_id_type (id, item_type),
    ADD KEY idx_plan_schedule_item_locator_signature (
        plan_version_id, schedule_type_snapshot, cycle_length_key_snapshot
    ),
    DROP FOREIGN KEY fk_plan_schedule_item_version,
    DROP CHECK ck_plan_schedule_item_locator,
    ADD CONSTRAINT fk_plan_schedule_item_locator_version_v36
        FOREIGN KEY (plan_version_id, schedule_type_snapshot, cycle_length_key_snapshot)
        REFERENCES training_plan_version(id, schedule_type, cycle_length_key)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    ADD CONSTRAINT ck_plan_schedule_item_cycle_key_v36 CHECK (
        cycle_length_key_snapshot = COALESCE(cycle_length_days_snapshot, 0)
    ),
    ADD CONSTRAINT ck_plan_schedule_item_locator_v36 CHECK (
        (
            schedule_type_snapshot = 'DATE_SPECIFIC'
            AND specific_date IS NOT NULL
            AND cycle_day_no IS NULL
            AND cycle_length_days_snapshot IS NULL
        )
        OR
        (
            schedule_type_snapshot IN ('REPEATING_CYCLE', 'WEEKLY')
            AND specific_date IS NULL
            AND cycle_day_no IS NOT NULL
            AND cycle_length_days_snapshot IS NOT NULL
            AND cycle_day_no >= 1
            AND cycle_day_no <= cycle_length_days_snapshot
        )
    ),
    ADD CONSTRAINT ck_plan_schedule_item_weekly_cycle_v36 CHECK (
        schedule_type_snapshot <> 'WEEKLY' OR cycle_length_days_snapshot = 7
    );

ALTER TABLE scheduled_workout
    ADD UNIQUE KEY uk_scheduled_workout_user_id (user_id, id),
    ADD UNIQUE KEY uk_scheduled_workout_user_id_type (user_id, id, item_type),
    ADD KEY idx_scheduled_workout_user_plan (user_id, plan_id),
    ADD KEY idx_scheduled_workout_plan_version (plan_id, plan_version_id),
    ADD KEY idx_scheduled_workout_version_item (plan_version_id, schedule_item_id),
    ADD KEY idx_scheduled_workout_item_type (schedule_item_id, item_type),
    DROP FOREIGN KEY fk_scheduled_workout_plan,
    DROP FOREIGN KEY fk_scheduled_workout_version,
    DROP FOREIGN KEY fk_scheduled_workout_item,
    ADD CONSTRAINT fk_scheduled_workout_plan_owner_v36
        FOREIGN KEY (user_id, plan_id)
        REFERENCES training_plan(user_id, id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    ADD CONSTRAINT fk_scheduled_workout_plan_version_v36
        FOREIGN KEY (plan_id, plan_version_id)
        REFERENCES training_plan_version(plan_id, id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    ADD CONSTRAINT fk_scheduled_workout_version_item_v36
        FOREIGN KEY (plan_version_id, schedule_item_id)
        REFERENCES training_plan_schedule_item(plan_version_id, id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    ADD CONSTRAINT fk_scheduled_workout_item_type_v36
        FOREIGN KEY (schedule_item_id, item_type)
        REFERENCES training_plan_schedule_item(id, item_type)
        ON DELETE RESTRICT ON UPDATE RESTRICT;

ALTER TABLE workout_session
    ADD COLUMN source_scheduled_item_type VARCHAR(32) NULL AFTER source_scheduled_workout_id,
    ADD COLUMN business_timezone_id VARCHAR(64) NULL AFTER business_date;

UPDATE workout_session ws
JOIN scheduled_workout sw ON sw.id = ws.source_scheduled_workout_id
SET ws.source_scheduled_item_type = sw.item_type
WHERE ws.source_scheduled_workout_id IS NOT NULL;

ALTER TABLE workout_session
    ADD KEY idx_workout_session_user_schedule_type (
        user_id, source_scheduled_workout_id, source_scheduled_item_type
    ),
    DROP FOREIGN KEY fk_workout_session_schedule,
    ADD CONSTRAINT fk_workout_session_schedule_owner_type_v36
        FOREIGN KEY (user_id, source_scheduled_workout_id, source_scheduled_item_type)
        REFERENCES scheduled_workout(user_id, id, item_type)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    ADD CONSTRAINT ck_workout_session_source_relation_v36 CHECK (
        (
            source_type = 'FREE'
            AND source_scheduled_workout_id IS NULL
            AND source_scheduled_item_type IS NULL
        )
        OR
        (
            source_type = 'PLAN'
            AND source_scheduled_workout_id IS NOT NULL
            AND source_scheduled_item_type = 'WORKOUT'
        )
    );

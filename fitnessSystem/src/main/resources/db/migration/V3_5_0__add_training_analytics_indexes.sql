-- Fitness Platform / Product V3.5
-- No new source-of-truth tables are required for first-release analytics.
-- Add read-path indexes only; PR/volume/frequency/completion remain derivable from raw facts.

CREATE INDEX idx_scheduled_workout_user_plan_date_status
    ON scheduled_workout(user_id, plan_id, scheduled_date, status);

CREATE INDEX idx_workout_session_category_day
    ON workout_session(user_id, category, business_date, status, deleted_at);

CREATE INDEX idx_session_exercise_snapshot_muscle
    ON workout_session_exercise(primary_muscle_snapshot, exercise_id, session_id);

-- V3.5 extends the existing Export Service to training data.
ALTER TABLE export_job
    DROP CHECK ck_export_job_domain,
    ADD CONSTRAINT ck_export_job_domain_v35 CHECK (domain IN ('NUTRITION', 'TRAINING', 'ALL'));

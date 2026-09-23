-- Fitness Platform V3.6 post-migration smoke checks.
-- These queries inspect metadata and hardened invariants after Flyway succeeds.

-- 1) Confirm hardening migrations were recorded.
SELECT version, description, success, installed_on
FROM flyway_schema_history
WHERE version IN ('3.6.0', '3.6.1', '3.6.2', '3.6.3')
ORDER BY installed_rank;

-- 2) Legacy rows may legitimately have NULL timezone provenance.
-- New application writes must populate business_timezone_id.
SELECT COUNT(*) AS legacy_food_records_without_timezone
FROM food_record
WHERE business_timezone_id IS NULL;

SELECT COUNT(*) AS legacy_workout_sessions_without_timezone
FROM workout_session
WHERE business_timezone_id IS NULL;

-- 3) Current plan version pointer should agree with the version number.
SELECT p.id, p.current_version_id, p.current_version_no,
       v.id AS resolved_version_id, v.version_no AS resolved_version_no
FROM training_plan p
LEFT JOIN training_plan_version v
  ON v.id = p.current_version_id
 AND v.plan_id = p.id
WHERE NOT (
    (p.current_version_id IS NULL AND p.current_version_no = 0)
    OR
    (p.current_version_id = v.id AND p.current_version_no = v.version_no)
);

-- 4) Exactly zero or one APPROVED+ACTIVE version per logical knowledge document.
SELECT document_id, COUNT(*) AS active_approved_count
FROM knowledge_document_version
WHERE review_status = 'APPROVED'
  AND effective_status = 'ACTIVE'
GROUP BY document_id
HAVING COUNT(*) > 1;

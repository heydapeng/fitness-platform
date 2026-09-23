-- Fitness Platform V3.6 hardening preflight checks
-- Expected result for every query: zero rows (or zero duplicate groups).
-- Run before applying V3_6_0 .. V3_6_3 to an existing database.

-- 1) Food source semantics.
SELECT id, source_type, owner_user_id, source_provider, source_external_id
FROM food
WHERE NOT (
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

-- 2) Nutrition cross-user references.
SELECT fr.id AS food_record_id, fr.user_id AS record_user_id,
       g.id AS group_id, g.user_id AS group_user_id
FROM food_record fr
JOIN food_record_group g ON g.id = fr.group_id
WHERE fr.user_id <> g.user_id;

SELECT p.id AS photo_id, p.user_id AS photo_user_id,
       fr.id AS food_record_id, fr.user_id AS record_user_id
FROM food_photo p
JOIN food_record fr ON fr.id = p.food_record_id
WHERE p.user_id <> fr.user_id;

SELECT p.id AS photo_id, p.user_id AS photo_user_id,
       g.id AS group_id, g.user_id AS group_user_id
FROM food_photo p
JOIN food_record_group g ON g.id = p.food_record_group_id
WHERE p.user_id <> g.user_id;

-- 3) Nutrition Goal interval overlap.
-- MySQL cannot express non-overlap with a normal UNIQUE key; V3.6 requires per-user
-- serialization by locking app_user before reading/updating nutrition_goal.
SELECT g1.user_id, g1.id AS goal_1, g2.id AS goal_2,
       g1.effective_date AS goal_1_start, g1.end_date AS goal_1_end,
       g2.effective_date AS goal_2_start, g2.end_date AS goal_2_end
FROM nutrition_goal g1
JOIN nutrition_goal g2
  ON g1.user_id = g2.user_id
 AND g1.id < g2.id
 AND g1.effective_date <= COALESCE(g2.end_date, '9999-12-31')
 AND g2.effective_date <= COALESCE(g1.end_date, '9999-12-31');

-- 4) AI owner/conversation chain.
SELECT r.id AS agent_run_id, r.user_id AS run_user_id,
       c.id AS conversation_id, c.user_id AS conversation_user_id
FROM ai_agent_run r
JOIN ai_conversation c ON c.id = r.conversation_id
WHERE r.user_id <> c.user_id;

SELECT r.id AS agent_run_id, r.conversation_id AS run_conversation_id,
       m.id AS user_message_id, m.conversation_id AS message_conversation_id
FROM ai_agent_run r
JOIN ai_message m ON m.id = r.user_message_id
WHERE r.user_message_id IS NOT NULL
  AND r.conversation_id <> m.conversation_id;

SELECT r.id AS agent_run_id, r.conversation_id AS run_conversation_id,
       m.id AS assistant_message_id, m.conversation_id AS message_conversation_id
FROM ai_agent_run r
JOIN ai_message m ON m.id = r.assistant_message_id
WHERE r.assistant_message_id IS NOT NULL
  AND r.conversation_id <> m.conversation_id;

SELECT a.id AS action_audit_id, a.user_id AS action_user_id,
       a.conversation_id AS action_conversation_id,
       c.user_id AS conversation_user_id
FROM ai_action_audit a
JOIN ai_conversation c ON c.id = a.conversation_id
WHERE a.user_id <> c.user_id;

SELECT a.id AS action_audit_id,
       a.user_id AS action_user_id, a.conversation_id AS action_conversation_id,
       r.user_id AS run_user_id, r.conversation_id AS run_conversation_id
FROM ai_action_audit a
JOIN ai_agent_run r ON r.id = a.agent_run_id
WHERE a.agent_run_id IS NOT NULL
  AND (a.user_id <> r.user_id OR a.conversation_id <> r.conversation_id);

-- 5) Exercise source semantics.
SELECT id, source_type, owner_user_id
FROM exercise
WHERE NOT (
    (source_type = 'SYSTEM' AND owner_user_id IS NULL)
    OR
    (source_type = 'USER_CUSTOM' AND owner_user_id IS NOT NULL)
);

-- 6) Training Plan current version integrity.
SELECT id AS plan_version_id, plan_id, version_no
FROM training_plan_version
WHERE version_no = 0;

SELECT p.id AS plan_id, p.current_version_no
FROM training_plan p
LEFT JOIN training_plan_version v
  ON v.plan_id = p.id
 AND v.version_no = p.current_version_no
WHERE (p.current_version_no = 0 AND v.id IS NOT NULL)
   OR (p.current_version_no > 0 AND v.id IS NULL);

-- 7) Plan-version schedule locator semantics.
SELECT i.id AS schedule_item_id, i.plan_version_id,
       v.schedule_type, v.cycle_length_days,
       i.cycle_day_no, i.specific_date
FROM training_plan_schedule_item i
JOIN training_plan_version v ON v.id = i.plan_version_id
WHERE
    (v.schedule_type = 'DATE_SPECIFIC'
        AND NOT (i.specific_date IS NOT NULL AND i.cycle_day_no IS NULL))
 OR (v.schedule_type IN ('REPEATING_CYCLE', 'WEEKLY')
        AND NOT (
            i.specific_date IS NULL
            AND i.cycle_day_no IS NOT NULL
            AND i.cycle_day_no >= 1
            AND i.cycle_day_no <= v.cycle_length_days
        ))
 OR (v.schedule_type = 'WEEKLY' AND v.cycle_length_days <> 7);

-- 8) Scheduled Workout must belong to one owner/version/item chain.
SELECT sw.id AS scheduled_workout_id,
       sw.user_id AS schedule_user_id, p.user_id AS plan_user_id,
       sw.plan_id, sw.plan_version_id, v.plan_id AS version_plan_id,
       sw.schedule_item_id, i.plan_version_id AS item_version_id,
       sw.item_type AS schedule_item_type_snapshot, i.item_type AS plan_item_type
FROM scheduled_workout sw
JOIN training_plan p ON p.id = sw.plan_id
JOIN training_plan_version v ON v.id = sw.plan_version_id
JOIN training_plan_schedule_item i ON i.id = sw.schedule_item_id
WHERE sw.user_id <> p.user_id
   OR sw.plan_id <> v.plan_id
   OR sw.plan_version_id <> i.plan_version_id
   OR sw.item_type <> i.item_type;

-- 9) Workout Session source relation and owner.
SELECT ws.id AS workout_session_id, ws.user_id, ws.source_type,
       ws.source_scheduled_workout_id
FROM workout_session ws
WHERE (ws.source_type = 'FREE' AND ws.source_scheduled_workout_id IS NOT NULL)
   OR (ws.source_type = 'PLAN' AND ws.source_scheduled_workout_id IS NULL);

SELECT ws.id AS workout_session_id, ws.source_type,
       sw.id AS scheduled_workout_id, sw.item_type
FROM workout_session ws
JOIN scheduled_workout sw ON sw.id = ws.source_scheduled_workout_id
WHERE ws.source_type = 'PLAN'
  AND sw.item_type <> 'WORKOUT';

SELECT ws.id AS workout_session_id,
       ws.user_id AS session_user_id,
       sw.user_id AS scheduled_workout_user_id
FROM workout_session ws
JOIN scheduled_workout sw ON sw.id = ws.source_scheduled_workout_id
WHERE ws.user_id <> sw.user_id;

-- 10) RAG production-version integrity.
SELECT document_id, COUNT(*) AS active_approved_count
FROM knowledge_document_version
WHERE review_status = 'APPROVED'
  AND effective_status = 'ACTIVE'
GROUP BY document_id
HAVING COUNT(*) > 1;

SELECT id, document_id, review_status, effective_status
FROM knowledge_document_version
WHERE effective_status = 'ACTIVE'
  AND review_status <> 'APPROVED';

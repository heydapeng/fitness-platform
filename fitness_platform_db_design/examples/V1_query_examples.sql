-- V1 query examples. These are application query examples, not Flyway migrations.

-- 1) Today's nutrition summary
SELECT
    COALESCE(SUM(calories_actual), 0) AS calories,
    COALESCE(SUM(protein_actual_g), 0) AS protein_g,
    COALESCE(SUM(carbs_actual_g), 0) AS carbs_g,
    COALESCE(SUM(fat_actual_g), 0) AS fat_g
FROM food_record
WHERE user_id = :user_id
  AND business_date = :business_date
  AND deleted_at IS NULL;

-- 2) Today's records in timeline order
SELECT
    id,
    food_id,
    food_name_snapshot,
    food_brand_snapshot,
    amount_g,
    meal_type,
    occurred_at,
    calories_actual,
    protein_actual_g,
    carbs_actual_g,
    fat_actual_g,
    note
FROM food_record
WHERE user_id = :user_id
  AND business_date = :business_date
  AND deleted_at IS NULL
ORDER BY occurred_at ASC, id ASC;

-- 3) Goal effective on a business date
SELECT *
FROM nutrition_goal
WHERE user_id = :user_id
  AND effective_date <= :business_date
  AND (end_date IS NULL OR end_date >= :business_date)
ORDER BY effective_date DESC
LIMIT 1;

-- 4) Active food search (simple V1 contains search)
SELECT
    f.id,
    f.name,
    f.brand,
    c.code AS category_code,
    c.display_name AS category_name,
    f.calories_per_100g,
    f.protein_per_100g,
    f.carbs_per_100g,
    f.fat_per_100g,
    f.source_type
FROM food f
JOIN food_category c ON c.id = f.category_id
WHERE f.status = 'ACTIVE'
  AND c.status = 'ACTIVE'
  AND (
      f.normalized_name LIKE CONCAT('%', :normalized_query, '%')
      OR f.normalized_brand LIKE CONCAT('%', :normalized_query, '%')
  )
ORDER BY
    CASE
      WHEN f.normalized_name = :normalized_query THEN 0
      WHEN f.normalized_name LIKE CONCAT(:normalized_query, '%') THEN 1
      ELSE 2
    END,
    f.id
LIMIT :limit OFFSET :offset;

-- 5) Lock one food record for an owner-scoped edit
SELECT *
FROM food_record
WHERE id = :record_id
  AND user_id = :current_user_id
  AND deleted_at IS NULL
FOR UPDATE;

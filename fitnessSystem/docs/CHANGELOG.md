# CHANGELOG

## 2026-09-20 - V1 Entity 映射

### Added

- `src/main/java/com/dapeng/fitnesssystem/user/entity/User.java`
  - 映射 `users` 表。
- `src/main/java/com/dapeng/fitnesssystem/user/entity/UserRole.java`
  - 映射 `users.role` 的 `USER` / `ADMIN`。
- `src/main/java/com/dapeng/fitnesssystem/nutrition/entity/NutritionGoal.java`
  - 映射 `nutrition_goals` 表及 `user_id` 外键。
- `src/main/java/com/dapeng/fitnesssystem/food/entity/FoodCategory.java`
  - 映射 `food_categories` 表。
- `src/main/java/com/dapeng/fitnesssystem/food/entity/Food.java`
  - 映射 `foods` 表及 `category_id` 外键。
- `src/main/java/com/dapeng/fitnesssystem/food/entity/MealType.java`
  - 映射 `food_records.meal_type` 的餐次字符串值。
- `src/main/java/com/dapeng/fitnesssystem/food/entity/FoodRecord.java`
  - 映射 `food_records` 表，保留食品快照与实际摄入字段。
- `docs/development/V1_ENTITY_IMPLEMENTATION.md`
  - 记录本次 Entity 实现设计、字段映射和逐文件 Change Log。

### Scope

- 本次仅包含 Entity、必要 Enum 和开发文档。
- 未创建 Repository、Service、Controller、DTO、VO、Mapper、API、Security 或前端代码。
- 未修改 `V1__init_schema.sql`。
- 未新增 Flyway migration。
- 未修改数据库结构。

### Database impact

无。

### API impact

无。

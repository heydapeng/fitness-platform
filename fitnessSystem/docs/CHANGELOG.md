# CHANGELOG

## 2026-09-23 - M1 T1.6 分页与序列化约定

### Changed

- 增加统一 `PageResponse` 和页码/大小/排序白名单校验。
- JSON 固定使用 ISO-8601 时间、两位小数和枚举名称字符串。

## 2026-09-23 - M1 T1.5 CurrentUser 抽象

### Changed

- 增加可注入的 `CurrentUser` 接口，业务 Service 后续只从这里读取用户 ID、时区和管理员角色。
- `SecurityContextCurrentUser` 从 Spring Security Context 读取认证主体；未认证时统一抛出 401 领域异常。
- 认证主体统一使用 `AuthenticatedUser(userId, timezone)`，不信任请求参数中的用户归属字段。

## 2026-09-23 - M1 T1.4 审计时间

### Changed

- `BaseEntity` 的 `createdAt`、`updatedAt` 改为 UTC `Instant`。
- JPA Auditing 显式使用 `utcDateTimeProvider` 自动维护审计时间。
- 新增时间与审计约定文档。

## 2026-09-23 - M1 T1.3 领域异常体系

### Changed

- 增加 Validation、NotFound、Forbidden、Conflict、Expired、ExternalService 六类领域异常。
- 全局处理器按异常类型返回固定的 HTTP 状态和业务错误码。
- 未预期异常只返回 `INTERNAL_ERROR` 和通用提示，不向客户端暴露内部异常信息。

## 2026-09-23 - M1 T1.2 统一响应模型

### Changed

- 响应 `code` 统一为字符串：成功为 `SUCCESS`，失败使用稳定错误码。
- 失败响应增加 `traceId`；字段校验失败增加 `fieldErrors`。
- 增加请求 `X-Trace-Id` 过滤器：有传入值时复用，未传入时自动生成，并回写到响应头。
- 全局异常处理和未认证响应改为统一错误码格式。

## 2026-09-23 - M1 T1.1 公共类型去重

### Changed

- 删除 `src/main/java/com/dapeng/fitnesssystem/common/Result.java`。
  - 该类型与 `common/response/Result.java` 的字段和工厂方法完全重复。
  - 现有全局异常处理和认证入口均已使用 `common.response.Result`，因此将其作为唯一响应类型，避免后续接口混用两个包名。

### Verification

- 当前源码仅保留 `common.response.Result`。
- `MealType` 已在此前移除旧 food 实体模块时一并删除；当前源码不存在第二个 `MealType`，无须迁移引用。

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

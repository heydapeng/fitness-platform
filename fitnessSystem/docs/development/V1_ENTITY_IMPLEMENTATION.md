# V1 JPA Entity Implementation

## 1. 本次任务

任务：
根据 `V1__init_schema.sql` 创建 V1 JPA Entity。

范围：
仅 Entity + 必要 Enum。

不包含：
Repository / Service / Controller / DTO / API。

## 2. 数据来源

数据库结构来源：
`src/main/resources/db/migration/V1__init_schema.sql`

说明：
- Flyway 管理数据库结构。
- Hibernate `ddl-auto` 使用 `validate`。
- Entity 以 SQL 为准，SQL 是当前数据库结构的事实来源。
- 本次实现依据提供的 V1 初始化 SQL；没有修改 SQL，也没有新增 migration。

## 3. Entity 清单

- `User` -> `users`
- `NutritionGoal` -> `nutrition_goals`
- `FoodCategory` -> `food_categories`
- `Food` -> `foods`
- `FoodRecord` -> `food_records`

V1 SQL 中实际存在 5 张业务表，本次均已建立对应 Entity。

## 4. 字段映射记录

### User

对应表：`users`

| Java 字段 | 数据库字段 | Java 类型 | SQL 类型 |
|---|---|---|---|
| id | id | Long | BIGINT |
| email | email | String | VARCHAR(255) |
| passwordHash | password_hash | String | VARCHAR(255) |
| nickname | nickname | String | VARCHAR(100) |
| timezone | timezone | String | VARCHAR(64) |
| role | role | UserRole | VARCHAR(20) |
| status | status | Integer | TINYINT |
| createdAt | created_at | LocalDateTime | DATETIME(6) |
| updatedAt | updated_at | LocalDateTime | DATETIME(6) |

### NutritionGoal

对应表：`nutrition_goals`

| Java 字段 | 数据库字段 | Java 类型 | SQL 类型 |
|---|---|---|---|
| id | id | Long | BIGINT |
| user | user_id | User | BIGINT FK |
| caloriesTarget | calories_target | BigDecimal | DECIMAL(10,2) |
| proteinTargetG | protein_target_g | BigDecimal | DECIMAL(10,2) |
| fatTargetG | fat_target_g | BigDecimal | DECIMAL(10,2) |
| carbsTargetG | carbs_target_g | BigDecimal | DECIMAL(10,2) |
| effectiveDate | effective_date | LocalDate | DATE |
| endDate | end_date | LocalDate | DATE, NULL allowed |
| createdAt | created_at | LocalDateTime | DATETIME(6) |
| updatedAt | updated_at | LocalDateTime | DATETIME(6) |

`end_date` 允许为 `NULL`。目标时间区间是否重叠属于后续 Service 层业务规则，本阶段未实现。

### FoodCategory

对应表：`food_categories`

| Java 字段 | 数据库字段 | Java 类型 | SQL 类型 |
|---|---|---|---|
| id | id | Long | BIGINT |
| name | name | String | VARCHAR(100) |
| sortOrder | sort_order | Integer | INT |
| status | status | Integer | TINYINT |
| createdAt | created_at | LocalDateTime | DATETIME(6) |
| updatedAt | updated_at | LocalDateTime | DATETIME(6) |

### Food

对应表：`foods`

| Java 字段 | 数据库字段 | Java 类型 | SQL 类型 |
|---|---|---|---|
| id | id | Long | BIGINT |
| category | category_id | FoodCategory | BIGINT FK |
| name | name | String | VARCHAR(255) |
| caloriesPer100g | calories_per_100g | BigDecimal | DECIMAL(10,2) |
| proteinPer100g | protein_per_100g | BigDecimal | DECIMAL(10,2) |
| fatPer100g | fat_per_100g | BigDecimal | DECIMAL(10,2) |
| carbsPer100g | carbs_per_100g | BigDecimal | DECIMAL(10,2) |
| source | source | String | VARCHAR(100), NULL allowed |
| sourceFoodId | source_food_id | String | VARCHAR(100), NULL allowed |
| description | description | String | VARCHAR(500), NULL allowed |
| status | status | Integer | TINYINT |
| createdAt | created_at | LocalDateTime | DATETIME(6) |
| updatedAt | updated_at | LocalDateTime | DATETIME(6) |

### FoodRecord

对应表：`food_records`

| Java 字段 | 数据库字段 | Java 类型 | SQL 类型 |
|---|---|---|---|
| id | id | Long | BIGINT |
| user | user_id | User | BIGINT FK |
| food | food_id | Food | BIGINT FK |
| recordDate | record_date | LocalDate | DATE |
| mealType | meal_type | MealType | VARCHAR(20) |
| weightG | weight_g | BigDecimal | DECIMAL(10,2) |
| foodNameSnapshot | food_name_snapshot | String | VARCHAR(255) |
| caloriesPer100gSnapshot | calories_per_100g_snapshot | BigDecimal | DECIMAL(10,2) |
| proteinPer100gSnapshot | protein_per_100g_snapshot | BigDecimal | DECIMAL(10,2) |
| fatPer100gSnapshot | fat_per_100g_snapshot | BigDecimal | DECIMAL(10,2) |
| carbsPer100gSnapshot | carbs_per_100g_snapshot | BigDecimal | DECIMAL(10,2) |
| caloriesActual | calories_actual | BigDecimal | DECIMAL(10,2) |
| proteinActual | protein_actual | BigDecimal | DECIMAL(10,2) |
| fatActual | fat_actual | BigDecimal | DECIMAL(10,2) |
| carbsActual | carbs_actual | BigDecimal | DECIMAL(10,2) |
| clientRequestId | client_request_id | String | VARCHAR(64) |
| createdAt | created_at | LocalDateTime | DATETIME(6) |
| updatedAt | updated_at | LocalDateTime | DATETIME(6) |

### SQL / Java 类型原则

- `BIGINT` -> `Long`
- `VARCHAR` / `TEXT` -> `String`
- `INT` -> `Integer`
- `TINYINT` -> `Integer`
- `DECIMAL` -> `BigDecimal`
- `DATE` -> `LocalDate`
- `DATETIME` -> `LocalDateTime`

所有营养值、重量及目标值的 `DECIMAL(10,2)` 均使用 `BigDecimal`，未使用 `float` / `double`。

## 5. Entity 关系

### NutritionGoal -> User

- `@ManyToOne(fetch = FetchType.LAZY)`
- 外键：`user_id`
- `nullable = false`

### Food -> FoodCategory

- `@ManyToOne(fetch = FetchType.LAZY)`
- 外键：`category_id`
- `nullable = false`

### FoodRecord -> User

- `@ManyToOne(fetch = FetchType.LAZY)`
- 外键：`user_id`
- `nullable = false`

### FoodRecord -> Food

- `@ManyToOne(fetch = FetchType.LAZY)`
- 外键：`food_id`
- `nullable = false`

当前阶段没有建立不必要的双向 `OneToMany`：
- `User` 不持有 `List<FoodRecord>` 或 `List<NutritionGoal>`。
- `FoodCategory` 不持有 `List<Food>`。
- `Food` 不持有 `List<FoodRecord>`。

这样避免当前阶段引入不必要的实体耦合、Lazy Loading 意外触发、JSON 循环引用和 `equals/hashCode` 复杂化。

## 6. Enum

### UserRole

对应数据库字段：`users.role`

值：
- `USER`
- `ADMIN`

映射：`@Enumerated(EnumType.STRING)`。

### MealType

对应数据库字段：`food_records.meal_type`

值：
- `BREAKFAST`
- `LUNCH`
- `DINNER`
- `SNACK`

映射：`@Enumerated(EnumType.STRING)`。

`status` 字段保持 `Integer`，未创建状态 Enum、`AttributeConverter` 或自定义数据库类型。

## 7. 特殊设计说明

### FoodRecord 食品快照设计

`FoodRecord` 同时保留 `food_id` 和食品营养快照。

`food_id`：
用于标识饮食记录来源食品。

snapshot：
用于保存饮食记录创建时的食品名称和营养数据。这样即使管理员后续修改 `foods` 表中的名称或营养数据，历史 `food_records` 的计算结果和历史事实不会随之改变。

本次完整保留以下快照字段：
- `food_name_snapshot`
- `calories_per_100g_snapshot`
- `protein_per_100g_snapshot`
- `fat_per_100g_snapshot`
- `carbs_per_100g_snapshot`

同时完整保留以下实际摄入字段：
- `calories_actual`
- `protein_actual`
- `fat_actual`
- `carbs_actual`

`Food` 表表达当前食品基础数据；`FoodRecord` snapshot 表达饮食记录发生时的数据事实，两者用途不同。

### 时间字段

- `created_at`、`updated_at` -> `LocalDateTime`
- 未新增 `BaseEntity`。
- 未新增 JPA Auditing。
- 未新增 `EntityListener`。
- 未新增自动时间填充机制。

### Lombok 处理

本次提供的材料未包含 `pom.xml`，无法确认项目是否已经引入 Lombok。为避免为 Entity 引入未确认依赖，本次 Entity 使用显式无参构造器、Getter、Setter；未新增 Lombok 依赖，也未使用 `@Data`。

### 数据库默认值

SQL 中已有 `timezone='UTC'`、`role='USER'`、`status=1`、`sort_order=0` 等默认值。本次 Entity 不额外引入 Hibernate 专有默认值注解，也不改变这些数据库定义。

## 8. 待确认问题

无数据库映射待确认问题。

说明：由于只提供了 V1 SQL 和项目结构截图，没有提供完整项目及 `pom.xml`，本次无法执行完整 Maven 项目编译；生成代码不依赖 Lombok。

## 9. Change Log

### Change 001

文件：
`src/main/java/com/dapeng/fitnesssystem/user/entity/UserRole.java`

类型：
新增

原因：
映射 `users.role` 的稳定字符串枚举值。

主要内容：
- 创建 `UserRole` Enum。
- 定义 `USER`、`ADMIN` 两个值，与 V1 SQL 注释及字段语义一致。
- 供 `User.role` 使用 `EnumType.STRING` 持久化。

数据库影响：
无

API 影响：
无

其他模块影响：
无

### Change 002

文件：
`src/main/java/com/dapeng/fitnesssystem/user/entity/User.java`

类型：
新增

原因：
映射 V1 `users` 表。

主要内容：
- 添加 `@Entity` 和 `@Table(name = "users")`。
- 主键 `id` 使用 `GenerationType.IDENTITY`。
- 显式映射 `password_hash`、`created_at`、`updated_at` 等数据库字段。
- `role` 使用 `UserRole` + `EnumType.STRING`。
- `status` 按要求保持 `Integer`。
- `created_at` / `updated_at` 使用 `LocalDateTime`。
- 记录 `uk_users_email` 唯一约束元数据。
- 未建立任何反向 `OneToMany`。

数据库影响：
无

API 影响：
无

其他模块影响：
无

### Change 003

文件：
`src/main/java/com/dapeng/fitnesssystem/nutrition/entity/NutritionGoal.java`

类型：
新增

原因：
映射 V1 `nutrition_goals` 表。

主要内容：
- 添加 `@Entity` 和 `@Table(name = "nutrition_goals")`。
- 主键 `id` 使用 `GenerationType.IDENTITY`。
- `user_id` 映射为 `@ManyToOne(fetch = LAZY)` -> `User`。
- 所有 `DECIMAL(10,2)` 目标字段使用 `BigDecimal`。
- `effective_date`、`end_date` 使用 `LocalDate`，其中 `end_date` 允许 `null`。
- `created_at` / `updated_at` 使用 `LocalDateTime`。
- 记录 SQL 中的唯一约束和日期索引元数据。
- 未实现目标时间区间重叠校验，该规则保留给后续 Service。

数据库影响：
无

API 影响：
无

其他模块影响：
无

### Change 004

文件：
`src/main/java/com/dapeng/fitnesssystem/food/entity/FoodCategory.java`

类型：
新增

原因：
映射 V1 `food_categories` 表。

主要内容：
- 添加 `@Entity` 和 `@Table(name = "food_categories")`。
- 主键 `id` 使用 `GenerationType.IDENTITY`。
- 显式映射 `sort_order`、`created_at`、`updated_at`。
- `sort_order` 使用 `Integer`；`status` 按要求保持 `Integer`。
- 记录分类名称唯一约束和状态/排序索引元数据。
- 未建立 `FoodCategory -> List<Food>` 双向关系。

数据库影响：
无

API 影响：
无

其他模块影响：
无

### Change 005

文件：
`src/main/java/com/dapeng/fitnesssystem/food/entity/Food.java`

类型：
新增

原因：
映射 V1 `foods` 表。

主要内容：
- 添加 `@Entity` 和 `@Table(name = "foods")`。
- 主键 `id` 使用 `GenerationType.IDENTITY`。
- `category_id` 映射为 `@ManyToOne(fetch = LAZY)` -> `FoodCategory`。
- 四个每 100g 营养字段均使用 `BigDecimal`，精度/小数位与 `DECIMAL(10,2)` 一致。
- 显式映射 `source_food_id`、时间字段及可空字段长度。
- `status` 保持 `Integer`。
- 记录 SQL 中食品名、数据源唯一约束及索引元数据。
- 未建立 `Food -> List<FoodRecord>` 双向关系。

数据库影响：
无

API 影响：
无

其他模块影响：
无

### Change 006

文件：
`src/main/java/com/dapeng/fitnesssystem/food/entity/MealType.java`

类型：
新增

原因：
映射 `food_records.meal_type` 的稳定字符串枚举值。

主要内容：
- 创建 `MealType` Enum。
- 定义 `BREAKFAST`、`LUNCH`、`DINNER`、`SNACK`。
- 供 `FoodRecord.mealType` 使用 `EnumType.STRING` 持久化。

数据库影响：
无

API 影响：
无

其他模块影响：
无

### Change 007

文件：
`src/main/java/com/dapeng/fitnesssystem/food/entity/FoodRecord.java`

类型：
新增

原因：
映射 V1 `food_records` 表，并完整保留饮食记录创建时的食品快照和实际摄入数据。

主要内容：
- 添加 `@Entity` 和 `@Table(name = "food_records")`。
- 主键 `id` 使用 `GenerationType.IDENTITY`。
- `user_id` 映射为 `@ManyToOne(fetch = LAZY)` -> `User`。
- `food_id` 映射为 `@ManyToOne(fetch = LAZY)` -> `Food`。
- `record_date` 使用 `LocalDate`。
- `meal_type` 使用 `MealType` + `EnumType.STRING`。
- `weight_g` 使用 `BigDecimal`。
- 完整保留 `food_name_snapshot` 和四个 `*_per_100g_snapshot` 字段。
- 完整保留 `calories_actual`、`protein_actual`、`fat_actual`、`carbs_actual`。
- 所有营养和重量 `DECIMAL(10,2)` 字段均使用 `BigDecimal`。
- 显式映射 `client_request_id` 及时间字段。
- 记录 SQL 中请求幂等唯一约束及查询索引元数据。
- 未建立任何反向 `OneToMany`。

数据库影响：
无

API 影响：
无

其他模块影响：
无

### Change 008

文件：
`docs/development/V1_ENTITY_IMPLEMENTATION.md`

类型：
新增

原因：
记录 V1 Entity 实现依据、字段映射、关系、Enum、FoodRecord 快照设计，以及本次每个文件的变更明细。

主要内容：
- 记录任务边界和 SQL 事实来源。
- 记录 5 个 Entity 与数据库表对应关系。
- 逐字段记录 Java/SQL 映射。
- 记录所有 ManyToOne 关系及 LAZY 策略。
- 记录 `UserRole`、`MealType`。
- 记录 FoodRecord snapshot 设计。
- 记录本次 Change Log。

数据库影响：
无

API 影响：
无

其他模块影响：
仅增加开发文档，不影响运行时代码。

### Change 009

文件：
`docs/CHANGELOG.md`

类型：
新增

原因：
项目材料中未提供现有统一变更日志，因此按任务要求提供本次 V1 Entity 变更记录文件。

主要内容：
- 汇总本次新增的 Entity、Enum、技术文档。
- 明确本次范围仅为 Entity + Enum + 文档。
- 明确数据库、API 无影响。
- 明确未修改 SQL、未新增 migration、未开发后续分层。

数据库影响：
无

API 影响：
无

其他模块影响：
仅增加变更记录文档，不影响运行时代码。

## 10. 完成前检查

- [x] SQL 中 5 张 V1 业务表均有 Entity。
- [x] Entity 表名与 SQL 一致。
- [x] 所有 SQL 字段均已映射。
- [x] `DECIMAL(10,2)` 均使用 `BigDecimal`。
- [x] `DATE` 均使用 `LocalDate`。
- [x] `DATETIME(6)` 均使用 `LocalDateTime`。
- [x] 主键均使用 `GenerationType.IDENTITY`。
- [x] 外键使用单向 `ManyToOne`。
- [x] 所有关联均使用 `FetchType.LAZY`。
- [x] `FoodRecord` 快照字段完整。
- [x] `FoodRecord` 实际摄入字段完整。
- [x] `NutritionGoal.endDate` 允许 `null`。
- [x] SQL 未修改。
- [x] 未创建 Repository。
- [x] 未创建 Service。
- [x] 未创建 Controller。
- [x] 未创建 DTO / VO / Mapper。
- [x] 未创建 Security / JWT / API / 前端代码。
- [x] 每个新增代码文件均有对应 Change Log。
- [x] 已提供 `docs/CHANGELOG.md`。
- [ ] 完整项目 Maven 编译：未执行（未提供 `pom.xml` 和完整项目）。

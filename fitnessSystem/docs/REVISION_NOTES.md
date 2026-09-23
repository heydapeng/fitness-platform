# 本次代码修订说明

这份工程是在原项目上直接调整，不是重建项目。

## 已修正

1. **认证流程**
   - `/api/auth/login` 改为 `POST`，并允许匿名访问。
   - 登录密码改为 `PasswordEncoder.matches(raw, hash)` 校验，不再对输入密码二次 `encode()` 比较。
   - 登录成功签发 JWT；Spring Security 改为无状态认证。
   - 增加统一 401 JSON 响应。

2. **包结构**
   - `auth` 继续按业务模块组织。
   - Security 独立到 `security` 包。
   - `Result` 移到 `common.response`。
   - 增加 `common.persistence.BaseEntity` 和 JPA Auditing。
   - 饮食事实 `FoodRecord` 从食品主数据模块中拆到 `record` 模块。

3. **新版 V1 数据模型**
   - 营养目标四个指标允许部分为空。
   - `foods.name` 不再全局唯一。
   - 食品支持 `SYSTEM / EXTERNAL / USER` 三种来源类型。
   - 增加 `owner_user_id`、`brand`，分类允许为空。
   - 第三方食品继续使用 `(source, source_food_id)` 去重。
   - 饮食记录增加 `occurred_at`，`meal_type` 改为可选。
   - 保留食品营养快照、实际营养值和 `(user_id, client_request_id)` 幂等唯一键。

4. **配置**
   - Flyway 继续负责 DDL，JPA 使用 `ddl-auto=validate`。
   - 数据库、Redis、JWT 参数支持环境变量覆盖。
   - 关闭 Open EntityManager in View。

## 启动前注意

本次直接修改了 `V1__init_schema.sql`。如果你的本地数据库已经执行过旧版 V1，Flyway 会检测到 checksum 改变。

目前仍处于开发阶段且没有需要保留的数据时，推荐直接删除本地 `fitness` 数据库并重新创建空数据库，然后启动项目，让 Flyway 从 V1 重新建表。

如果数据库数据已经必须保留，则不要替换已执行的 V1，应改成新增 `V2__adjust_schema.sql` 做 ALTER 迁移。

## 环境变量

可选：

```text
DB_URL
DB_USERNAME
DB_PASSWORD
REDIS_HOST
REDIS_PORT
JWT_SECRET
JWT_EXPIRATION_SECONDS
```

生产环境必须覆盖 `JWT_SECRET`。

## 当前阶段没有加入

LangChain4j / Agent / RAG 暂未加入本次 V1 Core 代码。建议先把 User、Food、NutritionGoal、FoodRecord 的 Service/API 跑通，再在后续 Agent 阶段引入 LangChain4j，避免 AI 层先于业务层存在。

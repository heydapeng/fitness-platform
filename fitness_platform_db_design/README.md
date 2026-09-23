# Fitness Platform Database Design Package

本目录根据上传的 Fitness Platform 分阶段 PRD，给出 MySQL 8 + Flyway 的数据库设计。

## 内容

```text
fitness_platform_db_design/
├─ README.md
├─ docs/
│  ├─ 01_V1_数据库详细设计.md
│  ├─ 02_分阶段数据库演进设计.md
│  └─ 03_数据库完整性加固_V3.6.md
├─ examples/
│  ├─ application-flyway-example.yml
│  ├─ V1_query_examples.sql
│  ├─ V1_full_schema_for_review.sql
│  ├─ V3_6_preflight_checks.sql
│  ├─ V3_6_post_migration_checks.sql
│  └─ full_schema_after_v3_6_for_review.sql
└─ src/main/resources/db/migration/
   ├─ V1_0_0__create_app_user.sql
   ├─ V1_0_1__create_food_catalog.sql
   ├─ V1_0_2__create_nutrition_goal.sql
   ├─ V1_0_3__create_food_record.sql
   ├─ V1_0_4__create_idempotency_request.sql
   ├─ V1_1_0__extend_food_sources_and_custom_food.sql
   ├─ V1_1_1__create_food_record_group.sql
   ├─ V1_2_0__create_food_photo.sql
   ├─ V1_2_1__create_export_job.sql
   ├─ V2_0_0__create_ai_conversation_and_message.sql
   ├─ V2_0_1__create_agent_trace.sql
   ├─ V2_0_2__create_ai_action_audit.sql
   ├─ V2_1_0__create_knowledge_metadata.sql
   ├─ V2_1_1__create_rag_trace.sql
   ├─ V3_0_0__create_exercise_library.sql
   ├─ V3_0_1__create_workout_routine.sql
   ├─ V3_0_2__create_training_plan_versioning.sql
   ├─ V3_0_3__create_scheduled_workout.sql
   ├─ V3_0_4__create_workout_session.sql
   ├─ V3_5_0__add_training_analytics_indexes.sql
   ├─ V3_6_0__harden_core_ownership_and_time_context.sql
   ├─ V3_6_1__harden_ai_relational_integrity.sql
   ├─ V3_6_2__harden_training_relational_integrity.sql
   └─ V3_6_3__harden_rag_version_integrity.sql
```

## 使用方式

把 `src/main/resources/db/migration` 复制到 Spring Boot 项目的同名目录即可。

新库建议先由基础设施创建：

```sql
CREATE DATABASE fitness_platform
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;
```

然后启动应用让 Flyway 执行。

> 建议 MySQL 8.0.16+。Migration 使用了真正生效的 CHECK constraints。

## 重要规则

- 已经在共享/测试/生产执行过的 Flyway migration 不要修改；新增 migration 修正。
- 不要在生产开启 `flyway.clean`。
- 应用/JDBC 统一 UTC；`business_date` 由用户 timezone 在业务层计算并固化；V3.6 后新事实同时保存 `business_timezone_id`。
- 所有营养计算由 Java `BigDecimal` 服务端重新计算。
- V2/V4 AI 不直连表，必须复用 Domain Service。
- Nutrition Goal 写事务必须先锁 `app_user` 行，再校验区间重叠，避免空区间并发插入竞态。
- V3.6 强化 user/resource、plan/version/item、conversation/run/message 的复合 FK 完整性。
- RAG Version APPROVED 后正文/Chunk 文本不可原地修改；内容变化创建新 Version。

## 说明

`examples/V1_full_schema_for_review.sql` 只是把 V1 的 5 个 migration 拼接成单文件。`examples/full_schema_after_v3_6_for_review.sql` 则串联从 V1 到 V3.6 的完整 forward-only 路径。两者都仅用于人工 Review / rehearsal，不要与独立 migration 同时放进 Flyway 目录执行。


## V3.6 升级说明

已有数据库升级前先执行 `examples/V3_6_preflight_checks.sql`。所有异常查询应返回 0 行后再执行 Flyway。详细约束、应用层 invariant 与测试清单见 `docs/03_数据库完整性加固_V3.6.md`。

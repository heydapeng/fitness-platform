# Fitness Platform API 接口契约

> 版本：1.0  
> API 前缀：`/api/v1`  
> 传输：HTTPS + JSON；聊天流使用 SSE；文件上传使用 multipart/form-data  
> 说明：本文是目标接口契约。当前已有 `/api/auth/*` 属于早期实现，后续任务中统一评估兼容或迁移。

## 1. 全局约定

### 1.1 认证

除注册、登录和显式公开资源外，请求头必须包含：

```http
Authorization: Bearer <access-token>
```

服务端从 Spring Security Context 获取 currentUser。任何普通业务接口都不接收用于决定数据归属的 `userId`。

### 1.2 成功响应

```json
{
  "code": 0,
  "message": "success",
  "data": {}
}
```

- `code=0` 表示成功；
- 创建成功使用 HTTP 201；
- 删除成功使用 HTTP 204 时不返回 envelope，或统一使用 200 + envelope；项目必须二选一。本项目约定删除使用 200 + `data: null`；
- 异步任务创建使用 HTTP 202。

### 1.3 失败响应

```json
{
  "code": "FOOD_RECORD_EDIT_WINDOW_EXPIRED",
  "message": "该记录已超过30天编辑窗口",
  "data": null,
  "traceId": "01J...",
  "fieldErrors": []
}
```

目标实现应把当前整数 HTTP 状态码式业务 `code` 升级为稳定字符串错误码；HTTP 状态表达协议结果，`code` 表达业务原因。

### 1.4 HTTP 状态

| 状态 | 用途 |
| --- | --- |
| 200 | 查询、更新、业务操作成功 |
| 201 | 同步创建资源成功 |
| 202 | 异步任务已接受 |
| 400 | 格式、字段、状态转换或业务参数非法 |
| 401 | 未认证、Token 无效/过期 |
| 403 | 已认证但无权限、账号禁用 |
| 404 | 当前用户可见范围内资源不存在 |
| 409 | 唯一冲突、版本冲突、重复但不能复用的状态冲突 |
| 410 | Pending Action 或下载资源已过期 |
| 422 | 语义可解析但存在歧义、缺失或不支持组合 |
| 429 | 频率或额度限制 |
| 500 | 未预期服务端异常 |
| 502/503 | 上游 LLM、Food API、向量服务等暂不可用 |

### 1.5 通用错误码

| 错误码 | 含义 |
| --- | --- |
| `VALIDATION_FAILED` | 字段校验失败 |
| `UNAUTHENTICATED` | 未认证 |
| `ACCESS_DENIED` | 无访问权限 |
| `RESOURCE_NOT_FOUND` | 当前权限范围内不存在 |
| `RESOURCE_VERSION_CONFLICT` | 乐观锁或 Preview 版本冲突 |
| `IDEMPOTENCY_CONFLICT` | 同 requestId 对应不同请求内容 |
| `EDIT_WINDOW_EXPIRED` | 超过 30 天修改窗口 |
| `EXTERNAL_SERVICE_UNAVAILABLE` | 上游暂不可用 |
| `RATE_LIMITED` | 触发限流 |
| `INTERNAL_ERROR` | 未预期错误 |

领域错误码使用前缀：`AUTH_`、`GOAL_`、`FOOD_`、`FOOD_RECORD_`、`EXPORT_`、`AGENT_`、`KNOWLEDGE_`、`PLAN_`、`WORKOUT_`。

### 1.6 分页

请求参数：

```text
page=0&size=20&sort=createdAt,desc
```

`size` 默认 20，最大 100。响应：

```json
{
  "content": [],
  "page": 0,
  "size": 20,
  "totalElements": 0,
  "totalPages": 0,
  "first": true,
  "last": true
}
```

### 1.7 数值、日期与枚举

- 金额、重量和营养数值以 JSON number 传输，服务端使用 BigDecimal；
- `LocalDate`：`2026-09-22`；
- 时间点：`2026-09-22T12:30:00+08:00`；
- 服务端拒绝没有偏移信息且无法明确解释的时间点；
- 枚举使用大写稳定字符串；未知枚举返回 `VALIDATION_FAILED`；
- 所有 ID 对前端可按字符串安全处理，后端为 Long/UUID 均可。

### 1.8 幂等

以下写接口必须携带：

```http
Idempotency-Key: <UUID or ULID, max 64 chars>
```

适用：创建单条/批量 FoodRecord、复制记录、Confirm Agent Action、创建 Workout Session、完成训练、创建 Export Job。

规则：

1. 幂等范围为 `currentUser + operation + key`；
2. 首次成功后重复请求返回相同资源和状态；
3. 相同 key 但请求摘要不同返回 409 `IDEMPOTENCY_CONFLICT`；
4. 数据库唯一约束是最终保护；
5. 前端防抖不能代替服务端幂等。

### 1.9 乐观并发

可修改资源响应包含 `version`。更新请求必须回传 `version`；过期版本返回 409 `RESOURCE_VERSION_CONFLICT`。

## 2. 通用 DTO

### 2.1 MacroNutrients

```json
{
  "calories": 320.00,
  "proteinG": 41.58,
  "carbsG": 12.30,
  "fatG": 8.20
}
```

### 2.2 MetricProgress

```json
{
  "actual": 120.00,
  "target": 160.00,
  "remaining": 40.00,
  "over": 0.00,
  "completionPercent": 75.00
}
```

没有目标时除 `actual` 外其他字段均为 null。

### 2.3 DateRange

```json
{
  "preset": "CUSTOM",
  "startDate": "2026-09-01",
  "endDate": "2026-09-22"
}
```

Preset：`TODAY`、`LAST_7_DAYS`、`LAST_30_DAYS`、`LAST_90_DAYS`、`THIS_MONTH`、`THIS_YEAR`、`CUSTOM`。CUSTOM 必须提供首尾日期且 startDate <= endDate。

### 2.4 NutritionQuerySpec

```json
{
  "dateRange": {"preset": "LAST_30_DAYS"},
  "filters": {
    "foodIds": [],
    "categoryIds": [],
    "brands": [],
    "mealTypes": [],
    "foodTypes": [],
    "hasPhoto": null
  },
  "groupBy": "DAY",
  "metrics": ["CALORIES", "PROTEIN", "CARBS", "FAT"],
  "sort": [{"field": "period", "direction": "ASC"}],
  "columns": []
}
```

所有字段使用白名单；不得接受任意 SQL 字段或表达式。

## 3. Authentication 与 Profile

### 3.1 接口清单

| 方法 | 路径 | 认证 | 说明 |
| --- | --- | --- | --- |
| POST | `/auth/register` | 否 | 注册 |
| POST | `/auth/login` | 否 | 登录 |
| POST | `/auth/logout` | 是 | 客户端清除凭证；启用撤销表时服务端撤销 |
| GET | `/users/me` | 是 | 当前用户资料 |
| PATCH | `/users/me` | 是 | 修改昵称、时区 |

### 3.2 注册

请求：

```json
{
  "email": "user@example.com",
  "password": "password123",
  "confirmPassword": "password123",
  "nickname": "大鹏",
  "timezone": "Asia/Shanghai"
}
```

响应不返回密码字段。冲突返回 409 `AUTH_EMAIL_ALREADY_EXISTS`，无效时区返回 400 `USER_TIMEZONE_INVALID`。

### 3.3 登录

请求：

```json
{"email":"user@example.com","password":"password123"}
```

响应：

```json
{
  "user": {"id": 1, "email": "user@example.com", "nickname": "大鹏", "timezone": "Asia/Shanghai", "role": "USER"},
  "accessToken": "...",
  "tokenType": "Bearer",
  "expiresInSeconds": 7200
}
```

不存在和密码错误统一返回 401 `AUTH_BAD_CREDENTIALS`；禁用返回 403 `AUTH_USER_DISABLED`。

## 4. Nutrition Goal

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | `/nutrition-goals/current?date=YYYY-MM-DD` | 查询指定日期有效目标 |
| GET | `/nutrition-goals?startDate=&endDate=` | 查询目标历史 |
| POST | `/nutrition-goals` | 从指定日期建立新目标 |
| PUT | `/nutrition-goals/{goalId}` | 修改同一目标版本 |
| POST | `/nutrition-goals/current/end` | 结束当前目标，进入无目标状态 |

创建请求：

```json
{
  "caloriesTarget": 2300.00,
  "proteinTargetG": 160.00,
  "carbsTargetG": 260.00,
  "fatTargetG": 70.00,
  "effectiveDate": "2026-09-23"
}
```

四个指标可以部分为 null，但不能全空；不得为 0 或负数。创建新目标时由 Service 关闭重叠的上一目标。错误码包括 `GOAL_ALL_METRICS_EMPTY`、`GOAL_VALUE_INVALID`、`GOAL_DATE_OVERLAP`。

## 5. Food 与分类

### 5.1 用户接口

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | `/food-categories` | ACTIVE 分类列表 |
| GET | `/foods` | 本地可见 Food 分页列表/搜索 |
| GET | `/foods/{foodId}` | 可见 Food 详情 |
| GET | `/foods/search?query=&categoryId=&includeExternal=false` | 统一食品搜索 |
| POST | `/foods/external/{provider}/{externalId}/import` | 选中外部食品后标准化入库 |
| POST | `/foods/custom` | 创建私有自定义 Food |
| PUT | `/foods/custom/{foodId}` | 修改自己的自定义 Food |
| POST | `/foods/{foodId}/favorite` | 收藏，重复调用仍成功 |
| DELETE | `/foods/{foodId}/favorite` | 取消收藏 |
| GET | `/foods/favorites` | 收藏列表 |
| GET | `/foods/recent` | 最近吃过，去重 |
| GET | `/foods/frequent?windowDays=30` | 常吃食品 |

列表参数：`query`、`categoryId`、`foodType`、`page`、`size`。用户不能通过参数扩大到其他用户的私有 Food。

Food 响应：

```json
{
  "id": 101,
  "name": "鸡胸肉",
  "brand": null,
  "category": {"id": 2, "name": "肉类"},
  "foodType": "SYSTEM",
  "nutritionPer100g": {"calories":165.00,"proteinG":31.00,"carbsG":0.00,"fatG":3.60},
  "source": "SYSTEM",
  "status": "ACTIVE",
  "favorite": false,
  "version": 0
}
```

自定义 Food 请求与响应不得允许普通用户设置 ownerUserId、SYSTEM 类型或公共状态。

### 5.2 管理接口

| 方法 | 路径 | 角色 | 说明 |
| --- | --- | --- | --- |
| POST | `/admin/food-categories` | ADMIN | 创建分类 |
| PUT | `/admin/food-categories/{id}` | ADMIN | 修改分类 |
| POST | `/admin/foods` | ADMIN | 创建公共 Food |
| PUT | `/admin/foods/{id}` | ADMIN | 修改当前标准 |
| PATCH | `/admin/foods/{id}/status` | ADMIN | ACTIVE/INACTIVE |

管理修改不触发历史记录重算；Food 被引用时禁止物理删除。

## 6. Food Record

### 6.1 接口清单

| 方法 | 路径 | 幂等 | 说明 |
| --- | --- | --- | --- |
| POST | `/food-records` | 是 | 新增单条记录 |
| POST | `/food-records/batch` | 是 | 原子新增多条 |
| GET | `/food-records/{recordId}` | 否 | 本人记录详情 |
| PUT | `/food-records/{recordId}` | 否 | 30 天内全量编辑 |
| DELETE | `/food-records/{recordId}` | 否 | 30 天内删除 |
| POST | `/food-records/{recordId}/copy` | 是 | 复制为新事实 |
| GET | `/food-records?date=&mealType=&page=&size=` | 否 | 历史列表 |

### 6.2 新增请求

```json
{
  "foodId": 101,
  "amountG": 180.00,
  "occurredAt": "2026-09-22T12:30:00+08:00",
  "mealType": "LUNCH",
  "note": "少油"
}
```

客户端不得提交可信的 Calories/P/C/F。响应包含 recordDate、快照、实际营养和 editableUntil：

```json
{
  "id": 9001,
  "foodId": 101,
  "foodName": "鸡胸肉",
  "amountG": 180.00,
  "occurredAt": "2026-09-22T12:30:00+08:00",
  "recordDate": "2026-09-22",
  "mealType": "LUNCH",
  "nutritionPer100gSnapshot": {"calories":165.00,"proteinG":31.00,"carbsG":0.00,"fatG":3.60},
  "actualNutrition": {"calories":297.00,"proteinG":55.80,"carbsG":0.00,"fatG":6.48},
  "note": "少油",
  "editable": true,
  "editableUntil": "2026-10-21",
  "version": 0
}
```

### 6.3 批量请求

```json
{
  "occurredAt": "2026-09-22T12:30:00+08:00",
  "mealType": "LUNCH",
  "items": [
    {"foodId":101,"amountG":200.00,"note":null},
    {"foodId":205,"amountG":150.00,"note":null}
  ]
}
```

整批先校验后事务提交。任一行失败返回字段路径（如 `items[1].amountG`），数据库不得出现部分成功。

### 6.4 编辑请求

```json
{
  "foodId": 101,
  "amountG": 200.00,
  "occurredAt": "2026-09-22T12:40:00+08:00",
  "mealType": "LUNCH",
  "note": null,
  "version": 0
}
```

修改 Food 时换用新 Food 当前快照；只改 amount 时基于该记录已有快照重算。错误包括 `FOOD_INACTIVE`、`FOOD_NOT_VISIBLE`、`FOOD_RECORD_EDIT_WINDOW_EXPIRED`。

## 7. Dashboard、History、Analytics

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | `/dashboard/today` | 当前用户时区下今天摘要 |
| GET | `/nutrition/daily/{date}` | 指定日期汇总、目标和时间线 |
| POST | `/nutrition/analytics/query` | 按 QuerySpec 聚合 |
| POST | `/nutrition/analytics/preview` | 可选：校验 QuerySpec 并返回解释 |

每日响应：

```json
{
  "date": "2026-09-22",
  "timezone": "Asia/Shanghai",
  "metrics": {
    "calories": {"actual":1860.00,"target":2300.00,"remaining":440.00,"over":0.00,"completionPercent":80.87},
    "protein": {"actual":142.00,"target":160.00,"remaining":18.00,"over":0.00,"completionPercent":88.75},
    "carbs": {"actual":205.00,"target":260.00,"remaining":55.00,"over":0.00,"completionPercent":78.85},
    "fat": {"actual":61.00,"target":70.00,"remaining":9.00,"over":0.00,"completionPercent":87.14}
  },
  "records": []
}
```

Analytics 响应包含规范化后的 QuerySpec、summary、series、table 和数据口径版本。无数据返回空结果而不是 404。

## 8. 图片

| 方法 | 路径 | 类型 | 说明 |
| --- | --- | --- | --- |
| POST | `/food-records/{recordId}/photos` | multipart | 给单条记录上传 |
| POST | `/food-record-batches/{batchId}/photos` | multipart | 给记录组上传 |
| GET | `/photos/{photoId}` | JSON | 元数据与短期访问地址 |
| DELETE | `/photos/{photoId}` | JSON | 删除本人附件/关联 |

上传限制由配置定义，建议首期 JPEG/PNG/WebP、单张不超过 10MB、单次不超过 6 张。上传失败只影响附件请求，不修改已存在 FoodRecord。

## 9. Export

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| POST | `/exports` | 创建导出任务，HTTP 202 |
| GET | `/exports` | 当前用户任务列表 |
| GET | `/exports/{jobId}` | 任务状态 |
| POST | `/exports/{jobId}/retry` | 重试失败/过期任务 |
| GET | `/exports/{jobId}/download` | 鉴权后下载或返回短期地址 |

创建请求：

```json
{
  "domain": "NUTRITION",
  "querySpec": {},
  "content": ["DETAIL", "DAILY_SUMMARY"],
  "format": "XLSX",
  "includePhotos": false
}
```

状态：`PENDING`、`PROCESSING`、`SUCCEEDED`、`FAILED`、`EXPIRED`。Job 必须保存 QuerySpec 快照、用户、状态、文件元数据和可理解失败原因。

## 10. Agent Conversation 与 SSE

### 10.1 接口清单

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| POST | `/agent/conversations` | 新建会话 |
| GET | `/agent/conversations` | 最近会话分页 |
| GET | `/agent/conversations/{conversationId}` | 会话及消息 |
| DELETE | `/agent/conversations/{conversationId}` | 删除/归档本人会话 |
| POST | `/agent/conversations/{conversationId}/messages` | 非流式调试接口 |
| POST | `/agent/conversations/{conversationId}/messages/stream` | SSE 主接口 |
| POST | `/agent/runs/{runId}/stop` | 尽力停止生成，不回滚已提交业务事务 |
| POST | `/agent/messages/{messageId}/retry` | 重试失败消息 |

发送请求：

```json
{
  "content": "中午吃了200g鸡胸和150g米饭",
  "clientMessageId": "01J...",
  "timezone": "Asia/Shanghai"
}
```

### 10.2 SSE 事件格式

```text
event: status
id: 17
data: {"runId":"...","stage":"SEARCHING_FOOD","message":"正在匹配食品"}

event: text_delta
data: {"delta":"我找到了"}

event: action_required
data: {"actionId":"...","actionType":"RECORD_FOOD","previewVersion":1,"preview":{}}

event: done
data: {"runId":"...","messageId":"..."}
```

事件类型：`status`、`text_delta`、`tool_result`、`action_required`、`execution_result`、`error`、`done`。断线重连使用 `Last-Event-ID`；服务端可在有限保留期内补发业务事件。

### 10.3 Pending Action

| 方法 | 路径 | 幂等 | 说明 |
| --- | --- | --- | --- |
| GET | `/agent/actions/{actionId}` | 否 | 查询本人 Pending Action |
| PUT | `/agent/actions/{actionId}/draft` | 否 | 编辑草稿并生成新 Preview |
| POST | `/agent/actions/{actionId}/confirm` | 是 | 确认并执行 |
| POST | `/agent/actions/{actionId}/cancel` | 否 | 取消，不写业务数据 |
| POST | `/agent/actions/{actionId}/resolve` | 否 | 提交食品/动作候选选择 |

Confirm 请求只包含：

```json
{"previewVersion": 3}
```

不得让客户端回传并覆盖服务器保存的 resolved draft。过期返回 410 `AGENT_ACTION_EXPIRED`，旧 Preview 返回 409 `AGENT_PREVIEW_VERSION_CONFLICT`。

## 11. Knowledge 与 RAG 管理

### 11.1 管理接口

| 方法 | 路径 | 角色 | 说明 |
| --- | --- | --- | --- |
| POST | `/admin/knowledge/documents` | ADMIN | 新建元数据 |
| POST | `/admin/knowledge/documents/{id}/content` | ADMIN | 上传/更新内容 |
| GET | `/admin/knowledge/documents` | ADMIN | 按状态、主题查询 |
| GET | `/admin/knowledge/documents/{id}` | ADMIN | 文档、版本和索引状态 |
| PUT | `/admin/knowledge/documents/{id}` | ADMIN | 修改草稿元数据 |
| POST | `/admin/knowledge/documents/{id}/submit-review` | ADMIN | DRAFT→REVIEWING |
| POST | `/admin/knowledge/documents/{id}/approve` | ADMIN | 审核通过 |
| POST | `/admin/knowledge/documents/{id}/reject` | ADMIN | 驳回并记录原因 |
| POST | `/admin/knowledge/documents/{id}/expire` | ADMIN | 过期 |
| POST | `/admin/knowledge/documents/{id}/reindex` | ADMIN | 创建重建任务 |
| GET | `/admin/knowledge/index-jobs/{jobId}` | ADMIN | 索引状态 |
| POST | `/admin/knowledge/retrieval-test` | ADMIN | 测试 rewrite/retrieval/rerank |

文档元数据请求至少包含 title、category、topic、source、author、publishDate、language、version、licenseStatus、sourceUrl。

### 11.2 检索测试响应

返回 originalQuery、rewrittenQuery、filters、retrieved chunks、初排分数、rerank 分数、是否通过阈值和索引版本。正式用户问答仍通过 Agent 接口完成。

## 12. Exercise 与 Routine

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | `/exercises` | 搜索可见动作 |
| GET | `/exercises/{exerciseId}` | 动作详情 |
| POST | `/exercises/custom` | 创建私有动作 |
| PUT | `/exercises/custom/{exerciseId}` | 修改私有动作 |
| POST | `/admin/exercises` | ADMIN 创建公共动作 |
| PATCH | `/admin/exercises/{id}/status` | ADMIN 停用/启用 |
| POST | `/routines` | 创建模板 |
| GET | `/routines` | 本人模板列表 |
| GET | `/routines/{routineId}` | 模板详情 |
| PUT | `/routines/{routineId}` | 编辑动作顺序和目标 |
| POST | `/routines/{routineId}/copy` | 复制模板 |
| DELETE | `/routines/{routineId}` | 删除未受保护模板 |

Routine Item 可包含 exerciseId、order、targetSets、targetReps、targetWeight、targetDuration、targetDistance、note；所有目标字段可按动作类型为空。

## 13. Training Plan 与 Calendar

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| POST | `/training-plans` | 创建 DRAFT Plan |
| GET | `/training-plans` | 本人计划列表 |
| GET | `/training-plans/{planId}` | 当前版本详情 |
| PUT | `/training-plans/{planId}` | 基于 version 创建/更新计划版本 |
| POST | `/training-plans/{planId}/activate` | 启用并校验投影条件 |
| POST | `/training-plans/{planId}/pause` | 暂停未来投影 |
| POST | `/training-plans/{planId}/archive` | 归档，不破坏历史 |
| GET | `/training-plans/{planId}/versions` | 版本历史 |
| GET | `/calendar?startDate=&endDate=&category=&planId=` | 合并 Schedule、Session、Rest Day |
| GET | `/calendar/{date}` | 单日详情 |

计划请求示例：

```json
{
  "name": "PPL 9-Day",
  "category": "STRENGTH",
  "scheduleType": "REPEATING_CYCLE",
  "startDate": "2026-10-01",
  "endDate": null,
  "cycleDays": [
    {"day":1,"type":"WORKOUT","routineId":11},
    {"day":2,"type":"WORKOUT","routineId":12},
    {"day":3,"type":"WORKOUT","routineId":13},
    {"day":4,"type":"REST"}
  ],
  "version": 0
}
```

真实请求必须包含完整 N 天数组、day 连续且唯一。多个计划同日投影允许存在。

## 14. Workout Session

| 方法 | 路径 | 幂等 | 说明 |
| --- | --- | --- | --- |
| POST | `/workout-sessions` | 是 | 开始自由训练或计划训练 |
| GET | `/workout-sessions/active` | 否 | 当前进行中的训练 |
| GET | `/workout-sessions/{sessionId}` | 否 | 本人训练详情 |
| POST | `/workout-sessions/{sessionId}/exercises` | 否 | 添加动作 |
| POST | `/workout-sessions/{sessionId}/exercises/{itemId}/sets` | 否 | 添加 Set |
| PUT | `/workout-sessions/{sessionId}/sets/{setId}` | 否 | 编辑 Set |
| DELETE | `/workout-sessions/{sessionId}/sets/{setId}` | 否 | 删除 Set |
| POST | `/workout-sessions/{sessionId}/finish` | 是 | 结束训练 |
| PUT | `/workout-sessions/{sessionId}` | 否 | 30 天内编辑事实 |
| DELETE | `/workout-sessions/{sessionId}` | 否 | 30 天内删除 |
| GET | `/workout-sessions?startDate=&endDate=&page=` | 否 | 历史列表 |

开始请求：

```json
{
  "sourceScheduleId": null,
  "title": "自由训练",
  "startedAt": "2026-09-22T18:30:00+08:00"
}
```

Set 请求：

```json
{
  "weightKg": 80.00,
  "reps": 8,
  "durationSeconds": null,
  "distanceMeters": null,
  "rpe": 8.5,
  "rir": 2,
  "setType": "WORKING",
  "completed": true,
  "note": null
}
```

服务端校验字段组合。未来 completed Session 返回 `WORKOUT_FUTURE_FACT_NOT_ALLOWED`。

## 15. Training Analytics

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| POST | `/training/analytics/query` | Training QuerySpec 聚合 |
| GET | `/exercises/{id}/history?startDate=&endDate=` | 动作历史 |
| GET | `/training/prs?exerciseId=&startDate=&endDate=` | PR |
| GET | `/training-plans/{id}/completion?startDate=&endDate=` | 计划完成率 |

Training QuerySpec：

```json
{
  "dateRange": {"preset":"LAST_90_DAYS"},
  "planIds": [],
  "exerciseIds": [88],
  "categories": ["STRENGTH"],
  "muscleGroups": [],
  "sessionSources": ["PLAN", "FREE"],
  "metrics": ["MAX_WEIGHT", "LOAD_VOLUME"],
  "groupBy": "WEEK"
}
```

响应必须携带 metric applicability 和 formulaVersion，不能给不适用动作伪造 Volume/1RM。

## 16. AI Training

不新增绕过业务层的特殊写接口。V4 继续使用 Agent Conversation、Pending Action 和 Confirm 接口，actionType 扩展为：

- `RECORD_WORKOUT`；
- `CREATE_TRAINING_PLAN`；
- `CHANGE_TRAINING_PLAN`；
- `EXPORT_TRAINING_DATA`。

Confirm 后分别调用 Workout、Plan、Export Service。计划修改 Preview 必须包含 baseVersion、before 和 after；版本冲突需重新生成草稿。

## 17. 权限矩阵

| 资源 | USER 读 | USER 写 | ADMIN |
| --- | --- | --- | --- |
| 自己的 Goal/Record/Photo/Export | 是 | 是 | 不默认可读 |
| 公共 Food/Exercise | 是 | 否 | 维护 |
| 自定义 Food/Exercise | 创建者 | 创建者 | 不默认接管 |
| 自己的 Conversation/Action | 是 | 是 | 不默认可读 |
| Knowledge APPROVED 来源信息 | 是 | 否 | 管理全文和状态 |
| 自己的 Plan/Session/Set | 是 | 是 | 不默认可读 |

所有详情、更新、删除接口都必须把 owner 条件放进查询或 Service 校验。不能先按 ID 查到对象再把“存在但无权”信息泄漏给调用者。

## 18. 接口验收最低要求

每个接口至少验证：

1. 正常成功路径；
2. Bean Validation/字段边界；
3. 未认证；
4. 跨用户访问；
5. 资源不存在；
6. 领域状态不允许的操作；
7. 幂等或并发（适用时）；
8. 数据库事务回滚（批量/复合写适用）；
9. 返回 DTO 不泄漏密码、内部路径、JPA 代理或 Secret；
10. OpenAPI 示例与真实响应一致。

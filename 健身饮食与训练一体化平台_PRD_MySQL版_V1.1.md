# 健身饮食与训练一体化平台 PRD

---

# 1. 文档信息

| 项目内容    |                                                                   |
| ------- | ----------------------------------------------------------------- |
| 产品名称    | 暂定：Fitness Nutrition Platform                                     |
| 文档类型    | 产品需求文档 PRD + 业务分析 + 系统设计前置说明                                      |
| 当前版本    | PRD V1.1（MySQL 技术基线版）                                                          |
| 产品阶段    | 0 → 1 产品构思 / MVP 设计阶段                                             |
| V1 核心主题 | 饮食记录与每日营养目标追踪                                                     |
| 主要用户    | 普通健身用户、管理员                                                        |
| 非 V1 用户 | 健身教练                                                              |
| 前端技术    | Vue 3、TypeScript、Vite、Pinia、Vue Router、Axios、Element Plus、ECharts |
| 后端技术    | Java 21、Spring Boot 3、Spring Security、JWT                         |
| ORM     | MyBatis-Plus / JPA                                                |
| 数据库     | MySQL 8.x                                            |
| 缓存      | Redis，V1 非强依赖                                                     |
| 对象存储    | MinIO / OSS，主要为后续媒体功能预留                                           |
| AI      | LangChain4j、LLM、Tool Calling、RAG，均不属于 V1                          |

---

# 2. 项目背景

健身用户在减脂、增肌或体重管理过程中，最常见的高频问题不是“缺少复杂的 AI”，而是：

> 我今天到底吃了多少？
> 我的蛋白质够不够？
> 我的热量还剩多少？

市面上的营养记录产品往往存在食品数据复杂、记录步骤过多、单位体系过重、界面信息冗余等问题。

本产品 V1 不试图解决完整健身生命周期，而是优先建立一条稳定、低操作成本、数据口径可靠的核心业务链路：

**设定目标 → 搜索食物 → 输入重量 → 自动计算 → 保存记录 → 查看当天完成情况 → 查看历史。**

该闭环同时为后续身体数据、训练、教练和 AI Agent 建立结构化用户数据基础。

---

# 3. 产品愿景

长期目标：

> 建立一个“一站式健身吃、练、学、问、教”平台。

长期能力包括：

- 饮食记录
- 营养统计
- 身体数据
- 动作库
- 训练计划
- 训练日志
- 训练统计
- 真人教练
- 健身知识库
- AI 问答
- Tool Calling
- Fitness Agent
- AI 与真人教练协同

但 V1 的核心不是 AI，而是建立可信赖的结构化健身数据系统。

---

# 4. 产品定位

## 4.1 V1 产品定位

一个面向健身人群的：

**轻量、快速、准确的每日饮食和宏量营养素记录工具。**

核心价值：

1. 记录快。
2. 计算可靠。
3. 历史数据不会因为食物库修改而改变。
4. 用户可以清楚看到当天距离目标还差多少。
5. 产品结构可自然扩展至身体数据、训练、教练与 AI。

## 4.2 V1 不追求

- 替代专业营养师。
- 自动生成医疗级饮食方案。
- AI 智能推荐。
- 社交。
- 内容社区。
- 商业课程体系。
- 复杂食谱或烹饪系统。

---

# 5. 产品目标

## 5.1 V1 核心目标

实现完整的饮食记录 MVP：

```text
注册/登录
→ 设置营养目标
→ 搜索食物
→ 输入食用重量
→ 计算营养
→ 保存记录
→ Dashboard 汇总
→ 查看剩余目标
→ 查看/编辑/删除历史记录

```

## 5.2 产品成功标准

V1 上线后至少应保证：

- 用户可以在 30 秒内完成一次常规饮食记录。
- 饮食记录计算结果一致且可复现。
- 管理员修改食品营养数据后，不影响已有历史记录。
- 用户可以查询任意历史日期。
- 所有用户数据严格按 user_id 隔离。
- 核心流程无明显阻塞步骤。
- 任何删除或修改操作均可立即反映在当日营养汇总中。

---

# 6. V1 范围

## 6.1 P0 功能

V1 必须实现：

- 用户注册。
- 用户登录。
- JWT 鉴权。
- 用户资料基础配置。
- 用户时区。
- 每日营养目标。
- 营养目标历史。
- 食物分类。
- 食物库。
- 食物模糊搜索。
- 食物详情。
- 每 100g 营养信息。
- 输入食用重量。
- 营养自动计算。
- 早餐 / 午餐 / 晚餐 / 加餐。
- 新增饮食记录。
- 编辑饮食记录。
- 删除饮食记录。
- 当日饮食 Dashboard。
- 按餐次展示记录。
- 每日营养汇总。
- 剩余营养计算。
- 营养进度。
- 历史日期查看。
- 管理员维护食物。
- 管理员维护食物分类。
- 食物停用。
- 历史营养快照。
- 统一参数校验。
- 统一异常处理。
- 权限隔离。

---

# 7. 非 V1 范围

以下明确不进入 V1：

- AI Agent。
- LangChain4j。
- RAG。
- 健身知识库。
- 真人教练。
- 教练与学员关系。
- 动作库。
- GIF / 视频动作教学。
- 训练计划。
- 训练日志。
- 训练容量统计。
- PR。
- 社区。
- 社交。
- 商城。
- 付费课程。
- 自动饮食推荐。
- 智能训练推荐。
- 自然语言录入饮食。

这些能力只进行架构预留，不实现业务逻辑。

---

# 8. 用户角色

| 角色V1主要权限  |   |                   |
| --------- | - | ----------------- |
| 普通用户 USER | 是 | 管理自己的目标、饮食记录、历史数据 |
| 管理员 ADMIN | 是 | 用户普通能力 + 食物库和分类管理 |
| 教练 COACH  | 否 | 后续管理学员、查看授权数据     |
| AI Agent  | 否 | 后续通过 Tool 调用系统能力  |

---

# 9. 用户画像

## 9.1 减脂用户

特点：

- 关注热量。
- 希望控制脂肪和碳水。
- 每天多次查看剩余热量。

核心问题：

> 我今天是不是吃超了？

## 9.2 增肌用户

特点：

- 关注蛋白质和总热量。
- 重复饮食比例高。
- 经常食用鸡胸肉、鸡蛋、米饭、牛肉等固定食品。

核心问题：

> 今天蛋白质还差多少？

## 9.3 有训练经验用户

特点：

- 有明确宏量营养目标。
- 对营养数据精度敏感。
- 不希望产品替自己“自动决定目标”。

核心问题：

> 我要快速记录，而不是被复杂推荐流程打断。

---

# 10. 用户痛点

主要痛点：

1. 不知道当天实际摄入多少。
2. 每次都需要手工计算营养。
3. 一天多餐后难以累计。
4. 不清楚剩余目标。
5. 历史记录难回顾。
6. 食品库数据更新可能污染历史记录。
7. 高频记录步骤过长。
8. 相同食品反复搜索效率低。
9. 部分产品把“食品当前营养值”和“用户历史摄入”混为一谈。

---

# 11. 核心用户场景

## 场景 A：第一次使用

```text
注册
→ 登录
→ 系统发现未设置营养目标
→ 引导设置目标
→ 保存
→ 进入 Dashboard

```

## 场景 B：记录午餐

```text
Dashboard
→ 添加饮食
→ 搜索“米饭”
→ 选择米饭
→ 输入 400g
→ 自动显示 464 kcal / 10.4g P / 1.2g F / 103.6g C
→ 选择午餐
→ 保存
→ 返回 Dashboard
→ 汇总数据更新

```

## 场景 C：查看昨天

```text
历史记录
→ 日期选择昨天
→ 加载昨日目标
→ 加载昨日饮食
→ 显示昨日摄入和当日目标完成度

```

## 场景 D：修改历史记录

用户发现昨天输入了 400g，实际为 300g：

```text
打开昨天记录
→ 编辑重量
→ 系统使用该记录原始的“每 100g 快照”重新计算
→ 保存
→ 昨日汇总更新

```

**不使用食品库今天最新的营养值重新计算。**

---

# 12. 用户故事

| 编号用户故事优先级 |                         |    |
| --------- | ----------------------- | -- |
| US-001    | 作为用户，我希望注册和登录系统，以保存个人数据 | P0 |
| US-002    | 我希望设置每日热量和三大营养素目标       | P0 |
| US-003    | 我希望目标修改后保留旧目标历史         | P0 |
| US-004    | 我希望搜索食品                 | P0 |
| US-005    | 我希望看到食品每 100g 营养值       | P0 |
| US-006    | 我希望输入食用克数后自动得到实际营养      | P0 |
| US-007    | 我希望指定早餐/午餐/晚餐/加餐        | P0 |
| US-008    | 我希望查看今天全部摄入             | P0 |
| US-009    | 我希望看到距离目标还差多少           | P0 |
| US-010    | 我希望编辑错误记录               | P0 |
| US-011    | 我希望删除错误记录               | P0 |
| US-012    | 我希望查看过去某一天              | P0 |
| US-013    | 管理员希望维护食品营养数据           | P0 |
| US-014    | 我希望快速选择最近吃过的食品          | P1 |
| US-015    | 我希望收藏食品                 | P1 |
| US-016    | 我希望复制昨天的饮食              | P1 |
| US-017    | 我希望自己创建食品               | P1 |
| US-018    | 我希望支持份、个、ml 等单位         | P2 |

---

# 13. 功能需求清单

核心模块：

```text
Authentication
├── Register
├── Login
└── Current User

User
├── Profile
└── Timezone

Nutrition Goal
├── Current Goal
├── Goal History
└── Goal Transition

Food
├── Category
├── Search
├── Detail
└── Nutrition

Food Record
├── Create
├── Update
├── Delete
└── Daily Query

Nutrition Statistics
└── Daily Summary

Admin
├── Food CRUD
├── Food Enable/Disable
└── Category CRUD

```

---

# 14. P0 / P1 / P2 / P3 优先级

| 功能优先级结论与原因 |    |                   |
| ---------- | -- | ----------------- |
| 模糊搜索       | P0 | 没有模糊搜索会直接破坏核心记录体验 |
| 食物分类       | P0 | 管理后台需要，搜索也可作为辅助筛选 |
| 最近吃过       | P1 | 高频价值很高，但不是建立闭环所必需 |
| 常吃食物       | P1 | 可由记录频次统计实现        |
| 收藏食物       | P1 | 简单且明显降低记录成本       |
| 复制昨天早餐     | P1 | 适合健身用户高度重复饮食      |
| 复制昨天全部     | P1 | 高价值效率能力           |
| 复制上一餐      | P1 | 高频训练饮食用户有价值       |
| 自定义食物      | P1 | 解决食品库覆盖不足         |
| 一次添加多个食物   | P1 | 建议在单条记录稳定后加入      |
| 自定义餐食      | P2 | 涉及组合食品、份量和嵌套快照    |
| 搜索历史       | P2 | “最近吃过”价值通常更高      |
| 品牌食品       | P2 | 会增加商品规格、条码等模型复杂度  |
| 常用单位       | P2 | 涉及单位体系            |
| g/ml/个/份换算 | P2 | 不同食品换算系数不同，不能通用转换 |
| 条码扫描       | P2 | 依赖商品数据库           |
| 菜谱/复合餐     | P2 | 需要配方与成分模型         |
| 社交推荐       | P3 | 非核心               |
| AI 自动饮食推荐  | P3 | 依赖稳定业务数据和规则       |

---

# 15. 功能详细说明

## 15.1 注册

字段：

- 用户名或昵称。
- 邮箱。
- 密码。
- 确认密码。
- 前端检测 IANA 时区。

业务规则：

- Email 唯一。
- Email 统一 lowercase。
- 密码不得明文保存。
- 注册成功后可直接登录或进入登录页。
- V1 暂不强制邮件验证。

建议：

**推荐方案：Email + Password。**

原因：

- 对个人开发者最简单。
- 不依赖短信成本。
- 后续容易增加 OAuth。

备选：

- 手机号。
- 微信登录。
- OAuth2。

均不建议进入初版。

---

## 15.2 营养目标

字段：

- calories。
- protein。
- fat。
- carbohydrate。
- startDate。

核心规则：

营养目标不是一个“当前配置对象”，而是一个时间区间。

推荐：

```text
start_date：包含
end_date：不包含

```

例如：

```text
减脂目标：
2026-01-01 <= date < 2026-04-01

增肌目标：
2026-04-01 <= date

```

数据库：

```text
goal 1
start_date = 2026-01-01
end_date   = 2026-04-01

goal 2
start_date = 2026-04-01
end_date   = null

```

### 查询某一天目标

查询日期 D：

```sql
start_date <= D
AND (
    end_date IS NULL
    OR D < end_date
)

```

每个用户同一天最多命中一条目标。

### 修改当前目标

如果用户从今天开始换目标：

```text
旧目标.end_date = today

创建：
new_goal.start_date = today
new_goal.end_date = null

```

必须在一个数据库事务内完成。

### active 字段设计

**推荐方案：不保存 active boolean。**

当前状态根据日期计算。

原因：

如果同时存在：

```text
active = true
end_date = 2025-01-01

```

就会产生状态冲突。

可在 DTO 返回：

```json
{
  "isCurrent": true
}

```

但它是计算字段。

---

## 15.3 食物搜索

P0 必须支持：

- 食物名称模糊搜索。
- 中文名称。
- 英文名称可选。
- 分类筛选。
- 只向普通用户返回 ACTIVE 食物。

搜索：

```text
米饭
鸡
牛
chicken

```

V1 不要求 Elasticsearch。

数据库：

```sql
WHERE status = 'ACTIVE'
AND name LIKE CONCAT('%', :keyword, '%')

```

MySQL 默认大小写不敏感排序规则下通常不需要手工 `LOWER(name)`。

注意：前后通配的 `LIKE '%keyword%'` 对普通 B-Tree 索引利用有限。V1 食品库规模较小时优先保持实现简单；数据量和查询压力明显上升后，再评估 MySQL FULLTEXT/ngram 或 Elasticsearch。

---

## 15.4 食物营养

V1 统一基础口径：

> 每 100g。

字段：

- calories_per_100g
- protein_per_100g
- fat_per_100g
- carbohydrate_per_100g

例：

```text
米饭 / 100g

116 kcal
Protein 2.6g
Fat 0.3g
Carbohydrate 25.9g

```

输入：

```text
400g

```

公式：

```text
factor = 400 / 100 = 4

calories = 116 × 4 = 464
protein = 2.6 × 4 = 10.4
fat = 0.3 × 4 = 1.2
carbohydrate = 25.9 × 4 = 103.6

```

---

## 15.5 食品记录快照

这是 V1 最关键的数据设计之一。

### 不推荐

只保存：

```text
food_id
weight

```

因为查询历史数据时，如果关联实时 food_nutrition：

```text
2026：
米饭 = 116 kcal

管理员之后修改：
米饭 = 130 kcal

```

历史记录会被重新解释。

这是错误的。

### 推荐方案

food_record 同时保存：

```text
food_id

food_name_snapshot

weight_g

calories_per_100g_snapshot
protein_per_100g_snapshot
fat_per_100g_snapshot
carbohydrate_per_100g_snapshot

calories
protein
fat
carbohydrate

```

因此历史数据完全独立。

### 为什么既保存每100g快照，又保存本次结果？

因为用户可能以后编辑：

```text
400g → 300g

```

系统需要按照**当时的营养口径**重新计算。

如果只保存：

```text
calories = 464

```

无法可靠知道原来的每100g是多少。

因此推荐双层快照。

---

## 15.6 编辑饮食记录

### 修改重量

使用记录中的：

```text
*_per_100g_snapshot

```

重新计算。

不得读取当前 food_nutrition。

### 修改餐次

不重新计算营养。

### 修改日期

记录从原日期统计移出，并加入新日期。

### 修改食品

视为重新选择食品：

- 获取该食品当前营养。
- 创建新的营养快照。
- 根据当前重量重新计算。

前端必须明确提示：

> 更换食品将按新食品当前营养信息重新计算。

---

## 15.7 删除饮食记录

删除后：

- 当天记录列表移除。
- 当天营养统计重新计算。
- Dashboard 立即刷新。

推荐 V1：

**food_record 直接物理删除。**

原因：

- 用户记录是个人操作数据。
- V1 没有财务审计需求。
- 降低实现复杂度。

备选：

添加：

```text
deleted_at
deleted_by

```

适合未来教练审计或恢复机制。

---

# 16. 核心业务流程

## 16.1 主流程

```text
注册
 ↓
登录
 ↓
是否存在当前营养目标？
 ├─ 否 → 引导设置目标
 └─ 是
 ↓
Dashboard
 ↓
点击添加饮食
 ↓
搜索食物
 ↓
选择食物
 ↓
读取每100g营养
 ↓
输入重量
 ↓
前端即时计算预览
 ↓
选择餐次
 ↓
提交
 ↓
后端重新计算
 ↓
保存食品快照 + 实际营养结果
 ↓
返回成功
 ↓
刷新 Daily Nutrition
 ↓
更新 Dashboard

```

注意：

**前端计算仅用于 UI 预览。**

最终保存值必须由 Java 后端重新计算。

不能信任客户端传入的 calories 等结果。

---

# 17. 页面结构

V1：

```text
/login
/register

/dashboard

/foods
/foods/:id

/records/new
/records/:id/edit

/history

/profile
/profile/nutrition-goals

/admin
/admin/foods
/admin/foods/new
/admin/foods/:id/edit
/admin/food-categories

```

推荐将原 `/food` 调整为 `/foods`。

推荐将 `/record` 调整为 REST 风格：

```text
/records/new
/records/:id/edit

```

---

# 18. 页面需求

| 页面目标主要组件空状态 / 异常         |        |                     |          |
| ------------------------ | ------ | ------------------- | -------- |
| /login                   | 用户登录   | Email、Password、登录按钮 | 登录失败提示   |
| /register                | 创建账户   | 注册表单                | Email 冲突 |
| /dashboard               | 查看今日摄入 | 目标卡、进度条、餐次列表        | 未设置目标引导  |
| /foods                   | 查找食品   | 搜索框、分类、食品列表         | 搜索无结果    |
| /records/new             | 添加饮食   | 食品信息、重量、餐次、预览       | 食品失效     |
| /records/\:id/edit       | 编辑记录   | 当前快照、重量、餐次          | 记录不存在    |
| /history                 | 查询历史   | 日期选择、汇总、餐次          | 当天无记录    |
| /profile                 | 资料与设置  | 用户资料、时区             | 保存失败     |
| /profile/nutrition-goals | 管理目标   | 当前目标、历史             | 无目标      |
| /admin/foods             | 食品维护   | 表格、搜索、状态            | 权限不足     |
| /admin/food-categories   | 分类维护   | 分类表格                | 引用中分类    |

## 18.1 Dashboard

必须展示：

- 今日日期。
- 目标是否存在。
- 热量。
- 蛋白质。
- 脂肪。
- 碳水。
- 早餐。
- 午餐。
- 晚餐。
- 加餐。
- 添加饮食按钮。

### 热量显示

```text
已摄入
1600 kcal

目标
2200 kcal

剩余
600 kcal

72.7%

```

如果超过目标：

```text
已摄入 2400
目标 2200
剩余 -200
超出 200 kcal
完成度 109.1%

```

API 不截断百分比。

UI 进度条视觉宽度可最大显示 100%，旁边显示真实百分比。

---

# 19. V1 数据模型

以下以 **MySQL 8.x** 作为 V1 数据库基线。

数据库统一约定：

- 存储引擎：`InnoDB`。
- 字符集：`utf8mb4`。
- 排序规则：建议使用 MySQL 8 默认的 `utf8mb4_0900_ai_ci`；如业务需要严格区分大小写/重音，再按字段单独指定。
- 主键：`BIGINT AUTO_INCREMENT`。
- 金额/营养等十进制定点数据：使用 `DECIMAL`，Java 使用 `BigDecimal`。
- 业务日期：使用 `DATE`。
- 系统时间：使用 `DATETIME(3)`，应用与 JDBC 统一按 UTC 写入和读取；用户时区单独保存在 `user_profile.timezone`。
- 物理表名建议使用复数形式：`users`、`user_profiles`、`nutrition_goals`、`food_categories`、`foods`、`food_nutrition`、`food_records`，避免与数据库函数/关键字产生歧义。
- `created_at` 默认 `CURRENT_TIMESTAMP(3)`；`updated_at` 推荐 `DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3)`，也可由 ORM 统一维护，但项目内必须二选一并保持一致。

---

## 19.1 user

### 职责

负责身份、登录、安全和账号状态。

| 字段类型Null默认说明  |              |   |          |                   |
| ------------- | ------------ | - | -------- | ----------------- |
| id            | BIGINT       | 否 | AUTO_INCREMENT | PK                |
| email         | VARCHAR(255) | 否 | -        | 登录账号              |
| password_hash | VARCHAR(255) | 否 | -        | 密码 Hash           |
| role          | VARCHAR(32)  | 否 | USER     | USER / ADMIN      |
| status        | VARCHAR(32)  | 否 | ACTIVE   | ACTIVE / DISABLED |
| last_login_at | DATETIME(3)  | 是 | null     | 最近登录              |
| created_at    | DATETIME(3)  | 否 | CURRENT_TIMESTAMP(3) | 创建                |
| updated_at    | DATETIME(3)  | 否 | CURRENT_TIMESTAMP(3) | 修改                |

唯一约束：

```sql
UNIQUE KEY uk_users_email (email)
```

业务层在注册、登录和修改邮箱时统一执行 `trim + lowercase`。在推荐的大小写不敏感排序规则下，唯一索引可进一步防止大小写不同但语义相同的重复邮箱。

索引：

```text
idx_user_status

```

逻辑删除：

不推荐 `is_deleted`。

账号状态使用：

```text
ACTIVE
DISABLED

```

真正账户删除未来单独设计隐私删除流程。

---

## 19.2 user_profile

### 职责

存放业务资料，与认证信息隔离。

| 字段类型Null默认说明 |              |   |          |         |
| ------------ | ------------ | - | -------- | ------- |
| id           | BIGINT       | 否 | AUTO_INCREMENT | PK      |
| user_id      | BIGINT       | 否 | -        | FK      |
| nickname     | VARCHAR(100) | 是 | null     | 昵称      |
| timezone     | VARCHAR(64)  | 否 | UTC/检测值  | IANA 时区 |
| created_at   | DATETIME(3)  | 否 | CURRENT_TIMESTAMP(3) |         |
| updated_at   | DATETIME(3)  | 否 | CURRENT_TIMESTAMP(3) |         |

约束：

```text
UNIQUE(user_id)

```

关系：

```text
user 1 : 1 user_profile

```

为什么拆表：

用户认证信息与业务资料生命周期不同。

未来：

- 身高。
- 性别。
- 出生日期。
- 健身目标。

也不会污染认证表。

---

## 19.3 nutrition_goal

### 职责

保存用户不同历史时期的每日营养目标。

| 字段类型Null默认   |               |   |          |
| ------------ | ------------- | - | -------- |
| id           | BIGINT        | 否 | AUTO_INCREMENT |
| user_id      | BIGINT        | 否 | -        |
| calories     | DECIMAL(10,2) | 否 | -        |
| protein      | DECIMAL(10,2) | 否 | -        |
| fat          | DECIMAL(10,2) | 否 | -        |
| carbohydrate | DECIMAL(10,2) | 否 | -        |
| start_date   | DATE          | 否 | -        |
| end_date     | DATE          | 是 | null     |
| created_at   | DATETIME(3)   | 否 | CURRENT_TIMESTAMP(3) |
| updated_at   | DATETIME(3)   | 否 | CURRENT_TIMESTAMP(3) |

索引：

```text
idx_goal_user_start_date
(user_id, start_date DESC)

idx_goal_user_date
(user_id, start_date, end_date)

```

MySQL 8.x 支持降序索引；如果实际查询计划没有收益，也可以简化为 `(user_id, start_date)`。V1 重点是保证 `user_id` 作为联合索引首列。

规则：

```text
end_date IS NULL OR end_date > start_date

```

同一用户目标区间禁止重叠。

MySQL 没有 PostgreSQL `daterange exclusion constraint` 这种直接的区间排斥约束，因此 **V1 由 Service 层事务保证区间不重叠**。推荐做法：

```text
1. 开启事务
2. 对当前用户已有目标记录执行必要的 SELECT ... FOR UPDATE
3. 校验新 start_date / end_date 是否与已有区间重叠
4. 若是“从某天开始启用新目标”，关闭上一目标的 end_date
5. 插入新目标
6. 提交事务
```

同时保留数据库基础 `CHECK`：

```sql
CHECK (end_date IS NULL OR end_date > start_date)
```

注意：该 `CHECK` 只能验证单行日期合法性，不能独立保证多行区间不重叠。

逻辑删除：

不推荐。

历史目标本身即是业务历史。

---

## 19.4 food_category

### 职责

管理食品分类。

| 字段类型Null默认 |              |   |          |
| ---------- | ------------ | - | -------- |
| id         | BIGINT       | 否 | AUTO_INCREMENT |
| name       | VARCHAR(100) | 否 | -        |
| sort_order | INT          | 否 | 0        |
| status     | VARCHAR(20)  | 否 | ACTIVE   |
| created_at | DATETIME(3)  | 否 | CURRENT_TIMESTAMP(3) |
| updated_at | DATETIME(3)  | 否 | CURRENT_TIMESTAMP(3) |

唯一：

```text
UNIQUE(name)

```

---

## 19.5 food

### 职责

描述食品实体，不直接承担营养快照。

| 字段类型Null默认说明 |              |   |          |                   |
| ------------ | ------------ | - | -------- | ----------------- |
| id           | BIGINT       | 否 | AUTO_INCREMENT | PK                |
| category_id  | BIGINT       | 是 | null     | 分类                |
| name         | VARCHAR(200) | 否 | -        | 中文名               |
| english_name | VARCHAR(200) | 是 | null     | 英文名               |
| brand_name   | VARCHAR(200) | 是 | null     | V1 可为空            |
| description  | TEXT         | 是 | null     |                   |
| status       | VARCHAR(20)  | 否 | ACTIVE   | ACTIVE / INACTIVE |
| created_by   | BIGINT       | 是 | null     | 管理员               |
| created_at   | DATETIME(3)  | 否 | CURRENT_TIMESTAMP(3) |                   |
| updated_at   | DATETIME(3)  | 否 | CURRENT_TIMESTAMP(3) |                   |

索引：

```text
idx_food_name
idx_food_category
idx_food_status

```

不建议：

```text
UNIQUE(name)

```

原因：

可能同时存在：

- 米饭。
- 糙米饭。
- 某品牌米饭。
- 不同营养来源的同名食品。

逻辑删除：

食品不建议真正删除。

使用：

```text
status = INACTIVE

```

历史记录不受影响。

---

## 19.6 food_nutrition

### 职责

保存食品当前标准营养数据。

V1 一个 food 对应一条当前 food_nutrition。

| 字段类型Null默认   |               |   |          |
| ------------ | ------------- | - | -------- |
| id           | BIGINT        | 否 | AUTO_INCREMENT |
| food_id      | BIGINT        | 否 | -        |
| basis_amount | DECIMAL(10,2) | 否 | 100      |
| basis_unit   | VARCHAR(16)   | 否 | g        |
| calories     | DECIMAL(10,3) | 否 | -        |
| protein      | DECIMAL(10,3) | 否 | -        |
| fat          | DECIMAL(10,3) | 否 | -        |
| carbohydrate | DECIMAL(10,3) | 否 | -        |
| data_source  | VARCHAR(255)  | 是 | null     |
| version      | INT           | 否 | 1        |
| created_at   | DATETIME(3)   | 否 | CURRENT_TIMESTAMP(3) |
| updated_at   | DATETIME(3)   | 否 | CURRENT_TIMESTAMP(3) |

唯一：

```text
UNIQUE(food_id)

```

为什么保留 version：

当管理员修改营养信息：

```text
version = version + 1

```

food_record 可以记录：

```text
food_nutrition_version

```

方便排查数据来源。

但 V1 不需要实现完整 food_nutrition_version 表。

### 备选方案

建立：

```text
food_nutrition_version

```

每次修改插入新行。

优点：

管理员可追溯历史。

缺点：

增加版本管理复杂度。

**V1 推荐暂不做。**

因为 food_record 已经通过快照解决用户历史数据问题。

---

## 19.7 food_record

### 职责

保存用户实际发生的一次食品摄入。

这是 V1 最重要的交易事实表。

| 字段类型Null默认说明                   |               |   |          |                |
| ------------------------------ | ------------- | - | -------- | -------------- |
| id                             | BIGINT        | 否 | AUTO_INCREMENT | PK             |
| user_id                        | BIGINT        | 否 | -        | 用户             |
| food_id                        | BIGINT        | 是 | -        | 原食品，可 SET NULL |
| food_nutrition_version         | INT           | 是 | null     | 来源版本           |
| food_name_snapshot             | VARCHAR(200)  | 否 | -        | 名称快照           |
| record_date                    | DATE          | 否 | -        | 用户本地业务日期       |
| meal_type                      | VARCHAR(20)   | 否 | -        | BREAKFAST 等    |
| weight_g                       | DECIMAL(10,2) | 否 | -        | 实际重量           |
| calories_per_100g_snapshot     | DECIMAL(10,3) | 否 | -        | 快照             |
| protein_per_100g_snapshot      | DECIMAL(10,3) | 否 | -        | 快照             |
| fat_per_100g_snapshot          | DECIMAL(10,3) | 否 | -        | 快照             |
| carbohydrate_per_100g_snapshot | DECIMAL(10,3) | 否 | -        | 快照             |
| calories                       | DECIMAL(12,3) | 否 | -        | 实际摄入           |
| protein                        | DECIMAL(12,3) | 否 | -        | 实际摄入           |
| fat                            | DECIMAL(12,3) | 否 | -        | 实际摄入           |
| carbohydrate                   | DECIMAL(12,3) | 否 | -        | 实际摄入           |
| client_request_id              | CHAR(36)      | 是 | null     | 幂等 UUID 字符串             |
| created_at                     | DATETIME(3)   | 否 | CURRENT_TIMESTAMP(3) |                |
| updated_at                     | DATETIME(3)   | 否 | CURRENT_TIMESTAMP(3) |                |

核心索引：

```text
idx_food_record_user_date
(user_id, record_date)

idx_food_record_user_date_meal
(user_id, record_date, meal_type)

idx_food_record_food
(food_id)

```

幂等唯一：

```text
UNIQUE(user_id, client_request_id)

```

其中 `client_request_id` 推荐 V1 使用 `CHAR(36)` 保存标准 UUID 字符串，便于 Java、前端和日志排查。

备选方案是 `BINARY(16)`，空间更小、索引更紧凑，但会增加 UUID 转换和调试复杂度；V1 不建议为了这点存储优化增加开发成本。

### food_id 为什么建议允许为空？

正常 V1 不删除 food。

但如果未来：

- 食品数据合并。
- 法务要求删除来源。
- 导入自定义食品。
- 食品被真正删除。

仍然能依靠：

```text
food_name_snapshot
nutrition snapshot

```

完整展示历史记录。

FK 可配置：

```text
ON DELETE SET NULL

```

---

# 20. ER 关系说明

```text
user
 │
 ├── 1:1 ── user_profile
 │
 ├── 1:N ── nutrition_goal
 │
 └── 1:N ── food_record

food_category
 │
 └── 1:N ── food

food
 │
 ├── 1:1 ── food_nutrition
 │
 └── 1:N ── food_record

```

核心原则：

**food 是主数据，food_record 是事实数据。**

food 可以变化。

food_record 已发生的事实不得被 food 的变化重写。

---

# 21. API 初步设计

统一前缀：

```text
/api/v1

```

## 21.1 Auth

| MethodURL权限说明 |                |        |      |
| ------------- | -------------- | ------ | ---- |
| POST          | /auth/register | Public | 注册   |
| POST          | /auth/login    | Public | 登录   |
| GET           | /users/me      | USER   | 当前用户 |

登录请求：

```json
{
  "email": "user@example.com",
  "password": "******"
}

```

---

## 21.2 User Profile

| MethodURL权限 |                   |      |
| ----------- | ----------------- | ---- |
| GET         | /users/me/profile | USER |
| PUT         | /users/me/profile | USER |

客户端不得传：

```text
userId

```

userId 始终从 JWT 获取。

---

## 21.3 Nutrition Goals

| MethodURL权限说明 |                                  |      |            |
| ------------- | -------------------------------- | ---- | ---------- |
| GET           | /nutrition-goals/current         | USER | 当前目标       |
| GET           | /nutrition-goals?date=2026-09-19 | USER | 查询指定日期目标   |
| GET           | /nutrition-goals/history         | USER | 历史         |
| POST          | /nutrition-goals                 | USER | 创建/切换目标    |
| PUT           | /nutrition-goals/{id}            | USER | 修正目标       |
| DELETE        | 不提供                              | -    | 历史目标不应随意删除 |

POST：

```json
{
  "calories": 2200,
  "protein": 160,
  "fat": 70,
  "carbohydrate": 250,
  "startDate": "2026-09-19"
}

```

服务端负责调整前一目标 end_date。

---

# 22. Food API

| MethodURL权限说明 |                  |      |      |
| ------------- | ---------------- | ---- | ---- |
| GET           | /foods           | USER | 搜索   |
| GET           | /foods/{foodId}  | USER | 食品详情 |
| GET           | /food-categories | USER | 分类   |

搜索：

```text
GET /api/v1/foods?keyword=米饭&categoryId=1&page=1&pageSize=20

```

普通用户只返回 ACTIVE。

---

# 23. Food Record API

| MethodURL权限 |                               |      |
| ----------- | ----------------------------- | ---- |
| POST        | /food-records                 | USER |
| GET         | /food-records/{id}            | USER |
| PUT         | /food-records/{id}            | USER |
| DELETE      | /food-records/{id}            | USER |
| GET         | /food-records?date=2026-09-19 | USER |

POST：

```json
{
  "foodId": 1001,
  "weightG": 400,
  "mealType": "LUNCH",
  "recordDate": "2026-09-19",
  "clientRequestId": "44a3d4c0-d5e0-4ecc-a44a-..."
}

```

客户端**不得提交最终 calories**。

服务器：

```text
1. 查询 food
2. 校验 ACTIVE
3. 查询 food_nutrition
4. 读取营养数据
5. BigDecimal 计算
6. 写入快照
7. 保存结果

```

---

# 24. Nutrition Summary API

推荐：

```text
GET /api/v1/nutrition/daily?date=2026-09-19

```

返回：

```json
{
  "code": "SUCCESS",
  "message": "success",
  "data": {
    "date": "2026-09-19",
    "goal": {
      "calories": 2200,
      "protein": 160,
      "fat": 70,
      "carbohydrate": 250
    },
    "consumed": {
      "calories": 1600,
      "protein": 110,
      "fat": 55,
      "carbohydrate": 170
    },
    "remaining": {
      "calories": 600,
      "protein": 50,
      "fat": 15,
      "carbohydrate": 80
    },
    "percentage": {
      "calories": 72.73,
      "protein": 68.75,
      "fat": 78.57,
      "carbohydrate": 68
    }
  }
}

```

如果超过：

```text
remaining 可以是负值。

```

例如：

```json
{
  "remaining": {
    "calories": -200
  }
}

```

UI 可转换为：

> 超出 200 kcal。

---

# 25. Admin API

| MethodURL权限 |                             |       |
| ----------- | --------------------------- | ----- |
| GET         | /admin/foods                | ADMIN |
| POST        | /admin/foods                | ADMIN |
| GET         | /admin/foods/{id}           | ADMIN |
| PUT         | /admin/foods/{id}           | ADMIN |
| PATCH       | /admin/foods/{id}/status    | ADMIN |
| GET         | /admin/food-categories      | ADMIN |
| POST        | /admin/food-categories      | ADMIN |
| PUT         | /admin/food-categories/{id} | ADMIN |

不建议：

```text
DELETE /admin/foods/{id}

```

推荐：

```text
ACTIVE
→
INACTIVE

```

---

# 26. 接口统一返回

推荐：

HTTP 状态码负责协议语义。

业务 code 使用稳定字符串。

```json
{
  "code": "SUCCESS",
  "message": "success",
  "data": {},
  "requestId": "abc123"
}

```

例如：

```text
200 成功
201 创建成功
400 参数错误
401 未认证
403 无权限
404 资源不存在
409 资源冲突 / 重复提交
422 业务校验失败
500 服务异常

```

不要出现：

```text
HTTP 200
{
  "code": 500
}

```

这种设计会增加网关、监控和客户端处理复杂度。

---

# 27. 权限模型

V1 使用简单 RBAC：

```text
USER
ADMIN

```

## 用户资源权限

最重要的原则：

**永远不要根据前端传来的 user_id 判断资源归属。**

例如：

错误：

```sql
SELECT *
FROM food_record
WHERE id = :recordId

```

然后直接返回。

正确：

```sql
SELECT *
FROM food_record
WHERE id = :recordId
AND user_id = :currentUserId

```

所有：

- GET。
- PUT。
- DELETE。

都必须检查资源归属。

管理员食品权限：

```text
ROLE_ADMIN

```

用户不得调用：

```text
/admin/**

```

---

# 28. 参数校验规则

| 参数规则                |                              |
| ------------------- | ---------------------------- |
| Email               | 合法格式，≤255                    |
| Password            | 推荐 ≥8，≤72/128                |
| calories target     | >0，建议 ≤20000                 |
| protein target      | ≥0，建议 ≤1000g                 |
| fat target          | ≥0，建议 ≤1000g                 |
| carbohydrate target | ≥0，建议 ≤2000g                 |
| food calories       | ≥0                           |
| food protein        | ≥0                           |
| food fat            | ≥0                           |
| food carbohydrate   | ≥0                           |
| weightG             | >0 且 ≤10000g                 |
| recordDate          | 合法日期                         |
| mealType            | BREAKFAST/LUNCH/DINNER/SNACK |
| name                | trim 后非空                     |
| category            | 必须存在且有效                      |

`999999g`：

拒绝。

返回：

```text
FOOD_RECORD_WEIGHT_OUT_OF_RANGE

```

10kg 上限建议做成配置：

```yaml
fitness:
  food-record:
    max-weight-grams: 10000

```

---

# 29. 精度设计

## 29.1 Java

**必须使用 BigDecimal。**

不推荐：

```java
double

```

因为：

```text
0.1 + 0.2

```

存在浮点精度问题。

营养数据本质上属于十进制业务数据。

推荐：

```java
BigDecimal

```

计算：

```java
nutrition
    .multiply(weight)
    .divide(new BigDecimal("100"), 6, RoundingMode.HALF_UP);

```

数据库可保留 3 位小数。

API：

- kcal 可展示 0\~1 位。
- 宏量营养展示 1 位。
- 底层不因为展示精度提前丢失数据。

---

# 30. 业务异常场景

| 场景系统行为                |                                               |
| --------------------- | --------------------------------------------- |
| 搜索不到食品                | 显示空状态；V1 提示“暂无匹配食品”                           |
| 输入 0g                 | 禁止提交                                          |
| 输入负数                  | 禁止提交                                          |
| 输入 999999g            | 超过单条最大重量，拒绝                                   |
| 未设置营养目标               | 允许记录饮食，但 Dashboard 不计算目标完成率                   |
| 没有当天记录                | consumed=0，显示空状态                              |
| 食品被停用                 | 禁止新增；历史记录正常显示                                 |
| 食品后来被删除               | 通过 food_name_snapshot 和 nutrition snapshot 显示 |
| 管理员修改食品营养             | 不影响历史记录                                       |
| 修改历史记录重量              | 按历史每100g快照重算                                  |
| 修改历史记录餐次              | 营养数据不变                                        |
| 修改历史记录日期              | 原日期与新日期统计均发生变化                                |
| 修改记录食品                | 使用新食品当前营养创建新快照                                |
| 删除饮食记录                | 实时 SUM 后自动变化                                  |
| 用户目标不存在               | target=null，percentage=null                   |
| 目标发生切换                | 按 record_date 查询当天目标                          |
| 目标日期重叠                | 创建时拒绝或自动关闭前一个区间                               |
| 跨时区                   | record_date 按用户时区决定                           |
| 用户修改时区                | 已有 record_date 不自动迁移                          |
| API 重复提交              | clientRequestId 去重                            |
| 用户连续双击保存              | 返回第一次创建结果                                     |
| 食品提交时被管理员停用           | 后端最终校验 status，拒绝                              |
| 管理员同时修改营养             | 使用 InnoDB 事务读取一致数据并写入快照                                 |
| mealType 非法           | 400                                           |
| foodId 不存在            | 404                                           |
| foodId 属于 INACTIVE    | 422                                           |
| 用户访问他人记录              | 返回 404 或 403，推荐 404 减少资源枚举                    |
| 页面网络超时                | 保留用户输入，可重试                                    |
| POST 超时但实际成功          | 相同 clientRequestId 重试返回原记录                    |
| calories 与宏量营养计算不完全匹配 | 允许，营养标签并不一定严格满足 4/4/9                         |
| 管理员填写负营养              | 拒绝                                            |
| 记录当天数据异常大             | 后端校验并记录 warning                               |
| recordDate 极远未来       | V1 建议仅允许 today±合理区间，如过去5年到未来1天                |
| 删除目标                  | V1 不允许                                        |
| 分类停用                  | 已有食品保留分类；普通搜索不作为可选分类展示                        |

---

# 31. 时区设计

推荐：

user_profile 保存：

```text
timezone = Asia/Shanghai
America/Los_Angeles
...

```

使用 IANA Time Zone。

不要保存：

```text
GMT+8

```

原因：

无法正确处理 DST。

业务字段：

```text
record_date = DATE

```

记录的是：

> 用户认为这是哪一天吃的。

created_at：

```text
DATETIME(3)
```

MySQL `DATETIME` 本身不携带时区信息，因此项目必须建立统一约定：

- Java / Spring Boot 以 UTC 处理系统时间。
- JDBC 连接时区配置为 UTC。
- `created_at`、`updated_at`、`last_login_at` 等统一写入 UTC。
- 对用户展示时，再根据 `user_profile.timezone` 转换。

不要把用户本地时间直接写进系统审计时间字段。

### 修改时区

不自动改变历史：

```text
record_date

```

否则用户历史会出现“昨天的晚餐跑到今天”的问题。

---

# 32. 性能设计

## 32.1 V1 推荐方案

**不建立 daily_nutrition_summary。**

直接：

```sql
SELECT
    SUM(calories),
    SUM(protein),
    SUM(fat),
    SUM(carbohydrate)
FROM food_record
WHERE user_id = ?
AND record_date = ?

```

有：

```text
(user_id, record_date)

```

联合索引以后，单用户单日通常只有数十条数据。

实时 SUM 成本极低。

### 为什么不提前做 summary 表？

增加：

- 创建记录同步。
- 修改同步。
- 删除同步。
- 事务一致性。
- 数据修复。
- 缓存失效。

对于 MVP 不值得。

---

## 32.2 什么时候增加 daily_nutrition_summary？

出现以下之一：

- 单日统计接口 P95 > 200ms。
- DAU 显著增长。
- 教练需要一次查询数百名学员。
- 首页趋势需要跨数百天聚合。
- AI 高频查询历史营养。

再增加：

```text
daily_nutrition_summary

```

或异步汇总。

---

## 32.3 Redis

V1：

Redis **不是业务必需组件**。

推荐：

先不用于营养汇总。

后期可用于：

- Refresh Token Session。
- 登录限流。
- 热门食品。
- 搜索缓存。
- 分布式锁。
- AI 会话。
- Dashboard 短 TTL 缓存。

避免出现：

```text
数据库数据正确
Redis 汇总错误

```

这种双写一致性问题。

---

# 33. 安全需求

## 33.1 JWT

推荐：

```text
Authorization: Bearer <token>

```

JWT 至少包含：

```text
sub/userId
role
iat
exp

```

不要存放：

- 密码。
- 敏感个人资料。
- 营养记录。

### Token 策略

V1 最简单方案：

- Access Token。
- 生命周期较短。

后续 P1：

- Access Token。
- Refresh Token。
- Redis / DB session 管理。

---

## 33.2 密码

推荐：

Spring Security BCrypt。

例如：

```text
BCrypt cost 10~12

```

不得：

- 明文。
- MD5。
- SHA256 直接 Hash。

---

## 33.3 接口安全

必须：

- Spring Security。
- RBAC。
- 参数校验。
- 防越权。
- 请求体大小限制。
- 登录限流。
- 管理员接口鉴权。
- SQL 参数化。
- 不记录 Authorization Header。
- 不记录密码。

---

# 34. 日志与监控

## 34.1 应用日志

需要：

- requestId / traceId。
- API。
- HTTP status。
- 耗时。
- 错误码。
- 异常 stack trace。

禁止记录：

- 密码。
- JWT。
- 完整认证 Header。

---

## 34.2 登录日志

建议记录：

```text
user_id
login_time
success
ip
user_agent
failure_reason

```

V1 可日志文件完成。

不必立即建表。

---

## 34.3 管理员操作日志

推荐至少记录：

```text
admin_id
action
resource_type
resource_id
before
after
created_at

```

尤其：

- 修改食物营养。
- 停用食品。
- 修改分类。

V1 若时间有限，可首先写结构化日志。

后续再建立：

```text
admin_audit_log

```

---

# 35. 统一异常处理

Spring Boot：

```text
@RestControllerAdvice

```

统一处理：

- MethodArgumentNotValidException。
- ConstraintViolationException。
- AuthenticationException。
- AccessDeniedException。
- BusinessException。
- ResourceNotFoundException。
- DuplicateRequestException。
- Exception。

推荐业务错误码：

```text
AUTH_INVALID_CREDENTIALS
USER_EMAIL_EXISTS

FOOD_NOT_FOUND
FOOD_INACTIVE

FOOD_RECORD_NOT_FOUND
FOOD_RECORD_WEIGHT_INVALID

NUTRITION_GOAL_NOT_FOUND
NUTRITION_GOAL_DATE_CONFLICT

PERMISSION_DENIED
DUPLICATE_REQUEST
INTERNAL_ERROR

```

---

# 36. Dashboard 数据查询建议

不要要求前端自己分别请求：

```text
goal
food records
sum

```

再组合。

推荐 Dashboard 使用：

```text
GET /nutrition/daily
GET /food-records

```

两次请求已经足够。

如果以后发现请求次数问题，再提供：

```text
GET /dashboard?date=

```

聚合 DTO。

**V1 不必为了“一个接口解决全部”专门构建 BFF。**

---

# 37. 数据统计指标

产品分析至少埋以下指标。

## 激活

- 注册人数。
- 注册后完成目标设置比例。
- 注册后 24h 内完成第一条饮食记录比例。

## 使用

- DAU。
- 饮食记录用户数。
- 每用户每日记录数。
- 有效记录天数。
- 连续记录天数。

## 核心漏斗

```text
进入 Dashboard
→ 点击添加
→ 搜索食品
→ 选择食品
→ 输入重量
→ 提交成功

```

统计各节点转化率。

## 搜索质量

- 搜索次数。
- 搜索无结果率。
- 搜索后创建记录比例。
- 热门搜索关键词。

## 快捷功能评估

为 V1.1 判断优先级：

- 用户每日重复食品比例。
- 相邻日期重复食品比例。
- 相同早餐重复比例。

---

# 38. V1 验收标准

## 38.1 账户

- 可以成功注册。
- 重复 Email 不允许注册。
- 密码安全保存。
- 登录后得到 JWT。
- 未登录无法访问业务接口。

## 38.2 营养目标

- 可以创建目标。
- 可以查询当前目标。
- 可以查询历史目标。
- 修改目标不会覆盖历史区间。
- 指定日期能匹配正确目标。
- 同一天不存在两个有效目标。

## 38.3 食物

- 管理员可创建。
- 管理员可编辑。
- 管理员可停用。
- 用户能搜索 ACTIVE 食品。
- INACTIVE 不允许新增记录。

## 38.4 饮食记录

输入：

```text
米饭
116 kcal
2.6 P
0.3 F
25.9 C

```

400g 后必须得到：

```text
464 kcal
10.4 protein
1.2 fat
103.6 carbohydrate

```

允许内部保留更多小数，但展示必须符合舍入规则。

## 38.5 快照

管理员将：

```text
米饭 116 kcal

```

改成：

```text
130 kcal

```

此前历史 400g 米饭必须仍为：

```text
464 kcal

```

这是 P0 验收条件。

## 38.6 修改

将该记录：

```text
400g → 300g

```

必须基于原来的：

```text
116 kcal / 100g

```

得到：

```text
348 kcal

```

而不是按新的 130 kcal 计算。

## 38.7 权限

User A：

```text
GET /food-records/{UserBRecordId}

```

不得读取 User B 数据。

PUT / DELETE 同样如此。

---

# 39. MVP Definition of Done

V1 可以判定完成必须同时满足：

### 功能

- 注册登录完成。
- 营养目标闭环完成。
- 食品库完成。
- 食品搜索完成。
- 饮食 CRUD 完成。
- Dashboard 完成。
- 历史记录完成。
- Admin 食品管理完成。

### 数据

- 营养快照正确。
- 目标历史正确。
- 时区方案落地。
- BigDecimal 全链路正确。
- 用户数据隔离正确。

### 质量

- 核心 API 集成测试。
- 营养计算单元测试。
- 越权测试。
- 重复提交测试。
- 食品停用测试。
- 快照测试。
- 目标时间区间测试。

### 运维

- 环境变量。
- DB migration。
- 日志。
- 全局异常。
- 基础健康检查。
- README 部署说明。

---

# 40. 推荐系统架构

V1 推荐：

```text
Vue SPA
   │
   ▼
Spring Boot REST API
   │
   ├── MySQL 8.x
   │
   └── MinIO（V1 可不启用）

```

Redis：

```text
optional

```

不要一开始设计：

- 微服务。
- MQ。
- CQRS。
- Event Sourcing。
- Elasticsearch。
- Kubernetes。
- 独立统计服务。

推荐：

**模块化单体 Modular Monolith。**

后端结构：

```text
auth
user
nutrition
food
foodrecord
admin
common

```

后续增加：

```text
body
workout
coach
ai
knowledge

```

即可。

---

# 41. MySQL 8.x 技术基线

本项目确定使用 **MySQL 8.x**，V1 不再保留 PostgreSQL 作为主实现方案。

## 41.1 推荐配置

```text
Database: MySQL 8.x
Engine: InnoDB
Charset: utf8mb4
Collation: utf8mb4_0900_ai_ci
Migration: Flyway
ORM: MyBatis-Plus
Application Timezone: UTC
User Timezone: IANA Time Zone
```

选择原因：

- 与 Java / Spring Boot / MyBatis-Plus 配合成熟。
- 个人开发、部署、备份和运维成本较低。
- V1 的用户、食品、记录、目标和统计均属于典型关系型业务，MySQL 能充分满足。
- `InnoDB` 可以满足事务、行锁、外键和一致性要求。
- 后续训练、教练等业务仍适合继续使用同一关系型数据库。

## 41.2 MySQL 下的设计注意事项

1. **时间字段**：MySQL 没有 PostgreSQL `TIMESTAMPTZ`。本项目使用 `DATETIME(3)` + 应用层 UTC 约定，并单独保存用户 IANA 时区。
2. **目标区间约束**：MySQL 无原生区间排斥约束，营养目标时间段的“不重叠”由 Service 事务 + 行锁保证。
3. **UUID**：V1 的幂等键使用 `CHAR(36)`，不使用数据库原生 UUID 类型。
4. **邮箱唯一性**：应用层统一 lowercase，数据库使用 `UNIQUE(email)`。
5. **模糊搜索**：`LIKE '%关键词%'` 在数据量较大时无法充分利用普通 B-Tree 索引。V1 食品规模可接受；达到明显性能瓶颈后再评估 MySQL FULLTEXT/ngram 或 Elasticsearch。
6. **CHECK**：以 MySQL 8.x 为基线，可以使用 `CHECK` 处理单行数值和日期合法性，但跨行业务规则仍必须由 Service 保证。

## 41.3 对未来 AI / RAG 的影响

继续使用 MySQL 作为核心交易数据库，不需要因为未来 RAG 更换 V1 数据库。

未来向量检索层应作为独立能力演进：

```text
MySQL
  └── 用户、饮食、身体、训练、教练等业务事实数据

Vector Store / Retrieval Service
  └── 文档 Chunk、Embedding、向量检索、Rerank
```

即：**业务事实继续由 MySQL 管理；RAG 检索能力按实际规模再选独立向量数据库或向量检索服务。**

V1 不引入向量数据库。

---

# 42. MyBatis-Plus vs JPA

两种均可。

## 推荐

如果项目偏：

- CRUD。
- 自己控制 SQL。
- 中国 Java 技术生态。

使用：

**MyBatis-Plus。**

## JPA 更适合

团队熟悉 Domain Model 并接受 ORM 行为时。

对于 V1，不要混用两套 ORM。

---

# 43. V1.1 快速记录

目标：

> 将一次记录从“搜索 → 选择 → 输入”缩短为“两三次操作”。

核心：

- 最近吃过。
- 收藏。
- 常吃。
- 复制上一餐。
- 复制昨天某餐。
- 复制昨天全部。
- 一次添加多个食品。
- 自定义食品。

### 最近吃过

无需新表。

可以：

```sql
SELECT food_id, MAX(record_date)
FROM food_record
WHERE user_id = ?
GROUP BY food_id
ORDER BY MAX(created_at) DESC
LIMIT 20

```

后续数据量大再优化。

### 常吃

同样可以由：

```text
过去30天 food_id 次数

```

计算。

不需要一开始建立 `frequent_food` 表。

---

# 44. V1.5 身体数据

目标：

把“吃多少”与“身体变化”建立关联。

新增：

```text
body_measurement

```

字段规划：

```text
id
user_id
record_date
weight
body_fat_percentage
muscle_mass
waist
chest
arm
thigh
created_at

```

未来派生计算：

- BMI。
- BMR。
- TDEE。
- 体重趋势。
- 周平均体重。
- 热量缺口。

原则：

原始测量值持久化。

BMI/BMR/TDEE 尽量作为：

- 计算结果。
- 或带算法版本的快照。

避免无法解释历史。

---

# 45. V2 动作库

核心实体：

## exercise

```text
id
name_cn
name_en
difficulty
description
instructions
precautions
common_mistakes
equipment_id
status

```

## muscle_group

```text
id
name_cn
name_en
parent_id

```

## exercise_muscle

```text
exercise_id
muscle_group_id
role

```

role：

```text
PRIMARY
SECONDARY

```

## exercise_media

```text
id
exercise_id
media_type
storage_key
source
copyright_type
license
author
sort_order

```

media_type：

```text
IMAGE
GIF
VIDEO

```

### 版权要求

严禁直接批量抓取互联网图片/GIF 用于商业系统。

资源必须明确：

- 自制。
- 获得许可。
- 可商业使用版权。
- 授权来源。

---

# 46. V2 训练记录

## workout_plan

训练计划。

```text
id
user_id
name
start_date
end_date
status

```

## workout_plan_item

```text
id
plan_id
exercise_id
day_index
sort_order
target_sets
target_reps
target_weight
target_rpe

```

## workout_session

一次实际训练。

```text
id
user_id
plan_id
started_at
ended_at
duration_seconds
notes

```

## workout_set

实际一组。

```text
id
session_id
exercise_id
set_number
weight
reps
rpe
rir
set_type
completed_at

```

训练容量：

```text
volume = weight × reps

```

Session 容量：

```text
SUM(all completed sets)

```

---

# 47. V2.5 训练统计

目标：

从记录升级到趋势分析。

核心：

- 动作训练历史。
- 最高重量。
- Rep PR。
- 估算 1RM。
- 周训练组数。
- 肌群训练量。
- 月训练量。
- 训练频率。
- 时间趋势。

PR 计算规则必须固定定义。

例如不能简单认为：

```text
100kg×1

```

与：

```text
90kg×5

```

谁是统一“更强”。

应分别记录：

- Weight PR。
- Rep PR。
- Estimated 1RM PR。

---

# 48. V3 真人教练

核心模型：

```text
coach
coach_student
coach_plan
coach_feedback
coach_message
appointment

```

## coach_student

必须包含：

```text
coach_id
student_id
status
started_at
ended_at
permission_scope

```

未来最关键的问题不是 UI，而是：

**数据授权。**

用户必须能够明确控制教练能访问：

- 身体数据。
- 饮食数据。
- 训练数据。
- 历史范围。

绑定解除后必须及时撤销权限。

---

# 49. 产品版本路线图

| 版本目标核心功能前置依赖技术重点主要风险验收 |               |                          |             |                           |         |           |
| ---------------------- | ------------- | ------------------------ | ----------- | ------------------------- | ------- | --------- |
| V1                     | 打通饮食闭环        | 用户、食品、目标、饮食、统计、历史        | 无           | 快照、权限、精度                  | 数据模型错误  | 完整记录闭环    |
| V1.1                   | 提高记录效率        | 最近、收藏、常吃、复制、自定义          | V1 数据稳定     | 查询优化                      | 快捷逻辑变复杂 | 高频饮食 ≤3步  |
| V1.5                   | 身体趋势          | 体重、体脂、围度、TDEE            | V1 用户体系     | 时间序列                      | 公式解释    | 可展示趋势     |
| V2                     | 训练闭环          | 动作、媒体、计划、训练记录            | 用户体系        | 训练实体模型                    | 动作版权    | 可完成一次训练   |
| V2.5                   | 训练分析          | PR、容量、周统计                | V2          | 聚合计算                      | 指标定义    | 历史趋势准确    |
| V3                     | 教练业务          | 教练、学员、计划、反馈              | V1.5+V2     | 授权模型                      | 隐私      | 教练闭环      |
| V4                     | AI Chat       | LangChain4j、Tool Calling | 业务 API 稳定   | Tool 边界                   | AI 幻觉   | AI 可读业务数据 |
| V4.5                   | 专业知识          | RAG                      | AI Chat     | Chunk、Embedding、Retrieval | 知识质量    | 答案可溯源     |
| V5                     | Fitness Agent | NL 录入、分析、计划辅助            | Tool + RAG  | Agent orchestration       | 错误执行    | 可完成复合任务   |
| V6                     | AI+Coach      | AI 辅助真人教练                | Coach+Agent | Human-in-loop             | 权责边界    | 教练有效审核 AI |

---

# 50. AI Agent 长期架构规划

核心原则：

> LLM 负责“理解和编排”，Java 负责“事实和计算”。

不允许让 LLM 自己凭感觉计算：

- 摄入热量。
- BMI。
- TDEE。
- 训练容量。
- 1RM。
- 数据统计。

架构：

```text
User
 ↓
AI Chat
 ↓
LangChain4j Agent
 ├── Intent Understanding
 ├── Chat Memory
 ├── RAG
 └── Tool Calling
       ↓
   Java Domain Services
       ↓
   MySQL 8.x

```

---

# 51. Agent Tool 规划

未来：

```text
getUserProfile
getTodayNutrition
getNutritionHistory
searchFood
addFoodRecord

getBodyMeasurements

getWorkoutHistory
getExerciseHistory
getCurrentWorkoutPlan

calculateBMI
calculateBMR
calculateTDEE
calculateOneRepMax

createWorkoutPlan
adjustNutritionGoal

```

Tool 不应该直接暴露：

```text
repository
SQL
database table

```

Tool 对应领域业务能力。

例如：

错误：

```text
executeSql(sql)

```

正确：

```text
getTodayNutrition()

```

---

# 52. AI 自然语言饮食录入

用户：

> 我刚才吃了 300g 米饭、200g 鸡胸肉和两个鸡蛋。

Agent：

```text
解析实体
 ↓
米饭 300g
鸡胸肉 200g
鸡蛋 2个
 ↓
searchFood()
 ↓
候选匹配
 ↓
单位换算
 ↓
必要时让用户确认歧义
 ↓
addFoodRecord()
 ↓
getTodayNutrition()
 ↓
生成自然语言反馈

```

注意：

“两个鸡蛋”必须依赖未来单位模型：

```text
1个鸡蛋 = X g

```

不能由 LLM 随意假设重量。

---

# 53. Agent 写操作安全

未来 AI Tool Calling 对：

```text
addFoodRecord
adjustNutritionGoal
createWorkoutPlan

```

应区分读取与写入。

建议：

读取 Tool：

可直接调用。

修改业务数据：

根据影响程度设计确认。

例如：

> 把我今天目标改成 1500 kcal。

Agent 应明确：

```text
从今天开始？
仅今天？
永久调整？

```

然后调用确定性 Java Service。

所有 Tool 写操作需要：

- user context。
- permission。
- idempotency。
- audit log。

---

# 54. RAG 知识库规划

内容：

- 营养学。
- 减脂。
- 增肌。
- 力量训练。
- RPE。
- RIR。
- 恢复。
- 睡眠。
- 蛋白质。
- 碳水。
- 脂肪。
- 补剂。
- FAQ。
- 研究论文。
- 教练内容。

---

# 55. RAG Metadata

推荐：

```json
{
  "category": "nutrition",
  "topic": "protein",
  "level": "intermediate",
  "source": "xxx",
  "author": "xxx",
  "publishDate": "2026-01-01",
  "version": "1.0",
  "language": "zh-CN",
  "contentType": "research",
  "license": "..."
}

```

额外建议：

```text
review_status
reviewed_by
reviewed_at
source_url
document_version

```

---

# 56. RAG Pipeline

长期：

```text
Document
 ↓
Document Validation
 ↓
Cleaning
 ↓
Chunk
 ↓
Metadata
 ↓
Embedding
 ↓
Vector Database
 ↓
Retrieval
 ↓
Metadata Filter
 ↓
Rerank
 ↓
Context
 ↓
LLM
 ↓
Answer + Citation

```

推荐优先保证：

**知识质量 > Embedding 模型复杂程度。**

---

# 57. RAG 版本与版权

必须解决：

- 文档版权。
- 来源。
- 作者。
- 是否允许商用。
- 内容发布日期。
- 是否过期。
- 是否经过审核。

特别是：

- 付费课程。
- 商业教练内容。
- 研究论文全文。

不能默认拥有再分发或训练权利。

---

# 58. 不同设计方案的最终推荐

| 问题推荐方案原因备选   |                |                  |                      |
| ------------ | -------------- | ---------------- | -------------------- |
| 数据库          | MySQL 8.x      | Java 生态成熟、V1 足够、个人开发运维简单 | MySQL 8.x（非本项目主方案） |
| 后端架构         | 模块化单体          | 个人开发最合适          | 微服务后期再拆              |
| ORM          | MyBatis-Plus   | CRUD简单，SQL透明     | JPA                  |
| 数值           | BigDecimal     | 十进制准确            | 不使用 double           |
| 食品历史         | food_record 快照 | 防历史漂移            | food nutrition 完整版本表 |
| 目标历史         | 时间区间           | 查询明确             | 每日快照                 |
| Dashboard 汇总 | SQL SUM        | 简单准确             | summary 表后期          |
| Redis        | V1 非强依赖        | 避免复杂度            | Token/限流可加入          |
| 食品删除         | INACTIVE       | 保留关系             | ON DELETE SET NULL   |
| 食品记录删除       | V1 物理删除        | 简单               | Soft Delete          |
| 时区           | IANA + DATE    | 业务语义稳定           | UTC 日期推导             |
| 搜索           | DB LIKE        | V1 足够            | Elasticsearch 后期     |
| 单位           | V1 只支持 g       | 避免错误换算           | V1.1/V1.2 单位体系       |

---

# 59. 项目风险

## 59.1 食品数据来源

最大的产品风险之一不是代码，而是：

> 食物库从哪里来？

需要确定：

- 人工录入。
- 公共数据库。
- 商业数据源。
- 是否允许商用。
- 营养单位是否统一。

---

## 59.2 数据质量

同一食物可能存在不同数据：

```text
鸡胸肉 生
鸡胸肉 熟
鸡胸肉 去皮
鸡胸肉 带皮

```

因此食品名称和描述必须具体。

后续建议增加：

```text
preparation_method
raw_or_cooked

```

但不建议 V1 强制建复杂 taxonomy。

---

## 59.3 快照遗漏

如果 V1 只保存：

```text
food_id + weight

```

以后几乎一定会出现历史数据漂移。

必须在 V1 就正确解决。

---

## 59.4 目标版本冲突

如果目标使用：

```text
active=true

```

而没有时间区间，很快会遇到历史目标问题。

V1 必须建立：

```text
start_date / end_date

```

机制。

---

## 59.5 功能膨胀

最大研发风险：

还没把饮食记录做好，就开始开发：

- 训练。
- AI。
- 教练。
- RAG。

建议严格冻结 V1 Scope。

---

## 59.6 AI 过早介入

在业务 API 尚不可靠时加入 Agent，会造成：

```text
不可靠业务系统
+
不确定性 LLM
=
更难定位问题

```

先完成可靠业务服务。

AI 最后成为“业务能力调用层”。

---

# 60. 待确认问题

进入 UI / DB 开发前建议确认以下产品决策：

1. 首发市场是否主要为中文用户。
2. 用户名是否真正需要，还是 Email + nickname 足够。
3. 是否要求邮箱验证。
4. V1 食品数据来源。
5. 食品数据版权是否合法。
6. V1 是否允许管理员批量 CSV 导入食品。
7. 是否考虑“生/熟”食品区别。
8. calories 是否允许小数展示。
9. 食物重量上限最终取 10kg 还是其他值。
10. 历史日期最早允许记录多久。
11. 是否允许记录未来日期。
12. 是否允许用户修改过去的营养目标。
13. 是否需要管理员审计日志落数据库。
14. V1 是否需要 Refresh Token。
15. 用户是否可以修改 Email。
16. 账户注销是否进入 V1。
17. 是否需要导出个人数据。
18. 自定义食品是否提前进入 V1。
19. V1 是否只支持 g。
20. 首页是否默认直接包含搜索框，还是点击“添加饮食”进入新页面。

其中真正阻塞数据库/API 开发的主要是：

```text
食品数据来源
目标历史修改策略
重量/单位策略
时区策略

```

其余多数可以后续决定。

---

# 61. 建议的 V1 开发顺序

不要先做页面。

优先确定领域规则和数据库。

推荐研发顺序：

```text
Schema
 ↓
Domain Rules
 ↓
API
 ↓
Backend Tests
 ↓
Frontend
 ↓
Integration
 ↓
Admin
 ↓
E2E

```

---

# 62. 从 PRD 到开发的下一步执行清单

## Phase 1：冻结 V1 Scope

完成：

- 确认 P0。
- 将 P1/P2 从 V1 backlog 移除。
- 明确食品数据来源。
- 明确单位只支持 g。
- 明确目标时间历史规则。
- 明确时区规则。

产物：

```text
V1 Scope Baseline

```

---

## Phase 2：设计数据库

首先创建 ERD。

实现：

```text
users
user_profiles
nutrition_goals
food_categories
foods
food_nutrition
food_records

```

确认：

- PK。
- FK。
- UNIQUE。
- INDEX。
- CHECK。
- decimal 精度。
- 时间类型。

使用：

```text
Flyway / Liquibase

```

管理 migration。

推荐 Flyway。

---

## Phase 3：设计 API Contract

先定义：

```text
OpenAPI 3

```

明确：

- URL。
- HTTP method。
- request。
- response。
- error code。
- permission。
- pagination。

完成以后再写 Controller。

---

## Phase 4：建立 Spring Boot 基础工程

模块：

```text
common
auth
user
nutrition
food
foodrecord
admin

```

完成：

- Spring Security。
- JWT。
- Exception Handler。
- Validation。
- Jackson。
- DB migration。
- ORM。
- logging。

---

## Phase 5：先实现最关键领域测试

第一批单元测试：

### 营养计算

```text
116 × 400 / 100 = 464

```

### 快照

食品数据修改后历史不变。

### 编辑记录

历史记录重量修改使用历史快照。

### 营养目标

不同日期命中不同目标。

### 权限

A 不能读取 B。

这些测试通过以后再继续 UI。

---

## Phase 6：实现 Auth

完成：

```text
register
login
current user

```

再开始任何用户业务。

---

## Phase 7：实现食品后台

先让系统里有可靠数据。

完成：

```text
分类 CRUD
食品 CRUD
营养 CRUD
启用/停用

```

可以先用管理员 API + Swagger 操作。

前期甚至不需要立即做 Admin UI。

---

## Phase 8：实现营养目标

完成：

```text
create
current
date query
history
transition

```

重点测试时间区间。

---

## Phase 9：实现饮食记录

完成：

```text
create
update
delete
daily list

```

确保：

```text
snapshot
BigDecimal
idempotency
ownership

```

全部正确。

---

## Phase 10：实现 Daily Nutrition Service

后端：

```text
Goal
+
SUM(food_record)
=
DailyNutrition

```

不要缓存。

不要 summary table。

先确保计算正确。

---

## Phase 11：Vue 前端基础

建立：

```text
Vue Router
Pinia
Axios
Auth interceptor
Global error handler
Element Plus

```

路由权限：

```text
guest
authenticated
admin

```

---

## Phase 12：开发页面

顺序：

```text
Login
Register
Nutrition Goal
Dashboard
Food Search
Add Record
History
Edit Record
Profile
Admin Food

```

Dashboard 不建议第一个写，因为它依赖最多后端能力。

---

## Phase 13：E2E 核心流程

测试：

```text
注册
↓
登录
↓
设置2200 kcal
↓
添加400g米饭
↓
Dashboard显示464 kcal
↓
管理员修改米饭
↓
历史仍然464
↓
修改为300g
↓
得到348
↓
删除
↓
Dashboard减少348

```

这条 E2E 通过以后，V1 的核心架构基本成立。

---

## Phase 14：安全测试

必须手工或自动测试：

```text
A访问B记录
普通用户访问admin
伪造userId
过期JWT
无JWT
非法mealType
负数weight
超大weight
重复POST

```

---

## Phase 15：性能基线

使用至少：

```text
10万 food_record
1万 food

```

做基本测试。

重点：

```text
GET /nutrition/daily
GET /food-records?date=
GET /foods?keyword=

```

只要索引合理，V1 无需 Redis。

---

## Phase 16：部署

推荐个人开发初期：

```text
Nginx
Vue static
Spring Boot
MySQL 8.x
Docker Compose

```

暂不需要 Kubernetes。

环境：

```text
dev
test
prod

```

敏感信息：

```text
DB Password
JWT Secret
OSS Secret

```

全部从环境变量读取。

---

# 63. 最终 V1 架构结论

V1 最正确的技术方向不是增加更多组件，而是确保四件事：

**第一：饮食记录是一条可靠事实记录。**

所以必须保存营养快照。

**第二：营养目标是有时间维度的。**

所以必须使用：

```text
start_date
end_date

```

而不是覆盖旧值。

**第三：统计应该从可靠事实数据计算。**

所以 V1：

```text
food_record
→ SUM
→ DailyNutrition

```

不需要 Redis 汇总，也不需要 daily summary。

**第四：为未来扩展预留领域边界，而不是提前实现未来架构。**

V1：

```text
auth
user
nutrition
food
foodrecord

```

以后自然扩展：

```text
body
workout
coach
knowledge
ai

```

而不需要现在就引入微服务、消息队列、向量数据库或复杂 Agent。

这能够同时满足：

- 个人开发者可以实际完成。
- V1 不过度设计。
- 数据模型足够可靠。
- 后续训练模块可以加入。
- 教练权限可以扩展。
- AI 能通过 Tool 调用已有稳定业务能力。
- RAG 可以独立演进。
- 不需要为了未来需求重写最核心的用户、日期、饮食和权限模型。
# Fitness Platform — PRD V2：Fitness Agent Core（实现对齐版）

## 一、版本概述

V2 是项目从传统健身饮食管理系统进入 AI 应用阶段的核心版本。

本版本不让 AI 建立自己的数据体系，而是把 V1～V1.2 已经稳定的 Food、Nutrition Goal、Food Record、Analytics 等业务能力封装为 Domain Tool，通过 LangChain4j + Tool Calling 提供自然语言查询和自然语言饮食录入。

AI 的职责限定为：

- 理解用户意图；
- Structured Output 参数抽取；
- 选择 Tool；
- 组织结果表达。

Java Service 继续负责：

- JWT 用户上下文；
- 权限；
- 业务校验；
- Food 匹配规则；
- BigDecimal 营养计算；
- 历史快照；
- 事务；
- 幂等；
- 持久化。

所有 AI 写操作都必须经过用户确认。

## 二、用户核心问题

- 我能不能直接说“中午吃了 200g 鸡胸和 150g 米饭”，系统帮我整理成记录？
- AI 搜到多个“牛奶”时，会不会自己乱选？
- 我能不能问“今天还差多少蛋白质”，AI 直接查询我的真实数据？
- AI 会不会直接操作数据库、绕过原来的业务规则？
- 网络超时、SSE 断开或 Tool 重试会不会重复记录？
- 多轮对话时，“刚才那个”能不能理解？
- AI 处理过程出错时，开发者能不能定位是 Intent、Tool、RAG 还是业务 Service 出问题？

## 三、版本目标

1. Dashboard/独立页面提供 AI 输入入口；
2. 支持文字输入；
3. 支持语音转文字后再发送；
4. 使用 LangChain4j 集成 LLM 与 Tool Calling；
5. Food Search、Nutrition Query、Food Record 等业务能力封装为 Domain Tool；
6. Structured Output 将自由文本转换为结构化意图参数；
7. Food/单位存在歧义时进入 Resolve 流程；
8. 所有写操作形成 Draft + Preview；
9. 用户点击 Confirm 后才执行正式 Tool；
10. 使用 JWT 当前用户上下文绑定数据归属；
11. 使用 Redis 保存短期 Conversation Memory/Pending Action；
12. 使用 requestId/幂等机制避免重复写入；
13. 使用 SSE 输出流式回答和业务状态；
14. 建立 Agent Run / Tool Call Trace；
15. AI 不可用时传统页面仍正常使用。

## 四、功能范围

本版本包含：

- AI Chat 基础页面；
- Text Input；
- Speech-to-Text Input；
- Intent Recognition；
- Structured Output；
- Tool Registry / Tool Calling；
- Food Search Tool；
- Nutrition Query Tool；
- Food Record Draft；
- Food Record Execute Tool；
- Nutrition Goal Query；
- Analytics Query；
- Preview / Confirm / Cancel；
- Conversation Memory；
- Pending Action；
- requestId 幂等；
- SSE；
- Agent/Tool Trace；
- 安全与降级。

本版本不包含：

- RAG（V2.1）；
- AI 图片食物识别；
- 自动训练计划；
- 训练写 Tool；
- 任意 Excel/PDF 历史导入；
- AI 自动修改 Goal；
- Autonomous Agent 自动执行多步骤写入。

## 五、AI 入口

### 1. Dashboard 入口

首页在核心 Today 数据附近提供轻量输入框：

```text
[ 问问今天摄入，或者说说你刚吃了什么… ] [Mic] [Send]
```

首页不被 Chat UI 占满。

### 2. 独立 AI 页面

支持：

- 消息列表；
- 新建会话；
- 最近会话；
- Tool 结果卡片；
- Pending Action 卡片；
- Stop Generation；
- Retry；
- 打开传统业务页面。

## 六、语音输入

语音只作为输入方式：

```text
Record Voice
→ Speech-to-Text
→ 展示转写文本
→ 用户可编辑
→ Send
→ 与普通文字走同一 Agent 流程
```

原因：健身饮食包含数字、单位、食品名，语音识别可能错误。默认不直接把语音转写结果自动执行写操作。

原始音频如果没有实际业务必要，不建议长期保存。

## 七、Agent Intent

至少支持：

- `QUERY_TODAY_NUTRITION`；
- `QUERY_NUTRITION_RANGE`；
- `SEARCH_FOOD`；
- `RECORD_FOOD`；
- `QUERY_FOOD_HISTORY`；
- `QUERY_NUTRITION_GOAL`；
- `QUERY_ANALYTICS`；
- `UNKNOWN / OUT_OF_SCOPE`。

名称可在技术设计调整，但产品必须区分读/写和业务域。

## 八、Structured Output

### 1. 目的

LLM 不能直接用自由文本参数调用写 Service。

自由文本先转换为结构化对象。

### 2. RECORD_FOOD 示例

用户：

> “中午吃了 200g 鸡胸和 150g 米饭。”

Structured Output 需要表达：

```text
intent: RECORD_FOOD
occurred_time_hint: 中午
items:
  - food_query: 鸡胸
    amount: 200
    unit: g
  - food_query: 米饭
    amount: 150
    unit: g
meal_hint: lunch / optional
missing_fields: []
ambiguities: []
```

### 3. 不确定性

结构化结果必须允许：

- missing；
- ambiguous；
- unresolved entity；
- unsupported unit。

不能要求模型为了 JSON 完整而强行猜值。

## 九、Domain Tool 设计原则

### 1. Tool 是业务能力适配层

Tool 内部调用 Java Service，不直接访问表。

建议初期 Tool：

- `searchFood(query)`；
- `getFoodDetail(foodId)`；
- `getTodayNutrition()`；
- `queryNutrition(querySpec)`；
- `getCurrentNutritionGoal()`；
- `prepareFoodRecord(draft)`；
- `executeFoodRecord(confirmedDraft, requestId)`。

### 2. Tool 权限

Tool 不接受模型任意指定 userId。

用户身份从当前认证上下文获取。

### 3. Tool 结果

返回模型可消费但仍是业务语义的结构化结果，例如：

```text
FoodCandidate[]
NutritionSummary
FoodRecordPreview
ExecuteResult
```

避免直接把数据库 Entity 暴露给模型。

## 十、Food Entity Resolve

### 1. 原则

AI 不创造 foodId。

每个 `food_query` 必须通过 Food Search Service 匹配真实 Food。

### 2. 单一明确候选

如果搜索结果足够明确，也仍进入 Preview，由用户最终确认整次写操作。

### 3. 多候选

用户说“牛奶 250ml”，返回：

- 全脂牛奶；
- 2% 牛奶；
- 脱脂牛奶；
- 品牌牛奶。

AI 展示候选，用户选择后继续。

### 4. 无结果

复用 V1.1：

```text
Local Search
→ Third-party API
→ Normalize
→ Candidates
→ User Select
```

AI 不自己去互联网查一个营养值直接写入。

## 十一、AI 写操作统一流程

所有正式写操作：

```text
User Input
→ Intent
→ Structured Output
→ Resolve Entity / Unit
→ Draft
→ Business Validation
→ Preview
→ User Confirm
→ Execute Tool
→ Result
```

### 1. Preview 卡片

示例：

```text
准备记录

鸡胸肉       200g
米饭         150g

Calories     xxx kcal
Protein      xx g
Carbs        xx g
Fat          xx g
Occurred     12:30
Meal         Lunch

[Edit] [Cancel] [Confirm]
```

Preview 的营养数据应来自 Java Service 计算，不由 LLM 自己计算。

### 2. Edit

用户可以：

- 改 Food；
- 改 amount；
- 改 occurred_at；
- 改 Meal；
- 删除某一项。

修改后重新走业务校验并刷新 Preview。

### 3. Confirm

只有用户点击 Confirm 或明确提交确认后，服务端才能执行写 Tool。

## 十二、自然语言查询

### 1. 今日摄入

用户：

> “我今天还差多少蛋白质？”

流程：

```text
Intent
→ getTodayNutrition
→ getCurrentNutritionGoal
→ Java Service 得出实际/目标/差额
→ LLM 组织语言
```

如果未设置 Protein Goal：

> 告知当前已摄入多少，但没有设置蛋白质目标，不伪造差额。

### 2. 范围查询

用户：

> “最近 30 天平均每天吃多少蛋白质？”

流程：

```text
Intent + DateRange
→ QuerySpec
→ queryNutrition(QuerySpec)
→ 返回聚合结果
→ LLM 表达
```

不允许 LLM 自己读取全部明细后手工算平均值。

## 十三、Conversation Memory

### 1. 目的

用于理解短期上下文：

```text
用户：搜一下全脂牛奶
AI：返回候选 A/B/C
用户：第二个
```

或：

```text
用户：刚才那个鸡胸再加100g
```

### 2. 可保存内容

- conversation summary；
- 最近实体引用；
- 最近日期范围；
- 当前 Pending Action；
- 最近 Tool 结果摘要。

### 3. 不作为权威事实

以下必须重新查询业务系统：

- 今天当前总摄入；
- 当前 Goal；
- Food 最新状态；
- 某条记录是否已经删除。

Redis Memory 不是数据库。

## 十四、Pending Action

当 AI 已经生成 Preview、等待确认时，需要保存 Pending Action：

至少包含：

- actionId；
- user context；
- intent；
- resolved parameters；
- preview version；
- status；
- expiresAt。

用户确认时使用服务器保存的 Pending Action，而不是重新信任前端传回的任意业务参数。

## 十五、JWT 与用户上下文

1. 当前用户由 Spring Security/JWT 认证得到；
2. 模型看不到也不需要持有 JWT；
3. Tool 执行时由服务端注入当前 user context；
4. 禁止 LLM 用 prompt 中的 `userId=xxx` 切换数据归属；
5. Tool 仍执行和普通 REST API 相同的数据隔离规则。

## 十六、requestId 与幂等

### 1. 需要覆盖的场景

- 用户重复点击 Confirm；
- 前端超时重试；
- SSE 断开重连；
- LLM/Tool 层重复触发；
- 网关重试。

### 2. 原则

同一个用户、同一个确认动作、同一个 requestId 只能产生一次正式业务写入。

重复请求返回第一次结果或当前执行状态。

### 3. 幂等边界

幂等不能只做前端防抖，必须在服务端业务写入层生效。

## 十七、SSE 流式响应

### 1. 用户可见事件

可显示：

- `UNDERSTANDING`：正在理解；
- `SEARCHING_FOOD`：正在匹配食品；
- `QUERYING_DATA`：正在查询数据；
- `WAITING_CONFIRMATION`：等待确认；
- `EXECUTING`：正在保存；
- `ANSWERING`：正在生成回答；
- `DONE`。

### 2. 不展示内部 Chain-of-Thought

只能展示业务阶段状态，不展示模型隐式推理文本。

### 3. SSE 中断

如果 Tool 已成功写入但 SSE 断开：

- requestId 保证重试不重复写；
- 用户重新进入会话时能够看到最终执行结果。

## 十八、Agent / Tool Trace

### 1. 目标

开发者能够定位：

- 用户输入是什么；
- 识别成什么 Intent；
- Structured Output 是什么；
- Food Resolve 返回什么；
- 调用了哪个 Tool；
- Tool 耗时/成功/失败；
- 用户何时确认；
- requestId 是什么；
- 最终是否产生业务记录。

### 2. Trace 关联对象

- conversationId；
- agentRunId；
- messageId；
- actionId；
- toolCallId；
- requestId。

### 3. 隐私

日志不能记录：

- Password；
- JWT 原文；
- API Secret；
- 不必要的完整敏感 Prompt。

## 十九、异常与降级

| 场景 | 系统行为 |
| --- | --- |
| LLM 不可用 | 传统页面正常使用 |
| Tool 超时 | 告知用户操作暂未完成；写操作先查幂等状态再允许重试 |
| Food 多候选 | 展示候选，不猜 |
| Food 无候选 | 进入第三方搜索/自定义 Food |
| Structured Output 缺字段 | 只补问必要信息 |
| Pending Action 过期 | 要求重新生成 Preview |
| 用户取消 | 不写正式业务数据 |
| SSE 断开 | 可恢复/重试，幂等保护 |
| 用户试图让 AI 越权查别人数据 | Tool 权限阻止 |

## 二十、典型端到端场景

### 场景 A：文字记录

```text
用户：中午吃了200g鸡胸和150g米饭
→ RECORD_FOOD
→ Structured Output
→ searchFood ×2
→ 用户选择必要候选
→ prepareFoodRecord
→ Preview
→ Confirm
→ executeFoodRecord(requestId)
→ 成功
→ 查询 Today Nutrition
→ 返回最新汇总
```

### 场景 B：语音记录

```text
用户说：“刚刚吃了两百克鸡胸一百五十克米饭”
→ Speech-to-Text
→ 用户看到文字并修正
→ Send
→ 与文字流程相同
```

### 场景 C：查询

```text
用户：最近30天平均每天蛋白质多少？
→ QUERY_NUTRITION_RANGE
→ QuerySpec(dateRange=30d, groupBy=day, metric=protein)
→ Analytics Service
→ 返回结构化聚合结果
→ LLM 组织回答
```

### 场景 D：重复确认

```text
用户点击Confirm
→ 写入成功但前端超时
→ 用户再次点击
→ 相同requestId
→ 服务端返回第一次成功结果
→ 不创建第二批Food Record
```

## 二十一、验收标准

- AI 可以查询 Today Nutrition；
- AI 查询结果来自真实 Service；
- AI 可以解析自然语言 Food + amount；
- 多候选 Food 会让用户选择；
- 写操作一定生成 Preview；
- 未 Confirm 时数据库没有正式 Food Record；
- Confirm 后复用 V1/V1.1 Service 创建记录；
- JWT 用户上下文不能被 prompt userId 覆盖；
- Redis Memory 能支持短期指代；
- 实时事实不会只从 Memory 获取；
- requestId 能防止重复写入；
- SSE 能输出业务状态和流式回答；
- Agent/Tool Trace 可以定位一次调用链；
- AI 故障不影响传统业务页面。

## 二十二、技术约束（简版）

- Java 21；
- Spring Boot 3；
- Spring Security + JWT；
- MySQL；
- Redis；
- LangChain4j；
- Tool Calling；
- Structured Output；
- SSE；
- 业务 Tool 只能调用 Service，不直连表；
- 正式业务写入保持事务、幂等与历史快照规则。

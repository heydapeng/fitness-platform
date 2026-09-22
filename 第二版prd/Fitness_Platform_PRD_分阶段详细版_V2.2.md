# Fitness Platform — 产品需求文档（分阶段详细版 V2.2）

> 文档说明：按原始 PRD 的“版本总览 + 分版本详细 PRD + 总需求清单”格式重构。当前实现优先对齐 Nutrition + Fitness Agent + RAG，训练与 Calendar 作为后续正式主线，轻社交及 Coach/Body 等放入 Future。

## 文档目录

1. 分版本 PRD 总览
2. V1 饮食记录 MVP
3. V1.1 快速记录与食品搜索
4. V1.2 饮食媒体、Analytics 与数据导出
5. V2 Fitness Agent Core
6. V2.1 RAG 健身营养知识增强
7. V3 训练闭环与 Calendar
8. V3.5 训练统计与进步分析
9. V4 AI Training Extension
10. Future 轻社交与可选扩展
11. 总需求清单

---
# Fitness Platform — 分版本 PRD 总览（实现对齐详细版）

## 1. 文档目的

本目录将 Fitness Platform 按真实产品演进阶段拆成多份 PRD。每一份 PRD 只描述当前阶段要解决的用户问题、页面与交互、业务规则、异常场景、验收标准，以及会直接影响产品行为的技术约束。

本版在完整产品愿景基础上，优先对齐当前项目可落地能力：食品、营养目标、饮食记录、查询与统计、Fitness Agent、RAG。训练、Calendar、训练统计和轻社交继续作为后续主线，而不是为了扩大范围提前塞进当前交付。

数据库表结构、Java 类设计、Redis Key、接口字段级协议、索引设计等不在 PRD 主体展开，后续进入技术设计文档。

## 2. 产品定位

Fitness Platform 面向普通健身记录者，核心解决三件事：

1. **记录**：把每天吃了什么、后续练了什么准确记录下来；
2. **计划与回顾**：有目标和训练计划时可以对照执行，没有目标或计划时仍能正常记录；
3. **分析与提效**：通过 Dashboard、Analytics、Calendar、Export 和 AI Assistant 降低查询、录入与复盘成本。

AI 的定位不是教练，也不拥有最终决策权。AI 是自然语言业务入口和知识问答助手。

## 3. 核心产品原则

1. **传统页面与 AI 长期并存**：没有 AI 时，饮食记录、查询、训练记录、计划、导出等核心能力仍可完整使用。
2. **事实优先**：Food Record、Workout Session 等是实际发生事实；Goal、Plan、Meal、Tag 是可选组织层。
3. **Plan is optional**：没有营养目标仍可记录饮食；没有训练计划仍可自由训练。
4. **AI 不直接写库**：所有读写最终调用 Java Service / API / Tool，不允许模型拼 SQL 或绕过业务校验。
5. **所有 AI 写操作统一确认**：AI 只生成 Draft/Preview，用户确认后正式执行。
6. **歧义不猜测**：食品、动作、单位等存在多个候选时展示候选给用户选择。
7. **历史可追溯**：饮食保存营养快照；训练计划修改不能改写历史 Session。
8. **统一查询口径**：Dashboard、History、Analytics、Export、AI Query 共享 QuerySpec 或等价条件模型。
9. **图片是附件**：饮食图片用于生活记录、回看和导出，不做 AI 食物识别和营养估算。
10. **历史事实一个月内可编辑**：超过一个月默认只读；判断基于 occurred_at / business_date，而不是 created_at。
11. **知识与事实分离**：MySQL 保存业务事实，RAG 保存非结构化健身知识，Redis 保存短期会话上下文。
12. **用户保留最终控制权**：AI 可以建议训练或营养调整，但不能自主改变用户目标、计划和历史事实。

## 4. 当前实现与长期愿景的关系

当前项目优先把下列链路做完整：

```text
Food / Nutrition Goal / Food Record
          ↓
稳定 Java Service
          ↓
Domain Tool
          ↓
LangChain4j + Tool Calling
          ↓
Structured Output / Entity Resolve
          ↓
Draft + Preview
          ↓
User Confirm
          ↓
Service Execute
```

再叠加 RAG：

```text
用户问题
   ├─ Personal Data → Tool / MySQL
   └─ Knowledge → Retrieval / RAG
                ↓
              LLM
                ↓
         带来源的综合回答
```

训练、Calendar、训练统计是后续正式产品路线，但不会阻塞当前 Agent 主链路交付。

## 5. 版本路线

| 版本 | 核心主题 | 主要用户价值 | 关键新增能力 | 与当前项目关系 |
| --- | --- | --- | --- | --- |
| V1 | 饮食记录 MVP | 准确记录每日摄入 | Food、Goal、Food Record、BigDecimal、营养快照、Today Dashboard | 当前底座 |
| V1.1 | 快速记录与食品搜索 | 降低重复录入成本 | 模糊搜索、第三方 Food API 回补、本地沉淀、Redis 热点缓存、最近/常吃/收藏、多食品 | 当前增强 |
| V1.2 | Analytics、媒体与导出 | 查询、复盘、导出自己的数据 | QuerySpec、筛选/聚合、Chart/Table、Food Photo、Export Job | 当前增强 |
| V2 | Fitness Agent Core | 用自然语言查询和记录饮食 | LangChain4j、Tool Calling、Structured Output、Confirm、JWT、Memory、SSE、Trace、幂等 | 当前核心 |
| V2.1 | RAG 知识增强 | AI 回答有来源、可追溯 | Chunk、Embedding、Retrieval、Rewrite、Rerank、Source、Tool+RAG | 当前核心 |
| V3 | 训练闭环与 Calendar | 记录真实训练并管理训练课表 | Exercise、Free Workout、Plan、任意 N 天循环、多计划、Session、Calendar | 后续主线 |
| V3.5 | 训练统计 | 看懂训练进度 | Exercise History、Volume、PR、Frequency、Completion、Query/Export | 后续主线 |
| V4 | AI Training Extension | AI 辅助训练查询、记录和计划草稿 | Workout Tools、Plan Draft、Training Query、AI Export | 后续主线 |
| Future | 轻社交与其他扩展 | 分享与产品扩展 | Plan/Workout Share、Copy、Body、Coach、Health Integration | 可选 |

## 6. 版本依赖关系

```text
V1 Nutrition Core
  └─ V1.1 Quick Logging / Food Search
       └─ V1.2 Analytics / Media / Export
            ├─ V2 Fitness Agent Core
            │    └─ V2.1 RAG
            │
            └─ V3 Training + Calendar
                 └─ V3.5 Training Analytics
                      └─ V4 AI Training Extension

Future
  ├─ Light Social
  ├─ Body Metrics
  ├─ Coach
  └─ Health Integration
```

## 7. 信息架构

### 7.1 Today Dashboard

首页保持简约，只展示“今天”：

- Calories / Protein / Carbs / Fat；
- Goal、Remaining、Over、Completion（存在目标时）；
- 今日饮食摘要；
- V3 后显示今日训练计划和完成状态；
- 快捷记录入口；
- AI 输入入口。

Calendar 不直接铺在首页。

### 7.2 Nutrition

- Food Search / Food Detail；
- Nutrition Goal；
- Food Record；
- Quick Logging；
- Food Photo；
- History；
- Analytics；
- Export。

### 7.3 AI Assistant

- Text / Voice-to-Text；
- Personal Data Query；
- Food Search；
- Food Record Draft；
- Preview / Confirm；
- RAG Q&A；
- Conversation Memory；
- SSE；
- Agent/Tool Trace。

### 7.4 Knowledge

- 营养基础；
- 增肌/减脂基础；
- 训练基础；
- 动作指南；
- RPE/RIR；
- 来源、版本、审核与有效期。

### 7.5 Training / Calendar（V3）

- Exercise Definition；
- Free Workout；
- Training Plan；
- Repeating Cycle；
- Scheduled Workout；
- Workout Session；
- Actual Set；
- Calendar Merge View。

## 8. 跨版本统一业务语义

### 8.1 时间

- `occurred_at`：饮食等事实真实发生时间；
- `started_at / ended_at`：训练事实时间；
- `business_date`：按用户时区得到的业务日期；
- `created_at`：系统收到数据的时间，不代表事实发生时间。

### 8.2 Goal

Goal 完全可选。允许只设置 Calories / Protein / Carbs / Fat 中部分指标。未设置字段保持 null，不使用 0 代表未设置。

### 8.3 Plan 与 Fact

- Nutrition Goal：比较基准，不改变 Food Record；
- Training Plan：未来安排，不等于 Workout Session；
- 修改未来计划不得回写历史训练；
- Missed Schedule 不自动顺延。

### 8.4 AI Action

统一状态：

```text
PARSED
→ RESOLVING
→ READY_FOR_CONFIRMATION
→ CONFIRMED
→ EXECUTING
→ SUCCEEDED / FAILED / CANCELLED
```

所有写操作在 `CONFIRMED` 前不能改变正式业务数据。

### 8.5 QuerySpec

查询、统计和导出共享至少以下条件：

- domain；
- dateRange；
- filters；
- groupBy；
- metrics；
- sort；
- columns。

后续 AI 也通过同一业务查询层构造查询，不建立独立统计逻辑。

## 9. 当前明确不做 / 暂缓

当前主线不包含：

- AI 图片识别食物和自动估算营养；
- AI 自动替用户调整营养目标；
- AI 自动修改训练计划；
- 真人教练主业务；
- 医疗诊断；
- Apple Health/Garmin/可穿戴设备接入；
- 完整 Body 数据域；
- 大型社区 Feed、私信、推荐算法；
- 任意文件“全自动无确认”导入。

## 10. PRD 使用方式

开发某个版本时，至少阅读：

1. 本总览；
2. 当前版本 PRD；
3. 当前版本直接依赖的前置 PRD。

例如开发 V2 Fitness Agent 时，应重点阅读 V1、V1.1、V1.2、V2；开发 V4 AI Training Extension 时，应阅读 V2/V2.1、V3/V3.5、V4。


---

# Fitness Platform — PRD V1：饮食记录 MVP（实现对齐版）

## 一、版本概述

V1 建立整个产品最重要的业务数据底座：**食品、营养目标、饮食记录、当日汇总与历史查询**。

本版本不依赖 AI。目标是确保用户即使完全不使用 Fitness Agent，也可以稳定完成“搜索食品 → 记录实际摄入 → 查看 Calories / Protein / Carbs / Fat → 回看历史”的闭环。

后续 Agent、Analytics、RAG、训练等能力都建立在稳定业务 Service 上，因此 V1 的数据语义、权限、快照和营养计算必须先做正确。

## 二、用户核心问题

- 我今天吃了什么，能不能快速记录下来？
- 我不设置减脂/增肌目标，还能不能正常记录？
- 如果设置目标，今天还差多少热量、蛋白质、碳水、脂肪？
- 食品库以后修改营养值，会不会把我过去的数据一起改掉？
- 我能不能补录今天早些时候或过去几天吃过的东西？
- 我的记录是否只对我自己可见？

## 三、版本目标

1. 建立用户账户、鉴权和数据隔离；
2. 建立 Food 结构化食品库；
3. 建立可选 Nutrition Goal；
4. 支持按真实发生时间记录 Food Record；
5. 使用 BigDecimal/定点方式完成确定性营养计算；
6. Food Record 保存历史营养快照；
7. Today Dashboard 展示当日宏量营养摄入与目标完成情况；
8. 支持历史日期查询；
9. 支持一个月内修改/删除历史事实；
10. 为 V2 Agent 提供稳定、可复用的业务 Service。

## 四、功能范围

本版本包含：

- 注册、登录、退出；
- 用户基础资料、时区；
- Nutrition Goal；
- Food 分类与 Food 库；
- Food 搜索和详情；
- Food Record 新增、编辑、删除；
- 历史营养快照；
- Today Dashboard；
- 历史日期查询；
- 用户权限隔离；
- 幂等提交基础能力。

本版本不包含：

- AI；
- RAG；
- 语音；
- 第三方 Food API；
- 高级 Analytics；
- 图片；
- 数据导出；
- 训练。

## 五、账户与用户资料

### 1. 注册

至少支持：

- Email；
- Password；
- Confirm Password。

规则：

- Email 唯一；
- Email 做基本格式校验；
- 密码不能明文存储；
- 禁用用户不可登录。

### 2. 登录/退出

- 登录成功进入 Today Dashboard；
- 退出后 Token 失效或客户端清除凭证；
- 所有受保护 API 必须校验用户身份。

### 3. 用户时区

用户可以设置时区。

时区用于：

- 判断“今天”；
- 计算 business_date；
- Dashboard 当日范围；
- 历史查询边界。

历史事实的 business_date 一旦生成，不因用户以后切换时区而静默改写。

## 六、Nutrition Goal

### 1. 产品定位

Goal 是可选比较基准，不是饮食记录前置条件。

用户可以：

- 不设置任何目标；
- 只设置 Calories；
- 只设置 Protein；
- 设置 Calories + Protein；
- 设置全部 Calories / Protein / Carbs / Fat。

### 2. 字段

建议至少支持：

- effective_date；
- end_date（可选）；
- calories_target；
- protein_target_g；
- carbs_target_g；
- fat_target_g；
- note（可选）。

未设置指标保持 null。

### 3. 历史规则

- 新目标从生效日开始；
- 同一日期只能命中一组有效目标；
- 修改今天以后的目标不应改写更早历史；
- 用户可以结束当前目标进入“无目标”状态；
- Dashboard 查看历史日期时使用当天有效目标。

### 4. 目标校验

- 已填写数值必须为合理正数；
- 不允许使用 0 代表“未设置”；
- 用户不应被系统强制先设置目标才能记录饮食。

## 七、Food 食品库

### 1. Food 基础字段

至少包含：

- name；
- category；
- brand（可选）；
- calories_per_100g；
- protein_per_100g；
- carbs_per_100g；
- fat_per_100g；
- source；
- status；
- description（可选）。

### 2. 搜索

V1 支持：

- 名称模糊搜索；
- 分类筛选；
- 分页；
- 只向普通用户返回可用 Food。

### 3. Food 状态

建议：

- ACTIVE；
- INACTIVE。

INACTIVE Food：

- 不允许新增 Food Record；
- 历史记录继续正常展示；
- 不允许删除导致历史记录引用断裂。

### 4. Food 修改对历史的影响

Food 当前标准被管理员修改后：

- 新记录使用新标准；
- 旧记录继续使用创建时营养快照；
- 不批量重算历史。

## 八、Food Record 饮食记录

### 1. 新增流程

```text
选择 Food
→ 输入 amount / unit
→ 设置实际发生时间
→ 可选 meal
→ 查看营养预览
→ 保存
→ Today Dashboard 更新
```

### 2. 必填与可选字段

必填：

- Food；
- amount；
- occurred_at。

可选：

- meal；
- note。

### 3. 营养计算

若当前仅支持克：

```text
实际营养 = 每100g营养 × amount_g / 100
```

要求：

- 前端可以做即时预览；
- 服务端必须重新计算；
- 使用 BigDecimal 或等价十进制定点方式；
- 统一舍入规则；
- 不允许前端提交的计算结果直接成为可信事实。

### 4. 历史营养快照

Food Record 创建时固化：

- Food name snapshot；
- calories_per_100g snapshot；
- protein snapshot；
- carbs snapshot；
- fat snapshot；
- amount；
- calculated actual nutrition。

意义：Food DB 后续变化不影响过去统计。

### 5. 发生时间

Food Record 使用 `occurred_at` 描述实际摄入时间。

`created_at` 只描述系统收到记录的时间。

例如用户 22:00 补录 12:30 午餐：

- occurred_at = 12:30；
- created_at = 22:00。

Dashboard 和历史统计按 occurred_at/business_date 计算。

### 6. Meal

Meal 是可选字段。

默认可提供：

- Breakfast；
- Lunch；
- Dinner；
- Snack。

用户不选择 Meal 时，Food Record 仍然合法。

## 九、记录编辑与删除

### 1. 时间窗口

用户可以编辑/删除最近一个月内的 Food Record。

超过一个月：

- 默认只读；
- 页面明确提示超过编辑窗口。

产品可在技术设计阶段决定“一月”采用自然月还是固定 30 天，但所有页面和 API 必须统一。

### 2. 编辑字段

一个月内可以修改：

- amount；
- occurred_at；
- meal；
- note；
- Food。

修改 amount：按该条历史快照重算。

修改 Food：视为重新选择食品，使用新 Food 当前营养标准形成新的快照。

### 3. 删除

删除前确认。

删除成功后：

- Dashboard 当日汇总刷新；
- History 不再显示；
- 统计从结果中扣除。

V1 不要求回收站。

## 十、Today Dashboard

### 1. 产品原则

首页不做复杂日历，只回答“今天怎么样”。

### 2. 营养卡片

显示：

- Calories；
- Protein；
- Carbs；
- Fat。

存在 Goal 时显示：

- actual；
- target；
- remaining / over；
- completion %。

未设置某指标目标时：

- 只展示 actual；
- 不展示虚假的 0 目标。

### 3. 今日记录

默认按 occurred_at 时间线展示 Food Record。

可选切换：

- 时间线；
- Meal 分组。

没有 Meal 的记录显示在“未分餐”。

### 4. 空状态

- 没有 Goal：正常显示实际摄入，并提供“设置目标”入口；
- 没有记录：显示 0，并提供“记录饮食”入口。

## 十一、历史查询

支持：

- 选择日期；
- 上一天/下一天；
- 快速回今天；
- 查看当天 Food Record；
- 查看当天营养汇总；
- 查看当天有效 Goal。

历史日期结果必须基于实际发生时间与历史快照，不读取 Food 当前营养标准重新计算。

## 十二、权限与安全

1. 普通用户只能访问自己的 Goal 和 Food Record；
2. 管理员可以维护公共 Food，但不能因为是管理员就默认读取用户全部饮食隐私；
3. API 不接受客户端任意 userId 直接决定数据归属；
4. 用户身份来自服务端认证上下文；
5. V2 Agent 后续同样复用这一权限模型。

## 十三、幂等与重复提交

新增 Food Record 时客户端生成 requestId / idempotency key。

服务端应避免：

- 双击按钮产生两条记录；
- 网络超时重试产生重复记录；
- 后续 Agent Tool 重试产生重复记录。

## 十四、异常与边界

| 场景 | 系统行为 |
| --- | --- |
| amount = 0 / 负数 | 阻止保存 |
| amount 超大 | 提示异常值，按规则阻止或二次确认 |
| Food 已停用 | 不允许新增，要求重新选择 |
| 无 Goal | 正常记录，只展示实际值 |
| 历史无记录 | 展示空状态 |
| 编辑超过一个月记录 | 只读并提示原因 |
| 网络超时 | 可安全重试，不产生重复记录 |
| Food 修改 | 不改写旧 Food Record 快照 |

## 十五、典型用户场景

### 场景 A：无目标用户记录午餐

```text
用户搜索“鸡胸肉”
→ 选择 Food
→ 输入 200g
→ occurred_at = 12:30
→ 不选择 Meal
→ 保存
→ Dashboard 显示实际 Calories/P/C/F
```

### 场景 B：有目标用户查看完成度

```text
Goal: 2300 kcal / P160 / C260 / F70
Actual: 1860 / P142 / C205 / F61
→ Dashboard 显示 actual / target / remaining
```

### 场景 C：Food 标准发生变化

```text
9月1日记录 Food A 200g
9月15日管理员修改 Food A 营养值
→ 9月1日记录保持旧快照
→ 9月15日以后新记录使用新标准
```

## 十六、验收标准

- 未设置 Goal 也能完整新增 Food Record；
- 可以只设置部分 Goal；
- Food 模糊搜索正常；
- Food Record 的 Calories/P/C/F 计算正确；
- 服务端计算与前端预览口径一致；
- Food 修改不会改变历史记录；
- Dashboard 能展示今日实际摄入和目标完成度；
- 历史查询使用 occurred_at/business_date；
- 最近一个月历史记录可修改，超过窗口只读；
- 两个用户之间数据严格隔离；
- 重复提交不会创建重复 Food Record。

## 十七、技术约束（简版）

- Java 21 + Spring Boot 3；
- Spring Security + JWT；
- MySQL；
- 营养数值使用 BigDecimal/Decimal；
- Food Record 保存历史营养快照；
- Service 层封装核心业务规则；
- V1 不依赖 LangChain4j/RAG；
- 为 V2 Tool Calling 保留稳定 Service 接口。


---

# Fitness Platform — PRD V1.1：快速记录与食品搜索（实现对齐版）

## 一、版本概述

V1 已经解决“饮食能不能准确记录”，V1.1 解决“能不能更快记录”。

普通健身用户每天会重复吃很多相似食物，如果每次都从公共食品库重新搜索、重新输入重量，长期使用成本会很高。因此本版本重点优化：

- Food 模糊搜索；
- 本地数据库优先；
- 本地没有时调用第三方 Food API；
- 第三方结果标准化后沉淀到本地；
- 高频 Food 使用 Redis 缓存；
- 最近吃过、常吃、收藏、自定义食品；
- 多食品一次添加。

所有快捷能力仍然复用 V1 Food Record 的快照、权限、营养计算和幂等规则。

## 二、用户核心问题

- 我搜“牛奶”时，能不能把多个匹配结果都展示出来让我选？
- 本地食品库没有的食品，系统能不能自动去第三方食品库查？
- 第三方查到以后，下次是不是不需要再请求外部 API？
- 我每天都吃的鸡胸、米饭、蛋白粉，能不能更快找到？
- 我能不能收藏常用食品？
- 我能不能一次记录一整顿饭里的多个食品？
- 品牌食品或自制食品没有时，能不能自己建？

## 三、版本目标

1. 提升 Food Search 覆盖率；
2. 本地 Food DB 始终作为首选数据源；
3. 本地结果不足时可调用第三方 Food API；
4. 第三方 Food 经过标准化、去重和来源标记后保存到本地；
5. 热点 Food 可使用 Redis 缓存减少数据库与第三方调用压力；
6. 支持最近吃过、常吃、收藏、自定义食品；
7. 支持一次添加多个 Food Record；
8. 高频饮食记录尽量控制在 2～3 次核心操作内完成；
9. 为 V2 Agent 的 Food Resolve 提供统一搜索能力。

## 四、Food Search 总体流程

```text
用户输入 query
   ↓
Redis Hot Search / Hot Food（可命中则快速返回）
   ↓
Local Food DB fuzzy search
   ↓
有足够候选？
 ├─ Yes → 返回候选给用户选择
 └─ No
      ↓
Third-party Food API
      ↓
Normalize / Validate / Deduplicate
      ↓
保存或更新 Local Food DB
      ↓
返回候选给用户选择
```

AI 上线后同样调用这套 Food Search Service，不允许 AI 自己使用另一套食品搜索逻辑。

## 五、本地模糊搜索

### 1. 搜索字段

至少支持：

- Food name；
- brand；
- alias（如后续维护）；
- category。

### 2. 结果展示

搜索“牛奶”时可能返回：

- 全脂牛奶；
- 2% 牛奶；
- 脱脂牛奶；
- 某品牌全脂牛奶。

用户搜索信息不足时，系统不替用户决定具体食品，直接展示候选二次选择。

### 3. 排序建议

可按以下优先级综合排序：

1. 完全名称匹配；
2. 用户最近吃过；
3. 用户收藏；
4. 系统热门；
5. 模糊相关度。

排序只是展示优先级，不改变 Food 的营养事实。

## 六、第三方 Food API

### 1. 触发条件

出现以下情况可调用第三方 API：

- 本地无结果；
- 本地候选数量过少；
- 用户主动选择“查看更多结果”。

避免每次搜索都调用第三方 API。

### 2. 标准化

第三方返回字段可能不同，系统需要转换为内部 Food 标准：

- name；
- brand；
- serving / base unit；
- calories；
- protein；
- carbs；
- fat；
- source_provider；
- source_external_id；
- source_updated_at（如有）。

### 3. 本地沉淀

用户真正选中并使用第三方 Food 后，优先保存到 Local Food DB。

也可在搜索结果返回前先保存为外部来源 Food，但必须避免重复创建。

### 4. 去重

至少可参考：

- provider + externalId；
- name + brand + nutrition signature；
- barcode（如果未来接入）；
- 人工合并标记。

同一外部 Food 重复搜索不能不断新增本地记录。

### 5. 来源标记

Food Detail 应可区分：

- SYSTEM；
- THIRD_PARTY；
- USER_CUSTOM。

若第三方条款要求展示来源，应保留可展示信息。

## 七、Redis 热点缓存

### 1. 使用场景

缓存可以用于：

- 高频搜索词对应候选；
- 热门 Food Detail；
- 用户最近吃过的 Food 简要信息；
- 第三方搜索短期结果（如果许可允许）。

### 2. 原则

- Redis 不是 Food 事实唯一来源；
- 缓存失效后可回源 MySQL；
- Food 修改/停用后主动清理相关缓存；
- 避免缓存长期保存第三方不允许持久化的数据。

### 3. 热点 Key 防击穿

技术实现可使用 Redisson 锁或等价方式限制同一热点 Key 并发重建，但具体 Key 格式不在 PRD 定义。

## 八、最近吃过

### 1. 定义

根据用户 Food Record 计算最近使用过的 Food，去重展示。

### 2. 展示

- Food name；
- 上次 amount；
- 上次使用时间；
- 可选上次 Meal；
- 快速添加按钮。

### 3. 快捷添加

点击后先进入确认/编辑状态：

- 默认使用上次 amount；
- occurred_at 使用本次时间；
- Meal 可以继承也可以修改；
- 用户确认后创建新 Food Record。

复制是创建新事实，不引用旧记录。

## 九、常吃食品

### 1. 定义

基于近 30 天或产品设定窗口计算 Food 使用频率。

### 2. 规则

- 统计结果是系统行为数据，不等于用户主动收藏；
- 同频可以按最近使用排序；
- 数据变化后结果可以动态变化。

## 十、收藏 Food

用户可以：

- 收藏；
- 取消收藏；
- 在收藏列表快速搜索/记录。

规则：

- 同一用户同一 Food 不重复收藏；
- Food 停用后仍可显示收藏状态，但不可直接新增记录；
- 收藏数据用户级隔离。

## 十一、自定义 Food

### 1. 使用场景

适用于：

- 自制餐食；
- 小众品牌；
- 第三方 Food API 查不到；
- 用户有更准确包装营养信息。

### 2. 字段

至少支持：

- name；
- brand（可选）；
- calories_per_100g；
- protein_per_100g；
- carbs_per_100g；
- fat_per_100g；
- note（可选）。

### 3. 权限

- 默认仅创建者可见；
- 普通用户不能直接发布到公共 Food DB；
- 修改当前标准不改写历史 Food Record。

## 十二、多食品一次添加

### 1. 页面结构

允许一次添加多行：

| 字段 | 说明 |
| --- | --- |
| Food | 搜索并选择 |
| amount | 每行独立填写 |
| nutrition preview | 每行即时展示 |
| occurred_at | 可统一，也可允许单独调整 |
| meal | 可选 |
| 操作 | 修改/删除该行 |

底部显示总 Calories / P / C / F。

### 2. 保存策略

V1.1 推荐：

```text
整批校验
→ 用户确认
→ 单事务/一致性策略保存
```

避免一半成功、一半失败导致用户难以理解。

每个 Food 仍保存为独立 Food Record。

### 3. 幂等

整批请求使用 batch requestId，网络重试不能重复创建整批记录。

## 十三、复制能力

可提供：

- 复制上一条；
- 复制上一餐；
- 复制昨天某餐；
- 复制昨天全部。

复制默认复制：

- Food；
- amount。

occurred_at 必须使用目标时间；Meal 是否继承要采用明确规则并允许用户修改。

## 十四、异常与边界

| 场景 | 系统行为 |
| --- | --- |
| 本地无结果 | 调用第三方或提示创建自定义 Food |
| 第三方 API 超时 | 本地功能继续可用，提示暂时无法获取更多结果 |
| 第三方返回缺少宏量字段 | 标记数据不完整，不允许当作完整营养 Food 使用或要求补充 |
| 第三方重复结果 | 去重后展示 |
| Food 停用 | 历史保留，新记录阻止 |
| 批量中某行非法 | 不提交整批并定位具体行 |
| 热点缓存异常 | 回源 MySQL，不阻塞核心记录 |
| 网络重试 | 幂等避免重复记录 |

## 十五、验收标准

- Food 搜索支持模糊匹配；
- 本地有结果时不必请求第三方；
- 本地无结果时可以从第三方补充；
- 用户选中的第三方 Food 能沉淀到本地；
- 相同第三方 Food 不重复入库；
- Food 修改/停用能正确失效缓存；
- 最近/常吃/收藏可用；
- 用户可创建自定义 Food；
- 可以一次添加多个 Food；
- 高频记录可明显少于 V1 的完整搜索流程；
- 后续 Agent 可复用同一个 Food Search Service。

## 十六、技术约束（简版）

- MySQL 保存本地 Food 与用户 Food；
- Redis 用于热点缓存，不作为权威数据源；
- Third-party Food API 通过 Adapter/Provider 层隔离；
- Food 标准化与去重在 Java Service 中完成；
- 需要保留 source/provider 标识；
- V2 Agent 不直接调用第三方 API，而调用 Food Search Tool/Service。


---

# Fitness Platform — PRD V1.2：饮食媒体、Analytics 与数据导出（实现对齐版）

## 一、版本概述

V1/V1.1 解决“准确、快速记录饮食”，V1.2 解决“如何回看、筛选、统计和导出”。

本版本把产品从单日记录工具扩展为个人数据工具，并建立后续 AI Query/Export 所依赖的统一查询语义。

图片仅作为饮食记录附件，用于生活记录、回看和导出，不承担 AI 食物识别职责。

## 二、用户核心问题

- 我今天/这周/这个月平均吃了多少？
- 我能不能按 Food、Meal、日期等条件筛选？
- 图表和明细表能不能用同一组条件？
- 我筛选完的数据能不能直接导出？
- 我能不能把饮食照片一起保存和导出？
- 以后 AI 问“过去三个月蛋白质趋势”时，能不能复用同一统计口径？

## 三、版本目标

1. 增加 Food Photo 附件；
2. 图片上传失败不影响结构化 Food Record；
3. 建立统一 QuerySpec；
4. 支持多条件筛选；
5. 支持日/周/月分组；
6. 支持 Calories/P/C/F 等核心指标；
7. 图表与表格复用同一查询结果；
8. 支持导出当前查询结果；
9. 支持独立数据中心导出；
10. 为 V2 Agent Query 和后续 AI Export 建立稳定业务能力。

## 四、饮食图片

### 1. 定位

图片是 Food Record/记录组的补充附件，不替代结构化 Food 数据。

典型场景：

- 用户喜欢拍一餐；
- 以后回看当时吃了什么；
- 导出备份时保留照片。

本版本不做：

- 图片识别 Food；
- 图片估算重量；
- 图片估算 Calories/P/C/F。

### 2. 上传入口

- 新增 Food Record；
- 多 Food 一次添加；
- Food Record 详情；
- 历史记录补传。

### 3. 关联方式

支持：

- 单条 Food Record 图片；
- 一组 Food Record / 一餐公共图片。

图片与 Meal 解耦；没有 Meal 也可上传。

### 4. 上传失败

```text
Food Record 保存成功
→ 图片上传失败
→ 明确提示“记录已保存，图片上传失败”
→ 用户稍后补传
```

图片不能成为饮食数据保存的强依赖。

### 5. 隐私

- 默认仅用户本人可见；
- 导出时由用户主动选择是否包含；
- 不默认用于模型训练或公开社区。

## 五、Analytics 统一查询模型

### 1. QuerySpec

至少表达：

```text
Domain
DateRange
Filters
GroupBy
Metrics
Sort
Columns
```

### 2. DateRange

支持：

- Today；
- Last 7 Days；
- Last 30 Days；
- Last 90 Days；
- This Month；
- This Year；
- Custom Range。

### 3. Filters

Nutrition 至少支持：

- Food；
- Category；
- Brand（可选）；
- Meal；
- Source（System/Third-party/User Custom）；
- Has Photo；
- 后续用户 Tag。

### 4. GroupBy

- Day；
- Week；
- Month；
- Meal；
- Food；
- Category。

### 5. Metrics

- Calories；
- Protein；
- Carbs；
- Fat；
- Record Count；
- Goal Completion（适用时）。

## 六、Analytics 页面

### 1. 页面结构

建议：

```text
[Date Range] [Filter] [Group By] [Metrics]

Summary Cards

Chart

Detail / Aggregation Table

[Export Current Result]
```

### 2. Summary Cards

根据当前 QuerySpec 展示：

- 总 Calories；
- 平均每日 Calories；
- 平均 Protein/Carbs/Fat；
- 记录天数；
- Goal 达标天数/比例（存在目标时）。

### 3. 图表

可采用：

- Line：日/周/月趋势；
- Bar：按 Meal/Food/Category 对比；
- Stacked（可选）：P/C/F 不建议和 Calories 混一比例图误导。

### 4. 表格

图表下方保留结构化表格，用户可以：

- 查看具体数值；
- 排序；
- 打开对应日期或 Food；
- 直接导出。

## 七、Today Dashboard 与 Analytics 的关系

Dashboard 只展示当天简约摘要。

Analytics 负责复杂条件查询。

两者的核心指标计算必须复用同一后端查询/统计服务，不能各算一套。

## 八、数据中心

入口建议：

```text
Profile / Settings → My Data
```

展示：

- Food Record 日期范围；
- 总记录数；
- Food Photo 数量；
- Nutrition Goal 历史；
- V3 后训练数据范围；
- 最近 Export Job。

## 九、导出

### 1. 两种入口

#### A. Export Current Result

从 Analytics/History 发起，自动继承当前 QuerySpec。

#### B. My Data Export

用户自行选择：

- 时间范围；
- 数据域；
- 明细/汇总；
- 是否包含图片。

### 2. 格式

优先支持：

- CSV；
- XLSX（如实现成本可接受）；
- ZIP（结构化文件 + 图片）。

### 3. Nutrition 明细

至少包含：

- business_date；
- occurred_at；
- Meal；
- Food name；
- amount；
- Calories；
- Protein；
- Carbs；
- Fat；
- source；
- note；
- photo reference（如有）。

### 4. Nutrition 汇总

至少包含：

- date；
- actual Calories/P/C/F；
- 当日 Goal（存在时）；
- Remaining/Over；
- Completion。

### 5. 图片包

用户选择包含图片时，可输出：

```text
nutrition_records.csv
nutrition_daily_summary.csv
photos/
  2026-09-01/
  2026-09-02/
```

需要保证结构化记录和图片可以对应。

## 十、Export Job

大范围导出使用异步任务。

状态：

- PENDING；
- PROCESSING；
- SUCCEEDED；
- FAILED；
- EXPIRED。

展示：

- 创建时间；
- Query/范围摘要；
- 数据类型；
- 状态；
- 文件大小；
- 下载入口；
- 失败原因（可理解形式）。

## 十一、查询与导出一致性

`Export Current Result` 必须使用当前 QuerySpec，而不是前端重新拼筛选条件。

要求：

```text
Same QuerySpec
→ Analytics
→ Table
→ Export
→ V2 AI Query
→ V4 AI Export
```

这是跨版本硬性设计原则。

## 十二、异常与边界

| 场景 | 系统行为 |
| --- | --- |
| 查询范围无数据 | 展示空状态，不伪造趋势 |
| 图片上传失败 | Food Record 正常保存，可重试图片 |
| 图片格式/大小非法 | 只拒绝图片 |
| 导出范围无数据 | 不生成空包，提示无数据 |
| 大导出处理较慢 | 创建 Job 并显示状态 |
| 导出失败 | 可重新生成，不影响原始数据 |
| 下载链接过期 | 数据仍保留，可重新生成 |
| QuerySpec 参数非法 | 服务端校验并返回明确错误 |

## 十三、验收标准

- Food Record 可关联图片；
- 图片失败不影响记录；
- Analytics 支持时间范围、筛选、分组和指标；
- 图表和表格数据一致；
- Dashboard 与 Analytics 核心口径一致；
- 可以导出当前筛选结果；
- 导出结果能复现 QuerySpec；
- 可以导出明细和每日汇总；
- 可选择图片打包；
- 大导出有 Job 状态；
- V2 Agent 后续可以通过稳定 Tool 查询同一统计结果。

## 十四、技术约束（简版）

- QuerySpec 在后端形成稳定业务对象；
- 聚合优先直接基于 MySQL 业务数据，不要求初期数仓；
- 图片使用对象存储类能力；
- 导出可通过异步 Worker/Queue；
- Export Service 独立于 AI；
- V2 AI 只能调用已有 Query/Export 能力。


---

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


---

# Fitness Platform — PRD V2.1：RAG 健身营养知识增强（实现对齐版）

## 一、版本概述

V2 已经让 AI 能查询用户真实营养数据、搜索 Food 并通过确认流程记录饮食，但对于“为什么”“怎么理解”“有哪些一般建议”这类知识问题，如果只依赖模型参数知识，来源和稳定性不足。

V2.1 引入 RAG，将经过筛选的健身营养知识通过 Document → Chunk → Embedding → Retrieval → Rerank 的链路提供给 LLM，并支持与用户真实业务数据 Tool 组合回答。

RAG 不替代 MySQL。用户真实摄入、Goal、Food Record 永远从 Tool 获取。

## 二、用户核心问题

- 蛋白质为什么重要？
- RPE/RIR 是什么意思？
- 我今天蛋白质还差很多，应该怎么理解？
- 这个回答的依据是什么？
- AI 能不能同时参考我的真实摄入和知识库？
- 知识库更新后，能不能知道回答用了哪个版本？

## 三、版本目标

1. 建立可管理的健身/营养知识库；
2. 支持文档导入和元数据；
3. 支持 Chunk；
4. 支持 Embedding；
5. 支持向量 Retrieval；
6. 支持 Query Rewrite；
7. 支持 Rerank；
8. 支持低相关结果过滤；
9. 回答提供来源；
10. 支持知识版本与有效状态；
11. 支持 Tool + RAG 混合问答；
12. RAG 不可用时 Personal Data Tool 仍可工作。

## 四、知识范围

可纳入：

- Calories 与能量平衡；
- Protein / Carbs / Fat 基础；
- 增肌/减脂基础；
- 饮食安排一般知识；
- 力量训练基础；
- RPE/RIR；
- 动作指南；
- 恢复与睡眠一般知识；
- 平台 FAQ；
- 合法可用的研究解读或公开资料。

暂不纳入：

- 用户个人记录；
- 未经授权的商业课程全文；
- 医疗诊断内容；
- 无来源网络拼接内容。

## 五、Knowledge Document

### 1. 元数据

至少记录：

- title；
- category；
- topic；
- source；
- author；
- publish_date；
- language；
- version；
- copyright/license status；
- review_status；
- effective_status；
- source_url（如允许）。

### 2. 状态

建议：

- DRAFT；
- REVIEWING；
- APPROVED；
- REJECTED；
- EXPIRED。

正式问答默认只检索 APPROVED 且有效内容。

### 3. 版本

新版本上线后：

- 旧版本保留；
- 可标记 EXPIRED；
- Trace 能知道某次回答使用哪个 Document Version。

## 六、文档处理链路

```text
Document
→ Normalize
→ Chunk
→ Metadata
→ Embedding
→ Vector Index
```

### 1. Chunk 原则

Chunk 不能只机械按固定字数切开，应尽量保留语义段落。

需要保留：

- documentId；
- version；
- heading/topic；
- source；
- chunk index。

### 2. Embedding

Embedding 模型属于技术实现，不在 PRD 固定供应商。

但需要保证：

- 同一索引版本使用可解释的 embedding 配置；
- 模型切换时可重新索引；
- 不把用户隐私记录混进公共知识索引。

## 七、Retrieval

### 1. Query Rewrite

用户问：

> “最后两下特别吃力但还能做，差不多是什么RIR？”

可以改写为更适合检索的查询，但最终回答必须仍然针对用户原问题。

### 2. Retrieval

返回候选 Chunk，并执行：

- metadata filter；
- topK；
- relevance threshold。

### 3. Rerank

初步召回后进行二次排序，避免单纯向量相似导致错误上下文进入 Prompt。

### 4. 无可靠结果

没有达到相关阈值时：

> 明确说明知识库中没有足够可靠内容。

不强行引用无关文档。

## 八、RAG Answer

### 1. 来源

回答至少可以展示：

- 来源标题；
- 来源类型；
- 版本/发布日期；
- 来源链接（允许时）。

### 2. 引用规则

- 不引用未审核内容；
- 不伪造来源；
- 不把模型自己知道的内容伪装成知识库来源；
- 多来源时展示真正参与回答的主要来源。

## 九、Tool + RAG 融合

### 1. 典型问题

用户：

> “我今天还差多少蛋白质？晚上怎么补比较合适？”

流程：

```text
Part A: Personal Data
→ Tool 查询 Today Nutrition + Goal

Part B: Knowledge
→ RAG 检索 Protein / Food Planning 内容

Part C: Compose
→ LLM 区分“你的数据”和“一般知识建议”
```

### 2. 来源优先级

建议：

1. 当前 Tool 业务事实；
2. 用户本轮明确输入；
3. APPROVED RAG；
4. Conversation Memory；
5. 模型一般知识。

低优先级不能覆盖高优先级事实。

### 3. 个性化边界

AI 可以说：

> “你今天已经记录 120g 蛋白质，如果你的目标是 160g，目前还差 40g。知识库中关于蛋白质摄入的一般建议……”。

AI 不应未经用户确认自动改变 Goal。

## 十、动作指南与 Food Knowledge

### 1. Food DB 与 Knowledge 分离

Food DB 用于：

- Calories/P/C/F 计算；
- Food Record。

RAG 用于：

- 食物相关一般知识；
- 饮食建议解释；
- 食品特点说明。

二者不要求一一对应。

### 2. Exercise Definition 与 Knowledge 分离

V3 上线后：

- Exercise Definition 用于训练记录和计划；
- RAG 动作指南用于步骤、注意事项、常见错误等知识解释。

## 十一、管理后台

管理员至少可以：

- 新建/导入文档；
- 编辑元数据；
- 查看 Chunk 状态；
- 提交审核；
- Approve/Reject；
- Expire；
- 触发重新索引；
- 测试某个 Query 的召回结果（可选）。

## 十二、Trace

一次 RAG Run 至少关联：

- agentRunId；
- original query；
- rewritten query；
- retrieved document/chunk IDs；
- rerank score；
- 最终选中 Chunk；
- document version。

生产日志不需要保存过量 Prompt 全文，但应足够定位检索问题。

## 十三、异常与降级

| 场景 | 系统行为 |
| --- | --- |
| 向量检索不可用 | 知识问答提示暂不可用；Tool 查询继续工作 |
| 无高相关 Chunk | 明确知识库无可靠依据 |
| Document 已过期 | 默认不召回 |
| 多来源观点不同 | 说明差异并展示来源，不强行合并 |
| Tool 查询失败但 RAG 成功 | 不猜用户个人数据，只回答一般知识部分 |
| RAG 成功但 Tool 无 Goal | 告知没有设置 Goal，不自行设定 |

## 十四、典型场景

### 场景 A：纯知识问答

```text
用户：RIR 2是什么意思？
→ Query Rewrite
→ Retrieval
→ Rerank
→ APPROVED chunks
→ LLM Answer + Sources
```

### 场景 B：用户数据 + RAG

```text
用户：我今天蛋白质吃得怎么样，有什么建议？
→ getTodayNutrition
→ getCurrentGoal
→ RAG: protein intake knowledge
→ Compose
→ “你的数据” + “一般知识” + Sources
```

### 场景 C：检索不足

```text
用户问一个知识库没有覆盖的专业问题
→ scores低
→ 不拼凑无关Chunk
→ 提示当前知识库没有足够依据
```

## 十五、验收标准

- 能导入知识文档；
- 能进行 Chunk + Embedding；
- 能按自然语言召回相关 Chunk；
- Query Rewrite 可以用于口语问题；
- Rerank 能改变明显不合理的初排；
- 低相关内容会被过滤；
- 回答展示来源；
- EXPIRED 文档不参与正式问答；
- Tool + RAG 能联合回答；
- 用户事实始终来自 Tool；
- RAG 故障不影响传统业务和 Personal Data Tool；
- Trace 能定位召回与 Rerank 过程。

## 十六、技术约束（简版）

- LangChain4j RAG/Embedding 接入；
- Vector Store 技术选型后定；
- 可以优先考虑 PostgreSQL/pgvector 或独立向量库，但 PRD 不绑定；
- Retrieval、Rerank、Query Rewrite 均形成独立可测试链路；
- MySQL 结构化事实不放入知识库替代查询；
- 知识文档需要来源、版权和版本元数据。


---

# Fitness Platform — PRD V3：训练闭环与 Calendar（实现对齐版）

## 一、版本概述

V3 将产品从“饮食 + AI 助手”扩展为真正的“吃 + 练 + 计划 + 回顾”健身记录工具。

本版本核心不是复杂训练理论，而是建立稳定的训练事实模型与课表模型：

- 用户可以没有计划直接自由训练；
- 用户可以创建一个或多个训练计划；
- 计划可以是 7 天，也可以是任意 N 天循环；
- 多个计划可以同时存在，Calendar 合并展示；
- 计划和实际执行必须分开保存；
- 未完成计划不自动顺延；
- 用户可以在一个月内补录或修改过去训练事实；
- 未来日期只允许修改计划，不允许提前创建“已执行训练事实”。

## 二、用户核心问题

- 今天没有计划，我能不能直接开始练？
- 我能不能做 3 练 1 休、3 练 2 休这种 9 天循环，而不是只能按星期？
- 我能不能同时有力量计划、跑步计划、拉伸计划？
- Calendar 能不能把不同计划合并在一起，再按类型筛选？
- 今天计划卧推 4×8，但我实际只做 8/8/7/8，系统能不能同时保留计划和实际？
- 今天没练，明天是不是还按原计划，而不是系统自动顺延？
- 我昨天练了但忘记记录，今天能不能补录？
- 我能不能查看动作说明？

## 三、版本目标

1. 建立 Exercise Definition；
2. 支持动作搜索和动作详情；
3. 支持自由训练；
4. 支持训练计划和训练模板；
5. 支持任意 N 天循环；
6. 支持可选开始/结束日期；
7. 支持多个训练计划并行；
8. Calendar 合并展示 Scheduled Workout；
9. 训练计划与 Workout Session 分离；
10. 支持基础 Set 记录；
11. 支持一个月内补录/修改历史训练；
12. Missed Schedule 不自动顺延；
13. 为 V3.5 统计和 V4 AI Training Tool 提供稳定业务底座。

## 四、功能范围

本版本包含：

- Exercise Library；
- Exercise Detail；
- User Custom Exercise；
- Free Workout；
- Routine / Workout Template；
- Training Plan；
- Repeating Cycle；
- Multiple Plans；
- Scheduled Workout；
- Calendar；
- Workout Session；
- Session Exercise；
- Workout Set；
- 训练历史；
- 计划与执行关联；
- 基础训练总结。

本版本不重点实现：

- 高级周期化算法；
- AI 自动训练计划；
- 自动调整重量；
- 复杂康复/医疗训练；
- 社区排行榜；
- Apple Health/Garmin。

## 五、Exercise Definition

### 1. 动作列表

至少支持：

- 中文/英文名称搜索；
- 主要肌群；
- 次要肌群（可选）；
- 器械；
- 分类；
- 状态。

### 2. 动作详情

展示：

- 名称；
- 主要肌群；
- 器械；
- 简要动作说明；
- RAG 动作指南入口；
- 合法媒体（如有）。

动作说明可以与 RAG Knowledge 关联，但训练记录本身只依赖 Exercise Definition。

### 3. 自定义动作

用户可以创建自己可见的动作。

至少填写：

- name；
- category / muscle（可选）；
- note（可选）。

修改/停用自定义动作不影响历史 Workout Session。

## 六、Workout Set 简化模型

本产品强调“记录自由”，不强迫用户填写复杂字段。

一组可以支持可选字段：

- weight；
- reps；
- duration；
- distance；
- rpe；
- rir；
- set_type；
- note；
- completed。

典型使用：

- 卧推：80kg × 8；
- 计划只写：4 × 8，不填重量；
- 跑步：5km / 30min；
- 平板：60s；
- 用户不需要的字段保持 null。

V3 不要求构建非常复杂的多态继承体系，但 Service 必须校验明显不合理组合。

## 七、Routine / Workout Template

### 1. 定位

Routine 是可重复使用的训练内容模板，不绑定日期也可以独立存在。

例如：

```text
Push A
- Bench Press 4×8
- Incline DB Press 3×10
- Lateral Raise 4×12
```

### 2. 功能

- 新建；
- 编辑；
- 复制；
- 排序动作；
- 从 Routine 开始训练；
- 被 Training Plan 引用。

## 八、Training Plan

### 1. 产品定位

Plan 描述未来训练安排，不是实际训练事实。

一个用户可以同时拥有多个有效计划，例如：

- Strength；
- Running；
- Mobility。

### 2. Plan 字段

建议：

- name；
- category；
- goal（可选）；
- status；
- schedule_type；
- start_date（可选）；
- end_date（可选）；
- note。

### 3. 状态

- DRAFT；
- ACTIVE；
- PAUSED；
- COMPLETED；
- ARCHIVED。

系统不强制只能有一个 ACTIVE Plan。

## 九、任意 N 天循环

### 1. 背景

不能只按 Monday～Sunday 建模。

必须支持：

```text
Day 1  Push
Day 2  Pull
Day 3  Legs
Day 4  Rest
Day 5  Push
Day 6  Pull
Day 7  Legs
Day 8  Rest
Day 9  Rest
→ Repeat
```

### 2. 模型原则

“循环规则”和“生效日期范围”是两个独立概念。

可支持：

- REPEATING_CYCLE：N 天循环；
- WEEKLY：可以视为特殊 7 天周期或单独交互模式；
- DATE_SPECIFIC：指定某些日期。

用户可以给循环设置 start_date，也可以设置 end_date。

### 3. 休息日

Cycle Day 可以是：

- Workout；
- Rest。

Rest Day 也是计划信息，但不会生成 Workout Session。

## 十、Multiple Plans

### 1. 并行

用户可同时拥有多个 ACTIVE Plan。

Calendar 根据日期将它们合并。

### 2. 分类

至少可以按：

- Strength；
- Cardio；
- Mobility；
- Custom。

筛选只是展示层，不影响实际 Schedule。

### 3. 冲突

同一天多个计划有安排时：

- 允许存在；
- Calendar 展示多个 Scheduled Workout；
- 不自动删除或重排；
- 可提示“当天有多个训练安排”。

## 十一、Scheduled Workout

Scheduled Workout 是 Plan 在某一天的具体安排投影。

它包含：

- planId；
- routine/template reference；
- scheduled_date；
- snapshot/version reference；
- title；
- category；
- status（planned / skipped 等可选）。

计划发生变化时，历史日期应能保留当时版本语义；后续技术设计需要版本/快照策略。

## 十二、Calendar

### 1. 独立页面

Calendar 不作为首页主体。

首页只展示“Today Training”。

### 2. 月视图

显示：

- Scheduled Workout；
- 实际 Workout Session；
- Rest Day（可简化显示）；
- 完成/未完成状态。

### 3. 分类筛选

支持：

- All；
- Strength；
- Cardio；
- Mobility；
- Specific Plan。

### 4. 日期详情

点击某日展示：

- 当天计划；
- 当天实际训练；
- Nutrition 摘要入口（可选联动）；
- Start Workout / Add Past Workout。

## 十三、Missed Schedule 规则

如果 9 月 20 日计划 Push，但用户没有记录完成：

- 9 月 20 日保持未完成/无 Session；
- 9 月 21 日仍按原计划执行；
- 不自动把 Push 顺延到 21 日；
- 用户可以自己编辑未来 Plan/Schedule。

原因：系统无法确定用户是真的没练，还是练了但没更新软件。

## 十四、Free Workout

自由训练是正式 P0 流程。

用户可以：

```text
Start Free Workout
→ Add Exercise
→ Add Sets
→ Finish
```

不需要：

- Training Plan；
- Routine；
- Goal。

完成后生成普通 Workout Session。

## 十五、从计划开始训练

用户从 Today/Calendar 点击计划：

```text
Scheduled Workout
→ Start Workout
→ 复制计划目标到本次 Session Draft
→ 用户按实际完成修改
→ Finish
```

计划内容只是参考，不得强制把未完成 Set 补成完成。

## 十六、Plan 与 Execution 分离

计划：

```text
Bench Press 4×8 @ 80kg
```

实际：

```text
80×8
80×8
80×7
75×8
```

系统同时保留：

- Scheduled target；
- Actual session facts。

Workout Session 可以关联 source_schedule_id，但自由训练允许为空。

## 十七、训练历史编辑窗口

与 Nutrition 保持一致：

- 最近一个月内可以补录、编辑、删除 Workout Session/Set；
- 超过一个月默认只读；
- 未来时间不能创建已完成 Workout Session；
- 未来 Plan/Schedule 当然允许编辑。

## 十八、训练进行页

至少展示：

- 当前训练名称；
- 开始时间；
- 动作列表；
- 每个动作计划目标（若来自计划）；
- 实际 Sets；
- Add Set；
- Copy Previous Set；
- Exercise Guide 入口；
- Finish Workout。

刷新/短暂离开不能丢失已经保存的数据。

## 十九、训练结束

结束时展示：

- duration；
- exercise count；
- completed sets；
- total reps（适用时）；
- load volume（适用时）；
- note。

如果存在计划中未完成 Set：

- 提示但允许结束；
- 以实际事实保存。

## 二十、计划修改与历史保护

用户 9 月 15 日把 Plan 中卧推从 4×8 改成 5×5：

- 9 月 15 日之后未来排期使用新版本；
- 9 月 10 日历史 Calendar/计划目标仍能显示当时 4×8；
- 已完成 Session 永远不被计划更新改写。

技术设计阶段应采用 Plan Version / Schedule Snapshot 等机制支持。

## 二十一、异常与边界

| 场景 | 系统行为 |
| --- | --- |
| 没有 Plan | Free Workout 正常使用 |
| 多 Plan 同日冲突 | 展示全部，提示但不自动调整 |
| Missed Workout | 不顺延 |
| 计划引用停用 Exercise | 提示替换，历史保持 |
| 用户未来日期提交完成训练 | 阻止 |
| 历史超过一个月编辑 | 只读 |
| Session 未结束又新开 | 提示继续/结束已有 Session |
| 网络中断 | 已保存 Sets 保留 |

## 二十二、验收标准

- 无 Plan 能自由训练；
- 可以创建 Routine；
- 可以创建 9 天等任意 N 天循环计划；
- Plan 可以设置可选 start/end date；
- 同时存在多个 ACTIVE Plan；
- Calendar 能合并多个 Plan；
- Calendar 支持分类筛选；
- Missed Schedule 不自动顺延；
- 从 Plan 启动后实际 Set 可和目标不同；
- Plan 修改不改写历史 Session；
- 一个月内可以补录过去训练；
- 未来不能创建已完成事实；
- Exercise Guide 可以从训练页访问。

## 二十三、技术约束（简版）

- Exercise / Plan / Schedule / Session / Set 分离；
- Plan 必须支持版本或快照语义；
- Calendar 是聚合查询层，不把所有数据复制成“日历事件表”作为唯一事实；
- Service 层处理循环投影、权限与历史规则；
- 为 V3.5 QuerySpec 和 V4 Training Tool 保留稳定 API。


---

# Fitness Platform — PRD V3.5：训练统计与进步分析（实现对齐版）

## 一、版本概述

V3 解决“记录训练和安排训练”，V3.5 解决“从训练事实里看懂自己练得怎么样”。

本版本强调稳定、可解释的统计口径和灵活条件查询，而不是堆砌大量复杂图表。

训练统计与 Nutrition Analytics 遵守同一产品思想：Query → Chart → Table → Export，并为 V4 AI Query 复用。

## 二、用户核心问题

- 我最近每周练几次？
- 我的卧推重量有没有进步？
- 本月计划训练 16 次，实际完成多少？
- 某个动作最近做了多少组、多少次数？
- 训练容量趋势怎么样？
- 我能不能按 Plan、Exercise、Category、日期筛选？
- 当前筛选结果能不能直接导出？

## 三、版本目标

1. 建立 Training QuerySpec；
2. 支持 Exercise History；
3. 支持 Frequency；
4. 支持 Set/Reps；
5. 支持 Load Volume；
6. 支持基础 PR；
7. 支持 Plan Completion；
8. 支持 Date/Plan/Exercise/Category 筛选；
9. 支持日/周/月分组；
10. 支持 Chart + Table；
11. 支持 Export Current Result；
12. 所有指标可追溯到原始 Workout Session/Set。

## 四、Training QuerySpec

至少支持：

```text
DateRange
PlanIds
ExerciseIds
Category
MuscleGroup
SessionSource (Plan/Free)
Metrics
GroupBy
Sort
```

后续 AI 询问：

> “过去三个月卧推变化怎么样？”

也构造同一 QuerySpec。

## 五、统计首页

建议展示：

- 本周 Workout Session 数；
- 本周完成 Sets；
- 本周训练总时长；
- 本周适用 Load Volume；
- 当前计划完成率；
- 最近 PR（可选）。

用户可改变时间范围后刷新。

## 六、Exercise History

用户选择一个 Exercise 后查看：

- 最近训练日期；
- 每次 Session；
- 各组 weight/reps；
- best weight；
- total sets；
- total reps；
- load volume；
- estimated 1RM（仅适用时）；
- PR 标记。

## 七、PR

### 1. Weight PR

适用于外部负重动作：历史成功完成 Set 的最高重量。

### 2. Rep PR

避免简单用“最高次数”跨不同重量比较。

可展示：

- 某重量下最多次数；
- 常见 rep range 下最佳重量。

### 3. Estimated 1RM

仅适用于合理的 weight + reps 动作。

必须标记为“估算”。

不对 duration/distance 等动作硬算。

### 4. 数据修改

用户在一个月窗口内修改历史 Set 后，PR 应同步重算。

## 八、Load Volume

仅对存在明确外部重量 + reps 的 Set：

```text
Volume = weight × reps
```

不把：

- 跑步距离；
- duration；
- 自重；
- 辅助重量；

强行转换后相加成同一个数字。

对不适用动作，应使用 sets/reps/duration/distance 等独立指标。

## 九、Training Frequency

至少支持：

- 每周 Session 数；
- 每月 Session 数；
- 平均每周次数；
- 按 Plan；
- 按 Category；
- 按 Exercise。

## 十、Plan Completion

### 1. 定义

在日期范围内：

```text
Completed Scheduled Workouts / Planned Scheduled Workouts
```

### 2. 注意

- Missed Schedule 不自动顺延；
- 用户补录并关联某 Scheduled Workout 后可以变为 Completed；
- Free Workout 不应自动算作某计划完成，除非用户明确关联。

### 3. 展示

例如：

```text
September
Planned: 16
Completed: 13
Completion: 81.25%
```

## 十一、计划目标与实际对比

可在单次 Workout 详情展示：

| Exercise | Planned | Actual |
| --- | --- | --- |
| Bench | 4×8 @80 | 80×8 / 80×8 / 80×7 / 75×8 |

本版本不要求自动评价“好/坏”，只展示事实差异。

## 十二、图表

推荐首期：

- Weekly Training Frequency；
- Exercise Max Weight Trend；
- Exercise Load Volume Trend；
- Plan Completion Trend；
- Completed Sets Trend。

避免所有指标都画成图导致页面噪音。

## 十三、条件查询

用户可以组合：

```text
Last 90 Days
Plan = PPL 9-Day
Exercise = Bench Press
Metric = Max Weight
Group = Week
```

结果同时提供：

- Chart；
- Table；
- Export。

## 十四、导出

复用 V1.2 Export Service。

可导出：

- Workout Session 明细；
- Set 明细；
- Exercise History；
- 按当前 QuerySpec 的聚合统计；
- Plan Completion。

## 十五、Calendar 与 Analytics 的关系

Calendar 回答：

> 哪天计划/练了什么？

Analytics 回答：

> 一段时间内练得怎么样？

二者读取同一 Plan/Schedule/Session 数据，不建立两份事实。

## 十六、异常与边界

| 场景 | 系统行为 |
| --- | --- |
| 只有一次训练 | 展示事实，不输出明显趋势结论 |
| 某 Exercise 数据不足 | 隐藏或标记相关 PR/趋势 |
| 历史被合法修改 | 统计重新计算 |
| Free Workout 无 Plan | 正常统计，但不算 Plan Completion |
| 不适用 Load Volume | 不展示该指标 |
| 时间范围无数据 | 空状态 |

## 十七、验收标准

- 能查看周/月训练次数；
- 能按 Plan/Exercise/Category 筛选；
- 能查看某 Exercise 的历史；
- 能正确计算适用 Load Volume；
- 能展示基础 PR；
- 能计算 Plan Completion；
- 计划和实际可以对比；
- 图表与表格结果一致；
- 当前查询结果可导出；
- 修改合法历史数据后统计同步变化；
- 后续 AI Query 可复用同一统计接口。

## 十八、技术约束（简版）

- 统计公式统一在后端；
- 初期不要求实时数仓；
- QuerySpec 与 Nutrition Analytics 尽量保持一致设计风格；
- 聚合结果可缓存，但原始 Session/Set 是权威事实；
- PR/公式需有版本意识，避免以后算法变化无法解释。


---

# Fitness Platform — PRD V4：AI Training Extension（实现对齐版）

## 一、版本概述

V4 在 V2/V2.1 的 Fitness Agent 基础上扩展训练业务 Tool，使 AI 可以：

- 查询训练历史；
- 查询训练统计；
- 生成训练记录 Draft；
- 生成训练计划 Draft；
- 根据用户要求修改计划 Draft；
- 结合 RAG 解释动作和训练知识。

AI 仍然不是教练，不拥有自主决策权。所有训练写操作都必须 Preview + Confirm。

## 二、用户核心问题

- 我能不能说“今天卧推 80kg 做了 8、8、7”，系统帮我生成训练记录？
- 我能不能问“过去三个月卧推进步了吗？”
- 我能不能一句话让 AI 生成一个 9 天循环训练计划草稿？
- AI 生成计划以后能不能直接进入传统编辑页面让我调整？
- AI 会不会自行改变我的训练计划？
- AI 提建议时能不能结合我的真实训练数据和 RAG？

## 三、版本目标

1. 增加 Training Read Tools；
2. 增加 Workout Record Draft；
3. 增加 Training Plan Draft；
4. 支持 N-Day Cycle 结构化生成；
5. 支持 Multiple Plan 场景；
6. 所有训练写操作确认后才执行；
7. AI 生成计划保存为 V3 正式 Plan，不在聊天中维护“AI 私有计划”；
8. AI 可以结合 Training Tool + RAG 回答；
9. AI 不自动顺延/修改用户 Plan；
10. AI 不能提前创建未来已完成 Session。

## 四、Training Read Tools

建议：

- `getTodayTraining()`；
- `queryWorkoutHistory(querySpec)`；
- `getExerciseHistory(exerciseId, range)`；
- `getTrainingAnalytics(querySpec)`；
- `getTrainingPlans()`；
- `getPlanDetail(planId)`；
- `searchExercise(query)`。

## 五、自然语言训练查询

用户：

> “我最近一个月卧推怎么样？”

流程：

```text
Resolve Exercise
→ Build Training QuerySpec
→ Training Analytics Tool
→ 返回结构化数据
→ LLM 组织答案
```

如果用户问“为什么进步慢”：

- 用户事实来自 Tool；
- 一般训练知识来自 RAG；
- 回答表述为建议/可能方向，不做绝对判断。

## 六、自然语言训练记录 Draft

### 1. 示例

用户：

> “今天卧推 80kg 做了 8、8、7，飞鸟 15kg 三组 12。”

Structured Output：

- date；
- exercise query；
- set values；
- weight；
- reps；
- optional session title。

### 2. Resolve

动作通过 Exercise Search 匹配真实 exerciseId。

多候选让用户选择。

### 3. 关联 Plan

如果今天有 Scheduled Workout，可提示：

> 是否关联到今天的 Push Day？

不能自动假定。

### 4. Preview

展示：

- Session Date；
- Plan/Schedule relation；
- Exercises；
- Actual Sets。

用户确认后调用正式 Workout Service。

## 七、AI Training Plan Draft

### 1. 产品定位

AI 只生成结构化草稿。

用户：

> “帮我做一个 3练1休、3练2休 的 9 天循环，主要增肌。”

AI 可生成：

```text
Day1 Push
Day2 Pull
Day3 Legs
Day4 Rest
Day5 Push
Day6 Pull
Day7 Legs
Day8 Rest
Day9 Rest
```

再为训练日填充 Exercise / Sets / Reps 等可选目标。

### 2. 用户输入不足

AI 可以询问必要约束：

- 目标；
- 训练经验；
- 可用器械；
- 每次时长；
- 不想做/不能做的动作；
- 周期是否有起止日期。

不需要无休止追问，允许用户之后在传统编辑器继续改。

### 3. 计划预览

AI 展示结构化 Plan Preview。

用户可以：

- Edit in chat；
- Open Plan Editor；
- Save Draft；
- Confirm Create；
- Cancel。

### 4. Confirm

只有确认后调用 Training Plan Service 创建正式 V3 Plan。

创建成功后传统页面立即可见。

## 八、AI 修改计划

用户：

> “把 Day 5 的杠铃卧推换成哑铃卧推。”

流程：

```text
Read current Plan version
→ Resolve target Day/Exercise
→ Create Change Draft
→ Before/After Preview
→ Confirm
→ Plan Service creates updated version
```

历史 Session 不受影响。

AI 不可以：

- 发现用户训练没完成就自动降重量；
- 自动改未来计划；
- 自动移动 Missed Schedule；
- 自主设置新的目标。

## 九、Training Tool + RAG

用户：

> “我最近卧推一直卡在 80kg，有什么可以注意的？”

系统：

- Tool：读取近期 Bench History；
- RAG：检索渐进超负荷、训练量、动作相关知识；
- LLM：区分数据事实和一般建议。

建议必须保持参考性质。

## 十、AI Export

用户：

> “把过去三个月卧推数据导出来。”

AI：

```text
Natural Language
→ QuerySpec
→ Export Preview
→ Confirm
→ Existing Export Service
```

AI 不自行生成另一份 Excel 实现。

## 十一、异常与边界

| 场景 | 系统行为 |
| --- | --- |
| Exercise 多候选 | 让用户选 |
| 用户没有 Plan | 可以创建 Free Workout Draft |
| Plan Draft 缺少关键约束 | 一次性询问必要信息 |
| 用户要求自动调整计划 | 提供建议/草稿，不自动执行 |
| 未来日期提交完成 Session | 阻止 |
| 计划变更冲突 | 展示冲突并要求用户确认处理 |
| RAG 不可用 | Training Tool 仍可查询事实 |

## 十二、验收标准

- AI 可以查询 Today Training；
- AI 可以查询 Exercise History；
- AI 可以构造 Training QuerySpec；
- 自然语言训练记录会生成 Preview；
- Confirm 后创建正式 Workout Session；
- AI 可生成 N-Day Plan Draft；
- Plan Draft 可进入传统编辑器；
- Confirm 后创建 V3 正式 Plan；
- AI 修改计划使用版本/变更草稿，不改历史；
- AI 不自主修改用户 Plan；
- Tool + RAG 可联合回答训练问题；
- AI Export 复用现有 Export Service。

## 十三、技术约束（简版）

- 复用 V2 Agent 状态机、Pending Action、requestId、SSE、Trace；
- Training Tools 只调用 V3/V3.5 Service；
- Plan Draft 使用 Structured Output；
- Exercise Resolve 与 Food Resolve 采用相同“真实实体 + 用户选择”原则；
- 所有写操作 Confirm-first。


---

# Fitness Platform — Future：轻社交与可选扩展

## 一、版本定位

本文件记录已经讨论过、但不进入当前主线的产品能力。它们可以在 Nutrition、Training、Agent 等核心留存验证后再排期。

原则：Future 能力不能反向拖慢当前核心系统。

## 二、轻社交

### 1. 第一阶段只做 Share

优先支持：

- 分享一次 Workout；
- 分享训练数据卡片；
- 分享 Training Plan；
- 公开/私密 Share Link；
- 复制公开 Plan 到自己的账户。

### 2. Workout Share Card

可展示：

- Workout Name；
- Date；
- Duration；
- Exercise Count；
- Working Sets；
- Load Volume（适用时）；
- Top Exercises。

用户可以选择隐藏：

- 具体重量；
- 备注；
- 其他隐私字段。

### 3. Plan Share

用户可以把 Plan 生成只读分享页面。

其他用户可以：

- 查看；
- Copy to My Plans。

Copy 后生成独立 Plan，不和来源计划实时联动。

### 4. 暂缓社区能力

暂不优先：

- Feed 推荐算法；
- 私信；
- 群聊；
- 点赞评论体系；
- 复杂排行榜；
- 创作者变现；
- 大规模内容审核。

## 三、Body Metrics

当前用户核心聚焦“吃 + 练”，完整 Body 模块暂缓。

未来可按需要增加：

- Weight；
- Body Fat；
- Measurements；
- Progress Photo；
- Trend。

若只需要体重，可先做 Lightweight Metric，不必一次建立完整 Body Domain。

## 四、Coach

真人教练不是当前核心用户。

未来商业化需要时再考虑：

- Coach Identity；
- Student Relationship；
- Permission Scope；
- Plan Sharing；
- Feedback；
- Subscription/Payment。

Coach 不应成为 Nutrition/Training/AI 主线的前置依赖。

## 五、Health Integration

未来可能支持：

- Apple Health；
- Google Health Connect；
- Garmin；
- Wearables。

当前不做的原因：

- 授权与平台适配复杂；
- 数据语义多；
- 不是当前“记录饮食与训练”的必要闭环。

## 六、历史文件智能导入

未来可以实现：

```text
Upload CSV/XLSX/JSON/Image/PDF
→ Detect
→ Mapping
→ Preview
→ Duplicate Check
→ Confirm
→ Batch Service Import
```

但这本身接近一个独立产品能力，不放入当前 Agent Core。

## 七、AI 图片识别

当前明确不做食物图片营养估算。

未来如尝试视觉能力，也应作为 Experimental Feature：

- 只提供候选；
- 明确估算；
- 不直接写入；
- 用户必须确认。

## 八、商业化

AI 可以作为低价增值能力，例如：

- 免费版：基础记录、Dashboard、手动查询；
- 付费版：更多 AI 对话、RAG、高级分析/导出等。

具体定价、额度、订阅体系需要在有真实用户数据后决定，本 PRD 不提前固化。


---

以下按“版本 → 模块 → 需求单元”提炼。每条尽量对应一个可开发、可验收的需求点。

---

# 0. 全局需求

- **G-01 双入口长期并存**：传统业务页面与 AI Assistant 长期并存，AI 不可用时基础业务正常使用。
- **G-02 事实优先**：Food Record、Workout Session 等实际发生事实独立于 Goal、Meal、Tag、Plan。
- **G-03 AI 不直写数据库**：AI 读写必须调用已有 Java Service/API/Tool。
- **G-04 Confirm-first**：所有 AI 写操作必须 Draft → Preview → User Confirm → Execute。
- **G-05 不确定性显式化**：食品、动作、单位或日期不明确时必须让用户选择/补充，不强行猜测。
- **G-06 历史快照**：Food Record 保存营养快照，Food DB 修改不改写历史统计。
- **G-07 计划与执行分离**：Training Plan/Schedule 与 Workout Session/Set 分离。
- **G-08 修改窗口**：饮食与训练事实最近一个月可修改/删除，超过窗口默认只读。
- **G-09 时间语义**：业务统计使用 occurred_at/business_date/started_at，不使用 created_at 替代事实时间。
- **G-10 QuerySpec**：Dashboard/History/Analytics/Export/AI Query 共享查询语义。
- **G-11 图片附件原则**：食物图片仅作为附件，不做 AI 营养识别。
- **G-12 用户最终决策权**：AI 可建议但不能自主修改 Goal/Plan/历史事实。
- **G-13 知识与事实分离**：MySQL 保存业务事实，RAG 保存知识，Redis 保存短期会话上下文。
- **G-14 数据所有权**：用户可按时间范围、数据域和当前查询条件导出自己的数据。
- **G-15 用户隔离**：所有业务 Service 和 Tool 强制当前用户数据范围。

---

# V1 饮食记录 MVP

- **V1-01 账户注册**：Email/Password 注册，Email 唯一，密码安全存储。
- **V1-02 登录退出**：Spring Security/JWT 鉴权，禁用用户不可登录。
- **V1-03 用户时区**：时区决定 Today 和 business_date。
- **V1-04 Goal 可选**：用户没有任何 Goal 仍可完整记录和统计。
- **V1-05 Goal 部分字段**：Calories/P/C/F 可只设置部分指标，未设置保持 null。
- **V1-06 Goal 历史**：按 effective_date 生效，同一日期只命中一组有效目标。
- **V1-07 Food 列表**：公共 Food 支持分类、状态、分页。
- **V1-08 Food 模糊搜索**：按名称搜索 ACTIVE Food。
- **V1-09 Food 详情**：展示每100g Calories/P/C/F 和来源。
- **V1-10 Food 状态保护**：INACTIVE 不可新增记录但不破坏历史。
- **V1-11 Food Record 新增**：Food + amount + occurred_at 必填，Meal/Note 可选。
- **V1-12 营养计算**：服务端使用 BigDecimal 统一计算。
- **V1-13 营养快照**：创建 Food Record 时固化营养标准及实际营养值。
- **V1-14 Food Record 编辑**：一个月内可修改 amount/time/meal/food/note。
- **V1-15 Food Record 删除**：一个月内可删除并同步刷新统计。
- **V1-16 历史只读**：超过一个月默认不可修改事实记录。
- **V1-17 幂等提交**：新增记录使用 requestId，重复提交不重复创建。
- **V1-18 Today Dashboard**：展示 Calories/P/C/F 实际值。
- **V1-19 Goal Completion**：有目标时展示 target/remaining/over/completion。
- **V1-20 无目标状态**：不显示虚假 0 目标。
- **V1-21 今日时间线**：按 occurred_at 展示记录。
- **V1-22 Meal 分组**：可选按 Meal 分组，未分餐有独立分组。
- **V1-23 历史日期查询**：支持查看指定日期 Food Record 和当日 Goal。
- **V1-24 权限隔离**：用户只能访问自己的记录和目标。

---

# V1.1 快速记录与食品搜索

- **V1.1-01 搜索优先级**：Local Food DB 作为首选搜索数据源。
- **V1.1-02 多候选展示**：模糊搜索结果由用户二次选择，不自动猜具体 Food。
- **V1.1-03 第三方回补**：本地无结果/不足时调用 Third-party Food API。
- **V1.1-04 第三方标准化**：外部字段映射为内部 Food 标准结构。
- **V1.1-05 第三方入库**：用户选中的外部 Food 保存到本地数据库。
- **V1.1-06 来源标识**：Food 区分 SYSTEM/THIRD_PARTY/USER_CUSTOM。
- **V1.1-07 Food 去重**：provider+externalId 等策略避免重复入库。
- **V1.1-08 Redis 热点缓存**：缓存热门 Food/Search 结果，失效后回源数据库。
- **V1.1-09 缓存失效**：Food 修改/停用主动失效相关缓存。
- **V1.1-10 最近吃过**：按历史记录去重展示最近 Food。
- **V1.1-11 常吃 Food**：按近阶段频率自动计算。
- **V1.1-12 收藏**：用户可收藏/取消收藏 Food。
- **V1.1-13 自定义 Food**：用户可创建仅自己可见的 Food。
- **V1.1-14 多 Food 添加**：一次输入多行 Food/amount 并汇总营养。
- **V1.1-15 批量幂等**：整批请求重试不重复创建。
- **V1.1-16 快速复制**：支持复制上一条/上一餐/昨天记录，创建新事实。

---

# V1.2 媒体、Analytics 与 Export

- **V1.2-01 Food Photo**：Food Record/记录组可关联图片。
- **V1.2-02 图片不阻塞记录**：上传失败不回滚 Food Record。
- **V1.2-03 图片隐私**：默认仅本人可见。
- **V1.2-04 QuerySpec**：定义 domain/dateRange/filters/groupBy/metrics/sort/columns。
- **V1.2-05 DateRange**：Today/7/30/90 days/month/year/custom。
- **V1.2-06 Nutrition Filters**：Food/Category/Brand/Meal/Source/HasPhoto 等。
- **V1.2-07 GroupBy**：Day/Week/Month/Meal/Food/Category。
- **V1.2-08 Metrics**：Calories/P/C/F/RecordCount/GoalCompletion。
- **V1.2-09 Chart + Table**：图表与明细/聚合表复用同一结果。
- **V1.2-10 Export Current Result**：继承当前 QuerySpec。
- **V1.2-11 My Data Export**：独立选择范围和数据域。
- **V1.2-12 导出明细**：包含发生时间、Food、amount、营养、来源等。
- **V1.2-13 导出汇总**：包含每日实际/目标/差额/完成度。
- **V1.2-14 图片打包**：用户可选择导出关联图片。
- **V1.2-15 Export Job**：PENDING/PROCESSING/SUCCEEDED/FAILED/EXPIRED。
- **V1.2-16 口径统一**：Dashboard/Analytics/Export/AI Query 使用同一后端计算。

---

# V2 Fitness Agent Core

- **V2-01 AI 入口**：Dashboard 轻量入口 + 独立 AI 页面。
- **V2-02 Text Input**：文字输入、发送、停止生成、重试。
- **V2-03 Voice-to-Text**：语音先转文字，用户可编辑后发送。
- **V2-04 LangChain4j**：用于 LLM、Tool Calling、Structured Output 编排。
- **V2-05 Intent**：区分 Query/Search/Record 等业务意图。
- **V2-06 Structured Output**：自由文本转结构化业务参数并允许 missing/ambiguous。
- **V2-07 Food Search Tool**：复用 V1.1 Food Search Service。
- **V2-08 Nutrition Query Tool**：查询 Today/Range/Goal/Analytics。
- **V2-09 Food Entity Resolve**：foodId 必须来自真实搜索候选。
- **V2-10 多候选确认**：食品不唯一时用户选择。
- **V2-11 Record Draft**：AI 先生成 Food Record Draft。
- **V2-12 Business Preview**：营养值由 Java Service 计算后展示。
- **V2-13 Confirm-first**：用户确认前不得写正式 Food Record。
- **V2-14 Execute Tool**：确认后调用原 Food Record Service。
- **V2-15 JWT Context**：Tool 使用当前认证用户，不接受模型任意 userId。
- **V2-16 Redis Memory**：保存短期会话上下文、实体引用、Pending Action。
- **V2-17 Memory 非事实库**：实时摄入/Goal 必须重新 Tool 查询。
- **V2-18 Pending Action**：服务端保存等待确认的结构化动作。
- **V2-19 requestId**：重复 Confirm/重试只能执行一次写入。
- **V2-20 SSE**：输出流式文本及 UNDERSTANDING/QUERYING/WAITING/EXECUTING 等业务状态。
- **V2-21 SSE 中断恢复**：写成功后断线重试不重复写。
- **V2-22 Agent Trace**：记录 Intent/Structured Output/Tool/Confirm/Result 链路。
- **V2-23 安全日志**：不得记录 Password/JWT/Secret 等敏感信息。
- **V2-24 降级**：LLM 不可用时传统页面仍可用。

---

# V2.1 RAG

- **V2.1-01 Knowledge Document**：文档保存 title/topic/source/version/license/status 等元数据。
- **V2.1-02 Review Status**：DRAFT/REVIEWING/APPROVED/REJECTED/EXPIRED。
- **V2.1-03 Chunk**：按语义切分并保留来源元数据。
- **V2.1-04 Embedding**：Chunk 生成向量索引。
- **V2.1-05 Retrieval**：自然语言检索相关 Chunk。
- **V2.1-06 Query Rewrite**：口语问题可改写为检索查询。
- **V2.1-07 Rerank**：对召回候选二次排序。
- **V2.1-08 Threshold**：低相关结果过滤，不强行生成来源。
- **V2.1-09 Source Citation**：回答展示实际使用的来源。
- **V2.1-10 Tool + RAG**：个人事实来自 Tool，一般知识来自 RAG。
- **V2.1-11 Source Priority**：业务事实 > 用户本轮输入 > RAG > Memory > 模型常识。
- **V2.1-12 RAG Trace**：记录 rewrite/retrieval/rerank/selected chunks/version。
- **V2.1-13 RAG 降级**：RAG 故障不影响 Personal Data Tool。

---

# V3 Training + Calendar

- **V3-01 Exercise Library**：支持搜索、肌群、器械、详情。
- **V3-02 Custom Exercise**：用户可创建自己的动作。
- **V3-03 Workout Set**：weight/reps/duration/distance/rpe/rir 等按需填写。
- **V3-04 Routine**：可重复使用的训练模板。
- **V3-05 Free Workout**：无 Plan 也能开始并完成训练。
- **V3-06 Training Plan**：未来训练安排与实际执行分离。
- **V3-07 Multiple Active Plans**：用户可同时启用多个计划。
- **V3-08 N-Day Cycle**：支持任意 N 天循环，包括 9 天循环。
- **V3-09 Optional Date Range**：Plan 可设置 start/end date。
- **V3-10 Rest Day**：Cycle 支持明确休息日。
- **V3-11 Calendar Merge**：合并多个 Plan 的 Schedule 与实际 Session。
- **V3-12 Calendar Filter**：按 Strength/Cardio/Mobility/Plan 分类筛选。
- **V3-13 Missed 不顺延**：未完成计划不会自动移动后续安排。
- **V3-14 Plan/Execution 分离**：计划目标和实际 Sets 同时保留。
- **V3-15 Historical Protection**：修改 Plan 不改写历史 Session。
- **V3-16 Past Edit Window**：一个月内可补录/修改训练。
- **V3-17 Future Fact Block**：未来不能创建已完成 Session。

---

# V3.5 Training Analytics

- **V3.5-01 Training QuerySpec**：支持日期、Plan、Exercise、Category、指标和分组。
- **V3.5-02 Exercise History**：查看某动作所有历史 Set。
- **V3.5-03 Frequency**：周/月 Session 数。
- **V3.5-04 Completed Sets/Reps**：基础训练量指标。
- **V3.5-05 Load Volume**：仅适用 weight×reps 动作。
- **V3.5-06 Weight PR**：最高成功重量。
- **V3.5-07 Estimated 1RM**：适用时计算并明确标识估算。
- **V3.5-08 Plan Completion**：Scheduled vs Completed。
- **V3.5-09 Planned vs Actual**：单次训练对比计划目标和实际执行。
- **V3.5-10 Chart/Table/Export**：当前 QuerySpec 结果可图表、表格和导出。

---

# V4 AI Training Extension

- **V4-01 Training Read Tools**：查询 Today Training、History、Exercise、Analytics、Plan。
- **V4-02 Workout Draft**：自然语言训练记录解析成结构化草稿。
- **V4-03 Exercise Resolve**：动作必须匹配真实 Exercise 候选。
- **V4-04 Schedule Relation**：关联今日计划需用户确认。
- **V4-05 Workout Confirm**：确认后创建正式 Session。
- **V4-06 Plan Draft**：AI 可生成结构化 Training Plan 草稿。
- **V4-07 N-Day Draft**：支持 9 天等任意循环。
- **V4-08 Open Plan Editor**：草稿可以进入传统编辑页继续修改。
- **V4-09 Plan Confirm**：用户确认后创建正式 V3 Plan。
- **V4-10 Plan Change Draft**：AI 修改计划必须 before/after preview。
- **V4-11 No Autonomous Change**：AI 不因训练表现自行改变 Plan。
- **V4-12 Training Tool + RAG**：结合真实训练数据和训练知识回答。
- **V4-13 AI Export**：自然语言生成 QuerySpec，确认后复用 Export Service。

---

# Future

- **F-01 Workout Share**：分享一次训练的数据卡片。
- **F-02 Plan Share**：分享/复制训练计划。
- **F-03 Privacy Share**：分享前用户选择隐藏重量、备注等字段。
- **F-04 Body Lightweight**：需要时先增加体重等轻量 Metric。
- **F-05 Coach Optional**：有商业需求后再建立 Coach/Student/Permission。
- **F-06 Health Integration**：Apple Health/Health Connect/Garmin 暂缓。
- **F-07 Intelligent Import**：复杂历史文件解析作为独立 Future 能力。
- **F-08 Vision Nutrition**：食物图片识别不进入当前主线。


---


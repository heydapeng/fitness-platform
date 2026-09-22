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

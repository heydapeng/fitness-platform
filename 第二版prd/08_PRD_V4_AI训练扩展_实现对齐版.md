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

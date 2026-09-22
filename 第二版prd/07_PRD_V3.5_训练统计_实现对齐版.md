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

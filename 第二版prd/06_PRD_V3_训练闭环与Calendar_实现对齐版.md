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

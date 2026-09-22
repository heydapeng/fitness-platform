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

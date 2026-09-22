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

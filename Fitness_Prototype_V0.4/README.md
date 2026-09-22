# Fitness Prototype V0.4

V0.4 统一了登录后的整套产品视觉。

## 核心变化

- 未登录首页仍然是品牌 Landing Page：Hero → 功能故事 → 底部注册/登录。
- 登录后进入个人数据首页，不再显示营销内容。
- 饮食、训练、日历、分析、AI 助手、指南全部改成与个人首页一致的 Design System：白色顶部导航、深蓝 Hero、蓝色强调色、统一卡片/按钮/图表/表格。
- 二级页面删除 QuerySpec、Tool 名称、active_plan_id 等开发者文案，保留用户能理解的产品信息。
- AI 页面仍然演示“先预览、后确认”的写入机制，但界面不暴露底层 Agent 技术细节。

## 页面

- `index.html`：访客 Landing Page + 登录后 Today Dashboard
- `nutrition.html`：饮食记录与食品搜索
- `training.html`：训练计划、自由训练、计划/实际分离
- `calendar.html`：多计划统一日历
- `analytics.html`：筛选、趋势、表格、CSV 导出
- `assistant.html`：AI 查询 / 记录草稿 / 知识问答
- `knowledge.html`：健身与营养指南

直接打开 `index.html` 即可。登录弹窗中的“使用演示数据进入”会切换到个人首页。

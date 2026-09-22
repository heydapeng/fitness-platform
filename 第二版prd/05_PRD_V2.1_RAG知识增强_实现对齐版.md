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

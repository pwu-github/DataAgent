# DataAgent 架构设计与技术方案

## 一、项目概述

DataAgent 是基于 **Spring AI Alibaba Graph** 打造的企业级智能数据分析 Agent。它超越了传统的 Text-to-SQL 工具，进化为一个能够执行 **Python 深度分析**、生成 **多维度图表报告** 的 AI 智能数据分析师。

### 1.1 核心特性

| 特性 | 说明 |
| :--- | :--- |
| **智能数据分析** | 基于 StateGraph 的 Text-to-SQL 转换，支持复杂的多表查询和多轮对话意图理解 |
| **Python 深度分析** | 内置 Docker/Local Python 执行器，自动生成并执行 Python 代码进行统计分析与机器学习预测 |
| **智能报告生成** | 分析结果自动汇总为包含 ECharts 图表的 HTML/Markdown 报告 |
| **人工反馈机制** | 独创的 Human-in-the-loop 机制，支持用户在计划生成阶段进行干预和调整 |
| **RAG 检索增强** | 集成向量数据库，支持对业务元数据、术语库的语义检索，提升 SQL 生成准确率 |
| **多模型调度** | 内置模型注册表，支持运行时动态切换不同的 LLM 和 Embedding 模型 |
| **MCP 服务器** | 遵循 MCP 协议，支持作为 Tool Server 对外提供 NL2SQL 和智能体管理能力 |

---

## 二、系统架构

### 2.1 整体架构图

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              前端 (Vue.js + ECharts)                         │
│                     data-agent-frontend/src/components                       │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Controller 层 (REST API)                            │
│     AgentController / ChatController / DatasourceController 等              │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Service 层 (业务逻辑)                                │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │GraphService │  │Nl2SqlService│  │CodeExecutor │  │VectorStore  │         │
│  │  (状态图)   │  │  (NL2SQL)   │  │ (Python执行) │  │  (向量检索)  │         │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      StateGraph 工作流 (核心引擎)                            │
│                                                                             │
│  START → IntentRecognition → EvidenceRecall → QueryEnhance → SchemaRecall  │
│    → TableRelation → FeasibilityAssessment → Planner → PlanExecutor        │
│    → [SQLGenerate → SQLExecute] / [PythonGenerate → PythonExecute]         │
│    → ReportGenerator → END                                                  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
              ┌───────────────────────┼───────────────────────┐
              ▼                       ▼                       ▼
┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐
│  LLM (大语言模型)   │  │  Vector Store       │  │  Database Connector  │
│  通义千问/DeepSeek  │  │  向量数据库          │  │  MySQL/PG/Hive/...   │
└─────────────────────┘  └─────────────────────┘  └─────────────────────┘
```

### 2.2 模块结构

```
DataAgent/
├── data-agent-management/              # 后端服务
│   └── src/main/java/com/alibaba/cloud/ai/dataagent/
│       ├── controller/                  # REST API 控制器
│       │   ├── AgentController.java
│       │   ├── ChatController.java
│       │   ├── GraphController.java
│       │   └── ...
│       ├── service/                     # 业务服务层
│       │   ├── graph/                   # 状态图服务
│       │   │   ├── GraphServiceImpl.java
│       │   │   └── Context/
│       │   │       ├── MultiTurnContextManager.java
│       │   │       └── StreamContext.java
│       │   ├── nl2sql/                  # NL2SQL 服务
│       │   │   ├── Nl2SqlService.java
│       │   │   └── Nl2SqlServiceImpl.java
│       │   ├── code/                    # Python 执行器
│       │   │   ├── CodePoolExecutorService.java
│       │   │   └── impls/
│       │   │       ├── DockerCodePoolExecutorService.java
│       │   │       └── LocalCodePoolExecutorService.java
│       │   ├── vectorstore/             # 向量存储服务
│       │   ├── hybrid/                  # 混合检索
│       │   └── mcp/                     # MCP 服务器
│       ├── workflow/                   # 工作流节点
│       │   ├── node/
│       │   │   ├── IntentRecognitionNode.java
│       │   │   ├── EvidenceRecallNode.java
│       │   │   ├── SchemaRecallNode.java
│       │   │   ├── SqlGenerateNode.java
│       │   │   ├── PythonGenerateNode.java
│       │   │   └── ...
│       │   └── dispatcher/
│       │       ├── IntentRecognitionDispatcher.java
│       │       ├── SchemaRecallDispatcher.java
│       │       └── ...
│       ├── prompt/                      # Prompt 模板
│       │   ├── PromptConstant.java
│       │   ├── PromptHelper.java
│       │   └── PromptLoader.java
│       ├── connector/                   # 数据库连接器
│       │   ├── pool/                    # 连接池
│       │   └── impls/                   # 各数据库实现
│       │       ├── mysql/
│       │       ├── postgre/
│       │       ├── hive/
│       │       └── ...
│       ├── config/
│       │   └── DataAgentConfiguration.java  # 核心配置类
│       └── dto/                         # 数据传输对象
├── data-agent-frontend/                 # 前端应用 (Vue.js)
└── docs/                               # 文档
```

---

## 三、核心实现思路

### 3.1 StateGraph 工作流设计

项目基于 **Spring AI Alibaba Graph** 的 `StateGraph` 实现智能数据分析流程。这是一个有向无环图（DAG）工作流，包含多个处理节点和条件边。

#### 工作流节点列表

| 节点名称 | 功能说明 |
| :--- | :--- |
| `INTENT_RECOGNITION_NODE` | 意图识别：判断用户查询类型（数据分析、简单查询等） |
| `EVIDENCE_RECALL_NODE` | 证据召回：通过 RAG 检索业务知识和智能体知识 |
| `QUERY_ENHANCE_NODE` | 查询增强：结合多轮对话历史重写和扩展查询 |
| `SCHEMA_RECALL_NODE` | Schema 召回：从向量数据库检索相关表结构 |
| `TABLE_RELATION_NODE` | 表关系识别：分析外键关系，确定多表关联 |
| `FEASIBILITY_ASSESSMENT_NODE` | 可行性评估：评估查询是否能被当前 Schema 支持 |
| `PLANNER_NODE` | 计划生成：将复杂任务分解为可执行的步骤 |
| `PLAN_EXECUTOR_NODE` | 计划执行：验证和调度执行计划 |
| `SQL_GENERATE_NODE` | SQL 生成：基于步骤描述生成 SQL 语句 |
| `SQL_EXECUTE_NODE` | SQL 执行：执行 SQL 并返回结果 |
| `PYTHON_GENERATE_NODE` | Python 代码生成：生成数据分析代码 |
| `PYTHON_EXECUTE_NODE` | Python 执行：运行 Python 代码 |
| `PYTHON_ANALYZE_NODE` | Python 分析：分析代码执行结果 |
| `REPORT_GENERATOR_NODE` | 报告生成：生成 HTML/Markdown 报告 |
| `SEMANTIC_CONSISTENCY_NODE` | 语义一致性校验：验证 SQL 与原始意图的一致性 |
| `HUMAN_FEEDBACK_NODE` | 人工反馈：用户干预和调整执行计划 |

#### 工作流边定义

```java
// 核心边定义 (来自 DataAgentConfiguration.java)
stateGraph.addEdge(START, INTENT_RECOGNITION_NODE)
    .addConditionalEdges(INTENT_RECOGNITION_NODE, edge_async(new IntentRecognitionDispatcher()), ...)
    .addEdge(EVIDENCE_RECALL_NODE, QUERY_ENHANCE_NODE)
    .addConditionalEdges(QUERY_ENHANCE_NODE, edge_async(new QueryEnhanceDispatcher()), ...)
    .addConditionalEdges(SCHEMA_RECALL_NODE, edge_async(new SchemaRecallDispatcher()), ...)
    .addConditionalEdges(TABLE_RELATION_NODE, edge_async(new TableRelationDispatcher()), ...)
    .addConditionalEdges(FEASIBILITY_ASSESSMENT_NODE, edge_async(new FeasibilityAssessmentDispatcher()), ...)
    .addEdge(PLANNER_NODE, PLAN_EXECUTOR_NODE)
    .addEdge(PYTHON_GENERATE_NODE, PYTHON_EXECUTE_NODE)
    .addConditionalEdges(PYTHON_EXECUTE_NODE, edge_async(new PythonExecutorDispatcher(...)), ...)
    .addEdge(PYTHON_ANALYZE_NODE, PLAN_EXECUTOR_NODE)
    .addConditionalEdges(PLAN_EXECUTOR_NODE, edge_async(new PlanExecutorDispatcher()), ...)
    .addConditionalEdges(SQL_GENERATE_NODE, nodeBeanUtil.getEdgeBeanAsync(SqlGenerateDispatcher.class), ...)
    .addConditionalEdges(SEMANTIC_CONSISTENCY_NODE, edge_async(new SemanticConsistenceDispatcher()), ...)
    .addConditionalEdges(SQL_EXECUTE_NODE, edge_async(new SQLExecutorDispatcher()), ...);
```

---

## 四、NL2SQL 实现详解

### 4.1 核心流程

NL2SQL 是 DataAgent 的核心能力，其实现分为以下几个阶段：

```
用户查询 → 意图识别 → 查询增强 → Schema召回 → 表关系识别
    → SQL生成 → 语义校验 → SQL执行 → 结果返回
```

### 4.2 关键代码实现

#### 4.2.1 SQL 生成服务

核心实现在 [Nl2SqlServiceImpl.java](data-agent-management/src/main/java/com/alibaba/cloud/ai/dataagent/service/nl2sql/Nl2SqlServiceImpl.java)：

```java
@Override
public Flux<String> generateSql(SqlGenerationDTO sqlGenerationDTO) {
    String sql = sqlGenerationDTO.getSql();

    Flux<String> newSqlFlux;
    if (sql != null && !sql.isEmpty()) {
        // SQL 执行失败时，使用错误修复 prompt
        String errorFixerPrompt = PromptHelper.buildSqlErrorFixerPrompt(sqlGenerationDTO);
        newSqlFlux = llmService.toStringFlux(llmService.callUser(errorFixerPrompt));
    } else {
        // 正常生成流程
        String prompt = PromptHelper.buildNewSqlGeneratorPrompt(sqlGenerationDTO);
        newSqlFlux = llmService.toStringFlux(llmService.callSystem(prompt));
    }
    return newSqlFlux;
}
```

#### 4.2.2 SQL 生成 Prompt 模板

Prompt 模板位于 [new-sql-generate.txt](data-agent-management/src/main/resources/prompts/new-sql-generate.txt)，核心要点：

1. **角色定义**：精通 {dialect} 的高级数据工程师
2. **输入上下文**：
   - 数据库 Schema（绝对事实）
   - 业务知识（参考）
   - 用户原始问题
   - 当前执行步骤
3. **约束条件**：
   - 方言兼容性（MySQL/PG/Oracle/SQL Server/Hive）
   - 结果集控制（不 SELECT *，只选需要的列）
   - 标识符转义（保留字处理）
   - 性能优化

#### 4.2.3 Schema 精细选择

```java
// 来自 Nl2SqlServiceImpl.java
public Flux<ChatResponse> fineSelect(SchemaDTO schemaDTO, String query, String evidence,
        String sqlGenerateSchemaMissingAdvice, DbConfigBO specificDbConfig, Consumer<SchemaDTO> dtoConsumer) {

    // 构建表选择 prompt，包含业务知识和证据
    String prompt = buildMixSelectorPrompt(evidence, query, schemaDTO);

    // 使用 LLM 选择相关表
    return llmService.callUser(prompt).doOnComplete(() -> {
        // 解析返回的表名列表，筛选 schema
        if (tableList != null && !tableList.isEmpty()) {
            schemaDTO.getTable().removeIf(table ->
                !selectedTables.contains(table.getName().toLowerCase()));
        }
        dtoConsumer.accept(schemaDTO);
    });
}
```

---

## 五、SQL 准确性优化方案

### 5.1 多层次优化策略

| 优化层 | 技术方案 | 说明 |
| :--- | :--- | :--- |
| **查询理解层** | 意图识别 + 查询增强 | 理解用户真实意图，处理多轮对话上下文 |
| **Schema 层** | 向量召回 + 表关系分析 | 精准召回相关表，分析外键关系 |
| **SQL 生成层** | 分步执行 + SQL 修复 | Planner 分解任务，失败时自动修复 |
| **语义校验层** | 语义一致性检查 | 验证生成的 SQL 是否与原始意图一致 |
| **执行反馈层** | SQL 重试机制 | 执行失败时自动重试和优化 |

### 5.2 关键优化点

#### 5.2.1 语义一致性校验

```java
// 来自 SemanticConsistencyNode.java
public Flux<ChatResponse> performSemanticConsistency(SemanticConsistencyDTO dto) {
    String prompt = PromptHelper.buildSemanticConsistenPrompt(dto);
    return llmService.callUser(prompt);
}
```

#### 5.2.2 SQL 错误自动修复

```java
// 来自 Nl2SqlServiceImpl.java
public Flux<String> generateSql(SqlGenerationDTO sqlGenerationDTO) {
    if (sql != null && !sql.isEmpty()) {
        // 当存在错误 SQL 时，使用专门的修复 prompt
        String errorFixerPrompt = PromptHelper.buildSqlErrorFixerPrompt(sqlGenerationDTO);
        newSqlFlux = llmService.toStringFlux(llmService.callUser(errorFixerPrompt));
    }
}
```

#### 5.2.3 重试机制配置

```java
// 来自 SqlGenerateNode.java
int count = state.value(SQL_GENERATE_COUNT, 0);
if (count >= properties.getMaxSqlRetryCount()) {
    // 达到最大重试次数，终止流程
    return Map.of(SQL_GENERATE_OUTPUT, generator);
}
```

#### 5.2.4 Planner 任务分解

```java
// 来自 PlannerNode.java - 将复杂查询分解为多个执行步骤
// 1. 分析用户意图
// 2. 识别需要的查询维度
// 3. 分解为多个子任务
// 4. 为每个子任务生成执行指令
```

---

## 六、技术栈与关键技术点

### 6.1 核心技术栈

| 类别 | 技术 | 说明 |
| :--- | :--- | :--- |
| **框架** | Spring Boot 3.4.8+ | 基础框架 |
| **AI 框架** | Spring AI Alibaba 1.1.0+ | AI 能力抽象层 |
| **状态图** | spring-ai-alibaba-graph | 工作流编排 |
| **LLM** | 通义千问/DeepSeek | 大语言模型 |
| **向量库** | Milvus/PgVector/Elasticsearch | 向量检索 |
| **数据库** | MySQL/PostgreSQL/Oracle/Hive/达梦 | 数据存储 |
| **前端** | Vue.js 3 + ECharts | 数据可视化 |
| **协议** | MCP (Model Context Protocol) | 模型上下文协议 |

### 6.2 关键技术点

#### 6.2.1 Spring AI Graph 工作流

```java
// 来自 DataAgentConfiguration.java
StateGraph stateGraph = new StateGraph(NL2SQL_GRAPH_NAME, keyStrategyFactory)
    .addNode(INTENT_RECOGNITION_NODE, nodeBeanUtil.getNodeBeanAsync(IntentRecognitionNode.class))
    .addNode(SQL_GENERATE_NODE, nodeBeanUtil.getNodeBeanAsync(SqlGenerateNode.class))
    // ... 更多节点
    .addConditionalEdges(INTENT_RECOGNITION_NODE, edge_async(new IntentRecognitionDispatcher()), ...);
```

#### 6.2.2 动态模型注册

```java
// 来自 DataAgentConfiguration.java - 动态代理实现
@Bean
@Primary
public EmbeddingModel embeddingModel(AiModelRegistry registry) {
    TargetSource targetSource = new TargetSource() {
        @Override
        public Object getTarget() {
            // 每次调用都从注册表获取最新的 EmbeddingModel
            return registry.getEmbeddingModel();
        }
    };
    ProxyFactory proxyFactory = new ProxyFactory();
    proxyFactory.setTargetSource(targetSource);
    return (EmbeddingModel) proxyFactory.getProxy();
}
```

#### 6.2.3 混合检索策略

```java
// 来自 HybridRetrievalStrategy
// 支持向量检索 + 关键词检索的混合策略
// RRF (Reciprocal Rank Fusion) 融合
public class RrfFusionStrategy implements FusionStrategy {
    // RRF 算法：1/(k1+rank) 加权融合
}
```

#### 6.2.4 Python 代码执行器

```java
// 来自 CodePoolExecutorService
// 支持 Docker 和本地执行两种模式
public interface CodePoolExecutorService {
    TaskResponse runTask(TaskRequest request);

    record TaskRequest(String code, String inputData, String config) {}
    record TaskResponse(boolean success, String stdOut, String stdErr, String exceptionMsg) {}
}

// 支持的执行模式
// 1. DockerCodePoolExecutorService - Docker 容器隔离执行
// 2. LocalCodePoolExecutorService - 本地进程执行
// 3. AiSimulationCodeExecutorService - AI 模拟执行（降级策略）
```

#### 6.2.5 多数据库支持

```java
// 数据库连接器实现
// 来自 connector/impls/ 目录
├── mysql/MySQLDBAccessor.java
├── postgre/PostgreDBAccessor.java
├── oracle/OracleDBAccessor.java
├── hive/HiveDBAccessor.java
├── sqlserver/SqlServerDBAccessor.java
└── dameng/DamengDBAccessor.java

// 连接池管理
// 来自 connector/pool/
├── AbstractDBConnectionPool.java
└── DBConnectionPoolFactory.java
```

#### 6.2.6 MCP 服务器集成

```java
// 来自 McpServerService.java
// 作为 MCP Tool Server 提供服务
@Tool(description = "将自然语言查询转换为SQL语句")
public String nl2SqlToolCallback(Nl2SqlRequest request) throws GraphRunnerException {
    return graphService.nl2sql(request.naturalQuery(), request.agentId());
}
```

#### 6.2.7 向量存储服务

```java
// 来自 AgentVectorStoreService.java
// 支持多种向量存储：Milvus、PgVector、Elasticsearch、Chroma 等
// 自动初始化和文档管理
public class AgentVectorStoreServiceImpl implements AgentVectorStoreService {
    // 文档添加、删除、检索
    // 支持混合检索策略
    // 支持动态过滤
}
```

#### 6.2.8 人工反馈机制 (Human-in-the-loop)

```java
// 来自 GraphServiceImpl.java
// 用户可以在 Planner 阶段干预执行计划
if (humanReviewEnabled) {
    // 暂停等待用户确认
    stateGraph.addConditionalEdges(PLAN_EXECUTOR_NODE, ..., HUMAN_FEEDBACK_NODE, ...);
}

// 处理用户反馈
private void handleHumanFeedback(GraphRequest graphRequest) {
    Map<String, Object> feedbackData = Map.of(
        "feedback", !graphRequest.isRejectedPlan(),
        "feedback_content", feedbackContent
    );
}
```

---

## 七、配置与扩展

### 7.1 主要配置类

| 配置类 | 功能 |
| :--- | :--- |
| `DataAgentConfiguration.java` | 核心配置：StateGraph、线程池、向量存储 |
| `McpServerConfig.java` | MCP 服务器配置 |
| `OpenApiConfig.java` | OpenAPI 配置 |
| `OpenTelemetryConfig.java` | 链路追踪配置 |

### 7.2 可扩展点

1. **自定义向量存储**：实现 `VectorStore` 接口
2. **自定义 LLM**：实现 `LlmService` 接口
3. **自定义代码执行器**：实现 `CodePoolExecutorService` 接口
4. **自定义数据库连接器**：实现 `DBAccessor` 接口

---

## 八、总结

DataAgent 是一个功能完善的企业级智能数据分析系统，其架构设计具有以下特点：

1. **模块化设计**：清晰的分层结构，便于维护和扩展
2. **工作流编排**：基于 StateGraph 的灵活流程控制
3. **多模型支持**：动态模型注册和切换
4. **RAG 增强**：混合检索提升语义理解能力
5. **安全可靠**：SQL 方言适配、错误修复、重试机制
6. **MCP 集成**：标准化协议支持生态扩展
7. **可视化报告**：ECharts 图表自动生成

该系统通过多层优化策略有效提升了 NL2SQL 的准确性和可靠性，是企业构建智能数据分析平台的优秀参考实现。
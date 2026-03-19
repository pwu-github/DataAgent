# Data-Agent-Management 模块代码阅读指南

## 一、项目概述

**项目定位**: 这是一个基于 Spring AI Alibaba 的数据智能 Agent 管理系统，核心功能是将自然语言转换为 SQL 查询（NL2SQL），并支持数据分析、报告生成等功能。

**技术栈**:
- Spring Boot + WebFlux (响应式编程)
- Spring AI Alibaba (LLM 集成)
- MyBatis (数据持久层)
- 多数据库支持 (MySQL/PostgreSQL/Oracle/SQL Server/H2/Hive/达梦)
- MCP Server (Model Context Protocol)
- OpenTelemetry (可观测性)
- Elasticsearch (向量存储)

---

## 二、项目结构图

```
data-agent-management/
├── src/main/java/com/alibaba/cloud/ai/dataagent/
│   ├── annotation/          # 自定义注解 (McpServerTool, InEnum 等)
│   ├── aop/                 # 切面 (异常处理、日志记录)
│   ├── bo/                  # Business Object 业务对象
│   ├── config/              # Spring 配置类 ⭐
│   ├── connector/           # 数据库连接器 (核心组件)
│   │   ├── accessor/        # 数据库访问器
│   │   ├── ddl/             # DDL 定义
│   │   ├── impls/           # 各数据库实现 (mysql/oracle/h2 等)
│   │   └── pool/            # 数据库连接池
│   ├── constant/            # 常量定义
│   ├── controller/          # REST API 控制器 ⭐
│   ├── converter/           # DTO 与 Entity 转换器
│   ├── dto/                 # 数据传输对象
│   ├── entity/              # 数据库实体 ⭐
│   ├── enums/               # 枚举类型
│   ├── event/               # 事件定义
│   ├── exception/           # 异常类
│   ├── mapper/              # MyBatis Mapper ⭐
│   ├── prompt/              # Prompt 模板构建
│   ├── properties/          # 配置属性类
│   ├── service/             # 业务逻辑层 ⭐⭐⭐
│   │   ├── agent/           # Agent 管理
│   │   ├── chat/            # 会话消息
│   │   ├── datasource/      # 数据源管理
│   │   ├── graph/           # Graph 工作流
│   │   ├── hybrid/          # 混合检索/融合
│   │   ├── knowledge/       # 知识库
│   │   ├── llm/             # LLM 调用服务
│   │   ├── nl2sql/          # NL2SQL 核心服务 ⭐⭐⭐
│   │   ├── prompt/          # Prompt 配置
│   │   ├── schema/          # Schema 管理
│   │   ├── semantic/        # 语义模型
│   │   └── vectorstore/     # 向量存储
│   ├── splitter/            # 文本分块器
│   ├── strategy/            # 策略模式实现
│   ├── util/                # 工具类
│   ├── vo/                  # View Object
│   └── workflow/            # 工作流定义 ⭐⭐⭐
│       ├── dispatcher/      # 节点分发器
│       └── node/            # 工作流节点 ⭐⭐⭐
├── src/main/resources/
│   ├── prompts/             # Prompt 模板文件 ⭐
│   ├── sql/                 # 数据库初始化脚本
│   └── application.yml      # 主配置文件 ⭐
└── pom.xml                  # Maven 依赖配置
```

---

## 三、程序入口

**启动类**: `DataAgentApplication.java`
- 位置：`src/main/java/.../dataagent/DataAgentApplication.java`
- 注解：`@SpringBootApplication` + `@EnableScheduling`
- 端口：8065 (配置在 application.yml)

**核心配置类**: `DataAgentConfiguration.java`
- 这是整个系统的"心脏"，定义了所有核心 Bean
- 最关键的是 `nl2sqlGraph()` 方法，它构建了完整的 AI 工作流图

---

## 四、核心工作流程 (NL2SQL Graph)

工作流图在 `DataAgentConfiguration.java:118-261` 定义，节点执行顺序如下:

```
START
  ↓
IntentRecognitionNode (意图识别)
  ↓
EvidenceRecallNode (证据召回)
  ↓
QueryEnhanceNode (查询增强)
  ↓
SchemaRecallNode (Schema 召回)
  ↓
TableRelationNode (表关系分析)
  ↓
FeasibilityAssessmentNode (可行性评估)
  ↓
PlannerNode (计划生成)
  ↓
PlanExecutorNode (计划执行)
  ├─→ SQL_GENERATE_NODE → SemanticConsistencyNode → SQL_EXECUTE_NODE ─┐
  ├─→ PYTHON_GENERATE_NODE → PYTHON_EXECUTE_NODE → PYTHON_ANALYZE_NODE ─┤
  └─→ REPORT_GENERATOR_NODE ────────────────────────────────────────────┘
  ↓
END
```

**16 个核心节点** (`workflow/node/` 目录):

| 节点 | 功能 |
|------|------|
| IntentRecognitionNode | 识别用户意图 |
| EvidenceRecallNode | 从向量库召回相关业务证据 |
| QueryEnhanceNode | 增强查询语句 |
| SchemaRecallNode | 召回相关的数据库表结构 |
| TableRelationNode | 分析表之间的关联关系 |
| FeasibilityAssessmentNode | 评估查询可行性 |
| PlannerNode | 生成执行计划 |
| PlanExecutorNode | 计划执行分发 |
| SqlGenerateNode | 生成 SQL |
| SemanticConsistencyNode | 语义一致性校验 |
| SqlExecuteNode | 执行 SQL |
| PythonGenerateNode | 生成 Python 代码 |
| PythonExecuteNode | 执行 Python 代码 |
| PythonAnalyzeNode | 分析 Python 执行结果 |
| ReportGeneratorNode | 生成报告 |
| HumanFeedbackNode | 人工审核 |

---

## 五、API 接口 (Controller 层)

**15 个 Controller**:

| Controller | 功能 |
|------------|------|
| `AgentController` | Agent 管理 |
| `AgentDatasourceController` | Agent 数据源绑定 |
| `AgentKnowledgeController` | Agent 知识库 |
| `AgentPresetQuestionController` | 预设问题 |
| `BusinessKnowledgeController` | 业务知识库 |
| `ChatController` ⭐ | 聊天会话接口 |
| `DatasourceController` | 数据源管理 |
| `FileUploadController` | 文件上传 |
| `GraphController` | 工作流图查询 |
| `ModelConfigController` | AI 模型配置 |
| `PromptConfigController` | Prompt 配置 |
| `SemanticModelController` | 语义模型 |
| `SessionEventController` | 会话事件 (SSE) |
| `EchoController` | 健康检查 |
| `GlobalExceptionHandler` | 全局异常处理 |

---

## 六、数据库实体 (12 个)

`entity/` 目录定义了所有业务表结构:

- `Agent` - Agent 主表
- `Datasource` - 数据源配置
- `AgentDatasource` - Agent 与数据源关联
- `ChatSession` / `ChatMessage` - 会话消息
- `AgentKnowledge` / `BusinessKnowledge` - 知识库
- `SemanticModel` - 语义模型
- `ModelConfig` - 模型配置
- `UserPromptConfig` - 用户 Prompt 配置
- `LogicalRelation` - 逻辑关系

---

## 七、Connector 模块 (多数据库支持)

`connector/` 目录实现了对多种数据库的统一访问:

```
connector/
├── Accessor (DB 访问接口)
├── Ddl (DDL 定义接口)
├── DBConnectionPool (连接池接口)
├── SqlExecutor (SQL 执行器)
└── impls/
    ├── mysql/
    ├── postgres/
    ├── oracle/
    ├── sqlserver/
    ├── h2/
    ├── hive/
    └── dameng/ (达梦数据库)
```

每个数据库实现包含:
- `XXXDBAccessor` - 数据库元数据访问
- `XXXJdbcDdl` - DDL 语句生成
- `XXXJdbcConnectionPool` - 连接池管理

---

## 八、Prompt 模板 (prompts/目录)

**17 个 Prompt 模板文件**:

| 文件 | 用途 |
|------|------|
| `intent-recognition.txt` | 意图识别 |
| `evidence-query-rewrite.txt` | 证据查询重写 |
| `query-enhancement.txt` | 查询增强 |
| `mix-selector.txt` | 表选择 |
| `feasibility-assessment.txt` | 可行性评估 |
| `planner.txt` | 计划生成 |
| `new-sql-generate.txt` | SQL 生成 |
| `semantic-consistency.txt` | 语义一致性 |
| `python-generator.txt` | Python 代码生成 |
| `python-analyze.txt` | Python 结果分析 |
| `report-generator-plain.txt` | 报告生成 |
| `sql-error-fixer.txt` | SQL 错误修复 |

---

## 九、推荐阅读顺序

**第一阶段：了解整体架构**
1. `DataAgentApplication.java` - 启动入口
2. `application.yml` - 配置文件
3. `DataAgentConfiguration.java` - 核心配置 (重点看 `nl2sqlGraph` 方法)

**第二阶段：理解工作流**
4. `workflow/node/` 目录下的 16 个节点类
5. `workflow/dispatcher/` 目录下的分发器

**第三阶段：API 层**
6. `ChatController.java` - 核心聊天接口
7. `SessionEventController.java` - SSE 流式输出

**第四阶段：业务逻辑**
8. `service/nl2sql/Nl2SqlServiceImpl.java` - NL2SQL 核心服务
9. `service/chat/` - 会话服务
10. `service/agent/` - Agent 管理服务

**第五阶段：基础设施**
11. `connector/` - 数据库连接器
12. `mapper/` - MyBatis 数据访问层

---

## 十、关键代码统计

- **总代码行数**: 约 31,617 行 (仅 main 源码)
- **Controller**: 15 个
- **Service**: 约 40+ 个
- **Mapper**: 13 个
- **Entity**: 12 个
- **Workflow Nodes**: 16 个
- **Prompt 模板**: 17 个

---

## 十一、快速调试指南

1. **启动前准备**:
   - 配置 `application.yml` 中的数据库连接
   - 配置 LLM API Key
   - 确保 MySQL 运行 (默认端口 3306)

2. **启动命令**:
   ```bash
   cd DataAgent/data-agent-management
   mvn spring-boot:run
   ```

3. **访问 Swagger UI**:
   - `http://localhost:8065/swagger-ui.html`

4. **核心测试接口**:
   - `POST /api/sessions/{sessionId}/messages` - 发送消息
   - `GET /api/sessions/{sessionId}/messages` - 获取消息历史

---

这份总结应该能帮助你快速理解整个项目的结构和运行逻辑。建议从 `DataAgentConfiguration.java` 的 `nl2sqlGraph` 方法开始深入阅读，这是整个系统的核心。
# Python 代码生成与执行流程详解

## 一、整体流程图

```
PlanExecutorNode (计划执行)
       ↓
PythonGenerateNode (生成 Python 代码) ⭐
       ↓
PythonExecuteNode (执行 Python 代码) ⭐
       ↓
PythonExecutorDispatcher (执行结果分发)
       ├─ 成功 → PythonAnalyzeNode (分析结果)
       ├─ 失败且未超重试次数 → PythonGenerateNode (重新生成)
       └─ 失败且超过重试次数 → END (终止) 或降级模式
       ↓
PythonAnalyzeNode (LLM 分析输出)
       ↓
PlanExecutorNode (继续下一步计划)
```

---

## 二、三个核心节点详解

### 1. PythonGenerateNode - 代码生成节点

**文件位置**: `workflow/node/PythonGenerateNode.java`

**核心逻辑**:

```java
// 1. 获取上下文信息
SchemaDTO schemaDTO = StateUtil.getObjectValue(state, TABLE_RELATION_OUTPUT, SchemaDTO.class);
List<Map<String, String>> sqlResults = StateUtil.getListValue(state, SQL_RESULT_LIST_MEMORY);
String userPrompt = StateUtil.getCanonicalQuery(state);

// 2. 如果上次代码运行失败，告知 AI 模型重新生成
if (!codeRunSuccess) {
    String lastCode = StateUtil.getStringValue(state, PYTHON_GENERATE_NODE_OUTPUT);
    String lastError = StateUtil.getStringValue(state, PYTHON_EXECUTE_NODE_OUTPUT);
    userPrompt += "上次尝试生成的 Python 代码运行失败...";
}

// 3. 构建 Prompt (包含内存限制、超时时间、数据库 schema、SQL 结果样例、计划描述)
String systemPrompt = PromptConstant.getPythonGeneratorPromptTemplate()
    .render(Map.of(
        "python_memory", codeExecutorProperties.getLimitMemory().toString(),
        "python_timeout", codeExecutorProperties.getCodeTimeout(),
        "database_schema", objectMapper.writeValueAsString(schemaDTO),
        "sample_input", objectMapper.writeValueAsString(sqlResults...),
        "plan_description", objectMapper.writeValueAsString(toolParameters)
    ));

// 4. 调用 LLM 生成代码
Flux<ChatResponse> pythonGenerateFlux = llmService.call(systemPrompt, userPrompt);

// 5. 处理输出：移除 Markdown 标记
aiResponse = aiResponse.substring(TextType.PYTHON.getStartSign().length(), ...);
aiResponse = MarkdownParserUtil.extractRawText(aiResponse);
```

**输入数据**:
- `TABLE_RELATION_OUTPUT`: 数据库表结构 Schema
- `SQL_RESULT_LIST_MEMORY`: SQL 查询结果 (前 5 条样例)
- `PYTHON_GENERATE_NODE_OUTPUT`: 上次生成的代码 (失败时)
- `PYTHON_EXECUTE_NODE_OUTPUT`: 上次的错误信息 (失败时)

**输出**: 纯净的 Python 代码字符串 (无 Markdown 标记)

---

### 2. PythonExecuteNode - 代码执行节点

**文件位置**: `workflow/node/PythonExecuteNode.java`

**核心逻辑**:

```java
// 1. 获取生成的 Python 代码和 SQL 查询结果
String pythonCode = StateUtil.getStringValue(state, PYTHON_GENERATE_NODE_OUTPUT);
List<Map<String, String>> sqlResults = StateUtil.getListValue(state, SQL_RESULT_LIST_MEMORY);

// 2. 构建任务请求
CodePoolExecutorService.TaskRequest taskRequest = new CodePoolExecutorService.TaskRequest(
    pythonCode,                              // 代码
    objectMapper.writeValueAsString(sqlResults), // 输入数据 (JSON 格式)
    null                                     // 依赖要求
);

// 3. 执行 Python 代码
CodePoolExecutorService.TaskResponse taskResponse = this.codePoolExecutor.runTask(taskRequest);

// 4. 处理执行结果
if (!taskResponse.isSuccess()) {
    // 检查重试次数
    if (triesCount >= codeExecutorProperties.getPythonMaxTriesCount()) {
        // 超过最大重试次数 → 启动降级模式
        return Map.of(PYTHON_EXECUTE_NODE_OUTPUT, fallbackOutput,
                      PYTHON_IS_SUCCESS, false,
                      PYTHON_FALLBACK_MODE, true);
    }
    throw new RuntimeException(errorMsg); // 返回错误，触发重新生成
}

// 5. 处理成功输出 (解析 Unicode 转义)
String stdout = taskResponse.stdOut();
Object value = jsonParseUtil.tryConvertToObject(stdout, Object.class);
if (value != null) {
    stdout = objectMapper.writeValueAsString(value); // 汉字解码
}
```

**TaskResponse 结构**:
```java
record TaskResponse(
    boolean isSuccess,           // 是否成功
    boolean executionSuccessButResultFailed, // 执行成功但代码返回错误
    String stdOut,               // 标准输出
    String stdErr,               // 标准错误
    String exceptionMsg          // 异常消息
)
```

---

### 3. PythonAnalyzeNode - 结果分析节点

**文件位置**: `workflow/node/PythonAnalyzeNode.java`

**核心逻辑**:

```java
// 1. 获取上下文
String userQuery = StateUtil.getCanonicalQuery(state);
String pythonOutput = StateUtil.getStringValue(state, PYTHON_EXECUTE_NODE_OUTPUT);
int currentStep = PlanProcessUtil.getCurrentStepNumber(state);

// 2. 检查降级模式
if (isFallbackMode) {
    String fallbackMessage = "Python 高级分析功能暂时不可用...";
    return Map.of(PYTHON_ANALYSIS_NODE_OUTPUT, generator);
}

// 3. 构建分析 Prompt
String systemPrompt = PromptConstant.getPythonAnalyzePromptTemplate()
    .render(Map.of(
        "python_output", pythonOutput,
        "user_query", userQuery
    ));

// 4. 调用 LLM 分析
Flux<ChatResponse> pythonAnalyzeFlux = llmService.callSystem(systemPrompt);

// 5. 将分析结果写入 state
updatedSqlResult.put("step_" + currentStep + "_analysis", aiResponse);
```

**输出**: 将 Python 执行结果转化为自然语言总结

---

## 三、代码执行器实现

### CodePoolExecutorService 接口

```java
public interface CodePoolExecutorService {
    TaskResponse runTask(TaskRequest request);

    record TaskRequest(String code, String input, String requirement) {}
    record TaskResponse(boolean isSuccess, ...) {}
}
```

### 三种实现方式

| 实现类 | 说明 | 适用场景 |
|--------|------|----------|
| `DockerCodePoolExecutorService` | 使用 Docker 容器运行 | 生产环境推荐 |
| `LocalCodePoolExecutorService` | 使用本地 Python3 环境 | 开发/测试环境 |
| `AiSimulationCodeExecutorService` | AI 模拟执行 | 无 Python 环境兜底 |

---

### DockerCodePoolExecutorService 执行流程

```java
// 1. 创建容器 (带资源限制)
HostConfig hostConfig = newHostConfig()
    .withMemory(500MB)           // 内存限制
    .withCpuCount(1)             // CPU 核心数
    .withCapDrop(Capability.ALL) // 移除所有权限
    .withNetworkMode("none")     // 网络隔离
    .withBinds(...)              // 挂载临时文件

// 2. 准备文件 (script.py, requirements.txt, input_data.txt)
Files.write(tempDir.resolve("script.py"), code.getBytes());
Files.write(tempDir.resolve("input_data.txt"), input.getBytes());

// 3. 执行命令
String cmd = "if [ -s requirements.txt ]; then " +
             "pip3 install --no-cache-dir -r requirements.txt > /dev/null; " +
             "fi && " +
             "timeout -s SIGKILL 60s python3 -u script.py < input_data.txt";

// 4. 等待执行完成
dockerClient.waitContainerCmd(containerId)
    .start()
    .awaitCompletion(300, TimeUnit.SECONDS);

// 5. 获取输出
dockerClient.logContainerCmd(containerId)
    .withStdOut(true)
    .withStdErr(true)
    .exec(...)
```

---

### LocalCodePoolExecutorService 执行流程

```java
// 1. 创建临时目录
Path container = Files.createTempDirectory("nl2sql-python-exec-");

// 2. 写入文件
Files.write(scriptFile, code.getBytes());
Files.write(stdinFile, input.getBytes());

// 3. 安装依赖 (如果有 requirements.txt)
ProcessBuilder pip = new ProcessBuilder("pip3", "install", ...);
process.waitFor(timeout, MINUTES);

// 4. 执行 Python
ProcessBuilder pb = new ProcessBuilder("python3", scriptFile.toString());
pb.redirectInput(stdinFile.toFile());
process = pb.start();

// 5. 读取输出并等待完成
process.waitFor(timeout, MILLISECONDS);
```

---

## 四、容器池管理机制

### AbstractCodePoolExecutorService 核心组件

```java
// 核心容器池 (固定数量，复用)
ConcurrentHashMap<String, State> coreContainerState;
ArrayBlockingQueue<String> readyCoreContainer;  // 可用核心容器队列

// 临时容器池 (动态创建，自动销毁)
ConcurrentHashMap<String, State> tempContainerState;
ArrayBlockingQueue<String> readyTempContainer;  // 可用临时容器队列

// 任务队列 (容器不足时缓存任务)
ArrayBlockingQueue<FutureTask<TaskResponse>> taskQueue;

// 线程池 (执行等待中的任务)
ExecutorService consumerThreadPool;
```

### 容器调度策略

```java
TaskResponse runTask(TaskRequest request) {
    // 1. 优先使用空闲核心容器
    String freeCoreId = readyCoreContainer.poll();
    if (freeCoreId != null) return useCoreContainer(freeCoreId, request);

    // 2. 其次使用空闲临时容器
    String freeTempId = readyTempContainer.poll();
    if (freeTempId != null) return useTempContainer(freeTempId, request);

    // 3. 创建新核心容器 (未达上限)
    if (currentCoreContainerSize < coreContainerNum) {
        return createAndUseCoreContainer(request);
    }

    // 4. 创建新临时容器 (未达上限)
    if (currentTempContainerSize < tempContainerNum) {
        return createAndUseTempContainer(request);
    }

    // 5. 放入任务队列等待
    return pushTaskQueue(request);
}
```

### 临时容器自动销毁

```java
// 临时容器使用后会启动销毁倒计时
private Future<?> registerRemoveTempContainer(String containerId) {
    return consumerThreadPool.submit(() -> {
        Thread.sleep(5 * 60 * 1000); // 5 分钟不活动后销毁
        removeContainerAndState(containerId, false, false);
    });
}
```

---

## 五、Prompt 模板

### python-generator.txt 关键要求

```
1. 输入：从 sys.stdin 读取 JSON 数据 (json.load(sys.stdin))
2. 输出：通过 print(json.dumps(result, ensure_ascii=False)) 输出 JSON 对象
3. 错误处理：try-except + traceback.print_exc(file=sys.stderr) + sys.exit(1)
4. 依赖限制：只能使用 anaconda3 默认安装的库 (pandas, numpy 等)
5. 安全限制：禁止文件/网络操作、系统调用、绘图、pickle 等危险库
6. 性能约束：内存 500MB，超时 60s
```

### python-analyze.txt 关键要求

```
1. 只输出自然语言总结，不要包含代码、JSON、Markdown
2. 总结内容直接回应用户查询需求
3. 如果分析结果为空或出错，明确指出
4. 严格基于 Python 输出结果，不猜测或虚构
```

---

## 六、重试与降级机制

### PythonExecutorDispatcher 路由逻辑

```java
String apply(OverAllState state) {
    // 1. 降级模式 → 跳过重试直接分析
    if (isFallbackMode) return PYTHON_ANALYZE_NODE;

    // 2. 执行失败
    if (!isSuccess) {
        if (triesCount >= pythonMaxTriesCount) {
            return END; // 超过重试次数，终止
        } else {
            return PYTHON_GENERATE_NODE; // 重新生成代码
        }
    }

    // 3. 执行成功 → 分析结果
    return PYTHON_ANALYZE_NODE;
}
```

### 默认配置

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `pythonMaxTriesCount` | 5 | Python 执行最大重试次数 |
| `limitMemory` | 500 MB | 容器内存限制 |
| `codeTimeout` | 60s | Python 代码执行超时 |
| `containerTimeout` | 3000s | 容器最大运行时间 |
| `coreContainerNum` | 2 | 核心容器数量 |
| `tempContainerNum` | 2 | 临时容器数量 |

---

## 七、完整数据流

```
用户查询
   ↓
PlanExecutorNode (解析出需要 Python 分析)
   ↓
[State 数据]
├── TABLE_RELATION_OUTPUT (Schema)
├── SQL_RESULT_LIST_MEMORY (SQL 结果)
└── PLAN_DESCRIPTION (执行计划)
   ↓
PythonGenerateNode
   ↓
[LLM 生成 Python 代码]
import sys, json, pandas as pd
try:
    input_data = json.load(sys.stdin)
    df = pd.DataFrame(input_data)
    # 数据分析...
    print(json.dumps(result, ensure_ascii=False))
except Exception:
    traceback.print_exc(file=sys.stderr)
    sys.exit(1)
   ↓
PythonExecuteNode
   ↓
[CodePoolExecutorService.runTask()]
1. 创建/获取容器
2. 写入代码和输入数据
3. 执行 python3 script.py < input_data.txt
4. 捕获 stdout/stderr
5. 返回 TaskResponse
   ↓
[TaskResponse]
├── isSuccess: true
├── stdOut: "{\"summary\": {...}}"
├── stdErr: null
└── exceptionMsg: null
   ↓
PythonExecutorDispatcher (路由)
   ↓
PythonAnalyzeNode
   ↓
[LLM 分析 Python 输出]
"根据分析结果，线上广告渠道带来了 500 条线索，转化率为 15%..."
   ↓
[写入 State]
SQL_EXECUTE_NODE_OUTPUT.step_X_analysis = "分析总结文本"
   ↓
PlanExecutorNode (继续下一步或返回结果)
```

---

## 八、安全特性

### Docker 容器隔离

```java
HostConfig config = newHostConfig()
    .withMemory(500 * 1024 * 1024L)      // 内存限制
    .withCpuCount(1L)                     // CPU 限制
    .withCapDrop(Capability.ALL)          // 降权
    .withAutoRemove(false)                // 手动清理
    .withTmpFs(Map.of("/tmp", ""))        // 临时文件系统
    .withNetworkMode("none");             // 网络隔离
```

### 执行超时控制

- **Docker**: `timeout -s SIGKILL 60s python3 -u script.py`
- **Local**: `process.waitFor(60000, MILLISECONDS)`

### 容器损坏处理

```java
if (!resp.isSuccess() && !resp.executionSuccessButResultFailed()) {
    // 容器异常 → 标记为 REMOVING → 强制删除 → 任务重新入队
    coreContainerState.replace(containerId, State.REMOVING);
    removeContainerAndState(containerId, true, true);
    return pushTaskQueue(request);
}
```

---

## 九、相关源文件清单

| 文件 | 路径 | 说明 |
|------|------|------|
| `PythonGenerateNode.java` | `workflow/node/` | Python 代码生成节点 |
| `PythonExecuteNode.java` | `workflow/node/` | Python 代码执行节点 |
| `PythonAnalyzeNode.java` | `workflow/node/` | Python 结果分析节点 |
| `PythonExecutorDispatcher.java` | `workflow/dispatcher/` | 执行结果路由分发器 |
| `CodePoolExecutorService.java` | `service/code/` | 代码执行器接口 |
| `AbstractCodePoolExecutorService.java` | `service/code/impls/` | 抽象基类 |
| `DockerCodePoolExecutorService.java` | `service/code/impls/` | Docker 实现 |
| `LocalCodePoolExecutorService.java` | `service/code/impls/` | 本地实现 |
| `CodeExecutorProperties.java` | `properties/` | 执行器配置属性 |
| `python-generator.txt` | `resources/prompts/` | 代码生成 Prompt 模板 |
| `python-analyze.txt` | `resources/prompts/` | 结果分析 Prompt 模板 |

---

*文档生成时间：2026-03-16*
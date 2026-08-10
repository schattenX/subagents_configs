# Codex 多模型 Subagent 软件开发工作流

> 一套以 **高质量设计 + 低成本执行 + 独立验证 + 风险驱动评审** 为核心的 Agentic Software Development Workflow。

这套工作流的目标不是让最强模型完成所有工作，而是根据任务的**决策价值、执行频率和推理难度**分配模型：

- **Sol** 负责少量但影响范围大的设计与高风险判断；
- **Luna** 负责绝大多数调度、探索和代码实现；
- **GPT-5.4-mini** 负责高频、低推理需求的验证执行；
- 测试、Build、Lint、Type Check 等确定性工具负责提供最终证据；
- 主 Agent 负责任务编排和验收，但不能静默推翻已经接受的架构与计划。

---

# 1. 工作流概览

整个开发过程分成两个 Session：

1. **Design Session**：使用 Sol-high 完成 Spec、UX、Architecture 和 Implementation Plan；
2. **Execution Session**：重新开启 Luna-max Session，由 Main Agent 根据 Plan 自动调度不同 Subagent 完成开发。

核心工作流如下：

```text
                         ┌─────────────────────┐
                         │      Sol-high       │
                         │                     │
                         │ Spec / UX           │
                         │ Architecture        │
                         │ Implementation Plan │
                         └──────────┬──────────┘
                                    │
                              User Accept
                                    │
                                    ▼
                         ┌─────────────────────┐
                         │      Luna-max       │
                         │     Main Agent      │
                         │                     │
                         │ Dispatch            │
                         │ Integration         │
                         │ Acceptance          │
                         └──────────┬──────────┘
                                    │
                 ┌──────────────────┼──────────────────┐
                 │                  │                  │
                 ▼                  ▼                  ▼
          code-explorer        implementer      quick-implementer
            Luna-low          Luna-medium           Luna-low
                 │                  │                  │
                 └──────────────────┼──────────────────┘
                                    │
                                    ▼
                             code-validator
                           GPT-5.4-mini-low
                                    │
                               PASS / FAIL
                                    │
                                    ▼
                                 Luna-max
                               Task Acceptance
                                    │
                         Qualifying high-risk?
                              ┌─────┴─────┐
                              │           │
                             No          Yes
                              │           │
                              │      code-reviewer
                              │        Sol-low
                              │           │
                              │     Confident verdict?
                              │       ┌───┴───┐
                              │       │       │
                              │      Yes      No
                              │       │       │
                              │       │   code-reviewer-deep
                              │       │       Sol-high
                              │       │
                              └───────┴──────────► Continue
```

这套设计遵循一个简单原则：

> **让强模型决定“做什么以及设计是否正确”，让低成本模型负责“把它做出来”，让确定性工具证明“它是否真的做对”。**

---

# 2. 两阶段开发流程

## 2.1 Design Session：Sol-high

一个新的 Version、Feature 或较大的 Workstream 首先进入独立设计 Session。

推荐配置：

```text
Model: Sol-high
Skills: BMAD Method + Superpowers
```

这一阶段主要产出：

```text
Requirement
    ↓
Spec
    ↓
UX
    ↓
Architecture
    ↓
Implementation Plan
    ↓
User Acceptance
```

Sol-high 的价值集中在**高杠杆决策**：

- 明确需求与边界；
- 设计用户体验；
- 定义模块职责和接口；
- 决定数据流、状态模型、并发策略等架构问题；
- 将整体设计拆解成可执行、可验证的 Implementation Plan。

设计错误通常会被后续几十个实现任务放大，因此这里不应为了节省少量模型成本而降低设计质量。

完成并接受设计文档后，结束当前 Session。

---

## 2.2 Execution Session：Luna-max

重新开启一个 Session：

```text
Model: Luna-max
Mode: Goal Mode
```

Main Agent 首先读取已经 Accepted 的：

- Spec；
- UX；
- Architecture；
- Implementation Plan；
- 相关项目文档。

随后按照 Plan 自动推进开发。

从这里开始，用户原则上不需要手动指定：

> “这个任务用 Luna-low，那个任务用 Luna-medium。”

Main Agent 根据 `SUBAGENT_ROUTING.md` 自动判断：

```text
任务是什么？
    ↓
需要哪种能力？
    ↓
选择最便宜且能够可靠完成任务的 Subagent
```

用户主要在以下场景重新介入：

- Architecture Deviation；
- Plan 或需求本身需要调整；
- 重大风险决策；
- Plan / Version 最终 Acceptance。

---

# 3. 模型与 Subagent Routing

## 3.1 模型角色

| 角色 | 模型 | 主要职责 |
|---|---|---|
| Architect / Planner | Sol-high | Spec、UX、Architecture、Plan |
| Main Agent | Luna-max | 调度、集成、验收、异常处理 |
| `code-explorer` | Luna-low | Repo 搜索、Contract / Data Flow 定位 |
| `quick-implementer` | Luna-low | 一两文件的小型机械修改 |
| `implementer` | Luna-medium | 常规开发、Debug、Unit Tests |
| `code-validator` | GPT-5.4-mini-low | Test / Build / Lint / Type Check |
| `code-reviewer` | Sol-low | 高风险修改的独立 Review |
| `code-reviewer-deep` | Sol-high | 存在重大未解决风险时的深度 Review |
| `commit-pusher` | Luna-low | Commit 与 Push |

当前 `implementer` 使用 Luna-medium，并负责实际代码和单元测试，但不能自己宣称 behavioral tests 已经通过；验证结果必须来自独立 Validator。

---

## 3.2 Subagent Routing 结构

```text
                         Luna-max
                         Main Agent
                             │
            ┌────────────────┼────────────────┐
            │                │                │
            ▼                ▼                ▼
      code-explorer      implementer    quick-implementer
        Luna-low        Luna-medium         Luna-low
            │                │                │
            └────────────────┼────────────────┘
                             │
                             ▼
                       code-validator
                     GPT-5.4-mini-low
                             │
                         PASS / FAIL
                             │
                ┌────────────┴────────────┐
                │                         │
              PASS                       FAIL
                │                         │
          Luna-max Accept          原 Implementer Repair
                │                         │
                │                    Re-validation
                ▼
       qualifying high-risk?
           ┌────┴────┐
          No         Yes
          │           │
       Continue   code-reviewer
                    Sol-low
                       │
             unresolved material risk?
                 ┌─────┴─────┐
                No           Yes
                │             │
             verdict    code-reviewer-deep
                           Sol-high
```

Routing 的几个核心原则：

**第一，优先使用最便宜但足够可靠的模型。**

Repository exploration、普通实现和机械修改默认委派给廉价 Subagent，而不是让 Luna-max 自己做所有工作。现有 Routing 也明确要求 Parent 不承担大量 discovery 和 implementation。

**第二，搜索与推理分离。**

`code-explorer` 的工作是：

> Search wide → Read narrow → 输出 decision-ready report。

它负责提供证据，而不是负责架构判断。

**第三，Implementer 与 Validator 分离。**

```text
Implementer
→ 写代码 + Unit Tests

Validator
→ 独立执行 Test / Build / Lint / Type Check
```

Validator 为只读 Agent，不能为了让测试通过而修改代码。

**第四，避免为了并行而并行。**

并行 Implementation 必须拥有明确且不重叠的文件或模块 Ownership；Write-heavy 工作默认避免无意义并行。

---

# 4. Execution Safety Gates

自动执行并不意味着 Main Agent 拥有无限决策权。

为了避免“Agent 看起来一直在工作，但逐渐偏离原设计”，工作流设置了三个关键安全机制。

## 4.1 Architecture Deviation Gate

Luna-max 可以自行决定：

- private helper 如何组织；
- 函数和类如何拆分；
- 局部命名；
- Test Fixture；
- 不影响公开 Contract 的内部实现。

但不能静默改变已经 Accepted 的：

- Architecture Boundary；
- Module Ownership；
- Public API / Published Port；
- Persistent Schema；
- Critical Data Flow；
- Concurrency / Transaction Model；
- Security / Trust Boundary；
- Architecture / Plan 中明确的关键假设。



触发 Architecture Deviation 后：

```text
Implementation
      ↓
发现 Accepted Architecture 无法按原方案实施
      ↓
STOP affected workstream
      ↓
整理：
- 原 Architecture / Constraint
- Evidence
- Proposed Deviation
- Affected Modules / Contracts
- Alternatives
      ↓
Architecture / Planning Authority
      ↓
Deviation Accepted
      ↓
更新 Architecture / Plan
      ↓
Resume
```

核心原则：

> **不得先改变架构，把代码写完，再要求补批准。**

如果 `code-reviewer-deep` 发现 `ARCHITECTURE_DEVIATION`，同样进入该 Gate；Reviewer 负责发现问题，不负责批准新的 Architecture。

---

## 4.2 Task → Plan → Version 三层验收

验证分三个层级：

```text
Task
  ↓
Targeted Validation
  ↓
Task Accepted


多个 Tasks
  ↓
Plan-defined Completion Gate
  ↓
Plan Accepted


多个 Plans / Workstreams
  ↓
Version / Release Acceptance
  ↓
Version Ready
```

因此：

> **Task PASS ≠ Plan Complete ≠ Version Ready**

Task 阶段优先执行受影响测试，避免每完成一个小任务都重复跑 Full Suite。

Plan 阶段则必须执行 Implementation Plan 自己定义的：

- Completion Gate；
- Acceptance Gate；
- Final Verification Commands；
- Behavioral Acceptance Criteria。



例如一个完整 Plan 可以在最后统一运行：

```text
Backend Unit / Integration / Contract / API
Frontend Tests
Production Build
Playwright E2E
```

而不是让 Routing 自己猜测应该跑哪些测试。实际 Comparison Plan 就采用了这种模式。

因此遵循：

> **Routing 定义 Validation Policy；Plan 定义 Validation Scope。**

如果 Plan 已经定义充分的最终验证，不再无条件重复执行整个 Full Suite / Integration / E2E。

---

## 4.3 Risk-driven Code Review

普通代码修改不需要 Sol Review。

只有以下类型的修改才进入 `code-reviewer`：

- high-risk；
- security-sensitive；
- architectural；
- public API；
- migration；
- concurrency；
- difficult-to-validate。



第一层：

```text
code-reviewer
→ Sol-low
```

如果它能够高置信给出：

```text
APPROVE
REQUEST_CHANGES
COMMENT
```

则停止。

只有仍然存在**重大且无法高置信解决的不确定性**时：

```text
Sol-low Review
      ↓
Material unresolved risk
      ↓
code-reviewer-deep
      ↓
Sol-high
```

Deep Review 不是固定第二遍 Review，也不会因为“这是 concurrency / security / migration”就自动触发。

---

# 5. 成本与效果设计

这套工作流不是简单追求“用最便宜的模型”，而是追求：

> **单位开发成本获得尽可能高的可靠性。**

模型调用大致形成以下金字塔：

```text
                 高智能
                 低频率
                    ▲
                    │
                Sol-high
           Architecture / Deep Risk

                 Sol-low
                High-risk Review

                 Luna-max
              Main Orchestration

               Luna-medium
            Main Implementation

        Luna-low / GPT-5.4-mini
      Search / Quick Work / Validate
                    │
                    ▼
                 高频率
                 低成本
```

核心原则有三条。

### 1. 贵模型负责高杠杆决策

Architecture 错误可能导致几十个 Implementation Task 全部返工，因此值得使用 Sol-high。

相反，一个明确 Plan 下的普通 CRUD、测试补充或局部修改，没有必要消耗 Sol。

### 2. 高频 Token 消耗放在 Luna / Mini

一个版本的大部分 Agent 工作实际上来自：

```text
Repository Search
Implementation
Debug
Test Execution
Result Summarization
```

因此这些任务决定了长期成本，应尽量运行在低成本模型上。

### 3. 控制 Sol 成本的关键是减少无意义调用

不是所有代码都 Review；

不是所有 High-risk 代码都 Deep Review；

不是每一个 Task 都让 Sol 重新理解整个项目。

Sol 应该出现在：

```text
Architecture / Planning
+
真正需要独立高级判断的 Review
+
重大 unresolved risk
```

而不是成为默认劳动力。

---

# 6. 使用方式与配置

## 6.1 开发一个 Version

实际操作可以浓缩为：

```text
1. 开启 Sol-high Design Session
      ↓
2. BMAD + Superpowers
      ↓
3. Spec / UX / Architecture / Plan
      ↓
4. User Acceptance
      ↓
5. 新开 Luna-max Execution Session
      ↓
6. Goal Mode 读取 Accepted Documents
      ↓
7. Main Agent 自动 Subagent Routing
      ↓
8. Task Validation
      ↓
9. Plan Completion Gate
      ↓
10. Version / Release Acceptance
      ↓
11. Commit / Push
```

用户不需要在 Execution Session 中持续微操模型路由。

真正需要关注的是：

- Plan 是否仍然正确；
- 是否发生 Architecture Deviation；
- Validation 是否提供了充分证据；
- Review 是否发现重大风险；
- Completion Gate 是否真正通过。

---

## 6.2 配置结构

典型配置结构：

```text
rules/
└── SUBAGENT_ROUTING.md

agents/
├── code-explorer.toml
├── quick-implementer.toml
├── implementer.toml
├── code-validator.toml
├── code-reviewer.toml
├── code-reviewer-deep.toml
└── commit-pusher.toml

install.sh
```

推荐配置修改流程：

```text
Fork / Clone 配置仓库
      ↓
修改配置
      ↓
Review
      ↓
Accepted
      ↓
继续修改下一项
      ↓
所有修改全部 Accepted
      ↓
统一运行 install.sh
      ↓
安装到 Codex
```

不要一边讨论规则，一边直接修改线上 Codex 配置。

---

## Quick Reference

| 遇到的问题 | Agent |
|---|---|
| 不知道代码在哪里 | `code-explorer` |
| 一两文件的小型明确修改 | `quick-implementer` |
| 正常 Feature / Bug Fix / Debug | `implementer` |
| 跑测试、Build、Lint、Type Check | `code-validator` |
| 高风险独立 Review | `code-reviewer` |
| 普通 Reviewer 无法解决的深层风险 | `code-reviewer-deep` |
| Commit + Push | `commit-pusher` |
| 需要改变 Accepted Architecture | **Architecture Deviation Gate** |

最终可以把整套方法记成一句话：

> **Sol 负责设计与关键判断，Luna 负责管理和生产，Mini/工具负责验证；Main Agent 可以自主执行，但不能绕过 Architecture、Validation 和 Acceptance Gates。**
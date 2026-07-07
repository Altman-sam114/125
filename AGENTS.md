# AGENTS.md
本文是 WWIIHexV0 项目的入口记忆、总览、基本规则和多 Agent 工作流。任何 Agent 接手任务时，先读本文，再读任务所需文档和源码；不要凭旧 prompt、旧记忆或猜测修改项目。
## 0. 角色召唤与身份标识
- 用户消息以 `agenta`、`a:` 或 `A:` 开头，表示召唤 Agent A；Agent A 最终回复第一行必须写：`我是 Agent A。`
- 用户消息以 `agentb`、`b:` 或 `B:` 开头，表示召唤 Agent B；Agent B 最终回复第一行必须写：`我是 Agent B。`
- 用户消息以 `agentc`、`c:` 或 `C:` 开头，表示召唤 Agent C；Agent C 最终回复第一行必须写：`我是 Agent C。`
- 没有这些前缀时，按普通 Codex 任务处理；若任务需要 A/B/C 边界，应提醒用户指定角色，或说明本轮按普通任务执行。
## 1. 必读文件
每轮任务按需阅读，但不得跳过与任务相关的入口文档：
1. `AGENTS.md`：当前工作流、基本规则、项目总览。
2. `update_log.md`：版本历史、已完成事项、遗留问题；用于把上一轮结果传给下一轮 Agent A。
3. `md/flow/flow.md`：项目当前核心逻辑，是架构和运行链路的主要依据。
4. `md/flow/flowchart.md`：核心逻辑的 mermaid/流程图说明。
5. `md/test/test.md`：轻量检查规范、禁止执行项和当前验证边界。
6. 当前目标对应的 prompt / 阶段文档，例如 `md/prompt/v0.3（已完成）/v0.37-命令统一/codex0.37-提示词.md`。
7. 相关源码、配置和必要时的测试文件：优先用 `rg` / `rg --files` 定位；测试文件默认只作语义参考，不默认执行。
若文档、源码、轻量检查结果冲突，以当前源码和真实检查结果为准，并在本轮结束时同步修正文档。
## 2. 项目基本规则
- 本项目是 Swift + SwiftUI + SpriteKit 的 iOS 二战回合制 hex 战棋。
- 当前产品主线是唐宋古代/中古战争迁移；底层 WWIIHexV0、FrontLine、FrontZone 等 legacy 命名可保留兼容，但玩家态和新设计不得把唐宋战争直接套成现代连续战线。
- 唐宋作战模型优先研究州府、关隘、行营、会战、袭扰、围城、粮道、仓储、漕运、士气、骑兵冲击与将领调度；可参考《十字军之王3》等中古战略游戏的集结、行军、围城和补给思路，但所有落地仍必须适配本项目 hex / region / command / rule 架构。
- 骑兵在开阔地、道路、追击和机动作战中应有明显价值；山地、林地、城池、关隘和围城环境应抑制骑兵优势。
- 补给、粮草和粮道是唐宋主线的核心规则，不是附属 UI 文案；断粮、被围、粮源、道路、山林、跨河、州府粮仓和围城压力会影响可行动作、战斗、退却和 attrition。
- Hex 是战术权威：单位位置、移动、攻击、真实占领、视野、补给落点以 hex 为准。
- Region 是战略聚合层：资源、人力、补给、胜利点、控制比例从 hex 状态聚合，不替代 hex。
- `regionToTheater` 是初始/基础战区归属和地图编辑器种子，不是运行时推进层。
- `hexToTheater` 是运行时动态战区权威；突破一个 hex 只能推进该 hex 的动态归属。
- `hexToFrontZone` 是部署层动态归属权威；`regionToFrontZone` 只能作 dominant / fallback。
- legacy 前线数据来自双方动态战区的真实 hex 邻接，不等于 region 边界或静态 theater 边界；唐宋玩家态应优先称为“接触带 / 敌我接触 / 行营部署”，避免暗示现代连续战线。
- 玩家、AI、聊天命令和 MockAI 都必须落到 `Command` / `ZoneDirective`，再经 `WarCommandExecutor`、`CommandValidator`、`RuleEngine` 执行；禁止绕过规则系统直接改 `GameState`。
- Legacy Agent D 管线保留作回归参考，默认战争 AI 主路径不得退回旧管线。
- 不恢复 organization；当前战斗核心是 strength、retreat、supply、encirclement。
- 严守用户给定范围。不要擅自扩展功能、重构架构、删除旧实现或回滚其他人改动。
## 3. main 直推与云端验证
- 当前协作制度固定使用 `main` 作为唯一上传、提交、推送和云端验证分支。
- 暂不设计 `smalldata_test`、`develop`、`codeb/...` 或 PR 合并流；已有历史分支只作记录，不进入默认流程。
- Agent B 每轮开始前必须同步最新 `origin/main`，确认当前分支是 `main`、目标远端是 `origin/main`、工作区没有无关改动。
- Agent B 完成本地轻量检查后，直接 commit 并 push 到 `origin/main`，触发 GitHub Actions 云端重验证。
- Agent C 只验收 `origin/main` 最新 commit 对应的 GitHub Actions run 与未加密结果包；不得验收旧 run、旧 artifact 或只看 Agent B 文字说明。
- Agent C 发现问题时，不做回滚式处理；默认退回 Agent B 在 `main` 上追加修复 commit，再 push 触发新 run。
- 任何 Agent 在 `git push origin main` 或改变远端 `main` 前，都必须确认提交范围只包含本轮相关文件。
## 4. 标准迭代工作流
### 4.1 人工
人工提出实现目标；精做任务可同时给出算法框架、边界、验收标准和禁止项。人工把 `AGENTS.md`、`update_log.md`、`md/flow/flow.md` 和相关上下文交给 Agent A。
### 4.2 Agent A：目标分析与提示词
Agent A 负责思考目标如何实现，不默认直接写代码。
Agent A 必须：
1. 阅读 `AGENTS.md`、`update_log.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/test/test.md` 和目标相关源码/文档。
2. 明确本轮目标、非目标、架构边界、数据流、可能风险和验收标准。
3. 设计实现流程：涉及哪些模块、是否需要拆分版本分支、是否适合并发子 Agent、需要哪些轻量检查、需要更新哪些文档。
4. 写出给 Agent B 的详细实现提示词，放入 `md/prompt/` 下的对应阶段路径。
Agent A 输出的提示词应包含：目标、范围、禁止项、当前架构依据、实现步骤、main 直推安排、GitHub Actions / artifact 验收要求、轻量检查要求、文档更新要求、验收标准、风险提示。
### 4.3 Agent B：实现、本地轻量检查与 main 推送
Agent B 负责按 Agent A 的提示词完成实现。
Agent B 必须：
1. 阅读 Agent A 提示词、`AGENTS.md`、`update_log.md`、`md/flow/flow.md`、`md/test/test.md` 和相关源码。
2. 先同步 `origin/main` 并切到 `main`，再按提示词小步实现；先定位根因，再改代码。
3. 本机只运行 `md/test/test.md` 允许的轻量检查；默认不跑完整 Xcode build/test、模拟器、Probe、Smoke、Stage Regression、Dynamic Theater Regression 或 Full。
4. 更新必要文档；若检查规则、核心逻辑、分支策略、CI 结果包或版本状态变化，必须同步更新 `md/test/test.md`、`md/flow/*`、`README.md`、`md/prompt/README.md` 或 `update_log.md`。
5. 轻量检查通过后 commit 并 push 到 `origin/main`，由 GitHub Actions 执行云端重验证。
6. 输出实现结果：改动摘要、关键文件、轻量检查命令和结果、push 的 commit SHA、等待 Agent C 下载核对的 workflow/artifact、未跑本机重测试及原因、遗留风险。
### 4.4 Agent C：云端结果包验收与核心逻辑文档
Agent C 负责验收 Agent B 的结果，并把当前进展沉淀进项目核心逻辑文档。
Agent C 必须：
1. 阅读 Agent B 输出、实际 diff、轻量检查结果、`AGENTS.md`、`update_log.md`、`md/flow/flow.md`、`md/flow/flowchart.md` 和 `md/test/test.md`。
2. 使用 `gh auth login` 完成 GitHub CLI 权限后，下载 `origin/main` 最新 commit 对应 run 的未加密 CI 结果包；缓存默认放在 `/private/tmp/wwiihexv0-c-review-<run_id>/`。
3. 核对 `ci-artifact-manifest.json` 中的 `branch`、`commitSha`、`runId`、`runAttempt` 与 `origin/main` 最新状态完全一致，并阅读 `junit.xml`、主构建日志和 `ci-failure-summary.md`。
4. 核对实现是否满足 Agent A 提示词和人工目标，重点检查架构边界、文档同步、冲突风险和未说明风险。
5. 根据当前真实进展更新 `md/flow/` 下的 markdown 与 mermaid/流程图文件，至少关注 `md/flow/flow.md` 和 `md/flow/flowchart.md`。
6. 若形成正式版本或历史维护事项，更新 `update_log.md`，让下一轮 Agent A 能接上上下文。
7. 若本轮使用多分支或多个子 Agent，必须检查文件级冲突、接口分叉、重复实现、项目文件变更冲突、数据 schema 冲突和文档口径冲突。
8. 输出验收结论：通过/不通过、问题清单、已下载 artifact、manifest 核对结果、云端 run 结果、已更新文档、建议下一步。
### 4.5 回到人工
人工阅读 Agent C 的验收、核心逻辑文档和轻量检查结果，决定是否接受、授权补测、修正、合并分支或进入下一轮开发。下一轮通过 `update_log.md` 和新的目标继续交给 Agent A，形成循环迭代。
### 4.6 多分支与并发子 Agent 规则
- 当前默认制度不使用多长期/候选分支；如人工后续明确授权多分支，每个分支必须记录目标、范围、关键文件、与其他分支的预期重叠、轻量检查结果和未确认风险。
- 大任务可以多开子 Agent 并发执行，但主 Agent 必须先分配清晰边界，尽量避免多个子 Agent 同时改同一文件或同一 public API。
- 并发完成后，主 Agent 必须做整合检查：文件冲突、重复逻辑、命名冲突、public API 兼容、数据 schema 兼容、Xcode project 变更冲突、文档冲突。
- 没有完成冲突检查前，不得声称多分支/多 Agent 工作已可合并。
## 5. 检查规则
- 每轮实现或验收前必须读 `md/test/test.md`。
- 默认云端重验证，本机只做轻量语法/格式检查：Markdown 文本检查、`plutil -lint`、`xmllint --noout`、`jq empty`、YAML 解析、针对改动文件的轻量静态检查等，具体以 `md/test/test.md` 为准。
- 除非人工明确要求本机构建或本机测试，否则本机禁止主动运行：`xcodebuild test`、`xcodebuild build`、`xcodebuild build-for-testing`、Probe、Smoke、Stage Regression、Dynamic Theater Regression、Full、UI test、性能测试、模拟器启动和全量 app 构建。
- Swift / Xcode / Web / CLI / 业务探针相关改动完成后，默认 commit 并 push 到 `origin/main`，由 GitHub Actions 运行重验证并上传未加密结果包。
- 若任务风险必须靠重测试才能排除，Agent 只能记录“本机未跑重测试；等待或参考云端结果包”，不得伪造本地结果。
- 不得用“已验证”代替具体命令和结果；不得伪造测试通过。
## 6. 文档规则
- `AGENTS.md` 只写工作流、入口规则和基本信息，保持精简，不堆阶段细节。
- `update_log.md` 记录版本历史、完成内容、关键文件、验证结果和遗留事项。
- `md/flow/flow.md` 与 `md/flow/flowchart.md` 记录当前核心逻辑和流程图。
- `md/test/test.md` 记录本地轻量检查范围、云端重验证、结果包内容、下载缓存位置、禁止执行项、命令模板和历史测试基线说明。
- `md/prompt/README.md` 记录阶段 prompt 管理、A/B/C 召唤约定和 Agent A 写提示词时必须包含的 CI / main push / artifact 要求。
- 阶段 prompt 放在对应 `md/prompt/...` 目录；Agent A 写目标提示词，Agent B 按提示词实现，Agent C 根据结果更新核心逻辑文档。
- 若源码行为、检查规则、核心流程、分支策略或版本状态改变，相关文档必须同步更新。
## 7. 交付格式
最终回复保持简洁，必须说明：
1. 完成了什么。
2. 改了哪些关键文件。
3. 跑了哪些本地轻量检查，具体结果是什么。
4. 是否已 push 到 `origin/main`；若触发云端验证，说明 commit SHA、run id、run attempt、artifact 名称和云端结果。
5. Agent C 是否下载并核对结果包；若不能下载，说明权限或环境阻塞。
6. 哪些本机重测试没跑，原因是什么。
7. 还剩什么风险或下一步。
若进行了 git stage / commit / push，只能在实际成功后按 Codex 桌面规范输出对应 directive。

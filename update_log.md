# 唐宋 v5.x 迁移与历史 v0.x 更新记录

本文档记录项目从 v0 原型到当前唐宋 v5.x 迁移的版本演进。资料来源包括 `git log`、`README.md`、阶段文档与云端 CI / artifact 验收报告。

维护规则：

- 每完成一个新的 v 版本任务后，必须在本文档追加对应版本记录。
- 记录应包含：版本号、完成日期、核心变更、关键文件/系统、验证结果、遗留事项。
- 若本轮只是文档整理、目录迁移、回滚或打捞，不应伪装成新 v 版本；可写入“历史维护记录”。
- 若 README、测试规范或源码语义发生变化，应同步更新本日志。

当前制度：唐宋 v5.x 迁移默认使用 `main` 直推和 GitHub Actions 云端重验证；下方 v0.x 分支、阿登、Guderian、Bastogne 等记录保留为历史事实和 legacy 回归参考，不代表当前默认产品主线。

## v5.8ap - 唐宋骑军追击与将领档案接触口径

完成日期：2026-07-07

核心更新：

- 按用户“古代作战不存在现代战线、骑兵强大、补给粮草重要、作战模式需继续研究”的方向，在 v5.8ao 已写入 README / AGENTS 的长期规则基础上，继续做一处小步规则落地。
- 本轮并发子 Agent 已启动但长时间未返回；主线程关闭子 Agent 后继续完成整合。未使用多分支，也未合并外部子 Agent 文件改动。
- `CommandExecutor.resolveCombatResult` 接收攻击方上下文；唐宋骑军造成敌军自动退却时，若防守者所在地是平原，或攻守相邻地格存在道路的丘陵环境，则通过 `tangSongPursuitDamage` 追加追击兵力损耗。
- 城池、关隘、山林和山地不触发骑军追击；追击损耗按本次 `CombatDamage.strengthDamage` 的 35% 四舍五入计算，最少 1 点，并与既有被围撤退追加损耗累加到 combat log 的 extra strength loss。
- `GeneralProfileView` 的唐宋旧英文履历 fallback 从“战线形势”改为“敌我接触形势”，继续避免玩家态现代连续战线口径。
- 同步 README、md 大纲、flow 文档、流程图和 v5.8ap 阶段记录。`AGENTS.md` 已在 v5.8ao 写入古代/中古作战、骑兵、粮草、CK3 参考和接触带原则，本轮不在入口规则中重复堆阶段细节。

关键文件：

- `WWIIHexV0/Rules/CommandExecutor.swift`
- `WWIIHexV0/UI/GeneralProfileView.swift`
- `README.md`
- `md/plan/plan.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v5.0-唐宋迁移/v5.8ap_cavalry_pursuit_contact_record.md`
- `update_log.md`

验证结果：

- 按当前规范和用户要求，本机不运行测试、build、Swift parse、Markdown 检查、`git diff --check`、模拟器、截图或 VoiceOver 实机验收。
- 已推送到 `origin/main`：commit `ccf158fc51dff744c543ea303f4540b8e0d8d4c5`。
- GitHub Actions `WWIIHexV0 CI Results` run `28864882666` attempt `1` 已完成并通过；artifact `wwiihexv0-ci-cloud-main-ci-v1-main-ccf158f-run28864882666-attempt1` 已下载到 `/private/tmp/wwiihexv0-c-review-28864882666/` 并核对。
- artifact manifest 匹配 `branch=main`、`commitSha=ccf158fc51dff744c543ea303f4540b8e0d8d4c5`、`runId=28864882666`、`runAttempt=1`；`staticChecksOutcome=success`、`buildOutcome=success`、`testOutcome=skipped`，JUnit 2 tests / 0 failures / 0 errors，`xcodebuild.log` 显示 `BUILD SUCCEEDED`。

遗留事项：

- 本轮不是完整古代战争系统重构，不删除内部 `FrontLine` / `FrontZone` / `hexToFrontZone` schema，也不新增骑军 AI、粮队、漕运、仓储容量、会战窗口、自动破城或 CK3 式战争系统。
- 追击系数与触发条件仍需云端构建后再结合实际手感、平衡和 AI 行为继续调参。

## v5.8ao - 唐宋骑兵冲击、断粮出击限制与接触带口径

完成日期：2026-07-07

核心更新：

- 按用户要求把“古代作战不存在现代连续战线、骑兵强大、补给粮草重要、作战模式需继续参考 CK3 等中古战争模型研究修改”的长期方向写入 `README.md` 和 `AGENTS.md`。
- 并发子 Agent 只读扫描后确认本轮做小步安全落地：不删除内部 `FrontLine` / `FrontZone` schema，只先强化骑军、断粮与玩家态接触带口径。
- `CombatRules` 把唐宋骑军在开阔地或道路条件下进攻的冲击加成从 `+0.15` 提高到 `+0.30`，保留攻城、攻关、攻林地和攻山地的抑制。
- `CommandValidator` 在唐宋场景下阻止 `SupplyState.encircled` 军队主动攻击或围城，新增 `CommandValidationError.supplyBlocked`，命令面板与战报显示“粮道断绝，不可主动出击”。
- `MapDisplayLayer`、`UnitInspectorView`、`RegionInspectorView` 和 `GeneralCommandPanelView` 把唐宋“前线/部署/防区/固守防线”玩家态文案收束为接触带、敌我接触、接触州府、接触压力、行营部署、行营辖区和固守城关。
- 同步 README、AGENTS、md 大纲、flow 文档、流程图、mermaid 源图和 v5.8ao 阶段记录。

关键文件：

- `AGENTS.md`
- `README.md`
- `WWIIHexV0/Rules/CombatRules.swift`
- `WWIIHexV0/Rules/CommandValidator.swift`
- `WWIIHexV0/Commands/CommandValidation.swift`
- `WWIIHexV0/Core/MapDisplayLayer.swift`
- `WWIIHexV0/UI/CommandPanelView.swift`
- `WWIIHexV0/UI/EventLogView.swift`
- `WWIIHexV0/UI/GeneralCommandPanelView.swift`
- `WWIIHexV0/UI/RegionInspectorView.swift`
- `WWIIHexV0/UI/UnitInspectorView.swift`
- `md/plan/plan.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/flow/01_overall_core_flow.mermaid`
- `md/prompt/v5.0-唐宋迁移/v5.8ao_ancient_combat_supply_contact_record.md`
- `update_log.md`

验证结果：

- 按当前规范和用户要求，本机不运行测试、build、Swift parse、Markdown 检查、`git diff --check`、模拟器、截图或 VoiceOver 实机验收。
- 已推送到 `origin/main`：commit `e053f28724caec4f1791a50377936efbc168a795`。
- GitHub Actions `WWIIHexV0 CI Results` run `28861419685` attempt `1` 已完成并通过；artifact `wwiihexv0-ci-cloud-main-ci-v1-main-e053f28-run28861419685-attempt1` 已下载到 `/private/tmp/wwiihexv0-c-review-28861419685/` 并核对。
- artifact manifest 匹配 `branch=main`、`commitSha=e053f28724caec4f1791a50377936efbc168a795`、`runId=28861419685`、`runAttempt=1`；`staticChecksOutcome=success`、`buildOutcome=success`、`testOutcome=skipped`，JUnit 2 tests / 0 failures / 0 errors，`xcodebuild.log` 显示 `BUILD SUCCEEDED`。

遗留事项：

- 本轮不是完整古代战争系统重构，不删除内部 `FrontLine` / `FrontZone` / `hexToFrontZone` schema，也不改变动态战区、部署层、AI 指令 raw case 或 Codable schema。
- 仍需继续研究州府、关隘、行营、会战、袭扰、围城、粮道、仓储、漕运、士气、骑兵追击与将领调度，并把可落地点继续收口到 `Command` / `ZoneDirective -> WarCommandExecutor -> RuleEngine`。
- 完整 CK3 式战争节奏、骑军平衡、粮草运输队、仓储容量、自动破城、AI 真实围城/粮道策略、截图布局和实机手感验收仍未完成。

## v5.8an - 外交面板复合行读屏硬化

完成日期：2026-07-07

核心更新：

- 并发子 Agent 只读扫描确认 v5.8am 后下一处低风险 UI 可读性切片是 `DiplomacyPanelView` 的诸国、关系和最近归附记录复合行。
- 诸国列表行补充合并后的 accessibility label/value，唐宋路径读出国家名、所属政权、集团和战意。
- 外交关系列表行补充合并后的 accessibility label/value，唐宋路径读出两国关系标题和关系状态。
- 最近归附记录行补充合并后的 accessibility label/value，唐宋路径读出归附目标、结果状态、回合、天命变化和归附州府。
- 本轮只处理 `DiplomacyPanelView` 复合行读屏语义，不扩大到外交状态规则、归附控制权交割、AI 方面军令卡片、诏令朝议摘要块或主棋盘逐地块 focus tree。
- 同步 README、md 大纲、flow 文档、流程图、mermaid 源图和 v5.8an 阶段记录。

关键文件：

- `WWIIHexV0/UI/DiplomacyPanelView.swift`
- `README.md`
- `md/plan/plan.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/flow/01_overall_core_flow.mermaid`
- `md/prompt/v5.0-唐宋迁移/v5.8an_diplomacy_row_accessibility_record.md`
- `update_log.md`

验证结果：

- 按当前规范和用户要求，本机不运行测试、build、Swift parse、Markdown 检查、`git diff --check`、模拟器、截图或 VoiceOver 实机验收。
- 已推送到 `origin/main`：commit `803b97a109a9e2337c3eb7d0c115db19b46c89fe`。
- GitHub Actions `WWIIHexV0 CI Results` run `28856191993` attempt `1` 已完成并通过；artifact `wwiihexv0-ci-cloud-main-ci-v1-main-803b97a-run28856191993-attempt1` 已核对。
- artifact manifest 匹配 `branch=main`、`commitSha=803b97a109a9e2337c3eb7d0c115db19b46c89fe`、`runId=28856191993`、`runAttempt=1`；`staticChecksOutcome=success`、`buildOutcome=success`、`testOutcome=skipped`，JUnit 2 tests / 0 failures / 0 errors，`xcodebuild.log` 显示 `BUILD SUCCEEDED`。

遗留事项：

- 本轮只改外交面板 SwiftUI 可读语义，不改变 `DiplomacyState`、`MandateState`、`PacificationRecord`、`Command.proposeSubmission`、关系投影、命令执行、AI 决策、控制权交割、日志结构或 Codable schema。
- 完整 VoiceOver 实机、截图布局、AI 方面军令卡片、诏令朝议摘要块、主棋盘逐地块/逐军队 focus tree、全项目玩家可见残留扫描、结构化 event payload、真 LLM 输出本地化和发布级 UI 验收仍未完成。

## v5.8am - 命令面板状态与反馈读屏硬化

完成日期：2026-07-07

核心更新：

- 并发子 Agent 只读扫描确认 v5.8al 后下一处低风险 UI 可读性切片是 `CommandPanelView` 的军令状态和最近反馈文本。
- 军令状态文本补充 accessibility label/value，唐宋路径读作“军令状态”，value 复用既有 `statusText`。
- 最近军令反馈文本补充 accessibility label/value，唐宋路径读作“军令反馈”，value 复用既有 `commandMessageText(_:)` 唐宋显示桥。
- 结束回合按钮补充可用状态 value，与既有军令按钮读屏状态口径保持一致。
- 本轮只处理 `CommandPanelView` 状态、结束回合和最近反馈，不扩大到外交面板复合行、AI 方面军令卡片、诏令朝议摘要块或主棋盘逐地块 focus tree。
- 同步 README、md 大纲、flow 文档、流程图、mermaid 源图和 v5.8am 阶段记录。

关键文件：

- `WWIIHexV0/UI/CommandPanelView.swift`
- `README.md`
- `md/plan/plan.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/flow/01_overall_core_flow.mermaid`
- `md/prompt/v5.0-唐宋迁移/v5.8am_command_panel_status_feedback_accessibility_record.md`
- `update_log.md`

验证结果：

- 按当前规范和用户要求，本机不运行测试、build、Swift parse、Markdown 检查、`git diff --check`、模拟器、截图或 VoiceOver 实机验收。
- 已推送到 `origin/main`：commit `38fac8f01927bde2151a9eca378284029a504f09`。
- GitHub Actions `WWIIHexV0 CI Results` run `28854791987` attempt `1` 已完成并通过；artifact `wwiihexv0-ci-cloud-main-ci-v1-main-38fac8f-run28854791987-attempt1` 已核对。
- artifact manifest 匹配 `branch=main`、`commitSha=38fac8f01927bde2151a9eca378284029a504f09`、`runId=28854791987`、`runAttempt=1`；`staticChecksOutcome=success`、`buildOutcome=success`、`testOutcome=skipped`，JUnit 2 tests / 0 failures / 0 errors，`xcodebuild.log` 显示 `BUILD SUCCEEDED`。

遗留事项：

- 本轮只改命令面板 SwiftUI 可读语义，不改变 `Command`、`CommandValidator`、`CommandExecutor`、`RuleEngine`、`lastCommandMessage` 写入端、按钮启停条件、命令反馈映射、AI 决策、规则系统、日志结构或 Codable schema。
- 完整 VoiceOver 实机、截图布局、外交面板国家/关系/归附复合行、AI 方面军令卡片、诏令朝议摘要块、主棋盘逐地块/逐军队 focus tree、全项目玩家可见残留扫描、结构化 event payload、真 LLM 输出本地化和发布级 UI 验收仍未完成。

## v5.8al - AI 面板军令结果行读屏硬化

完成日期：2026-07-07

核心更新：

- 并发子 Agent 只读扫描确认 v5.8ak 后下一处低风险 AI 可解释性切片是 `AgentPanelView` 的“军令结果”列表行。
- 军令结果行补充合并后的 accessibility label/value，唐宋路径读作“军令结果：命令标题”。
- 军令结果行读屏 value 复用既有 `resultLine(_:)`，继续显示“已执行 / 规则拒绝 / 映射失败 / 未执行”等状态，不改变命令结果生成或可见文案。
- 本轮只处理 `record.commandResults` 行，不扩大到方面军令卡片、诏令朝议摘要块、CommandPanel 状态反馈或 DiplomacyPanel 归附记录。
- 同步 README、md 大纲、flow 文档、流程图、mermaid 源图和 v5.8al 阶段记录。

关键文件：

- `WWIIHexV0/UI/AgentPanelView.swift`
- `README.md`
- `md/plan/plan.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/flow/01_overall_core_flow.mermaid`
- `md/prompt/v5.0-唐宋迁移/v5.8al_agent_command_result_accessibility_record.md`
- `update_log.md`

验证结果：

- 按当前规范和用户要求，本机不运行测试、build、Swift parse、Markdown 检查、`git diff --check`、模拟器、截图或 VoiceOver 实机验收。
- 已推送到 `origin/main`：commit `8567f0d0b4e4127fc2cf63f458d5df5417c1f506`。
- GitHub Actions `WWIIHexV0 CI Results` run `28850548732` attempt `1` 已完成并通过；artifact `wwiihexv0-ci-cloud-main-ci-v1-main-8567f0d-run28850548732-attempt1` 已核对。
- artifact manifest 匹配 `branch=main`、`commitSha=8567f0d0b4e4127fc2cf63f458d5df5417c1f506`、`runId=28850548732`、`runAttempt=1`；`staticChecksOutcome=success`、`buildOutcome=success`、`testOutcome=skipped`，JUnit 2 tests / 0 failures / 0 errors，`xcodebuild.log` 显示 `BUILD SUCCEEDED`。

遗留事项：

- 本轮只改 AI 面板 SwiftUI 可读语义，不改变 `AgentDecisionRecord`、`CommandResultSummary`、`WarDirectiveRecord`、`TheaterDirectiveEnvelope`、`ZoneDirective`、`Command`、命令执行、AI 决策、规则系统、日志结构、raw JSON 存储或 Codable schema。
- 完整 VoiceOver 实机、截图布局、方面军令卡片、诏令朝议摘要块、CommandPanel 状态反馈、DiplomacyPanel 复合行、全项目玩家可见残留扫描、结构化 event payload、真 LLM 输出本地化和发布级 UI 验收仍未完成。

## v5.8ak - HUD 目标与下一步提示读屏硬化

完成日期：2026-07-07

核心更新：

- 并发子 Agent 只读扫描确认 v5.8ae 已覆盖 HUD 库存/队列指标，v5.8ai/v5.8aj 已覆盖战报胜负/评分/胜利目标，下一处低风险切片是 HUD 目标摘要与下一步提示卡片。
- HUD “目标”摘要文本补充合并后的 accessibility label/value，唐宋路径读作“目标提示”，value 复用既有 `objectiveGuideText`。
- HUD 目标州府 chips / 按钮保持独立 accessibility label/value/hint 和独立焦点，不把整张目标卡合并，避免吞掉“查看目标”按钮。
- HUD “下一步”提示卡片补充合并后的 accessibility label/value，唐宋路径读作“下一步提示”，value 复用既有 `nextActionHint`。
- 同步 README、md 大纲、flow 文档、流程图、mermaid 源图和 v5.8ak 阶段记录。

关键文件：

- `WWIIHexV0/UI/HUDView.swift`
- `README.md`
- `md/plan/plan.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/flow/01_overall_core_flow.mermaid`
- `md/prompt/v5.0-唐宋迁移/v5.8ak_hud_objective_next_action_accessibility_record.md`
- `update_log.md`

验证结果：

- 按当前规范和用户要求，本机不运行测试、build、Swift parse、Markdown 检查、`git diff --check`、模拟器、截图或 VoiceOver 实机验收。
- 已推送到 `origin/main`：commit `685163b91706ef64d58669432a5d0af3f31181a6`。
- GitHub Actions `WWIIHexV0 CI Results` run `28849690949` attempt `1` 已完成并通过；artifact `wwiihexv0-ci-cloud-main-ci-v1-main-685163b-run28849690949-attempt1` 已核对。
- artifact manifest 匹配 `branch=main`、`commitSha=685163b91706ef64d58669432a5d0af3f31181a6`、`runId=28849690949`、`runAttempt=1`；`staticChecksOutcome=success`、`buildOutcome=success`、`testOutcome=skipped`，JUnit 2 tests / 0 failures / 0 errors，`xcodebuild.log` 显示 `BUILD SUCCEEDED`。

遗留事项：

- 本轮只改 HUD SwiftUI 可读语义，不改变 `VictoryRules.objectiveProgress(in:)`、`objectiveGuideItems` 生成、目标排序、`onFocusObjective`、地图 spotlight / focus、`RootGameView.nextActionHint` 派生、`CommandValidator`、命令执行、AI 决策、规则系统、日志结构或 Codable schema。
- 完整 VoiceOver 实机、截图布局、主棋盘逐地块/逐军队 focus tree、全项目玩家可见残留扫描、结构化 event payload、真 LLM 输出本地化和发布级 UI 验收仍未完成。

## v5.8aj - 战报胜利目标行读屏硬化

完成日期：2026-07-07

核心更新：

- 并发子 Agent 只读扫描确认 v5.8ai 后 `EventLogView` 的胜利目标 progress 行仍由标题、达成状态、摘要和详情多段 `Text` 拆开朗读。
- 胜利目标行补充合并后的 accessibility label/value，唐宋路径读作“胜利目标：目标标题”。
- 目标行读屏 value 复用既有达成/推进中文案、`VictoryObjectiveProgress.summary` 和 `detail`，不改变胜利目标计算、排序或可见文案。
- 同步 README、md 大纲、flow 文档、流程图、mermaid 源图和 v5.8aj 阶段记录。

关键文件：

- `WWIIHexV0/UI/EventLogView.swift`
- `README.md`
- `md/plan/plan.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/flow/01_overall_core_flow.mermaid`
- `md/prompt/v5.0-唐宋迁移/v5.8aj_event_log_victory_objective_accessibility_record.md`
- `update_log.md`

验证结果：

- 按当前规范和用户要求，本机不运行测试、build、Swift parse、Markdown 检查、`git diff --check`、模拟器、截图或 VoiceOver 实机验收。
- 已推送到 `origin/main`：commit `e7187380d9776132a350643d5ba604115685de97`。
- GitHub Actions `WWIIHexV0 CI Results` run `28848479176` attempt `1` 已完成并通过；artifact `wwiihexv0-ci-cloud-main-ci-v1-main-e718738-run28848479176-attempt1` 已核对。
- artifact manifest 匹配 `branch=main`、`commitSha=e7187380d9776132a350643d5ba604115685de97`、`runId=28848479176`、`runAttempt=1`；`staticChecksOutcome=success`、`buildOutcome=success`、`testOutcome=skipped`，JUnit 2 tests / 0 failures / 0 errors，`xcodebuild.log` 显示 `BUILD SUCCEEDED`。

遗留事项：

- 本轮只改战报胜利目标行 SwiftUI 可读语义，不改变 `VictoryState`、`VictoryReason`、`VictoryRules.objectiveProgress(in:)`、`VictoryObjectiveProgress` 计算逻辑、评分估算算法、胜利目标排序、可见 UI 文案、`GameLogEntry`、事件写入端、命令执行、AI 决策、规则系统、日志结构或 Codable schema。
- 完整 VoiceOver 实机、截图布局、全项目玩家可见残留扫描、结构化 event payload、真 LLM 输出本地化和发布级 UI 验收仍未完成。

## v5.8ai - 战报胜负与评分卡片读屏硬化

完成日期：2026-07-07

核心更新：

- 并发子 Agent 只读扫描确认 `EventLogView` 顶部胜负、评分估算与胜利目标区域仍有复合文本拆散读屏空间；本轮选择更窄的胜负卡片与评分估算卡片。
- 胜负卡片补充合并后的 accessibility label/value，唐宋路径读作“胜负摘要”，value 复用既有 `victorySummary`。
- 评分估算卡片补充合并后的 accessibility label/value，value 复用既有 `SettlementSummary.score`、`grade` 和 `detail`，不改变评分估算算法。
- 同步 README、md 大纲、flow 文档、流程图和 v5.8ai 阶段记录。

关键文件：

- `WWIIHexV0/UI/EventLogView.swift`
- `README.md`
- `md/plan/plan.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v5.0-唐宋迁移/v5.8ai_event_log_victory_score_accessibility_record.md`
- `update_log.md`

验证结果：

- 按当前规范和用户要求，本机不运行测试、build、Swift parse、Markdown 检查、`git diff --check`、模拟器、截图或 VoiceOver 实机验收。
- 已推送到 `origin/main`：commit `61d83eddb0ba61e53c78f64d1fbbf72d513c5a6b`。
- GitHub Actions `WWIIHexV0 CI Results` run `28846985332` attempt `1` 已完成并通过；artifact `wwiihexv0-ci-cloud-main-ci-v1-main-61d83ed-run28846985332-attempt1` 已核对。
- artifact manifest 匹配 `branch=main`、`commitSha=61d83eddb0ba61e53c78f64d1fbbf72d513c5a6b`、`runId=28846985332`、`runAttempt=1`；`staticChecksOutcome=success`、`buildOutcome=success`、`testOutcome=skipped`，JUnit 2 tests / 0 failures / 0 errors，`xcodebuild.log` 显示 `BUILD SUCCEEDED`。

遗留事项：

- 本轮只改战报顶部胜负/评分卡片 SwiftUI 可读语义，不改变 `VictoryState`、`VictoryReason`、`VictoryRules.objectiveProgress(in:)`、评分估算算法、`GameLogEntry`、`TurnReportSummary`、`TangSongEventLogMessage` 显示桥、事件写入端、命令执行、AI 决策、规则系统、日志结构或 Codable schema。
- 完整 VoiceOver 实机、截图布局、胜利目标行读屏、全项目玩家可见残留扫描、结构化 event payload、真 LLM 输出本地化和发布级 UI 验收仍未完成。

## v5.8ah - 战报摘要卡片读屏硬化

完成日期：2026-07-07

核心更新：

- 并发子 Agent 只读扫描确认 v5.8ag 只处理最近战报列表行，`EventLogView` 顶部“本回合战报 / 最近战报”摘要卡片仍由标题、回合、汇总和 highlight 多段 `Text` 拆开朗读。
- 战报摘要卡片补充合并后的 accessibility label/value，唐宋路径读作“战报摘要：本回合战报 / 最近战报”。
- 摘要卡片读屏 value 复用既有 `TurnReportSummary.turnText`、`summaryText` 和 highlights，不改变摘要生成或日志解析。
- 同步 README、md 大纲、flow 文档、流程图和 v5.8ah 阶段记录。

关键文件：

- `WWIIHexV0/UI/EventLogView.swift`
- `README.md`
- `md/plan/plan.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v5.0-唐宋迁移/v5.8ah_event_log_summary_card_accessibility_record.md`
- `update_log.md`

验证结果：

- 按当前规范和用户要求，本机不运行测试、build、Swift parse、Markdown 检查、`git diff --check`、模拟器、截图或 VoiceOver 实机验收。
- 已推送到 `origin/main`：commit `adedde9f28f7e37943e25c616b3aa93b0a0e37a2`。
- GitHub Actions `WWIIHexV0 CI Results` run `28846030370` attempt `1` 已完成并通过；artifact `wwiihexv0-ci-cloud-main-ci-v1-main-adedde9-run28846030370-attempt1` 已核对。
- artifact manifest 匹配 `branch=main`、`commitSha=adedde9f28f7e37943e25c616b3aa93b0a0e37a2`、`runId=28846030370`、`runAttempt=1`；`staticChecksOutcome=success`、`buildOutcome=success`、`testOutcome=skipped`，JUnit 2 tests / 0 failures / 0 errors，`xcodebuild.log` 显示 `BUILD SUCCEEDED`。

遗留事项：

- 本轮只改战报摘要卡片 SwiftUI 可读语义，不改变 `GameLogEntry`、`TurnReportSummary` 派生逻辑、`TangSongEventLogMessage` 显示桥、事件写入端、命令执行、AI 决策、规则系统、日志结构或 Codable schema。
- 完整 VoiceOver 实机、截图布局、胜负/评分/胜利目标卡片读屏、全项目玩家可见残留扫描、结构化 event payload、真 LLM 输出本地化和发布级 UI 验收仍未完成。

## v5.8ag - 战报行整行读屏硬化

完成日期：2026-07-07

核心更新：

- 并发子 Agent 只读扫描确认 `EventLogView` 的最近战报列表行仍由分类、metadata 和正文多个 `Text` 拆开呈现，适合作为 v5.8af 后续低风险 accessibility 小切片。
- 最近战报列表行补充合并后的 accessibility label/value，唐宋路径按“战报：战斗 / 粮道 / 州府”等分类读出。
- 战报行读屏 value 复用既有 `metadata(for:)` 和 `displayMessage(for:)`，继续经过 `TangSongEventLogMessage` 显示桥，不重新解析日志。
- 同步 README、md 大纲、flow 文档、流程图和 v5.8ag 阶段记录。

关键文件：

- `WWIIHexV0/UI/EventLogView.swift`
- `README.md`
- `md/plan/plan.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v5.0-唐宋迁移/v5.8ag_event_log_row_accessibility_record.md`
- `update_log.md`

验证结果：

- 按当前规范和用户要求，本机不运行测试、build、Swift parse、Markdown 检查、`git diff --check`、模拟器、截图或 VoiceOver 实机验收。
- 已推送到 `origin/main`：commit `0db6a836c003a096f10f0875ac5d5e60f4be036a`。
- GitHub Actions `WWIIHexV0 CI Results` run `28845234610` attempt `1` 已完成并通过；artifact `wwiihexv0-ci-cloud-main-ci-v1-main-0db6a83-run28845234610-attempt1` 已核对。
- artifact manifest 匹配 `branch=main`、`commitSha=0db6a836c003a096f10f0875ac5d5e60f4be036a`、`runId=28845234610`、`runAttempt=1`；`staticChecksOutcome=success`、`buildOutcome=success`、`testOutcome=skipped`，JUnit 2 tests / 0 failures / 0 errors，`xcodebuild.log` 显示 `BUILD SUCCEEDED`。
- 最终文档补记提交 `97d97b4cee10100117c70cb84091308d2fdd7c59` 也已推送到 `origin/main`；GitHub Actions run `28845385787` attempt `1` 已完成并通过，artifact `wwiihexv0-ci-cloud-main-ci-v1-main-97d97b4-run28845385787-attempt1` 已核对，manifest / JUnit / `xcodebuild.log` 均匹配最新 main 且 `BUILD SUCCEEDED`。

遗留事项：

- 本轮只改战报列表行 SwiftUI 可读语义，不改变 `GameLogEntry`、`TangSongEventLogMessage` 显示桥、事件写入端、命令执行、AI 决策、规则系统、日志结构或 Codable schema。
- 完整 VoiceOver 实机、截图布局、战报摘要卡片读屏、全项目玩家可见残留扫描、结构化 event payload、真 LLM 输出本地化和发布级 UI 验收仍未完成。

## v5.8af - 将领军令面板指标与列表读屏硬化

完成日期：2026-07-07

核心更新：

- 并发子 Agent 只读扫描指出 `GeneralCommandPanelView` 仍有裸数字和拆散读屏问题；该切片不与 v5.8z 将领档案页重复。
- 忠诚/军心指标补合并 accessibility 语义，唐宋路径读作“数值，满百”。
- 亲征干预显示为“N 次”，所属军队行补兵力与满额读屏值。
- 已拟军令行补“已拟军令：进攻/固守”和目标值，减少图标与摘要被拆散朗读。
- 同步 README、md 大纲、flow 文档、流程图和 v5.8af 阶段记录。

关键文件：

- `WWIIHexV0/UI/GeneralCommandPanelView.swift`
- `README.md`
- `md/plan/plan.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v5.0-唐宋迁移/v5.8af_general_command_panel_accessibility_record.md`
- `update_log.md`

验证结果：

- 按当前规范和用户要求，本机不运行测试、build、Swift parse、Markdown 检查、`git diff --check`、模拟器、截图或 VoiceOver 实机验收。
- 已推送到 `origin/main`：commit `b5f3387319ec84ac40e60f3be955144da211be0b`。
- GitHub Actions `WWIIHexV0 CI Results` run `28844637241` attempt `1` 已完成并通过；artifact `wwiihexv0-ci-cloud-main-ci-v1-main-b5f3387-run28844637241-attempt1` 已核对。
- artifact manifest 匹配 `branch=main`、`commitSha=b5f3387319ec84ac40e60f3be955144da211be0b`、`runId=28844637241`、`runAttempt=1`；`staticChecksOutcome=success`、`buildOutcome=success`、`testOutcome=skipped`，JUnit 2 tests / 0 failures / 0 errors，`xcodebuild.log` 显示 `BUILD SUCCEEDED`。

遗留事项：

- 本轮只改将领军令面板显示和 SwiftUI 可读语义，不改变 `GeneralData`、`GeneralAssignment`、`Division`、`PlayerPlannedOperation`、命令按钮、AI 决策、规则系统、日志结构或 Codable schema。
- 战报行整行读屏、完整 VoiceOver 实机、截图布局、全项目玩家可见残留扫描和发布级 UI 验收仍未完成。

## v5.8ae - HUD 指标与队列读法硬化

完成日期：2026-07-07

核心更新：

- 并发子 Agent 只读扫描指出 HUD 仍有高频首屏裸数字：丁口、钱帛、粮草和军备队列数量缺少唐宋读法与合并读屏语义。
- `HUDView` 唐宋路径的库存指标改为“丁口 N / 钱帛 N / 粮草 N”。
- HUD 军备队列指标改为“暂无军备”或“军备队列 N 项”。
- HUD 指标行补充合并后的 accessibility label/value，减少读屏拆散标签和值。
- 同步 README、md 大纲、flow 文档、流程图和 v5.8ae 阶段记录。

关键文件：

- `WWIIHexV0/UI/HUDView.swift`
- `README.md`
- `md/plan/plan.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v5.0-唐宋迁移/v5.8ae_hud_metric_readability_record.md`
- `update_log.md`

验证结果：

- 按当前规范和用户要求，本机未运行测试、build、Swift parse、Markdown 检查、`git diff --check`、模拟器、截图或 VoiceOver 实机验收。
- 已推送到 `origin/main`：commit `92713e075e9f52cbf5f7fe0c956c6773037ef452`。
- GitHub Actions `WWIIHexV0 CI Results` run `28843991712` attempt `1` 已完成并通过；artifact `wwiihexv0-ci-cloud-main-ci-v1-main-92713e0-run28843991712-attempt1` 已核对。
- artifact manifest 匹配 `branch=main`、`commitSha=92713e075e9f52cbf5f7fe0c956c6773037ef452`、`runId=28843991712`、`runAttempt=1`；`staticChecksOutcome=success`、`buildOutcome=success`、`testOutcome=skipped`，JUnit 2 tests / 0 failures / 0 errors，`xcodebuild.log` 显示 `BUILD SUCCEEDED`。

遗留事项：

- 本轮只改 HUD 显示和 SwiftUI 可读语义，不改变 `EconomyState`、生产队列、资源规则、命令、胜利规则、日志结构或 Codable schema。
- 战报行整行读屏、完整 VoiceOver 实机、截图布局、全项目玩家可见残留扫描和发布级 UI 验收仍未完成。

## v5.8ad - 府库军备队列可读性硬化

完成日期：2026-07-07

核心更新：

- 并发子 Agent 只读扫描指出主游戏府库面板仍有更高产品价值的可读性切片：队列剩余回合裸数字、收入/耗粮短标签和军备按钮动作语义可继续收口。
- `EconomyPanelView` 唐宋路径的军备队列未就绪项改为“尚需 N 回合”，就绪项继续显示“就绪”。
- 府库指标从“入丁 / 入帛 / 耗粮”改为“本回合丁口 / 本回合钱帛 / 本回合耗粮”，指标行补合并后的 accessibility label/value。
- 军备按钮补“下达军备令：军备名”读屏动作名，队列行补“军备队列：军备名”和剩余回合 accessibility value。
- 同步 README、md 大纲、flow 文档、流程图和 v5.8ad 阶段记录。

关键文件：

- `WWIIHexV0/UI/EconomyPanelView.swift`
- `README.md`
- `md/plan/plan.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v5.0-唐宋迁移/v5.8ad_economy_queue_readability_record.md`
- `update_log.md`

验证结果：

- 按当前规范和用户要求，本机未运行测试、build、Swift parse、Markdown 检查、`git diff --check`、模拟器、截图或 VoiceOver 实机验收。
- 已推送到 `origin/main`：commit `2a1f66d0145a79ae2099b7ab79e3d354d83cd09b`。
- GitHub Actions `WWIIHexV0 CI Results` run `28842972271` attempt `1` 已完成并通过；artifact `wwiihexv0-ci-cloud-main-ci-v1-main-2a1f66d-run28842972271-attempt1` 已核对。
- artifact manifest 匹配 `branch=main`、`commitSha=2a1f66d0145a79ae2099b7ab79e3d354d83cd09b`、`runId=28842972271`、`runAttempt=1`；`staticChecksOutcome=success`、`buildOutcome=success`、`testOutcome=skipped`，JUnit 2 tests / 0 failures / 0 errors，`xcodebuild.log` 显示 `BUILD SUCCEEDED`。

遗留事项：

- 本轮只改府库面板显示和 SwiftUI 可读语义，不改变 `ProductionOrder`、`ProductionKind`、经济规则、队列执行、资源扣除、命令、日志结构或 Codable schema。
- 完整 VoiceOver 实机、截图布局、全项目玩家可见残留扫描和发布级 UI 验收仍未完成。

## v5.8ac - 军议与方面军令反馈硬化

完成日期：2026-07-07

核心更新：

- 并发子 Agent 只读扫描指出 `AppContainer`、`CommandPanelView` 和 `AgentPanelView` 仍有低风险玩家可见反馈可继续收口；另有 README、plan、flow、flowchart 旧版本口径需要同步。
- `AppContainer.playerDirectiveMessage` 在唐宋路径下把方面军令部分执行摘要从 `N/M` 改为“已执行 N 道，未执行 M 道”。
- `CommandPanelView.commandMessageText` 对旧式 `General order executed...` 反馈做完整中文兜底，避免留下半英文格式。
- `AgentPanelView` 唐宋玩家态把“军议原文”改称“军议详文”，raw JSON 仍按既有 legacy/开发态路径留存。
- 同步 README、md 大纲、flow 文档、流程图和 v5.8ac 阶段记录；顺手修正默认资源 fallback 与 MapEditor 军队标签旧口径。

关键文件：

- `WWIIHexV0/App/AppContainer.swift`
- `WWIIHexV0/UI/CommandPanelView.swift`
- `WWIIHexV0/UI/AgentPanelView.swift`
- `README.md`
- `md/plan/plan.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v5.0-唐宋迁移/v5.8ac_command_feedback_readability_record.md`
- `update_log.md`

验证结果：

- 按当前规范和用户要求，本机不运行测试、build、Swift parse、Markdown 检查、`git diff --check`、模拟器、截图或 VoiceOver 实机验收。
- 本轮完成后推送到 `origin/main`，等待 GitHub Actions `WWIIHexV0 CI Results` 云端验证和 artifact 核对。

遗留事项：

- 本轮只改玩家可见反馈和显示桥，不改变 `Command`、`ZoneDirective`、`WarDirectiveRecord`、`AgentDecisionRecord.rawJSON`、`GameLogEntry`、命令执行、AI 决策、规则系统或 Codable schema。
- 完整全项目写入端本地化、结构化 event payload、真 LLM 输出本地化、截图布局和发布级 UI 验收仍未完成。

## v5.8ab - MapEditor 画布符号硬化

完成日期：2026-07-07

核心更新：

- 并发子 Agent 只读扫描指出 `MapEditorCanvasScene` 画布内实际可见文字集中在粮源标记和军队模板标记；未发现坐标、raw id 或 `node.name` 调试命名直接绘制到画布。
- `MapEditorCanvasScene` 的粮源画布标记从“补”改为“粮”，更贴近唐宋资源口径。
- MapEditor 军队模板画布标记从单字 `禁/骑/弩/械/守/州/军` 改为“禁军、骑军、弩兵、器械、守军、州军、军队”，减少过短调试符号。
- 底图 SpriteKit 节点不再写 `name = "底图"`；SwiftUI 画布 accessibility value 仍由 `MapEditorSpriteView` 提供。
- 同步 README、md 大纲、flow 文档、流程图和 v5.8ab 阶段记录。

关键文件：

- `MapEditor/MapEditorCanvasScene.swift`
- `README.md`
- `md/plan/plan.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v5.0-唐宋迁移/v5.8ab_mapeditor_canvas_symbol_hardening_record.md`
- `update_log.md`

验证结果：

- 按当前规范和用户要求，本机不运行测试、build、Swift parse、Markdown 检查、`git diff --check`、模拟器、截图或 VoiceOver 实机验收。
- 本轮完成后推送到 `origin/main`，等待 GitHub Actions `WWIIHexV0 CI Results` 云端验证和 artifact 核对。

遗留事项：

- 本轮只改 MapEditor SpriteKit 画布显示标签，不改变 `MapEditorDocument`、单位模板 id、导出 JSON schema、资源桥路径、画布交互、快捷键处理、主游戏规则或 Codable raw 值。
- 完整截图、布局、MapEditor 真实 VoiceOver 和发布级符号系统验收仍未完成。
- 若后续要把画布文字彻底替换成图标/形状标记，应单独做视觉/符号设计切片。

## v5.8aa - MapEditor 画布 value 与底图控件硬化

完成日期：2026-07-07

核心更新：

- 并发子 Agent 只读扫描指出 `MapEditorView` 的地图编辑画布缺少 accessibility value，底图导入/参数控件缺少读屏上下文，帮助文案仍有 `Option+左键`、`N`、`M` 和偏移输入框 `X/Y` 这类 ASCII 快捷键/轴字母表达；本轮选择低风险 MapEditor 显示层小切片。
- `MapEditorSpriteView` 的地图编辑画布补充 accessibility value，读出当前模式、编辑状态、地块/州府/方面/军队数量、选中地块、待加入/待部署数量和底图状态。
- `MapEditorView` 的底图导入、移除、缩放、横向/纵向偏移和应用参数控件补充 accessibility label/value/hint，说明底图只是绘制参考，不改变游戏规则数据。
- MapEditor 帮助文案去掉 `Option+左键`、`N`、`M` 快捷键表达，底图偏移输入框去掉可见 `X/Y` 轴字母。
- 同步 README、md 大纲、flow 文档、流程图和 v5.8aa 阶段记录。

关键文件：

- `MapEditor/MapEditorView.swift`
- `README.md`
- `md/plan/plan.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v5.0-唐宋迁移/v5.8aa_mapeditor_canvas_background_accessibility_record.md`
- `update_log.md`

验证结果：

- 按当前规范和用户要求，本机不运行测试、build、Swift parse、Markdown 检查、`git diff --check`、模拟器、截图或 VoiceOver 实机验收。
- 本轮完成后推送到 `origin/main`，等待 GitHub Actions `WWIIHexV0 CI Results` 云端验证和 artifact 核对。

遗留事项：

- 本轮只改 MapEditor SwiftUI 可读语义和说明文字，不改变 `MapEditorDocument`、导出 JSON schema、资源桥路径、SpriteKit 画布交互、快捷键处理、主游戏规则或 Codable raw 值。
- 完整 MapEditor VoiceOver 实机、截图、macOS 编辑器布局和 v5.9 发布验收仍未完成。
- 画布内“补”与军队短字标仍作为地图编辑符号保留；若后续需要发布级图标系统，应单独做视觉/符号设计切片。

## v5.8z - 将领档案 accessibility 与 fallback 硬化

完成日期：2026-07-07

核心更新：

- 并发子 Agent 只读扫描指出 `GeneralProfileView` 的关闭按钮上下文、指标 value、技能/辖下军队读屏、HQ 警告读法和唐宋 fallback 仍可硬化；本轮选择低风险将领档案显示层小切片。
- `GeneralProfileView` 的关闭按钮补“关闭将领档案 / Close General Profile” accessibility label 和返回提示。
- 忠诚与军心 `metricBar` 合并为单个可访问元素，value 显示“满百 / out of 100”；技能项补“特长 / Skill”上下文，HQ 受压补警告读法。
- 辖下军队行补完整 accessibility label/value，唐宋路径读作军队名与“兵力 x，满额 y”。
- 唐宋头像占位遇到 legacy Latin 名称时显示“将”，所辖方面名为空或含 Latin 时 fallback 为“未命名方面”。
- 同步 README、md 大纲、flow 文档、流程图和 v5.8z 阶段记录。

关键文件：

- `WWIIHexV0/UI/GeneralProfileView.swift`
- `README.md`
- `md/plan/plan.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v5.0-唐宋迁移/v5.8z_general_profile_accessibility_record.md`
- `update_log.md`

验证结果：

- 按当前规范和用户要求，本机不运行测试、build、Swift parse、Markdown 检查、`git diff --check`、模拟器、截图或 VoiceOver 实机验收。
- 本轮完成后推送到 `origin/main`，等待 GitHub Actions `WWIIHexV0 CI Results` 云端验证和 artifact 核对。

遗留事项：

- 本轮只改将领档案 SwiftUI 可读语义和缺名 fallback，不改变 `GeneralData`、`GeneralAssignment`、`FrontZone`、`Division`、将领分配、命令、规则、AI 决策或 Codable schema。
- 完整逐地块/逐军队 VoiceOver focus order、实机读屏验收、截图验收、iPhone/iPad 横竖屏布局验收和 v5.9 发布验收仍未完成。
- MapEditor 画布 value、底图按钮/参数说明和更完整的 Dynamic Type 布局仍可继续拆成后续小切片。

## v5.8y - tooltip 与检查面板读法硬化

完成日期：2026-07-07

核心更新：

- 并发子 Agent 只读扫描指出常驻军队 tooltip 的读屏 label 漏掉补给/退却/本回合状态，军队/州府检查面板仍有英文内部型标签、资源缩写和唐宋围城摘要可读性问题；本轮选择低风险 tooltip/inspector 显示层小切片。
- `UnitTooltipView` 的合并 accessibility 内容拆成 label/value，value 补充兵力、补给、退却和本回合状态；英文 low supply tooltip 不再只显示 `Low`。
- `UnitInspectorView` 的英文 `FrontZone` / `FrontLine` / `Deploy` 标签改为自然读法，英文部署状态不再直出 `FRONT` / `DEPTH` / `GARRISON`；唐宋编成比例从百分号改为“占 N／100”。
- `RegionInspectorView` 的英文 `FrontZone` 标签与 `MP/IC/SUP` 资源缩写改为自然读法；唐宋围城摘要改为攻方、守方、压力、城防和围城军队数量的结构化读法。
- 同步 README、md 大纲、flow 文档、流程图和 v5.8y 阶段记录。

关键文件：

- `WWIIHexV0/UI/UnitTooltipView.swift`
- `WWIIHexV0/UI/UnitInspectorView.swift`
- `WWIIHexV0/UI/RegionInspectorView.swift`
- `README.md`
- `md/plan/plan.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v5.0-唐宋迁移/v5.8y_tooltip_inspector_readability_record.md`
- `update_log.md`

验证结果：

- 按当前规范和用户要求，本机不运行测试、build、Swift parse、Markdown 检查、`git diff --check`、模拟器、截图或 VoiceOver 实机验收。
- 本轮完成后推送到 `origin/main`，等待 GitHub Actions `WWIIHexV0 CI Results` 云端验证和 artifact 核对。

遗留事项：

- 本轮只改 tooltip 和检查面板显示/读屏语义，不改变 `Division`、`ComponentType`、`RegionInspectorState`、围城规则、补给规则、命令、AI 决策或 Codable schema。
- 完整逐地块/逐军队 VoiceOver focus order、实机读屏验收、截图验收、iPhone/iPad 横竖屏布局验收和 v5.9 发布验收仍未完成。
- 子 Agent 另指出 GeneralProfile 关闭按钮、档案指标 value、辖下军队读屏、MapEditor 画布 value 和底图说明仍可继续拆成后续小切片。

## v5.8x - 面板控件 accessibility 与 fallback 硬化

完成日期：2026-07-07

核心更新：

- 并发子 Agent 只读扫描指出地图图层选择器、紧凑信息面板分页、将领军令按钮和外交/军议面板缺名 fallback 仍有读屏上下文或 raw id 风险；本轮选择低风险 SwiftUI 面板显示层小切片。
- `RootGameView` 的地图图层选择器补 accessibility label/value/hint，读屏可获知当前图层和切换用途。
- `RootGameView` 的紧凑信息面板分页补 accessibility label/value/hint，读屏可获知当前军队/州府/将领/战报/府库/外交/军议分页。
- `RootGameView` 传给外交面板与军议面板的唐宋州府/方面缺名 fallback 改为“未知州府 / 未命名方面”，不再回退显示 `RegionId` 或 `FrontZoneId` rawValue。
- `GeneralCommandPanelView` 的头像入口、查看档案、固守防线和进攻州府按钮补充更明确的 accessibility label/value/hint；固守/进攻按钮会朗读可用/停用与缺少防区、将领或目标的原因。
- 同步 README、md 大纲、flow 文档、流程图和 v5.8x 阶段记录。

关键文件：

- `WWIIHexV0/UI/RootGameView.swift`
- `WWIIHexV0/UI/GeneralCommandPanelView.swift`
- `README.md`
- `md/plan/plan.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v5.0-唐宋迁移/v5.8x_panel_accessibility_fallback_record.md`
- `update_log.md`

验证结果：

- 按当前规范和用户要求，本机不运行测试、build、Swift parse、Markdown 检查、`git diff --check`、模拟器、截图或 VoiceOver 实机验收。
- 本轮完成后推送到 `origin/main`，等待 GitHub Actions `WWIIHexV0 CI Results` 云端验证和 artifact 核对。

遗留事项：

- 本轮只改 SwiftUI 可读语义和缺名 fallback，不改变棋盘 custom actions、SpriteKit 渲染、命令执行、将领计划、外交/AI 记录、JSON schema、规则系统或 legacy `Faction` 桥。
- 完整逐地块/逐军队 VoiceOver focus order、实机读屏验收、截图验收、iPhone/iPad 横竖屏布局验收和 v5.9 发布验收仍未完成。
- 子 Agent 另指出 Unit/Region inspector 英文 legacy 标签、MapEditor 底图按钮/画布 value 和 UnitTooltip accessibility value 仍可继续拆成后续小切片。

## v5.8w - 主棋盘 VoiceOver 自定义动作硬化

完成日期：2026-07-06

核心更新：

- `RootGameView` 的 `BoardSceneView` 包装层新增 VoiceOver custom actions：攻击下一处红色目标、行军到下一处高亮地块、打开信息面板。
- 棋盘 accessibility value 在唐宋场景下补充选中地块、州府、控制政权、当前已选军队、红色攻击目标数量和高亮行军格数量。
- 攻击/行军 custom action 复用既有 `AppContainer.handleBoardTap(_:)`，不会绕过点击链路；形成命令后仍由 `CommandValidator` / `RuleEngine` 判定。
- 补强 v5.0 总提示词的当前入口文档优先、并发边界、v5.8 小切片、main push、GitHub Actions artifact、Agent C manifest 核对、文档同步和每轮验收口径。
- 同步 README、md 大纲、flow 文档、流程图和 v5.8w 阶段记录。

关键文件：

- `WWIIHexV0/UI/RootGameView.swift`
- `md/prompt/v5.0-唐宋迁移/codex-v5.0-唐宋aiagent历史策略迁移总提示词.md`
- `README.md`
- `md/plan/plan.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v5.0-唐宋迁移/v5.8w_board_accessibility_actions_record.md`
- `update_log.md`

验证结果：

- 按当前规范和用户要求，本机不运行测试、build、Swift parse、Markdown 检查、`git diff --check`、模拟器、截图或 VoiceOver 实机验收。
- 本轮完成后推送到 `origin/main`，等待 GitHub Actions `WWIIHexV0 CI Results` 云端验证和 artifact 核对。

遗留事项：

- 本轮只改主棋盘 SwiftUI 包装层的读屏动作和文档口径，不改变 SpriteKit 渲染、逐 hex focus tree、命令、规则、JSON schema、legacy `Faction` 桥或 MapEditor。
- 完整逐地块/逐军队 VoiceOver focus order、实机读屏验收、截图验收、iPhone/iPad 横竖屏布局验收和 v5.9 发布验收仍未完成。
- 并发子 Agent 只读审查确认后续大风险仍在真实多政权 `PowerId` 数据/schema、`Faction.opponent` / `GamePhase` legacy 桥、MapEditor 导出二元阵营和 AI/兵种/经济二战 raw 兼容名；这些不应混入本轮小切片。

## v5.8f - README / plan / flow 产品定位收口

完成日期：2026-07-06

核心更新：

- 将 README 接手说明从 v0.5 / 阿登原型叙述切到唐宋 v5.x / `jianlong_960_unification` 当前主线，补 v5.8e MapEditor 与 v5.8f docs-only 记录索引。
- 更新 `md/plan/plan.md` 的当前进度快照、v5.8 路线表、v5.3 历史收口命名和 v5.8 后续风险，让 MapEditor 默认路径硬化与文档定位收口进入当前 md 大纲。
- 更新 `md/flow/flow.md` 标题、资料依据和历史 v1.0 / v0.4 分支章节，明确旧分支只作历史兼容附录，当前默认 main-only。
- 更新 `md/flow/flowchart.md` 的 MapEditor 默认数据文件节点，避免误读为 MapEditor 默认读取仍会静默回退阿登资源。
- 新增 `md/prompt/v5.0-唐宋迁移/v5.8f_docs_product_positioning_record.md`，记录本轮 docs-only 范围、并发子 Agent 发现、验证口径和遗留风险。

关键文件：

- `README.md`
- `md/plan/plan.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `update_log.md`
- `md/prompt/v5.0-唐宋迁移/v5.8f_docs_product_positioning_record.md`

验证结果：

- 按用户要求，本机不运行测试、build、Swift parse、Markdown 检查或 `git diff --check`。
- 本轮完成后推送到 `origin/main`，等待 GitHub Actions `WWIIHexV0 CI Results` 云端验证和 artifact 核对。

遗留事项：

- 仍需完整 v5.8 RC 玩家可见残留清单、剩余全局 accessibility、主棋盘逐地块可访问操作路径、截图/布局/完整 VoiceOver 实机验收计划；主游戏 `DataLoader` 默认 fallback 策略已由 v5.8g 收口，accessibility / VoiceOver 可读文案与控件状态提示已由 v5.8t-v5.8u 做首轮收口。
- v0.x 历史段落仍保留在文档中作为技术地基；后续只应在必要处继续压缩，不应删除影响回归理解的历史事实。

## v5.8g - 主游戏默认启动 fallback 硬化

完成日期：2026-07-06

核心更新：

- `DataLoader.loadInitialGameState()` 默认只加载唐宋 960 三件套：`tangsong_jianlong_960_scenario`、`tangsong_jianlong_960_regions`、`tangsong_unit_templates`。
- 唐宋资源缺失、JSON 解码失败、引用校验失败或单位模板缺失时，默认启动进入唐宋错误态并写入中文日志，不再静默回退 `ardennes_v0_scenario`、`ardennes_v02_regions` 或 hardcoded `GameState.initial()`。
- 新增显式 `loadLegacyArdennesGameState()` 保留历史阿登入口；`loadArdennesDataSet()` 和指定 `loadGameState(ardennes...)` 仍可用于 legacy 回归参考。
- `makeDivisions` 不再把任意未知 `templateId` 静默降级成 infantry；只有已知 legacy 模板 id 允许 fallback，唐宋模板错名会抛校验错误。
- 同步 README、md 大纲、flow 文档、流程图和 v5.8e/v5.8f/v5.8g 阶段记录。

关键文件：

- `WWIIHexV0/Data/DataLoader.swift`
- `README.md`
- `md/plan/plan.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v5.0-唐宋迁移/v5.8e_mapeditor_default_path_hardening_record.md`
- `md/prompt/v5.0-唐宋迁移/v5.8f_docs_product_positioning_record.md`
- `md/prompt/v5.0-唐宋迁移/v5.8g_main_game_default_loader_hardening_record.md`
- `update_log.md`

验证结果：

- 按用户要求，本机不运行测试、build、Swift parse、Markdown 检查或 `git diff --check`。
- 本轮完成后推送到 `origin/main`，等待 GitHub Actions `WWIIHexV0 CI Results` 云端验证和 artifact 核对。

遗留事项：

- 唐宋默认资源失败时目前是空地图错误态，后续可设计专门的发布态错误 UI。
- legacy `generals.json` 在唐宋默认将领面板中的残留已由 v5.8h 收口；命令面板 raw validation、inspector raw id、EventLog relatedRecordId 和部分 VoiceOver 文案残留仍建议作为后续 v5.8/v5.9 小切片。

## v5.8h - 唐宋将领注册表默认路径硬化

完成日期：2026-07-06

核心更新：

- 新增 `TangSongCharacterCatalogDefinition` / `TangSongCharacterDefinition` 到兼容 `GeneralData` 的映射，复用已入资源包的 `tangsong_characters.json`。
- `DataLoader.loadGeneralRegistry(for:)` 在 `scenarioId == jianlong_960_unification` 时读取唐宋人物注册表；legacy `generals.json` 保留给阿登历史路径和显式 legacy 调用。
- `DataLoader.assignGenerals` 与 `AppContainer.bootstrap()` 按当前 scenario 加载将领注册表，唐宋默认主路径不再把蒙哥马利、古德里安等 WWII 将领分配到方面防区。
- `GeneralCommandPanelView` 与 `GeneralProfileView` 在唐宋场景下对 rank、biography、skills 增加中文显示桥；即使后续遇到 legacy 将领数据，也不直接显示 `Field Marshal`、英文 biography 或下划线技能 key。
- `GeneralProfileView` 的唐宋头像 accessibility label 改为中文“头像占位”。
- 同步 README、md 大纲、flow 文档、流程图和 v5.8h 阶段记录。

关键文件：

- `WWIIHexV0/Agents/GeneralRegistry.swift`
- `WWIIHexV0/Data/DataLoader.swift`
- `WWIIHexV0/App/AppContainer.swift`
- `WWIIHexV0/UI/GeneralCommandPanelView.swift`
- `WWIIHexV0/UI/GeneralProfileView.swift`
- `README.md`
- `md/plan/plan.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v5.0-唐宋迁移/v5.8h_tangsong_general_registry_hardening_record.md`
- `update_log.md`

验证结果：

- 按用户要求，本机不运行测试、build、Swift parse、Markdown 检查或 `git diff --check`。
- 本轮完成后推送到 `origin/main`，等待 GitHub Actions `WWIIHexV0 CI Results` 云端验证和 artifact 核对。

遗留事项：

- `tangsong_characters.json` 当前是轻量人物表，只映射为兼容 `GeneralData`；后续可扩展更完整的唐宋将领 catalog，但不应恢复唐宋默认读取 legacy `generals.json`。
- 命令面板 `lastCommandMessage` 与 EventLog `relatedRecordId` 已由 v5.8i 首轮收口；Unit/Region inspector raw id、MapDisplayAdapter objectiveStatus 和部分 accessibility 文案仍有玩家可见残留，建议作为后续 v5.8/v5.9 小切片。

## v5.8i - 命令反馈与战报元数据硬化

完成日期：2026-07-06

核心更新：

- `CommandValidationError` 新增 `displayName(isTangSongScenario:)`，唐宋场景下把 `wrongPhase`、`wrongFaction`、`regionNotFound`、`submissionNotReady` 等 raw validation key 显示为中文拒绝原因。
- `RuleEngine` 唐宋拒绝消息使用中文 validation 名称；底层 raw enum case 与 Codable schema 保持不变。
- `AppContainer` 的 AI 回合反馈从 `AI turn completed...` 改为“军议回合已完成”，方面军令反馈从 `General order executed...` 改为“方面军令已执行”，方面军令提交日志使用防区显示名，不再写 directive type / zone raw id。
- `AppContainer.selectionMessage` 唐宋路径写入“已选州府 / 已选地块”，不再把 region raw id 写进交互日志。
- `CommandPanelView` 对 `lastCommandMessage` 增加唐宋显示兜底，减少旧英文 AI/General order 文案和常见 raw validation key 外露。
- `EventLogView` 唐宋 metadata 隐藏 `relatedRecordId`，避免在默认战报路径显示内部记录 id。
- 同步 README、md 大纲、flow 文档、流程图和 v5.8i 阶段记录。

关键文件：

- `WWIIHexV0/Commands/CommandValidation.swift`
- `WWIIHexV0/Rules/RuleEngine.swift`
- `WWIIHexV0/App/AppContainer.swift`
- `WWIIHexV0/UI/CommandPanelView.swift`
- `WWIIHexV0/UI/EventLogView.swift`
- `README.md`
- `md/plan/plan.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v5.0-唐宋迁移/v5.8i_command_feedback_event_metadata_hardening_record.md`
- `update_log.md`

验证结果：

- 按用户要求，本机不运行测试、build、Swift parse、Markdown 检查或 `git diff --check`。
- 本轮完成后推送到 `origin/main`，等待 GitHub Actions `WWIIHexV0 CI Results` 云端验证和 artifact 核对。

遗留事项：

- Unit/Region inspector 仍有 region/theater/frontZone raw id 与英文 objectiveStatus 残留，已由并发子 Agent 定位，建议下一轮 v5.8j 小切片处理。
- 部分交互日志写入端仍可能传入英文 fallback；本轮只处理命令反馈、AI/方面军令和选中州府高频路径。

## v5.8j - 检查面板 raw id 与目标状态硬化

完成日期：2026-07-06

核心更新：

- `MapDisplayAdapter` 为 `RegionInspectorState` 补 selected hex / region 的动态方面和防区显示名，为 `UnitInspectorStrategicState` 补州府、动态方面、防区和粮源显示名。
- `MapDisplayAdapter.inspectorState` 的目标状态改为场景感知：唐宋路径显示“无目标”或“某政权控制”，不再把英文 `None` / `controlled` 直接传给州府详情。
- `UnitInspectorView` 在唐宋路径优先显示运行态州府、动态方面、防区名称；缺名时显示“未知州府 / 未命名方面 / 未命名防区”，不把 raw id 当默认玩家文案。
- `UnitInspectorView.frontLineSummary` 在唐宋路径显示“相关战线 N 条”，粮道摘要使用州府名或“补给源”兜底，不直接展示 `FrontLineId` 或 supply source id。
- `RegionInspectorView` 在唐宋路径优先显示 selected hex 和州府的动态方面 / 防区名称；缺名时使用中文 fallback。
- 同步 README、md 大纲、flow 文档、流程图和 v5.8j 阶段记录。

关键文件：

- `WWIIHexV0/SpriteKit/MapDisplayAdapter.swift`
- `WWIIHexV0/UI/UnitInspectorView.swift`
- `WWIIHexV0/UI/RegionInspectorView.swift`
- `README.md`
- `md/plan/plan.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v5.0-唐宋迁移/v5.8j_inspector_raw_id_hardening_record.md`
- `update_log.md`

验证结果：

- 按用户要求，本机不运行测试、build、Swift parse、Markdown 检查或 `git diff --check`。
- 本轮完成后推送到 `origin/main`，等待 GitHub Actions `WWIIHexV0 CI Results` 云端验证和 artifact 核对。

遗留事项：

- 本轮只处理军队/州府检查面板的 raw id 与目标状态显示；完整 accessibility、截图/布局验收和其他默认主路径英文/raw id 残留仍待后续 v5.8/v5.9 小切片。
- raw id 字段仍保留在 inspector state 和底层 schema 中，供 legacy 显示、排序、调试和规则使用；唐宋路径仅改变玩家可见显示桥。

## v5.8k - 命令面板与战报 raw 英文兜底硬化

完成日期：2026-07-06

核心更新：

- 并发子 Agent 只读扫描 UI/SpriteKit 与 Rules/App/Turn 残留后，选择重叠度低的命令反馈与战报兜底作为本轮小切片。
- `TangSongEventLogMessage` 改为模块内可复用，`CommandPanelView` 的唐宋命令反馈兜底复用同一显示桥，减少命令面板直出英文诊断或 raw validation key。
- `EventLogView` 补退却路线、被围损耗、玩家方面军令诊断、州府归属变化和动态方面变更等常见英文事件映射。
- `EventLogView` 在唐宋显示桥处理后若仍含拉丁字母，降级为中文“战报已更新；原始记录留在调试日志中。”，不把未归档 raw 英文/内部 key 直接展示给玩家。
- `RootGameView.nextActionHint` 的已行动提示改为“各方军议推进”，不再显示 `AI`。
- 同步 README、md 大纲、flow 文档、流程图和 v5.8k 阶段记录。

关键文件：

- `WWIIHexV0/UI/EventLogView.swift`
- `WWIIHexV0/UI/CommandPanelView.swift`
- `WWIIHexV0/UI/RootGameView.swift`
- `README.md`
- `md/plan/plan.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v5.0-唐宋迁移/v5.8k_command_event_raw_english_fallback_record.md`
- `update_log.md`

验证结果：

- 按用户要求，本机不运行测试、build、Swift parse、Markdown 检查或 `git diff --check`。
- 本轮完成后推送到 `origin/main`，等待 GitHub Actions `WWIIHexV0 CI Results` 云端验证和 artifact 核对。

遗留事项：

- 本轮只处理玩家可见 UI 兜底，不改事件写入端；`SupplyRules`、`CommandExecutor`、`StrategicStateSynchronizer`、`TurnManager` 等源头仍可能写入英文日志，后续可逐步源头唐宋化或改结构化 event payload。
- AI 面板 diagnostics/raw JSON、GeneralCommandPanelView 已拟军令 raw id、DiplomacyPanelView 数据名 Latin guard、macOS 菜单和 SpriteKit 空地图提示仍建议作为后续 v5.8/v5.9 小切片。

## v5.8l - 将领计划摘要与固定英文 UI 硬化

完成日期：2026-07-06

核心更新：

- 并发子 Agent 只读扫描指出将领“已拟军令”仍可展示 planned operation raw id，SpriteKit 空棋盘、macOS 菜单和通用信息按钮仍有固定英文。
- `GeneralCommandPanelView` 新增 `regionDisplayName` / `zoneDisplayName` 只读查找闭包；`RootGameView` 传入运行态州府和方面名称。
- `GeneralCommandPanelView.operationSummary` 在唐宋路径优先显示目标州府、来源州府或方面名称，缺名时显示“未命名州府 / 未命名方面”，不再默认展示 `targetRegionId/sourceRegionId/zoneId.rawValue`。
- `BoardScene` 空棋盘标题由 `Hex Board` 改为“舆图加载中”。
- macOS 菜单由 `Game / End Turn / New Game` 改为“军务 / 结束回合 / 重新开局”。
- `InfoPanelToggle` 固定 `[ INFO ]` 改为“详情”，并补中文 accessibility label。
- 同步 README、md 大纲、flow 文档、流程图和 v5.8l 阶段记录。

关键文件：

- `WWIIHexV0/UI/GeneralCommandPanelView.swift`
- `WWIIHexV0/UI/RootGameView.swift`
- `WWIIHexV0/SpriteKit/BoardScene.swift`
- `WWIIHexV0/App/WWIIHexV0MacApp.swift`
- `WWIIHexV0/UI/InfoPanelToggle.swift`
- `README.md`
- `md/plan/plan.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v5.0-唐宋迁移/v5.8l_general_plan_fixed_english_ui_record.md`
- `update_log.md`

验证结果：

- 按用户要求，本机不运行测试、build、Swift parse、Markdown 检查或 `git diff --check`。
- 本轮完成后推送到 `origin/main`，等待 GitHub Actions `WWIIHexV0 CI Results` 云端验证和 artifact 核对。

遗留事项：

- 本轮未处理 AI 面板 `mandateIntent/courtPolicy/summary/diagnostics/rawJSON` 原文风险，未处理外交面板国家/集团名 Latin guard 与 ASCII 连接符，建议作为后续 v5.8/v5.9 小切片。
- 将领面板仍直接显示 `zone.name`、`division.name`、`targetRegion.name`；当前唐宋默认数据为中文名，若未来混入英文数据，仍需要更完整的名称清洗或本地化 fallback。

## v5.8m - 外交 Latin 名称与 ASCII 连接符硬化

完成日期：2026-07-06

核心更新：

- 并发子 Agent 只读扫描指出 `DiplomacyPanelView` 的国家名、集团名、关系连接符、归附连接符和列表标点仍可在唐宋路径外露 Latin/ASCII 读法。
- `DiplomacyPanelView` 新增国家显示 helper：唐宋路径先按 `CountryId` 映射宋、北汉、辽边境压力、南唐、吴越、后蜀等名称；遇到 legacy `germany/united_states/united_kingdom/belgium` 时给中文 fallback；其他含 Latin 或等于 raw id 的名称按 faction 显示为宋或割据政权。
- `DiplomacyPanelView` 新增集团显示 helper：唐宋路径按 `DiplomaticBlocId` 映射宋朝廷、抗宋同盟、南方割据诸国；legacy `axis/allied_coalition` 也给中文 fallback。
- 关系行从 `甲 - 乙` 改为“甲 与 乙”，归附记录从 `甲 -> 乙` 改为“甲 招抚 乙”。
- 国家副标题分隔从 ASCII `/` 改为“·”；归附州府列表和君主目标列表从 `, ` 改为“、”。
- 同步 README、md 大纲、flow 文档、流程图和 v5.8m 阶段记录。

关键文件：

- `WWIIHexV0/UI/DiplomacyPanelView.swift`
- `README.md`
- `md/plan/plan.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v5.0-唐宋迁移/v5.8m_diplomacy_latin_ascii_hardening_record.md`
- `update_log.md`

验证结果：

- 按用户要求，本机不运行测试、build、Swift parse、Markdown 检查或 `git diff --check`。
- 本轮完成后推送到 `origin/main`，等待 GitHub Actions `WWIIHexV0 CI Results` 云端验证和 artifact 核对。

遗留事项：

- 本轮未处理 `AgentPanelView` 的 `mandateIntent/courtPolicy/summary/diagnostics/rawJSON` 原文风险，建议下一轮单独收口 AI 面板玩家态 raw 文本。
- 外交面板仍只做显示层清洗，不改变底层国家/集团 id、关系记录、归附记录或外交规则。

## v5.8n - AI 面板原始文本兜底硬化

完成日期：2026-07-06

核心更新：

- 并发子 Agent 只读扫描指出 `AgentPanelView` 的重点防区、军议解释字段、战况摘要、diagnostics、errors、raw JSON、方面军令摘要和未知命令标题仍可能在唐宋路径外露 Latin、JSON、schema key、raw id 或 ASCII 分隔符。
- `AgentPanelView` 唐宋路径对 `summary`、`strategicIntent`、`mandateIntent`、`courtPolicy`、`contextSummary` 和未知命令标题增加原始文本风险判断；遇到 Latin、JSON 痕迹、schema key 或旧英文 fallback 时显示中文摘要。
- 唐宋路径不再展开显示 `WarDirectiveRecord.diagnostics`、`AgentDecisionRecord.errors` 和 `rawJSON` 原文，改为显示计数或“军议原文已记录”提示，原始记录仍保留在既有数据结构中供调试追溯。
- 重点防区统一走运行态防区显示桥；方面军令摘要和州府列表使用“·”“、”等中文连接符，减少 ASCII 分隔符残留。
- 同步 README、md 大纲、flow 文档、流程图和 v5.8n 阶段记录。

关键文件：

- `WWIIHexV0/UI/AgentPanelView.swift`
- `README.md`
- `md/plan/plan.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v5.0-唐宋迁移/v5.8n_ai_panel_raw_text_fallback_record.md`
- `update_log.md`

验证结果：

- 按用户要求，本机不运行测试、build、Swift parse、Markdown 检查或 `git diff --check`。
- 本轮完成后推送到 `origin/main`，等待 GitHub Actions `WWIIHexV0 CI Results` 云端验证和 artifact 核对。

遗留事项：

- 本轮只改 AI 面板只读显示桥，不改变 `AgentDecisionRecord`、`WarDirectiveRecord`、`TheaterDirectiveEnvelope`、raw JSON 存储、AI 决策、编译器、执行器、规则或 Codable schema。
- 完整真 LLM 输出本地化、结构化 event payload、截图/布局/VoiceOver 和发布级 UI 验收仍未完成。

## v5.8o - 固定英文与 ASCII UI 硬化

完成日期：2026-07-06

核心更新：

- 并发子 Agent 只读扫描指出 `GeneralCommandPanelView` 和 `RegionInspectorView` 仍有唐宋玩家态 ASCII 分隔符残留。
- `GeneralCommandPanelView` 唐宋路径的将领副标题从 `rank / style` 改为“rank · style”，已拟军令摘要从“动作 / 目标”改为“动作：目标”。
- `RegionInspectorView` 唐宋路径的地块坐标从 `q,r` 改为“第 q 列，第 r 行”，目标列表和军队列表改用“、”，围城城防改用“／”。
- 同步 README、md 大纲、flow 文档、流程图和 v5.8o 阶段记录。

关键文件：

- `WWIIHexV0/UI/GeneralCommandPanelView.swift`
- `WWIIHexV0/UI/RegionInspectorView.swift`
- `README.md`
- `md/plan/plan.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v5.0-唐宋迁移/v5.8o_accessibility_fixed_english_ui_record.md`
- `update_log.md`

验证结果：

- 按用户要求，本机不运行测试、build、Swift parse、Markdown 检查或 `git diff --check`。
- 本轮完成后推送到 `origin/main`，等待 GitHub Actions `WWIIHexV0 CI Results` 云端验证和 artifact 核对。

遗留事项：

- 本轮只改将领面板与州府详情面板的玩家可见显示桥，不改变 `PlayerPlannedOperation`、`RegionInspectorState`、`SiegeRecord`、命令、围城规则、AI 决策、事件写入或 Codable schema。
- 这不是完整 VoiceOver 实机验收、截图验收、iPhone/iPad 横竖屏布局验收或 v5.9 发布验收；全局 accessibility 和其他玩家可见残留仍需后续切片继续收口。

## v5.8s - MapEditor raw UI 硬化

完成日期：2026-07-06

核心更新：

- 并发子 Agent 只读扫描指出 MapEditor 默认工具路径仍有 `JSON` 技术词、`.json` 文件名、`q,r` 坐标、底图完整路径、导出校验 raw id 和底层错误信息直出风险。
- `HexCoord.mapEditorDisplayName` 新增 MapEditor 中文坐标读法，信息面板、状态栏、扩展地块反馈和导出错误改用“第 q 列，第 r 行”。
- MapEditor 资源区按钮改为“生成资源预览”，默认资源说明改为“建隆元年剧本 / 州府数据”，覆盖/导出状态不再默认显示 `.json` 文件名或 JSON 技术词。
- 底图区只显示底图文件名，不在默认侧栏直出完整本机路径。
- `MapEditorExportError` 与 `MapEditorGameResourceBridgeError` 的默认描述改为中文包装，不再默认暴露 `RegionId.rawValue`、`terrain.rawValue` 或底层英文编码错误。
- 自动州城名、粮仓 fallback 和默认州府/方面名继续收口为中文读法。
- 同步 README、md 大纲、flow 文档、流程图和 v5.8s 阶段记录。

关键文件：

- `MapEditor/MapEditorDocument.swift`
- `MapEditor/MapEditorView.swift`
- `MapEditor/MapEditorViewModel.swift`
- `MapEditor/MapEditorExporter.swift`
- `MapEditor/MapEditorGameResourceBridge.swift`
- `README.md`
- `md/plan/plan.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v5.0-唐宋迁移/v5.8s_mapeditor_raw_ui_hardening_record.md`
- `update_log.md`

验证结果：

- 按用户要求，本机不运行测试、build、Swift parse、Markdown 检查或 `git diff --check`。
- 本轮完成后推送到 `origin/main`，等待 GitHub Actions `WWIIHexV0 CI Results` 云端验证和 artifact 核对。

遗留事项：

- 本轮只改 MapEditor 玩家/编辑器可见显示桥和错误包装，不改变导出的 JSON schema、`Faction.allies/germany`、`GamePhase.alliedPlayer`、`RegionId`、`TheaterId`、主游戏 `DataLoader`、规则系统、AI 决策或 Codable raw 值。
- MapEditor 仍保留底层 `.json` 输出、legacy faction/phase raw 值、`region_#` / `theater_#` 内部 id 和测试夹具历史命名；这些属于后续 schema / 数据驱动迁移范围。
- 这不是结构化 event payload、真 LLM 输出本地化、完整 VoiceOver 实机、截图、横竖屏布局或 v5.9 发布验收。

## v5.8t - accessibility / VoiceOver 可读文案硬化

完成日期：2026-07-07

核心更新：

- 并发子 Agent 只读扫描指出主游戏信息面板切换、通用详情按钮、将领头像占位、MapEditor 底图偏移输入框和编辑画布仍有可读语义不足；主棋盘逐 hex 可访问操作路径仍是较大后续项。
- `RootGameView` 信息面板按钮补 accessibility label/value/hint，棋盘 accessibility value 从当前 `selectedHex` / `selectedRegionId` 派生“已选中第 q 列，第 r 行 / 州府名”。
- `InfoPanelToggle` 通用“详情”按钮补“已展开 / 已收起”和展开/收起提示。
- `GeneralProfileView` 头像占位改为装饰性元素，不再朗读“头像占位 / portrait placeholder”。
- MapEditor 底图偏移输入框补“底图横向偏移 / 底图纵向偏移”可访问标签，地图编辑画布补中文 accessibility label/hint。
- 同步 README、md 大纲、flow 文档、流程图和 v5.8t 阶段记录。

关键文件：

- `WWIIHexV0/UI/RootGameView.swift`
- `WWIIHexV0/UI/InfoPanelToggle.swift`
- `WWIIHexV0/UI/GeneralProfileView.swift`
- `MapEditor/MapEditorView.swift`
- `README.md`
- `md/plan/plan.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v5.0-唐宋迁移/v5.8t_accessibility_voiceover_text_hardening_record.md`
- `update_log.md`

验证结果：

- 按用户要求，本机不运行测试、build、Swift parse、Markdown 检查、`git diff --check`、模拟器、截图或 VoiceOver 实机验收。
- 本轮完成后推送到 `origin/main`，等待 GitHub Actions `WWIIHexV0 CI Results` 云端验证和 artifact 核对。

遗留事项：

- 本轮只改 SwiftUI 可读语义和文案，不改变 SpriteKit 地图交互、逐 hex focus、focus order、hit target、布局、规则、导出 JSON schema 或 Codable raw 值。
- 主棋盘每个地块/军队/可攻击目标的 VoiceOver 可聚焦与可操作路径仍未实现；完整 VoiceOver 实机验收、截图验收、iPhone/iPad 横竖屏布局验收和 v5.9 发布验收仍未完成。

## v5.8v - MapEditor 错误与输入可访问性硬化

完成日期：2026-07-07

核心更新：

- 并发子 Agent 只读扫描指出 MapEditor 读取/覆盖默认资源和生成资源预览时仍可能用 `String(describing: error)` 把 raw `Error`、解码描述、系统域或路径暴露给玩家/读屏；本轮选择低风险 MapEditor 显示与输入语义小切片。
- `MapEditorViewModel` 新增错误显示包装，已知 `MapEditorExportError` / `MapEditorGameResourceBridgeError` 继续显示中文说明，其他读取、覆盖和资源预览失败统一落到中文 fallback。
- MapEditor 新建州府、方面和军队名称默认改为空输入，继续由既有自动命名生成“州府 N / 方面 N / 军 N”，避免把“新州府 / 新方面 / 军”等示例文字误写入真实草案。
- `MapEditorView` 为新建州府、新建方面、新建军队、选中地块州府/方面编辑框补充上下文 accessibility label/hint。
- MapEditor 错误区显示和读屏都补“错误：”前缀，减少状态文本与错误文本混淆。
- 同步 README、md 大纲、flow 文档、流程图和 v5.8v 阶段记录。

关键文件：

- `MapEditor/MapEditorViewModel.swift`
- `MapEditor/MapEditorView.swift`
- `README.md`
- `md/plan/plan.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v5.0-唐宋迁移/v5.8v_mapeditor_error_input_accessibility_record.md`
- `update_log.md`

验证结果：

- 按用户要求，本机不运行测试、build、Swift parse、Markdown 检查、`git diff --check`、模拟器、截图或 VoiceOver 实机验收。
- 本轮完成后推送到 `origin/main`，等待 GitHub Actions `WWIIHexV0 CI Results` 云端验证和 artifact 核对。

遗留事项：

- 本轮只改 MapEditor 显示、输入默认值和 SwiftUI 可读语义，不改变导出 JSON schema、默认资源路径、`Faction.allies/germany`、`GamePhase.alliedPlayer`、`RegionId`、`TheaterId`、主游戏规则、AI 决策或 Codable raw 值。
- 主棋盘每个地块/军队/可攻击目标的 VoiceOver 可聚焦与可操作路径仍未实现；完整 VoiceOver 实机验收、截图验收、iPhone/iPad 横竖屏布局验收和 v5.9 发布验收仍未完成。

## v5.8u - accessibility 控件状态提示硬化

完成日期：2026-07-07

核心更新：

- 并发子 Agent 只读扫描指出军令、府库、亲征/观战和统一目标锚点按钮在禁用或改变权限时缺少读屏原因；本轮选择低风险 SwiftUI modifier 小切片，不做主棋盘逐 hex focus 大改。
- `CommandPanelView` 为固守、可退、整补、围城、修城、解围、招降、招抚和结束回合按钮补充 accessibility value/hint，唐宋路径会朗读“可用 / 停用”以及观战、阶段、未选军队、已行动或缺目标等原因。
- `EconomyPanelView` 军备按钮补充 accessibility value/hint，把费用、建造回合、观战模式、当前阶段不可下令和资源不足原因绑定到按钮读法。
- `RootGameView` 亲征选择与观战切换补充当前值和提示，说明切换亲征政权会清空选择/高亮，观战会停用军令和府库命令。
- `HUDView` 统一目标锚点按钮补充“查看目标”可访问标签、已据/待取状态和地图聚焦提示。
- 同步 README、md 大纲、flow 文档、流程图和 v5.8u 阶段记录。

关键文件：

- `WWIIHexV0/UI/CommandPanelView.swift`
- `WWIIHexV0/UI/EconomyPanelView.swift`
- `WWIIHexV0/UI/RootGameView.swift`
- `WWIIHexV0/UI/HUDView.swift`
- `README.md`
- `md/plan/plan.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v5.0-唐宋迁移/v5.8u_accessibility_control_state_hints_record.md`
- `update_log.md`

验证结果：

- 按用户要求，本机不运行测试、build、Swift parse、Markdown 检查、`git diff --check`、模拟器、截图或 VoiceOver 实机验收。
- 本轮完成后推送到 `origin/main`，等待 GitHub Actions `WWIIHexV0 CI Results` 云端验证和 artifact 核对。

遗留事项：

- 本轮只改 SwiftUI 控件可读语义，不改变命令执行、经济规则、胜利目标、地图聚焦逻辑、SpriteKit 地图交互、逐 hex focus、focus order、hit target、布局、JSON schema 或 Codable raw 值。
- 主棋盘每个地块/军队/可攻击目标的 VoiceOver 可聚焦与可操作路径仍未实现；完整 VoiceOver 实机验收、截图验收、iPhone/iPad 横竖屏布局验收和 v5.9 发布验收仍未完成。

## v5.8r - 胜利、粮道与军议摘要显示硬化

完成日期：2026-07-06

核心更新：

- 并发子 Agent 只读扫描指出 HUD / EventLog / UnitInspector / Economy 仍有唐宋路径下的 ASCII `/`、`,`、`q,r` 坐标和上游军议 raw 文本直出风险。
- `VictoryObjectiveProgress.summary`、HUD 统一/天命进度和战报评分估算改用“／”，减少胜利目标与天命门槛中的 ASCII 分隔符。
- `EconomyResources.summary(isTangSongScenario:)` 唐宋路径改用“、”连接丁口、钱帛、粮草，府库军备成本行同步受益。
- `UnitInspectorView` 粮道近源坐标与 `EventLogView` 旧英文 `Selected hex` 日志显示桥改用“第 q 列，第 r 行”。
- `EventLogView` 本回合军议摘要遇到 Latin、JSON 痕迹、schema key 或 raw id 风险时，降级为“军议摘要已形成 / 已形成方面军令”。
- 同步 README、md 大纲、flow 文档、流程图和 v5.8r 阶段记录。

关键文件：

- `WWIIHexV0/Core/EconomyState.swift`
- `WWIIHexV0/Rules/VictoryRules.swift`
- `WWIIHexV0/UI/HUDView.swift`
- `WWIIHexV0/UI/EventLogView.swift`
- `WWIIHexV0/UI/UnitInspectorView.swift`
- `README.md`
- `md/plan/plan.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v5.0-唐宋迁移/v5.8r_victory_supply_summary_hardening_record.md`
- `update_log.md`

验证结果：

- 按用户要求，本机不运行测试、build、Swift parse、Markdown 检查或 `git diff --check`。
- 本轮完成后推送到 `origin/main`，等待 GitHub Actions `WWIIHexV0 CI Results` 云端验证和 artifact 核对。

遗留事项：

- 本轮只改主游戏玩家可见显示桥，不改变胜利规则、经济规则、补给规则、`AgentDecisionRecord`、`WarDirectiveRecord`、事件写入职责、AI 决策或 Codable raw 值。
- MapEditor 默认可见 raw 文件名、`q,r` 坐标、`JSON` 文案和导出错误 raw id 已由 v5.8s 做首轮收口；底层 JSON schema 与 legacy raw 值仍留后续迁移。
- 这不是结构化 event payload、真 LLM 输出本地化、完整 VoiceOver 实机、截图、横竖屏布局或 v5.9 发布验收。

## v5.8q - AppContainer 源头反馈中文化

完成日期：2026-07-06

核心更新：

- 并发子 Agent 与主线程只读扫描指出 `AppContainer` 仍会在唐宋路径写入英文交互反馈、ASCII 标点、`enemy/non-hostile` 关系标签和 `q,r` 地块坐标。
- `AppContainer.submit(_:)` 唐宋路径的 `lastCommandMessage` 与交互日志改为动作级中文摘要，规则拒绝原因继续读取 `CommandValidationError.displayName(isTangSongScenario:)`。
- 固守、准许退却、整补、围城、修城、解围、招降、招抚、将领军令和府库观战拒绝的本地 guard 反馈在唐宋路径改为中文写入，legacy 英文 fallback 保留。
- 观战查看军队、选中本方/敌方/非敌对军队和选中地块坐标改为唐宋读法；地块坐标写为“第 q 列，第 r 行”。
- 同步 README、md 大纲、flow 文档、流程图和 v5.8q 阶段记录。

关键文件：

- `WWIIHexV0/App/AppContainer.swift`
- `README.md`
- `md/plan/plan.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v5.0-唐宋迁移/v5.8q_appcontainer_source_feedback_localization_record.md`
- `update_log.md`

验证结果：

- 按用户要求，本机不运行测试、build、Swift parse、Markdown 检查或 `git diff --check`。
- 本轮完成后推送到 `origin/main`，等待 GitHub Actions `WWIIHexV0 CI Results` 云端验证和 artifact 核对。

遗留事项：

- 本轮只覆盖 `AppContainer` 常见玩家交互反馈写入端，不改变 `Command`、`CommandResult`、`GameLogEntry`、`CommandValidator`、`RuleEngine`、`WarCommandExecutor`、AI 决策或 Codable schema。
- 这不是结构化 event payload、全项目写入端本地化、真 LLM 输出本地化、完整 VoiceOver 实机、截图、横竖屏布局或 v5.9 发布验收。

## v5.8p - 兵力、粮道与数值标记 ASCII UI 硬化

完成日期：2026-07-06

核心更新：

- 并发子 Agent 与主线程只读扫描指出唐宋路径仍有兵力、粮道、城防、回合、评分、战报 metadata 和军备成本中的 ASCII `/`、`|`、` - `、` / `、`q,r` 残留。
- `EconomyPanelView` 唐宋军备成本行从 `耗 ... | N 回合` 改为中文逗号读法。
- `HUDView` 唐宋回合进度改用“／”；`EventLogView` 唐宋胜负评分改用“／”，战报 metadata 改用中文分号，方面军议摘要改用“：”。
- `UnitInspectorView` 唐宋军队详情地块坐标改为“第 q 列，第 r 行”，兵力与粮道成本从 ASCII `/` 改为“／”，编成和多状态列表改用“、”。
- `UnitTooltipView`、`GeneralProfileView` 和 `UnitNode` 唐宋路径的兵力显示改用“／”，tooltip accessibility label 同步使用同一读法。
- `MapDisplayAdapter` 唐宋地图围城城防与粮道 overlay 标签改用“／”。
- 同步 README、md 大纲、flow 文档、流程图和 v5.8p 阶段记录。

关键文件：

- `WWIIHexV0/UI/EconomyPanelView.swift`
- `WWIIHexV0/UI/HUDView.swift`
- `WWIIHexV0/UI/EventLogView.swift`
- `WWIIHexV0/UI/UnitInspectorView.swift`
- `WWIIHexV0/UI/UnitTooltipView.swift`
- `WWIIHexV0/UI/GeneralProfileView.swift`
- `WWIIHexV0/SpriteKit/UnitNode.swift`
- `WWIIHexV0/SpriteKit/MapDisplayAdapter.swift`
- `README.md`
- `md/plan/plan.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v5.0-唐宋迁移/v5.8p_numeric_marker_ascii_hardening_record.md`
- `update_log.md`

验证结果：

- 按用户要求，本机不运行测试、build、Swift parse、Markdown 检查或 `git diff --check`。
- 本轮完成后推送到 `origin/main`，等待 GitHub Actions `WWIIHexV0 CI Results` 云端验证和 artifact 核对。

遗留事项：

- 本轮只改 UI 与地图标签的玩家可见显示桥，不改变 `Division`、`SupplyRouteSummary`、`SiegeOverlayState`、生产、补给、围城、命令、AI 决策、事件写入或 Codable schema。
- 这不是完整 accessibility、VoiceOver 实机、截图、横竖屏布局、资源授权或 v5.9 发布验收；全局玩家可见残留仍需继续扫描。

## v0 - 六角格测试板

完成日期：2026-06-14 至 2026-06-15

核心更新：

- 建立 iOS 二战回合制战棋原型，技术栈为 Swift + SwiftUI + SpriteKit。
- 创建阿登测试战场，使用 11x9 左右的 axial hex 地图。
- 落地地形、移动、战斗、占领、补给、包围、胜利条件、回合流程。
- 建立德军 MockAI 将领 `guderian`，按局势摘要生成结构化命令，再经规则系统校验执行。
- 建立 SwiftUI HUD、命令面板、事件日志、单位详情和 SpriteKit 六角格渲染。

关键系统：

- `Core/HexCoord.swift`
- `Core/MapState.swift`
- `Core/Division.swift`
- `Rules/RuleEngine.swift`
- `Rules/MovementRules.swift`
- `Rules/CombatRules.swift`
- `Rules/SupplyRules.swift`
- `Rules/VictoryRules.swift`
- `SpriteKit/BoardScene.swift`
- `UI/RootGameView.swift`

备注：

- v0 的核心边界是“可玩测试板”，不做空军、海军、经济、生产、外交、多级指挥链和真实 LLM。
- 后续所有版本都必须保留 hex 作为战术层权威。

## v0.1 - strength、撤退与补员

完成日期：2026-06-15 前后

核心更新：

- `Division` 战斗模型升级为 `strength/maxStrength`，保留 `hp/maxHP` 兼容。
- 战斗伤害从 HP 语义转向兵力语义，后续明确不恢复 organization。
- 引入撤退状态与 `RetreatMode`：`retreatable` 可自动撤退，`hold` 获得防御加成。
- 撤退失败会施加额外惩罚；无补给、包围会影响战斗与回合损耗。
- `resupply/rest` 能恢复兵力。
- UI 和日志补充 Strength、Retreating、combat/retreat/reinforce/encircle/supply 分类。

关键系统：

- `Core/Division.swift`
- `Rules/CombatRules.swift`
- `Rules/SupplyRules.swift`
- `Rules/RuleEngine.swift`
- `UI/UnitInspectorView.swift`
- `UI/HUDView.swift`

备注：

- v0.1 最终模型只看兵力，不引入 organization。
- `HOLD` 防御约 +20%，`RETREATABLE` 在单次损失比例达到阈值时自动撤退。

## Agent D - AI/Agent 决策管线

完成日期：2026-06-15

核心更新：

- 打捞并恢复早期 Agent D 管线，修复此前异常删除。
- 建立 `DecisionProvider` 协议，为 MockAI 与未来本地 LLM 共用。
- 建立 `AgentContext` / `AgentContextBuilder`，只传 Codable 摘要，不暴露 UI/SpriteKit 对象。
- 建立 `AgentDecisionEnvelope` / `AgentOrder` JSON schema。
- 建立 parser、command mapper、decision record 与 AI 决策展示面板。
- `TurnManager` 负责德军 AI 回合编排，`AppContainer.runAIIfNeeded()` 接入启动流程。

关键系统：

- `Agents/DecisionProvider.swift`
- `Agents/AgentContexts.swift`
- `Agents/AgentDecision.swift`
- `Agents/AgentDecisionParser.swift`
- `Agents/AgentCommandMapper.swift`
- `Agents/MockAIClient.swift`
- `Agents/LocalLLMDecisionProvider.swift`
- `Turn/TurnManager.swift`
- `UI/AgentPanelView.swift`
- `Tests/AgentPipelineTests.swift`

备注：

- Agent D 是重要历史管线，但 v0.37 后默认战争 AI 主路径已改为 ZoneDirective。
- 后续不得删除 Legacy Agent D；只能隔离、退役或作为回归参考。

## v0.2 - Region 战略层叠加

完成日期：2026-06-15 至 2026-06-16

核心更新：

- 明确废弃旧版“用 province 替换 hex”的方案，改为 Region 战略层叠加。
- `MapState` 同时持有 hex 与 region：`regions`、`hexToRegion`、`regionEdges`。
- 新增 `RegionId`、`RegionNode`、`RegionEdge`、`RegionGraph` 与校验错误类型。
- 建立阿登 v0.2 省份数据：17 省、41 边、99 hex 全覆盖、零重叠。
- `DataLoader` 加载 `ardennes_v02_regions.json` 并反向填充 `HexTile.regionId`。
- 新增 Region 规则层：移动、战斗、占领、补给、视野、胜利、pathfinder、rule system。
- 新增 `RegionCommand`、`CommandIntentAdapter`、AgentOrder schema v2，支持 region 命令与 hex 命令互转。
- UI 增加 `MapDisplayAdapter`、Region overlay 与 `RegionInspectorView`，hex 仍为唯一渲染对象。

关键系统：

- `Core/Region.swift`
- `Core/MapState.swift`
- `Data/RegionDataSet.swift`
- `Data/ardennes_v02_regions.json`
- `Rules/RegionRuleSystem.swift`
- `Rules/RegionMovementRules.swift`
- `Rules/RegionCombatRules.swift`
- `Rules/RegionOccupationRules.swift`
- `Rules/RegionSupplyRules.swift`
- `Rules/RegionVisibilityRules.swift`
- `Rules/RegionVictoryRules.swift`
- `Commands/RegionCommand.swift`
- `Commands/CommandIntentAdapter.swift`
- `SpriteKit/MapDisplayAdapter.swift`
- `UI/RegionInspectorView.swift`

验证记录：

- v0.2 Agent 6 验收：132 tests, 0 failures。
- 关键覆盖：RegionGraph、ArdennesV02Data、Region rules、Agent region command、MapDisplayAdapter、Board interaction、RuleEngineCore。

备注：

- v0.2 达成 Hex x Region 双轨架构稳定状态。
- 技术债：中立省 owner/controller 为 null 时仍回退到 `.allies`，因为 `Faction` 暂无 neutral case。

## v0.21 - 界面优化与重置流程

完成日期：2026-06-16

核心更新：

- 新增 `InfoPanelToggle`，信息面板默认收起，通过 `[ INFO ]` 展开。
- 新增 `UnitTooltipView`，右下角固定展示选中单位摘要。
- 新增 `NewGameButton` 与 `AppContainer.resetGame()`，支持重载初始地图/单位/Region 并清空选择与日志。
- `RootGameView` 在常规、竖屏、横屏布局中接入 Info toggle 与单位 tooltip。
- 任务 6 zoom 按设计跳过，保留固定放大 hex 与 camera drag。

关键系统：

- `UI/InfoPanelToggle.swift`
- `UI/UnitTooltipView.swift`
- `UI/NewGameButton.swift`
- `UI/RootGameView.swift`
- `UI/HUDView.swift`
- `App/AppContainer.swift`

验证记录：

- 135 tests, 0 failures。
- `swiftc -parse`、`plutil -lint`、`git diff --check` 通过。
- 模拟器烟测通过，截图记录为 `/tmp/wwiihex_v021_smoke2.png`。

## v0.31 - Theater 战区系统

完成日期：2026-06-17

核心更新：

- 新增战区数据结构：`TheaterId`、`TheaterNode`、`TheaterState`、支援请求和 AI 摘要。
- 新增 `TheaterSystem`，从 v0.2 Region 生成四个固定战区。
- 建立 `hex -> region -> theater` 映射与控制比例/胜利点聚合。
- 引入 70% 控制阈值，用于战区扩张正式化、退役和单位池重分配。
- 在 `GameState` 中加入 `theaterState`，兼容旧存档解码。
- `DataLoader` 在加载 Region 后自动生成 v0.31 四战区。

关键系统：

- `Core/Theater.swift`
- `Rules/TheaterSystem.swift`
- `Core/GameState.swift`
- `Data/DataLoader.swift`
- `Tests/TheaterSystemTests.swift`

验证记录：

- `plutil -lint WWIIHexV0.xcodeproj/project.pbxproj` 通过。
- 全量测试：146 tests, 0 failures。

备注：

- v0.31 不做 FrontLine、自动布防、攻势规划、LLM 决策、UI 重构或战斗/hex 规则改动。

## v0.32 - FrontLine 前线层

完成日期：2026-06-17

核心更新：

- 新增前线模型：`FrontLine`、`FrontSegment`、`RegionFrontState`、`FrontLineState`。
- 新增 `FrontLineManager`，支持 turn rebuild 与 event-driven dirty update。
- 建立 `enemyNeighborCache`，简化包围识别。
- 单战区面对多敌战区时，仍暴露一条主 `FrontLine` 给 AI/UI 聚合使用。
- `GameState` 增加 `frontLineState` 并兼容旧存档 empty。
- `DataLoader` 初始加载 Region/Theater 后生成 FrontLine。

关键系统：

- `Core/FrontLine.swift`
- `Core/FrontSegment.swift`
- `Core/RegionFrontState.swift`
- `Core/FrontLineState.swift`
- `Rules/FrontLineManager.swift`
- `Tests/FrontLineCreationTests.swift`
- `Tests/FrontLineUpdateTests.swift`
- `Tests/MultiEnemyFrontTests.swift`

验证记录：

- v0.32 专项测试：9 tests, 0 failures。
- 全量测试：155 tests, 0 failures。
- `project.pbxproj` lint 通过。

备注：

- v0.32 未改 UI、SpriteKit、AI agent、LLM、命令系统、RegionGraph 或 TheaterSystem 结构。

## v0.33 - WarDeployment 部署层

完成日期：2026-06-17

核心更新：

- 新增 `FrontZone`、`FrontZoneSegment`、`WarDeploymentState` 与 `WarDeploymentManager`。
- 从 v0.31 Theater 生成 v0.33 `FrontZone`。
- 建立 region 粒度前线 segment 与 `FRONT / DEPTH / GARRISON` 三层单位池。
- 支持推进、崩溃、战区消亡与事件更新。
- dirty region + neighbor zone 局部重建，避免每次全图前线扫描。
- 新增前线、segment、部署、战争演化和局部更新性能测试。

关键系统：

- `Core/FrontZone.swift`
- `Core/FrontZoneSegment.swift`
- `Core/WarDeploymentState.swift`
- `Core/WarDeploymentTypes.swift`
- `Rules/WarDeploymentManager.swift`
- `Tests/WarDeploymentFrontLineTests.swift`
- `Tests/WarDeploymentSegmentTests.swift`
- `Tests/WarDeploymentDeploymentTests.swift`
- `Tests/WarEvolutionTests.swift`

验证记录：

- v0.33 选定测试：13 tests, 0 failures。
- 全量测试：168 tests, 0 failures。
- `plutil -lint` 通过。

备注：

- v0.33 未改 UI/SpriteKit、AI/LLM/命令系统，也未引入复杂路径搜索。

## v0.331 - v0.31 至 v0.33 总测试

完成日期：2026-06-18

核心更新：

- 对 v0.31 战区、v0.32 前线、v0.33 部署进行阶段集成测试。
- 清理和巩固测试 fixture，使战区、前线、部署三层能稳定共同回归。
- 优化探针检测，准备后续地图编辑器和战争命令系统接入。

关键系统：

- `Tests/TheaterSystemTests.swift`
- `Tests/FrontLine*Tests.swift`
- `Tests/WarDeployment*Tests.swift`
- `Tests/Stage035CampaignSimulationTests.swift`

备注：

- 本阶段主要是集成验收和测试基线整理，不是新玩法版本。

## v0.34 - 地图编辑器

完成日期：2026-06-18 至 2026-06-19

核心更新：

- 在 `MapEditor/` 下加入项目专属地图编辑器骨架。
- 使用 SwiftUI 管理工具面板，SpriteKit 管理六角格交互视口。
- 编辑器直接导出项目自有 `ScenarioDefinition` 与 `RegionDataSet` JSON，不再引入 Tiled 中间件。
- 新增 macOS 独立 target `MapEditorMac`。
- 支持地块、省份、战区、初始部队编辑。
- `DataLoader` 增加任意文件名加载入口和 MapEditor 输出专用加载路径。
- 地形补充 `hill`，并同步 `terrain_rules.json`、颜色和 inspector 显示。

关键系统：

- `MapEditor/MapEditorDocument.swift`
- `MapEditor/MapEditorHexMath.swift`
- `MapEditor/MapEditorExporter.swift`
- `MapEditor/MapEditorViewModel.swift`
- `MapEditor/MapEditorCanvasScene.swift`
- `MapEditor/MapEditorView.swift`
- `MapEditor/MapEditorMacApp.swift`
- `MapEditor/MapEditorGameResourceBridge.swift`
- `Tests/MapEditorOutputTests.swift`

验证记录：

- `MapEditorOutputTests` 覆盖编辑器输出到 `GameState` 的集成链路。

## v0.341 - macOS 独立编辑器

完成日期：2026-06-18

核心更新：

- 新增 `MapEditorMac` target，作为独立 macOS app 运行。
- 默认窗口适配宽屏/全屏地图编辑。
- 左侧 SwiftUI split panel 管理地图、模式、参数、文件操作。
- 右侧 SpriteKit canvas 渲染六角格。
- 支持鼠标拖拽连续涂色、滚轮/触控板缩放、右键/中键/Option+左键平移。
- 默认工作流读写 `WWIIHexV0/Data/ardennes_v0_scenario.json` 与 `ardennes_v02_regions.json`。

备注：

- MapEditor 不接入 iOS 主入口，避免污染游戏 app 启动流程。

## v0.342 - 地图编辑器中文化与显式编辑流

完成日期：2026-06-18

核心更新：

- 地图编辑器左侧面板改为中文。
- 模式拆成：地块、省份、战区、部队。
- 各模式采用统一 `添加 / 删除 / 完成 / 取消` 显式编辑会话。
- 切换模式会取消当前编辑会话，避免误操作。
- 分层显示只突出当前模式相关数据。
- `MapEditorOutputTests.testEditorSessionActionsReflectInGameState` 覆盖地块、省份、战区、部队完整编辑与导出读取。

## v0.343 - 地图编辑器视口稳定、稀疏扩图与快捷键

完成日期：2026-06-18

核心更新：

- 平移改用 view-space 指针增量，避免 camera 移动导致拖动抖动。
- 滚轮/触控板缩放以鼠标所在 scene point 为锚点，减少视口漂移。
- `MapEditorDocument.contains(_:)` 改为判断实际存在 hex，支持稀疏地图。
- 地块模式新增扩展地块动作，允许在已有 hex 邻位生成新 hex。
- 删除 hex 会清理该 hex 上的初始部队，并移除空 region/theater assignment。
- region/theater 名称由 UI 输入，内部 ID 自动递增。
- 新增快捷键：`N` 添加，`M` 完成。

验证记录：

- `MapEditorOutputTests` 扩展覆盖自动 ID、邻接扩展、虚空造地失败、删除清理、平移/缩放数学。

## v0.344 - 地图编辑器交互修复、信息面板与底图层

完成日期：2026-06-19

核心更新：

- macOS 画布改用 `NSViewRepresentable + SKView`，直接接收 `keyDown`。
- 修复 SpriteKit 抢焦点后 SwiftUI `Button.keyboardShortcut` 不稳定的问题。
- 滚轮缩放与水平/Shift 滚轮平移接入 `SKView.scrollWheel`。
- 右键短按选择 hex，并在左侧信息面板展示/编辑坐标、地形、道路、region、theater 信息。
- Region/Theater 颜色改用固定高对比色板按 ID hash 取色。
- 新增编辑器底图层：导入图片、设置透明度、缩放和位置；底图不写入游戏 JSON。

验证记录：

- `MapEditorOutputTests` 扩展覆盖快捷键、右键信息选择、名称保存、底图文档状态与移动增量。

## v0.351 - 初步战争命令系统

完成日期：2026-06-19

核心更新：

- 新增战争指令协议：`DirectiveEnvelope` / `ZoneDirective`。
- 新增 `WarCommandExecutor`，将 zone 级 attack/defend 意图翻译为底层 `Command`。
- 新增 `MockAICommander`，按兵力比阈值输出 attack/defend。
- AI 指令与玩家命令最终都走 `RuleEngine` / `CommandValidator` 校验执行。
- 为后续 LLM 输出 JSON 指令预留协议层。

关键系统：

- `Commands/WarDirective.swift`
- `Commands/WarCommandExecutor.swift`
- `Agents/MockAICommander.swift`
- `Core/WarDirectiveRecord.swift`
- `Tests/CommandSystemTests.swift`

备注：

- v0.351 只是初级战争命令，不做复杂战术、撤退命令、装甲差异化或真实 LLM。

## v0.352 - 新管线唯一化、观察者模式与分层 UI

完成日期：2026-06-19

核心更新：

- 新增/强化 `WarPipelineMode.zoneDirective`，默认战争 AI 走新 ZoneDirective 管线。
- Legacy Agent D 保留但不作为默认战争 AI 主路径。
- 引入观察者模式，支持双方由 AI 自动对战，但回合推进仍受玩家操作控制。
- 新增 `WarDirectiveRecord`，记录 directive、结果、诊断和 UI 回放信息。
- UI 支持 hex/province/theater/frontLine 等图层切换。
- `MockAICommander` attack 阈值从 1.5 调整到 1.2，使战局更容易推进。

关键系统：

- `Core/WarPipelineMode.swift`
- `Turn/TurnManager.swift`
- `App/AppContainer.swift`
- `Core/WarDirectiveRecord.swift`
- `Core/MapDisplayLayer.swift`
- `SpriteKit/MapLayerOverlayNode.swift`
- `SpriteKit/MapLayerOverlayCalculator.swift`

## v0.353 - 默认地图验收与归属权威重构

完成日期：2026-06-19

核心更新：

- 默认地图接入真实战局模拟验收。
- 确立 hex controller 为归属权威。
- region controller、theater 控制比例、补给站归属改为从 hex controller 派生。
- 避免继续依赖静态阵营标签判断动态占领结果。
- 观察者模式下新地图可用于战争模拟和回归测试。

关键系统：

- `Rules/OccupationRules.swift`
- `Rules/StrategicStateSynchronizer.swift`
- `Rules/TheaterSystem.swift`
- `Rules/RegionOccupationRules.swift`
- `Tests/ObserverModeIntegrationTests.swift`
- `Tests/Stage035CampaignSimulationTests.swift`

备注：

- 本阶段是后续 v0.354/v0.355 修复“AI 不动、联动不及时、占领不对称”的地基。

## v0.354 - 联动修复、拒绝率治理与玩家/AI 对称性

完成日期：2026-06-19 至 2026-06-20

核心更新：

- 修复占领后 region、theater、frontline、visibility 不在同一回合联动的问题。
- 修复 ZOC 友军穿越误判，避免友军互相阻挡。
- 定位“德军若干回合后不动”的真实病灶：推进过深的部队被部署层误判为 garrison，从前线兵力池消失。
- 统一玩家与 AI 的占领判定入口，避免 AI 能占玩家地、玩家不能占 AI 地的不对称。
- 改善 RuleEngine 拒绝率诊断，避免非法命令被静默吞掉。

关键系统：

- `Rules/OccupationRules.swift`
- `Rules/StrategicStateSynchronizer.swift`
- `Rules/WarDeploymentManager.swift`
- `Rules/CommandValidator.swift`
- `Commands/WarCommandExecutor.swift`
- `Tests/WarEvolutionTests.swift`
- `Tests/ObserverModeIntegrationTests.swift`

备注：

- v0.354 期间有多轮 debug 与修复提交，包括 `v0.354 优化1`、`v0.354修复`、`0.354debug`。

## v0.355 - 动态/初始战区分离、前线 UI 与观察者收尾

完成日期：2026-06-20 至 2026-06-23

核心更新：

- 正式分离 `TheaterState.initialSnapshot` 与运行时动态战区状态。
- 修复战区阵营身份不能从动态控制比例反推的问题。
- 图层拆分为 `hex`、`province`、`initialTheater`、`dynamicTheater`、`frontLine`。
- 前线 overlay 改为按 `FrontSegment` 连线绘制。
- 观察者模式开关接入主界面 UI。
- 执行 20 回合观察者模式模拟与阶段分析，记录 directive、拒绝原因、省份换手和补给/包围趋势。

关键系统：

- `Core/Theater.swift`
- `Core/MapDisplayLayer.swift`
- `SpriteKit/MapLayerOverlayNode.swift`
- `SpriteKit/MapLayerOverlayCalculator.swift`
- `UI/RootGameView.swift`
- `Tests/Stage035CampaignSimulationTests.swift`
- `Tests/Stage0355DynamicTheaterTests.swift`

验证记录：

- 历史记录显示 v0.355 阶段曾达到 Probe 9/0、Smoke 4/0、Stage Regression 63/0、Full 198/0。
- 20 回合观察者模拟：57 条 directive，拒绝率约 10%，主要拒绝原因为移动力不足与无路径。

备注：

- 文档 `0.355-迄今概览.md` 记录该阶段架构总结与后续注意事项。

## v0.356 - 默认资源一致性与前线 UI 修正

完成日期：2026-06-24

核心更新：

- DEBUG 下 `DataLoader` 优先读取源码 `WWIIHexV0/Data/*.json`，避免编辑器覆盖保存后游戏仍读取旧 bundle 资源。
- 新增默认资源一致性测试，确保编辑器 document、导出 JSON、游戏加载后的 `hexToRegion`、`regionToTheater`、`tile.regionId`、`region.name` 一致。
- 前线 UI 改为在我方动态战区侧绘制，用 `segment.regionA` 内接敌 hex 的中心点连线。
- 不同 theater 前线使用固定不同基色。
- 每个 segment 单独绘制，并在 segment 起点加分隔符，避免被看成一整条红线。

验证记录：

- 定向 MapEditorOutputTests + Stage0355DynamicTheaterTests：10 tests, 0 failures。
- Probe：9 tests, 0 failures。
- Smoke：4 tests, 0 failures。
- Full regression：200 tests, 0 failures。
- `git diff --check` 通过。

备注：

- 如果模拟器中仍运行旧 app 进程，需要重新运行 app 才会读到 DEBUG 源码 JSON。

## v0.357 - 地图视角、开局单位与前线 UI 修正

完成日期：2026-06-24

核心更新：

- 修复地图编辑器与游戏内视角上下颠倒/不一致问题。
- 修复部队初始部署异常与跨阵营战区问题。
- 修正开局不应立即让 AI 自动行动的行为，开局应先显示真实初始部队状态。
- 继续优化前线 UI，使动态战区、segment 与视觉表达一致。

关键系统：

- `MapEditor/*`
- `Data/DataLoader.swift`
- `App/AppContainer.swift`
- `SpriteKit/MapLayerOverlayNode.swift`
- `Tests/Stage0355DynamicTheaterTests.swift`

## v0.358 - 动态 hex 战区语义收口

完成日期：2026-06-24

核心更新：

- 确认核心语义：`regionToTheater` 是初始/基础战区映射，`hexToTheater` 是运行时动态战区权威。
- 单位占领一个 hex 只推进该 hex 的动态战区归属，不能把整个 region 拖入进攻方 theater。
- 部署层同步引入/强化 `hexToFrontZone`，避免 region 粒度误判 FRONT/DEPTH/GARRISON。
- 前线改按动态 hex 邻接生成，测试 fixture 必须构造真实相邻 hex，不能只声明 region 邻接。
- AI target、WarDeployment、overlay、probe 和 stage tests 同步适配动态 hex 语义。

关键系统：

- `Core/Theater.swift`
- `Core/WarDeploymentState.swift`
- `Rules/TheaterSystem.swift`
- `Rules/FrontLineManager.swift`
- `Rules/WarDeploymentManager.swift`
- `Tests/Stage0355DynamicTheaterTests.swift`
- `Probes/WWIIHexV0ProbeTests.swift`

备注：

- 这是 v0.3 主线的重要铁律：运行时动态战区跟 hex 走，不跟 region 走。

## v0.359 - 前线 UI 优化

完成日期：2026-06-25

核心更新：

- 继续优化前线 overlay 的可读性。
- 强化不同战区/不同 segment 的视觉区分。
- 保留 encirclement/collapsing 等警示状态的红色与加粗表达。
- 使前线 UI 更接近真实动态战区接触，而不是静态 region/theater 边界。

关键系统：

- `SpriteKit/MapLayerOverlayNode.swift`
- `SpriteKit/MapLayerOverlayCalculator.swift`
- `UI/RootGameView.swift`

## v0.3510 - 颜色优化

完成日期：2026-06-25

核心更新：

- 优化地图分层 UI 的颜色表达。
- 强化 province、initialTheater、dynamicTheater、frontLine 等 layer 的辨识度。
- 避免相邻 region/theater 颜色过近导致误判。

关键系统：

- `SpriteKit/TerrainStyle.swift`
- `SpriteKit/MapLayerOverlayNode.swift`
- `SpriteKit/MapLayerOverlayCalculator.swift`

备注：

- 该版本号沿用提交历史中的 `v0.3510`，语义上属于 v0.35x UI 收尾序列，不是 v0.351 的子补丁。

## v0.3511 - UI 修复优化

完成日期：2026-06-25

核心更新：

- 继续修复和优化主游戏 UI。
- 配合 v0.359/v0.3510 的颜色和前线显示调整，改善可读性。
- 为 v0.36 命令层扩展前的界面状态收口。

关键系统：

- `UI/*`
- `SpriteKit/*`

备注：

- 该版本号同样来自提交历史，属于 v0.35x 收尾序列。

## v0.36 - 命令层扩展与多将领 MockAI

完成日期：2026-06-25

核心更新：

- `ZoneDirective` 扩展 `CommandCategory`、`TacticName`、`DirectiveTarget`。
- 新增 `ZoneCommanderAgent`，每个动态战区可由独立将领 agent 生成 directive。
- 新增 `BinaryTacticClassifier`，在 `standardAttack` 与 `holdPosition` 之间做初步分类。
- 新增 `TheaterCommanderPool`，为动态战区提供将领配置，未知新战区使用 fallback commander。
- `WarDirectiveRecord` 增加 category、tactic、commanderAgentId、commandTarget 等字段，便于回放和审计。
- `MockAICommander` 转为兼容 facade，不作为未来扩展主入口。
- 修复旧测试 fixture，使其符合 v0.358 动态 hex 邻接语义。

关键系统：

- `Commands/WarDirective.swift`
- `Commands/WarCommandExecutor.swift`
- `Core/WarDirectiveRecord.swift`
- `Agents/ZoneCommanderAgent.swift`
- `Agents/MockAICommander.swift`
- `Turn/TurnManager.swift`
- `App/AppContainer.swift`
- `Tests/CommandSystemTests.swift`
- `Probes/WWIIHexV0ProbeTests.swift`

验证记录：

- Probe：17 tests, 0 failures。
- Stage Regression：63 tests, 0 failures。
- Full Regression：213 tests, 0 failures。
- 静态检查：`plutil`、`xmllint`、`jq`、`git diff --check` 通过。

备注：

- `AttackIntensity` 字段仍存在，但没有实际分流执行逻辑。
- 战区互助接口仍无调用方。
- 真 LLM 尚未接入。

## v0.37 - 命令层统一整合

完成日期：2026-06-27

核心更新：

- 默认战争 AI 路径收口为：

```text
TheaterCommanderPool -> ZoneCommanderAgent -> ZoneDirective -> WarCommandExecutor -> RuleEngine -> WarDirectiveRecord
```

- 移除 `TurnManager` 中 `MockAICommander` fallback，避免默认路径语义模糊。
- `.zoneDirective` 分支只通过显式 `commanderPool` 或 `TheaterCommanderPool.automatic(for:)` 产生 envelope。
- Legacy Agent D 只在显式 `.legacyAgentOrder` 或测试回归中使用。
- 保留 `MockAICommander` 作兼容/阈值行为测试用途，但不再作为 `TurnManager` 默认备用入口。
- 确认 `WarCommandExecutor.execute(_ directive:in:)` 不依赖具体 `ZoneCommanderAgent` 实例，手写合法 `ZoneDirective` 可直接执行。
- 新增 v0.37 手写 directive 探针，为 v0.4 玩家 UI 共用命令管线预留后端能力。
- 决定将撤退命令、突破/闪电战、装甲差异化、`AttackIntensity` 实际分流推迟到 1.x。

关键系统：

- `Turn/TurnManager.swift`
- `Commands/WarCommandExecutor.swift`
- `Commands/WarDirective.swift`
- `Agents/ZoneCommanderAgent.swift`
- `Agents/MockAICommander.swift`
- `Core/WarDirectiveRecord.swift`
- `Tests/CommandSystemTests.swift`
- `Probes/WWIIHexV0ProbeTests.swift`

验证记录：

- Probe：18 tests, 0 failures。
- CommandSystemTests：15 tests, 0 failures。
- Stage Regression：69 tests, 0 failures。
- Full Regression：226 tests, 0 failures。

备注：

- v0.37 是命令层地基工程，不新增玩法机制。
- v0.4 可以在此基础上接玩家聊天/命令 UI，但必须继续共用 `ZoneDirective -> WarCommandExecutor -> RuleEngine`。

## v0.5 - 元帅层、模拟 LLM JSON 与决策链规范化

完成日期：2026-07-04

目标分支：`v0.5-marshal-decision-chain`

分支审计：本轮开始时创建并切换过该分支；后续轻量审计中当前 checkout 先后显示为 `v0.9-ruler-diplomacy`、`v0.4-generals-command-ui-resume`、`v1.1-macos-main-game`、`v1.0-ui-ai-playtest` 等非 v0.5 分支，且工作树已有多批其他版本未提交改动。用户同意切换后，当前 checkout 已确认回到 `v0.5-marshal-decision-chain`；合并前仍必须审查 dirty worktree 中非 v0.5 文件归属和文件级冲突。

核心更新：

- 新增元帅层 `MarshalAgent`，在战区将军上游读取降维战场摘要并产出战役级意图。
- 默认战争 AI 管线升级为：

```text
MarshalAgent
  -> MarshalBattlefieldSummarizer
  -> SimulatedMarshalLLMClient
  -> TheaterDirectiveDecoder
  -> TheaterDirectiveCompiler
  -> ZoneDirective
  -> WarCommandExecutor
  -> RuleEngine
```

- 新增 `TheaterDirectiveEnvelope` / `TheaterDirective` 作为 v0.5 LLM-facing JSON schema。
- 新增 `TheaterDirectiveDecoder`，支持 fenced JSON 提取、`JSONDecoder` 解码、schemaVersion / issuer / turn / faction / zone / region / tactic-category 校验。
- 新增 `SimulatedMarshalLLMClient`，只模拟 LLM 接口和 JSON 输出，不接真实网络、本地模型或云端 API。
- 新增 `TheaterDirectiveCompiler`，把元帅意图降级为现有 `ZoneDirective`；缺失或失败时 fallback 到 `TheaterCommanderPool`。
- `WarPipelineMode` 新增 `.marshalDirective`，`AppContainer` 和 `TurnManager` 默认使用该模式；旧 `.zoneDirective` 和 `.legacyAgentOrder` 仍保留为显式路径。
- `TurnManager` 抽出公共 `executeDirectiveEnvelope`，确保元帅链路和旧将军池链路共享同一执行、记录和 endTurn 逻辑。
- v0.5 收口时移除 v0.9 旁支曾插入的 `RulerAgent` 塑形调用；当前 `.marshalDirective` 与显式 `.zoneDirective` 都不写统治者记录，统治者仅作为后续上游预留。
- 新增实现记录文档，详细写明本分支算法、边界、fallback 和轻量验证。

关键系统：

- `WWIIHexV0/Commands/WarDirective.swift`
- `WWIIHexV0/Agents/ZoneCommanderAgent.swift`
- `WWIIHexV0/Turn/TurnManager.swift`
- `WWIIHexV0/Core/WarPipelineMode.swift`
- `WWIIHexV0/App/AppContainer.swift`
- `md/prompt/anti生成/v0.5/anti/0.50_v0.5_marshal_implementation_record.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `README.md`

验证记录：

- `git rev-parse --abbrev-ref HEAD`：`v0.5-marshal-decision-chain`。
- 轻量单文件语法检查通过：
  - `swiftc -parse WWIIHexV0/Commands/WarDirective.swift`
  - `swiftc -parse WWIIHexV0/Agents/ZoneCommanderAgent.swift`
  - `swiftc -parse WWIIHexV0/Turn/TurnManager.swift`
  - `swiftc -parse WWIIHexV0/App/AppContainer.swift`
  - `swiftc -parse WWIIHexV0/Core/WarPipelineMode.swift`
- `plutil -lint WWIIHexV0.xcodeproj/project.pbxproj`：OK。
- `jq empty` 已通过：
  - `WWIIHexV0/Data/ardennes_v02_regions.json`
  - `WWIIHexV0/Data/general_agents.json`
  - `WWIIHexV0/Data/generals.json`
  - `WWIIHexV0/Data/terrain_rules.json`
  - `WWIIHexV0/Data/unit_templates.json`
- 文档尾随空白扫描：无命中。
- 旧默认测试口径扫描（`AGENTS.md`、`md/flow/flow.md`）：无命中。
- Cabinet/Minister 旧污染源码扫描：无命中。
- v0.5 当前文档与 `TurnManager` 的 `RulerAgent` 默认接入残留扫描：无命中。
- `git diff --check`：通过，无输出。

未跑：

- 未跑 Xcode / XCTest / 模拟器 / Probe / Smoke / Stage Regression / Dynamic Theater Regression / Full；原因是当前 `AGENTS.md` 与 `md/test/test.md` 规定默认只做轻量检查，且本轮用户明确禁止跑 Xcode。

备注：

- 本轮没有恢复历史回退的 `CabinetState`、`DirectiveBoard`、`MinisterDecisionProvider`、`RulerDirectiveFactory`、`national_cabinet.json` 或部长系统。
- 统治者层仅作为未来元帅上游预留方向，不在 v0.5 当前实现中落地。
- 当前工作树还存在不属于本 v0.5 核心目标的高级战术、外交、经济、UI 和地图编辑器方向未提交改动；v0.5 实现选择兼容现有工作树，不回滚其他改动。

## v0.8 - 初级经济、生产、城市、地形与补兵

完成日期：2026-07-04

目标分支：`codex/v0.8-economy-production`

分支审计：本轮早期创建 v0.8 分支曾因 `.git` 写入权限受限失败；期间当前 checkout 先后观察到其他版本分支，且工作树已有多批其他版本未提交改动。最终已通过受控审批成功创建 `codex/v0.8-economy-production`，但创建后仍观察到外部 checkout 漂移。因此本记录描述当前工作树中的 v0.8 经济系统实现，合并前必须重新确认当前分支、分支基点、文件级冲突、public API 冲突和 Xcode project 引用。

核心更新：

- 新增 `EconomyState`，建立 faction 级 manpower、industry、supplies 总账、生产队列、上回合收入/维护费/补员消耗。
- 新增 `EconomyRules`，从真实己方 hex 控制证据、region 城市、工厂、基础设施和补给值聚合收入。
- `GameState` 增加 `economyState`，旧存档缺失时 fallback `.empty`。
- `StrategicStateBootstrapper` 与 `RuleEngine` 在需要时 bootstrap 经济总账，保证旧状态第一次执行命令也有经济账本。
- `Command` 新增 `queueProduction(kind:)`，经 `CommandValidator` 检查 phase 和资源，经 `CommandExecutor` 调 `EconomyRules.queueProduction` 预付成本并入队。
- `CommandExecutor.executeEndTurn` 增加 active faction 经济结算：收入、战略补给维护费、短缺降级、自动补兵、生产队列推进和完成部署。
- 自动补兵只处理本阵营、未毁灭、未撤退、supplied、非敌邻、strength 未满的单位，每回合每单位最多恢复 2 strength，按兵种权重扣资源。
- 生产完成单位只能部署到本方控制、passable、空置、非敌邻，且位于首都、城镇/大都会、工厂、高基建、高补给 region 或 supply source 的后方 hex；找不到安全部署点时订单保留。
- `BaseTerrain`、`MovementRules`、`CombatRules` 增加地形加成：装甲进困难地形额外移动成本，装甲攻击平原加成，攻击困难地形惩罚，步兵在森林/城市/堡垒防御加成。
- 新增 `EconomyPanelView`，`RootGameView` 接入 Economy tab，`HUDView` 展示经济摘要，Region inspector 展示城市等级和经济产出。
- `project.pbxproj` 当前已有 `EconomyState.swift`、`EconomyRules.swift`、`EconomyPanelView.swift` 引用，未新增重复 UUID。
- 新增 v0.8 实现记录，详细写明规则算法、接入点、非目标、轻量检查和风险。

关键系统：

- `WWIIHexV0/Core/EconomyState.swift`
- `WWIIHexV0/Rules/EconomyRules.swift`
- `WWIIHexV0/Core/GameState.swift`
- `WWIIHexV0/Core/StrategicStateBootstrapper.swift`
- `WWIIHexV0/Commands/Command.swift`
- `WWIIHexV0/Rules/CommandValidator.swift`
- `WWIIHexV0/Rules/CommandExecutor.swift`
- `WWIIHexV0/Rules/RuleEngine.swift`
- `WWIIHexV0/Core/Terrain.swift`
- `WWIIHexV0/Rules/MovementRules.swift`
- `WWIIHexV0/Rules/CombatRules.swift`
- `WWIIHexV0/UI/EconomyPanelView.swift`
- `WWIIHexV0/UI/RootGameView.swift`
- `WWIIHexV0/UI/HUDView.swift`
- `WWIIHexV0/SpriteKit/MapDisplayAdapter.swift`
- `WWIIHexV0/UI/RegionInspectorView.swift`
- `md/prompt/anti生成/v0.8/anti/0.80_v0.8_economy_implementation_record.md`
- `md/prompt/anti生成/v0.8/anti/0.80_overall_analysis_report.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`

验证记录：

- 轻量 Swift parse 通过：
  - 核心规则集合，含 `EconomyState.swift`、`EconomyRules.swift`、`GameState.swift`、`Command.swift`、`CommandValidator.swift`、`CommandExecutor.swift`、`RuleEngine.swift`、`StrategicStateBootstrapper.swift`、`MovementRules.swift`、`CombatRules.swift` 等。
  - 核心规则集合 + `PlatformStyles.swift` + `EconomyPanelView.swift`。
  - 核心规则集合 + `MapDisplayAdapter.swift` + `PlatformStyles.swift` + `EconomyPanelView.swift` + `HUDView.swift` + `RegionInspectorView.swift`。
- `plutil -lint WWIIHexV0.xcodeproj/project.pbxproj`：通过。
- `jq empty WWIIHexV0/Data/ardennes_v02_regions.json`：通过。
- 改动文档尾随空白检查：通过。
- 旧默认测试口径残留检查：通过。

未跑：

- 未跑 Xcode / XCTest / 模拟器 / Probe / Smoke / Stage Regression / Dynamic Theater Regression / Full / 性能测试；原因是当前规范和用户要求均禁止本轮主动跑 Xcode 与重测试。

备注：

- v0.8 不接真实 LLM 经济部长、不做完整商品价格网、不恢复 organization、不做空军/海军/战略轰炸/工厂损毁。
- `RegionDataSet.toRegions()` 仍有历史 fallback：owner/controller 缺失最终落到 `.allies`。v0.8 经济收入已加真实 hex 控制守卫，但数据层中立语义建议后续单独修。
- 当前 AI 不会主动排产；规则层已支持 active faction 通过统一 `Command` 排产，AI 经济策略留后续版本。

## v1.0 - UI / AI / 初版试玩收口

完成日期：2026-07-04

分支：`v1.0-ui-ai-playtest`

分支审计：续接收尾时当前 checkout 曾显示为 `v1.1-macos-main-game`，切回 `v1.0-ui-ai-playtest` 后又在轻量检查期间漂到 `v0.9-ruler-diplomacy` 和 `v0.5-marshal-decision-chain`。`v1.0-ui-ai-playtest` 分支已存在且与当前基线一致；交付前最后一次即时核对显示当前分支为 `v1.0-ui-ai-playtest`。由于当前工作树存在外部 checkout 漂移风险，合并前必须重新做分支与冲突审查。

核心更新：

- 创建并切换到 1.0 分支，围绕主游戏 UI、MockAI 行为、轻量性能和试玩记录做收口。
- `AgentPanelView` 接入 `WarDirectiveRecord`，AI tab 现在展示 zone、directive type、tactic、成功/拒绝命令数、目标 region 和 diagnostics。
- `EventLogView` 改为 `LogDisplayEntry` 展示模型，最近 60 条日志每条只计算一次分类，并补充 diplomacy 日志分类。
- `BoardScene.drawUnits` 缓存单位显示 hex 后排序，部署图层复用同一个 `WarDeploymentManager` 计算 role。
- `WarCommandExecutor` 开始解释 `AttackIntensity.infiltration`，无显式投入上限时限制默认投入单位数；佯攻/袭扰保留低投入策略。
- `PlatformStyles` 补充跨平台面板样式；Economy / Diplomacy 面板收口到跨平台背景和更可读字号。
- 新增 1.0 分支实现记录，写明 UI、性能、MockAI、试玩观察点、风险和未跑重测试原因。

关键系统：

- `WWIIHexV0/UI/PlatformStyles.swift`
- `WWIIHexV0/UI/RootGameView.swift`
- `WWIIHexV0/UI/AgentPanelView.swift`
- `WWIIHexV0/UI/EventLogView.swift`
- `WWIIHexV0/UI/EconomyPanelView.swift`
- `WWIIHexV0/UI/DiplomacyPanelView.swift`
- `WWIIHexV0/SpriteKit/BoardScene.swift`
- `WWIIHexV0/Commands/WarCommandExecutor.swift`
- `md/prompt/anti生成/v1.0/anti/1.00_v1.0_ui_ai_playtest_implementation_record.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`

验证记录：

- `git branch --show-current`：切回后曾返回 `v1.0-ui-ai-playtest`，但后续轻量检查期间又返回 `v0.9-ruler-diplomacy` 和 `v0.5-marshal-decision-chain`；分支漂移未完全消除。
- `plutil -lint WWIIHexV0.xcodeproj/project.pbxproj`：OK。
- `jq empty WWIIHexV0/Data/ardennes_v02_regions.json`：通过，无输出。
- `jq empty WWIIHexV0/Data/generals.json`：通过，无输出。
- `git diff --check`：通过，无输出。
- `rg -n "[[:blank:]]+$" AGENTS.md README.md update_log.md md/test/test.md md/flow/flow.md md/flow/flowchart.md md/prompt/anti生成/v1.0/anti/1.00_v1.0_ui_ai_playtest_implementation_record.md`：无命中。
- `rg -n "默认先跑|默认 Probe|Probe -> Smoke|Stage Regression -> Full|代码改动按 .*Probe" AGENTS.md md/flow/flow.md`：无命中。
- 冲突标记扫描（AGENTS.md、README.md、update_log.md、md/flow、WWIIHexV0、MapEditor）：无命中。

未跑：

- 未跑 Xcode / XCTest / 模拟器 / Probe / Smoke / Stage Regression / Dynamic Theater Regression / Full / 性能测试；原因是 `AGENTS.md`、`md/test/test.md` 和用户要求均禁止本轮主动跑重测试。

备注：

- 本轮并发子 agent 中 UI 只读定位完成，AI / 性能子 agent 因外部 503 失败，主线程接回实现。
- 当前工作树仍含 v0.5 / v0.7 / v1.1 等方向未提交改动，合并前必须做文件级、public API、schema、Xcode project 和文档口径冲突审查。

## v0.9 - 统治者、多国家、阵营集团与初步外交状态

完成日期：2026-07-04

分支：`v0.9-ruler-diplomacy`

核心更新：

- 新增 `DiplomacyState`，在 `GameState` 中保存国家、阵营集团、国家间外交关系和统治者决策记录。
- 新增 `CountryProfile`、`DiplomaticBloc`、`DiplomaticRelation`、`DiplomaticStatus`、`RulerStrategicPosture`、`RulerDecisionRecord` 等数据结构。
- 开局外交种子：
  - Germany 规则阵营：`German Reich`，`Axis`，`ruler_germany`。
  - Allies 规则阵营：`United States`、`United Kingdom`、`Belgium`，`Allied Coalition`，主统治者 `ruler_allies`。
  - 同阵营关系为 `allied`，跨阵营关系为 `atWar`。
- 新增 `RulerAgent`：读取外交、前线、部署、历史战争指令记录，生成 `RulerStrategicSnapshot`，选择 `offensive` / `defensive` / `coalitionMaintenance` / `stabilizeFront` 姿态。
- `RulerAgent` 只塑形 `DirectiveEnvelope`：
  - offensive：攻击强度提升为 `allOut`，按 region priority 重排目标。
  - defensive：攻击 directive 转为 `holdLine` 防御 directive。
  - coalitionMaintenance：提高防御预备队。
  - stabilizeFront：降低 `allOut` 为 `limitedCounter`，或采用 `flexible` 防御。
- `TurnManager` 在 `.marshalDirective` 与显式 `.zoneDirective` 路径中执行 `applyRuler`，写入 `RulerDecisionRecord` 和 `.diplomacy` 日志后，再交给 `WarCommandExecutor -> RuleEngine`。
- `DataLoader` 和 `StrategicStateBootstrapper` 会为新局或旧存档补齐外交状态。
- 新增 `DiplomacyPanelView`，`RootGameView` 增加 `Diplomacy` 面板，`AgentPanelView` 展示最近统治者 posture / focus。
- `GameLogCategory` 新增 `diplomacy`。
- 修复 `RulerStrategicSnapshot` 静态去重调用；修复 `hostileCountryIds(to:)` 在多盟友共享同一敌国时重复计数的问题。
- 新增 v0.9 实现记录，详细写明本分支算法、边界、冲突情况和未跑重测试原因。

关键系统：

- `WWIIHexV0/Core/DiplomacyState.swift`
- `WWIIHexV0/Agents/RulerAgent.swift`
- `WWIIHexV0/Core/GameState.swift`
- `WWIIHexV0/Core/StrategicStateBootstrapper.swift`
- `WWIIHexV0/Data/DataLoader.swift`
- `WWIIHexV0/Core/GameLogEntry.swift`
- `WWIIHexV0/Turn/TurnManager.swift`
- `WWIIHexV0/UI/DiplomacyPanelView.swift`
- `WWIIHexV0/UI/AgentPanelView.swift`
- `WWIIHexV0/UI/RootGameView.swift`
- `WWIIHexV0.xcodeproj/project.pbxproj`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `README.md`
- `md/prompt/anti生成/v0.9/anti/0.90_v0.9_ruler_diplomacy_implementation_record.md`

验证记录：

- `git branch --show-current`：`v0.9-ruler-diplomacy`。
- `plutil -lint WWIIHexV0.xcodeproj/project.pbxproj`：OK。
- `jq empty WWIIHexV0/Data/ardennes_v02_regions.json`：通过，无输出。
- `jq empty WWIIHexV0/Data/generals.json`：通过，无输出。
- `rg -n "[[:blank:]]+$" AGENTS.md README.md update_log.md md/test/test.md md/flow/flow.md md/flow/flowchart.md md/prompt/anti生成/v0.9/anti/0.90_v0.9_ruler_diplomacy_implementation_record.md`：无命中。
- `rg -n "默认先跑|默认 Probe|Probe -> Smoke|Stage Regression -> Full|代码改动按 .*Probe" AGENTS.md md/flow/flow.md`：无命中。
- 冲突标记扫描（README.md、update_log.md、md/flow、v0.9 实现记录与相关 Swift 文件）：无命中。
- `swiftc -parse WWIIHexV0/Core/DiplomacyState.swift WWIIHexV0/Agents/RulerAgent.swift WWIIHexV0/UI/DiplomacyPanelView.swift`：通过，无输出。

未跑：

- 未跑 Xcode / XCTest / 模拟器 / app 启动 / Probe / Smoke / Stage Regression / Dynamic Theater Regression / Full；原因是当前规范与本轮用户要求均禁止主动跑 Xcode 和重测试。

备注：

- 本轮尝试把国家/外交、AI 管线、文档三块拆给子 Agent 并行，但子 Agent 调用返回 503，没有可用产物；最终由主 Agent 在当前分支内完成实现和整合。
- 当前工作树已有 v0.5 元帅层、经济层、v1.1 macOS target、地图编辑器和 UI 等未提交改动；v0.9 选择兼容当前源码，不回滚其他改动。合并前仍需做文件级冲突审查。
- 多国家当前是战略身份层，底层规则阵营仍是 `Faction.germany` / `Faction.allies`。后续若要国家级参战、中立、投降、宣战或外交行动，需要先设计国家级权限和命令入口。

## v1.1 - 主游戏 macOS target

完成日期：2026-07-04

分支：`v1.1-macos-main-game`

核心更新：

- 新增独立主游戏 macOS app target `WWIIHexV0Mac`，区别于既有 iOS 主游戏 target `WWIIHexV0` 和地图编辑器 target `MapEditorMac`。
- 新增 macOS 主入口 `WWIIHexV0MacApp`，复用 `AppContainer.bootstrap()` 与 `RootGameView(container:)`，默认窗口 1440x900，最小内容区域 1200x760。
- `WWIIHexV0Mac` resource phase 接入主游戏默认 JSON：`ardennes_v0_scenario.json`、`ardennes_v02_regions.json`、`general_agents.json`、`generals.json`、`terrain_rules.json`、`unit_templates.json`。
- `BoardSceneView` 增加 macOS `NSViewRepresentable` 分支，用 `BoardEventSKView` 承载 `BoardScene`，iOS 继续使用 `UIViewRepresentable` 分支。
- `BoardScene` 增加 macOS 鼠标点击、拖拽平移、滚轮/触控板缩放；点击仍只回调 `onHexTapped`，后续由 `AppContainer.handleBoardTap -> RuleEngine` 处理。
- 新增 `PlatformStyles`，将主游戏 UI 的 `Color(.systemBackground)` / `Color(.tertiarySystemBackground)` 替换为 iOS/macOS 条件背景色。
- 因当前工作树已有经济、外交、统治者、将领 registry 等源码引用，`project.pbxproj` 同步把这些已被引用的支持文件和 `generals.json` 接入相关 target phase，但本轮不改这些业务逻辑。
- 新增 v1.1 实现记录，详细写明 target 设计、输入桥接算法、资源加载、轻量检查和风险。

关键系统：

- `WWIIHexV0.xcodeproj/project.pbxproj`
- `WWIIHexV0/App/WWIIHexV0MacApp.swift`
- `WWIIHexV0/SpriteKit/BoardScene.swift`
- `WWIIHexV0/SpriteKit/BoardSceneView.swift`
- `WWIIHexV0/UI/PlatformStyles.swift`
- `WWIIHexV0/UI/RootGameView.swift`
- `md/prompt/anti生成/v1.1/anti/1.10_v1.1_macos_main_game_implementation_record.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `README.md`

验证记录：

- `plutil -lint WWIIHexV0.xcodeproj/project.pbxproj` 通过。

未跑：

- 未跑 Xcode / XCTest / 模拟器 / macOS app 启动 / Probe / Smoke / Stage Regression / Dynamic Theater Regression / Full；原因是当前规范与用户要求均禁止本轮主动跑 Xcode 和重测试。

备注：

- v1.1 是平台承载和输入桥接分支，不改变 `Command` / `ZoneDirective` / `WarCommandExecutor` / `RuleEngine` 规则权威链路。
- 当前工作树存在多条其他方向的未提交改动；v1.1 选择兼容当前源码引用并记录风险，不回滚其他人改动。

## v0.7 - 高级战术与命令扩展

完成日期：2026-07-04

目标分支：`v0.7-tactical-upgrade`

分支审计：本轮曾创建并切换到 `v0.7-tactical-upgrade`，但连续接力时当前 checkout 多次显示为其他分支，且工作树已有多批 v0.5 / v1.0 / v1.1 / UI / 经济 / 外交方向未提交改动。按项目规则，本轮未回滚这些改动；合并前必须重新确认分支归属和文件级冲突。

核心更新：

- `TacticName` 扩展为进攻 8 类、防御 4 类：
  - 进攻：`standardAttack`、`blitzkrieg`、`spearhead`、`breakthrough`、`pincerMovement`、`fireCoverage`、`feint`、`guerrillaWarfare`。
  - 防御：`holdPosition`、`elasticDefense`、`defenseInDepth`、`lastStand`。
- `AttackParameters` 新增 `focusRegionId`、`supportRegionIds`、`convergenceRegionId`、`coordinatedZoneIds`、`maxCommittedUnits`、`exploitDepth`，支持定点突破、钳形会师、投入上限和纵深目标意图。
- `DefenseParameters` 新增 `fallbackRegionIds`、`counterattackRegionIds`、`strongpointRegionIds`、`maxFrontCommitment`，支持弹性防御、纵深防御和死守口径。
- `TheaterDirective` 新增 `convergenceRegionId` / `coordinatedZoneIds`，并补自定义 decode，旧 JSON 缺字段时仍兼容。
- `TheaterDirectiveDecoder` 校验 convergence region 和 coordinated zone 存在性，继续校验 tactic/category 一致性。
- `BinaryTacticClassifier` 从二元分类升级为读取兵力比、机动兵力、炮兵支援、纵深预备队、压力和补给警告的战术分类器。
- `TacticConditionChecker` 从恒 true 改为按战术最低条件放行：机动战术要求机动单位，火力覆盖要求炮兵/远程单位，佯攻要求前线单位，纵深防御要求 depth 预备队。
- `WarCommandExecutor` 新增 `AttackTacticProfile`，按战术控制单位来源、机动优先、炮兵优先、只攻击不推进、弱点聚焦、深目标候选、非矛头单位 hold 和投入上限。
- 定点突破弱点评分落地：

```text
enemyStrength 越低越优先
terrain.movementCost 越低越优先
region 内有 road 越优先
city.victoryPoints + supplyValue + factories 越高越优先
guerrillaWarfare 额外参考 infrastructure
```

- `defenseInDepth` 新增独立执行路径：一线 `allowRetreat`，保留预备队，其余 depth 机动单位尝试反击，否则向 fallback / strongpoint 防御地形移动。
- `fireCoverage` 落地为炮兵/远程优先、能打则打、无目标则 hold，不主动推进。
- `feint` 落地为少量前线单位牵制，默认约 1/3 前线投入。
- `blitzkrieg` / `spearhead` 落地为机动优先、集中弱点、可使用 depth 单位，非矛头前线单位 hold。
- `pincerMovement` 落地为 convergence / coordinated 数据层和单 zone 执行器 profile；多 zone 会师由元帅层或人工下发多条 directive，包围效果交给动态战区/前线/补给派生。
- `MockAICommander` 保留新增 attack 参数，避免 allOut 包装时丢失 focus/convergence/coordinated 字段。
- 新增 v0.7 实现记录文档，详细写明算法、边界、冲突风险和轻量检查口径。

关键系统：

- `WWIIHexV0/Commands/WarDirective.swift`
- `WWIIHexV0/Commands/WarCommandExecutor.swift`
- `WWIIHexV0/Agents/ZoneCommanderAgent.swift`
- `WWIIHexV0/Agents/MockAICommander.swift`
- `md/prompt/anti生成/v0.7/anti/0.70_v0.7_tactical_upgrade_implementation_record.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/flow/03_ai_zone_directive_pipeline.mermaid`
- `README.md`

验证记录：

- 轻量单文件语法检查通过：
  - `swiftc -parse WWIIHexV0/Commands/WarDirective.swift`
  - `swiftc -parse WWIIHexV0/Commands/WarCommandExecutor.swift`
  - `swiftc -parse WWIIHexV0/Agents/ZoneCommanderAgent.swift`
  - `swiftc -parse WWIIHexV0/Agents/MockAICommander.swift`

未跑：

- 未跑 Xcode / XCTest / 模拟器 / Probe / Smoke / Stage Regression / Dynamic Theater Regression / Full；原因是当前 `AGENTS.md` 与 `md/test/test.md` 规定默认只做轻量检查，且本轮用户明确禁止跑 Xcode。

遗留风险：

- 未做运行时战局验证，战术效果和 AI 行为只通过源码与轻量 parse 检查确认语法层可用。
- 当前工作树混有其他版本改动，合并前必须做文件/API/schema/文档冲突检查。

## v0.4 - 将军养成初步、将军 UI 与玩家双轨命令

完成日期：2026-07-04

目标分支：`v0.4-generals-command-ui-final`

分支审计：本轮从一个已混入 v0.9 / v0.5 / v1.x 外部未提交改动的工作树创建 0.4 续作分支。期间 checkout 又被外部切到 `codex/v0.8-economy-production`，最终已重新固定到 `v0.4-generals-command-ui-final`。按项目规则，本轮没有回滚外部改动；只在当前分支继续补齐 0.4 将军和玩家命令链路。合并前必须重新审查 project、public API、JSON schema 和文档口径冲突。

核心更新：

- 新增实体将军数据链：`generals.json`、`GeneralData`、`GeneralRegistry`、`GeneralDispatcher`。
- `RegionNodeDefinition` / MapEditor region draft 支持 `assignedGeneralId`，默认阿登 region JSON 已给蒙哥马利、魏刚、古德里安、里布写入初始种子。
- `FrontZone` 增加 `generalAssignment`，记录将军 id、HQ region、辖下 division、忠诚、满意度和玩家干预次数。
- `WarDeploymentState.preservingGeneralAssignments` 与 AppContainer 刷新逻辑保留/补齐将军分配，避免部署层重建后将军丢失。
- `TheaterCommanderPool` 在 AppContainer 构造时可由 `GeneralDispatcher.commanderPool` 使用真实将军配置，缺失时仍 fallback 到自动 commander。
- 新增 `PlayerCommandState` 和 `PlayerPlannedOperation`，保存本回合微操锁和玩家战区计划。
- 玩家微操 move/attack/hold/resupply/allowRetreat 成功后锁定该师，降低所属将军满意度并增加干预次数；结束回合或阵营/回合变化时清空锁。
- `WarCommandExecutor.execute` 新增兼容参数 `excluding excludedDivisionIds`，在进攻、防御、纵深防御和非矛头 hold 阶段跳过玩家微操部队。
- `AppContainer` 新增玩家宏观将军命令：`Hold Line` 生成 defense `ZoneDirective`，`Attack Region` 根据当前选中敌方 region 和相邻玩家 FrontZone 生成 attack `ZoneDirective`，执行后不自动结束回合。
- 新增 `GeneralCommandPanelView` 与 `GeneralProfileView`，展示将军头像占位、军衔、风格、技能、履历、忠诚/满意度、HQ 状态、辖下部队和计划操作。
- `RootGameView` 新增 `General` tab，Unit tab 也嵌入将军命令面板。
- `BoardScene` 根据 `PlayerPlannedOperation` 画进攻箭头/防御圆环，`UnitNode` 对本回合玩家微操单位画金色圈。
- `WarDirectiveRecord` 记录玩家宏观指令结果，AI 面板与日志可继续共用同一复盘数据。

关键系统：

- `WWIIHexV0/Data/generals.json`
- `WWIIHexV0/Agents/GeneralRegistry.swift`
- `WWIIHexV0/Core/GeneralAssignment.swift`
- `WWIIHexV0/Core/PlayerCommandState.swift`
- `WWIIHexV0/Core/FrontZone.swift`
- `WWIIHexV0/Core/WarDeploymentState.swift`
- `WWIIHexV0/Data/DataLoader.swift`
- `WWIIHexV0/Data/RegionDataSet.swift`
- `MapEditor/MapEditorDocument.swift`
- `MapEditor/MapEditorExporter.swift`
- `MapEditor/MapEditorGameResourceBridge.swift`
- `WWIIHexV0/App/AppContainer.swift`
- `WWIIHexV0/Commands/WarCommandExecutor.swift`
- `WWIIHexV0/UI/GeneralCommandPanelView.swift`
- `WWIIHexV0/UI/GeneralProfileView.swift`
- `WWIIHexV0/UI/RootGameView.swift`
- `WWIIHexV0/SpriteKit/BoardScene.swift`
- `WWIIHexV0/SpriteKit/UnitNode.swift`
- `WWIIHexV0.xcodeproj/project.pbxproj`
- `md/prompt/anti生成/0.4/v0.4_generals_command_ui_branch_record.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`

验证记录：

- `jq empty WWIIHexV0/Data/generals.json` 通过。
- `jq empty WWIIHexV0/Data/ardennes_v02_regions.json` 通过。
- `plutil -lint WWIIHexV0.xcodeproj/project.pbxproj` 通过，输出 `OK`。
- `git diff --check` 通过。
- 文档尾随空白检查无匹配。
- 单文件轻量 parse 通过：`PlayerCommandState.swift`、`GeneralAssignment.swift`、`GeneralRegistry.swift`、`GeneralCommandPanelView.swift`、`GeneralProfileView.swift`、`WarCommandExecutor.swift`、`AppContainer.swift`、`BoardScene.swift`、`UnitNode.swift`、`RootGameView.swift`。

未跑：

- 未跑 Xcode / XCTest / 模拟器 / Probe / Smoke / Stage Regression / Dynamic Theater Regression / Full；原因是当前 `AGENTS.md`、`md/test/test.md` 和用户要求均禁止本轮主动跑 Xcode 与重测试。

遗留风险：

- 未做运行时 UI 点击和 SpriteKit 视觉验证，按钮行为、sheet 展示、计划线位置仍需后续人工或授权轻量运行确认。
- 当前工作树混有其他版本改动，合并前必须重新做文件/API/schema/project 冲突审查。

## 历史维护记录

以下提交不作为正式 v 版本，但影响项目资料完整性：

- 2026-06-15：重整 `md` 目录，添加 README，补充 v0.1-v1.0 提示词。
- 2026-06-15：打捞 Agent D 与误删代码，恢复 AI 决策管线。
- 2026-06-15：记录 v0.5 擅自编程与回退资料，保留为历史警示；当前主线不得引入 Cabinet/StrategicDirective/Minister 污染。
- 2026-06-18：整理文档结构，将已完成阶段文档迁入 `md/prompt/...（已完成）`。
- 2026-06-24 至 2026-06-25：补充 0.36 提示词、0.355 截止分析、20 回合文档更新。
- 2026-06-27：创建 `AGENT.md`，写入后续 Codex 接手项目时的架构、测试、文档维护和交付规则。
- 2026-07-04：更新当前协作规范：默认禁止 Xcode / XCTest / 模拟器 / 性能类重测试，只做轻量语法/格式检查；新增多版本分支、并发子 Agent 和合并前冲突检查规则。关键文件：`AGENTS.md`、`md/test/test.md`、`md/flow/flow.md`、`README.md`、`md/prompt/v0.f/fable-5-重构优化总提示词.md`。
- 2026-07-04：新增拿破仑战争迁移总提示词，规划 v3.0-v3.8 从 WWIIHexV0 迁移为 AI Agent 驱动拿战游戏的版本路线、最终发布效果、并发子 Agent 分工、轻量检查和风险边界。关键文件：`md/prompt/v3.0-拿战迁移/codex-v3.0-拿战aiagent迁移总提示词.md`。
- 2026-07-04：新增明末迁移总提示词，规划 v4.0-v4.8 从 WWIIHexV0 迁移为 AI Agent 驱动明末历史策略游戏的产品目标、版本路线、最终发布效果、并发子 Agent 分工、轻量检查和风险边界。关键文件：`md/prompt/v4.0-明末迁移/codex-v4.0-明末aiagent迁移总提示词.md`。
- 2026-07-04：新增唐宋迁移总提示词，规划 v5.0-v5.9 从 WWIIHexV0 迁移为 AI Agent 驱动唐宋时代历史策略游戏的首发剧本、产品目标、架构边界、版本路线、并发子 Agent 分工、轻量检查和发布验收标准。关键文件：`md/prompt/v5.0-唐宋迁移/codex-v5.0-唐宋aiagent历史策略迁移总提示词.md`。
- 2026-07-04：新增现代战争迁移总提示词，规划 v6.0-v6.10 从 WWIIHexV0 迁移为 AI Agent 驱动现代联合指挥策略游戏的首发虚构剧本、ISR/EW/火力/无人系统闭环、版本路线、并发子 Agent 分工、轻量检查和发布验收标准。为避免与既有 v5.0 唐宋/维多利亚迁移文档冲突，现代战争路线使用 v6.0 起始版本。关键文件：`md/prompt/v6.0-现代战争迁移/codex-v6.0-现代战争aiagent迁移总提示词.md`。
- 2026-07-04：协作流程制度升级，不作为业务质量版本。项目从“本机轻量检查 + 人工/本地验收”升级为“`main` 直推 + GitHub Actions 云端重验证 + Agent C 下载未加密结果包复判”。新增角色召唤与身份标识、`main` 唯一上传/提交/推送/云端验证分支规则、Agent B push 后触发 CI、Agent C 核对 manifest/JUnit/xcodebuild log/failure summary、失败后在 `main` 追加修复 commit 的闭环。明确只复用 AITRANS 的协作制度骨架，不照搬漫画探针、GGUF、模型 Release、`smalldata_test` 等项目特例。关键文件：`AGENTS.md`、`README.md`、`md/test/test.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md`、`.github/workflows/ci-results.yml`。
- 2026-07-04：云端验证首跑发现 GitHub runner 使用的 Xcode 15 / Swift 5 不支持源码中的 `collection.count { ... }` 写法，追加等价兼容修复为 `filter { ... }.count`，不改变算法语义。关键文件：`WWIIHexV0/Rules/TheaterSystem.swift`、`WWIIHexV0/Rules/FrontLineManager.swift`、`WWIIHexV0/Rules/WarDeploymentManager.swift`。
- 2026-07-04：云端验证第二轮发现 `WarCommandExecutor.defensiveDestination` 的链式表达式在 Swift 5 下类型检查超时，追加拆分为显式 `preferredRegions`、`regionHexes`、`candidateHexes` 和命名排序闭包，不改变防御目的地选择语义。关键文件：`WWIIHexV0/Commands/WarCommandExecutor.swift`。
- 2026-07-04：根据唐宋迁移总提示词更新项目 `md` 大纲，不作为业务迁移实现。`md/plan/plan.md` 从旧 0.x 路线改为唐宋迁移版，补充 `md/` 目录职责、`山河一统 Agent` 首发目标、v5.0-v5.9 路线、迁移词汇表、阶段记录建议和轻量检查入口；README 文档索引同步为当前目录结构。关键文件：`md/plan/plan.md`、`README.md`。
- 2026-07-04：补充唐宋 v5.0 迁移审计与合同冻结记录，不作为源码迁移实现。记录当前二战绑定点、玩家可见残留、数据加载风险、AI 人物残留、v5.1 多势力/通用回合 public API 合同和实施边界。关键文件：`md/prompt/v5.0-唐宋迁移/v5.0_audit_and_contract.md`。
- 2026-07-04：推进唐宋 v5.1 多势力与通用回合地基第一步。新增 `PowerId`、`PowerProfile`、`PowerRelation`、`TurnOrderState`、`WarRelationRules` 兼容合同；`GameState` 新增可向后解码的 `turnOrderState`；`CommandValidator`、`CommandExecutor`、`TurnManager`、`AppContainer`、命令/经济面板改为通过 `effectiveTurnOrderState` 判断命令和 AI 控制权，不再在这些主路径直接 switch Germany/Allies 推进回合。默认阿登数据和 legacy `Faction` 仍保留，唐宋剧本切换留给 v5.2。关键文件：`WWIIHexV0/Core/Faction.swift`、`WWIIHexV0/Core/GameState.swift`、`WWIIHexV0/Rules/CommandValidator.swift`、`WWIIHexV0/Rules/CommandExecutor.swift`、`WWIIHexV0/Turn/TurnManager.swift`、`WWIIHexV0/App/AppContainer.swift`、`WWIIHexV0/Data/DataLoader.swift`、`WWIIHexV0/UI/CommandPanelView.swift`、`WWIIHexV0/UI/EconomyPanelView.swift`、`WWIIHexV0/UI/RootGameView.swift`、`md/prompt/v5.0-唐宋迁移/v5.1_powers_turn_order_record.md`。
- 2026-07-05：推进唐宋 v5.2 首发剧本数据与默认入口首轮。新增 `tangsong_jianlong_960_scenario.json`、`tangsong_jianlong_960_regions.json`、`tangsong_unit_templates.json`、`tangsong_characters.json`；默认 `DataLoader.loadInitialGameState()` 优先加载 `jianlong_960_unification`，阿登作为 legacy fallback；`GameState` 增加场景/势力/阶段显示桥；HUD、经济面板、命令面板和棋盘 accessibility label 改为唐宋场景感知显示；新 JSON 加入 iOS/macOS 主 target resources。底层 `Faction.allies/germany` 仍作为宋/割据 AI legacy 桥，MapEditor 全术语迁移和真实多政权数据驱动留给后续。关键文件：`WWIIHexV0/Data/DataLoader.swift`、`WWIIHexV0/Core/GameState.swift`、`WWIIHexV0/UI/HUDView.swift`、`WWIIHexV0/UI/EconomyPanelView.swift`、`WWIIHexV0/UI/CommandPanelView.swift`、`WWIIHexV0/UI/RootGameView.swift`、`WWIIHexV0/SpriteKit/BoardScene.swift`、`WWIIHexV0.xcodeproj/project.pbxproj`、`md/prompt/v5.0-唐宋迁移/v5.2_scenario_mapeditor_record.md`。
- 2026-07-05：推进唐宋 v5.2 MapEditor 默认资源桥与工具术语迁移。`MapEditorGameResourceBridge` 默认读写 `tangsong_jianlong_960_scenario.json` / `tangsong_jianlong_960_regions.json`，读取时保留阿登 legacy fallback；MapEditor 模式、侧栏、状态消息和模板选择迁为地块、州府、方面、军队、粮仓、关隘、宋、割据诸政权；默认军队模板改为 `tangsong_prefecture_army`，导出注记改为 v5.2 唐宋资源桥。底层 `Faction`、`RegionId`、`TheaterId`、`Division` 兼容类型仍保留，MapEditor 仍不编辑单位模板和人物 JSON。关键文件：`MapEditor/MapEditorGameResourceBridge.swift`、`MapEditor/MapEditorDocument.swift`、`MapEditor/MapEditorViewModel.swift`、`MapEditor/MapEditorView.swift`、`MapEditor/MapEditorExporter.swift`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/v5.0-唐宋迁移/v5.2_scenario_mapeditor_record.md`、`README.md`、`md/plan/plan.md`。
- 2026-07-05：推进唐宋 v5.3 古代军制、粮草与生产显示桥首轮。新增 `EconomyResources.summary(isTangSongScenario:)`、`ProductionKind.displayName(isTangSongScenario:)` 和 `producedUnitBaseName(isTangSongScenario:)`；唐宋路径下生产按钮、排产/部署/补员/缺粮/经济结算/结束回合日志显示为军备、府库、丁口、钱帛、粮草、禁军、厢军、骑军、攻城器械营，不再在该生产链路直接输出 `Panzer Division`、`Germany`、`MP/IC/SUP`。底层 `ProductionKind`、`EconomyResources`、`Division`、`ComponentType` schema 仍保留，真实围城、粮道和古代兵种战斗加成留后续 v5.3 切片。关键文件：`WWIIHexV0/Core/EconomyState.swift`、`WWIIHexV0/Commands/Command.swift`、`WWIIHexV0/Rules/EconomyRules.swift`、`WWIIHexV0/Rules/RuleEngine.swift`、`WWIIHexV0/Rules/CommandExecutor.swift`、`WWIIHexV0/App/AppContainer.swift`、`WWIIHexV0/UI/EconomyPanelView.swift`、`md/prompt/v5.0-唐宋迁移/v5.3_rules_siege_grain_record.md`、`md/flow/flow.md`、`md/flow/flowchart.md`。
- 2026-07-05：按唐宋 v5.0-v5.9 总提示词补强项目 `md` 大纲，不作为源码迁移实现。`md/plan/plan.md` 增加当前迁移进度快照、v5.0-v5.9 状态列、v5.3 待续风险和下一轮优先方向，明确当前只完成生产/府库显示桥首轮，围城、真实粮道、古代兵种规则、天命/归附/治理、发布级 UI 和 AI 术语迁移仍待后续。关键文件：`md/plan/plan.md`、`update_log.md`。
- 2026-07-05：推进唐宋 v5.3 古代兵种战斗修正首轮。新增 `TangSongCombatRole` 和 `Division.tangSongCombatRoles`，在不改 `ComponentType` Codable schema 的前提下，由单位 id、生产 kind id 和现有组件权重推导禁军、厢军、骑军、弓弩守军、攻城器械营和守军角色；`CombatRules` 仅在 `state.isTangSongScenario` 下启用唐宋攻防修正：骑军平原/道路进攻加成、攻城器械攻城加成与野战弱化、弓弩守军和守军城防加成。攻击、撤退、反击、消灭仍走 `CommandExecutor` / `RuleEngine`，攻击不直接占领 hex；围城状态、真实粮道、城防耐久和水师仍待后续。关键文件：`WWIIHexV0/Core/Division.swift`、`WWIIHexV0/Rules/CombatRules.swift`、`md/prompt/v5.0-唐宋迁移/v5.3_rules_siege_grain_record.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`README.md`、`md/plan/plan.md`。
- 2026-07-05：推进唐宋 v5.3 粮道供给首轮。`SupplyRules` 在唐宋场景下把己方控制、passable、`supplyValue >= 4` 的州府/粮仓 region 追加为有效补给源，唐宋补给路径上限提高到 9，并按道路、城关、平原、山林、山地、跨河设置不同成本；`SupplyRules` 与 `RegionSupplyRules` 的敌控通行判断改用 `WarRelationRules.canTarget`，不再依赖二元 `Faction.opponent`。本轮不新增 `SupplyState`、漕运 UI、粮队、仓储容量、围城断粮或城防耐久。关键文件：`WWIIHexV0/Rules/SupplyRules.swift`、`WWIIHexV0/Rules/RegionSupplyRules.swift`、`md/prompt/v5.0-唐宋迁移/v5.3_rules_siege_grain_record.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`README.md`、`md/plan/plan.md`。
- 2026-07-05：推进唐宋 v5.3 围城状态首轮。新增 `SiegeState` / `SiegeRecord` 和 `Command.besiege(attackerId:targetRegionId:)`，围城命令经 `CommandValidator` 校验敌对城池/关隘/高补给粮仓州府与距离后，由 `CommandExecutor` 登记围城压力并标记军队已行动；结束回合在补给刷新后应用围城压力，pressure 达阈值时把被围州府内 supplied 守方军队降为 `lowSupply`；Region 面板和 EventLog 可读围城状态。本轮不自动破城，不改 `HexTile.controller`、`RegionNode.controller`、`hexToTheater` 或 `hexToFrontZone`，不实现城防耐久、修城、招降、围城 overlay 或 AI 主动围城指令。关键文件：`WWIIHexV0/Core/GameState.swift`、`WWIIHexV0/Core/GameLogEntry.swift`、`WWIIHexV0/Commands/Command.swift`、`WWIIHexV0/Commands/CommandValidation.swift`、`WWIIHexV0/Commands/WarCommandExecutor.swift`、`WWIIHexV0/Rules/CommandValidator.swift`、`WWIIHexV0/Rules/CommandExecutor.swift`、`WWIIHexV0/App/AppContainer.swift`、`WWIIHexV0/SpriteKit/MapDisplayAdapter.swift`、`WWIIHexV0/UI/CommandPanelView.swift`、`WWIIHexV0/UI/EventLogView.swift`、`WWIIHexV0/UI/RegionInspectorView.swift`、`WWIIHexV0/UI/RootGameView.swift`、`md/prompt/v5.0-唐宋迁移/v5.3_rules_siege_grain_record.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`README.md`、`md/plan/plan.md`。
- 2026-07-05：根据唐宋 v5.0-v5.9 总提示词再次整理项目 `md` 大纲，不作为业务源码迁移。`md/plan/plan.md` 增加交接使用方式、v5.3 剩余切片队列、v5.3 收口标准、后续阶段进入条件和文档同步触发规则，明确下一步仍优先围绕城防耐久、修城、解围、AI 围城指令、围城 UI 或漕运粮道小切片推进。关键文件：`md/plan/plan.md`、`update_log.md`。
- 2026-07-05：推进唐宋 v5.3 城防耐久与修城命令首轮。`SiegeRecord` 新增向后兼容的 `fortification / maxFortification` 字段，旧围城记录缺字段时用 `decodeIfPresent` 从默认城防和既有 pressure 推导；`Command.besiege` 现在累积 pressure 并按攻城器械、骑军和要塞地形损耗城防；结束回合只有在 `pressure >= 10` 且城防归零时才把目标州府内 supplied 守军压为 `lowSupply`。新增 `Command.repairFortification(defenderId:targetRegionId:)`，守方军队必须位于己控且被围的目标州府内，并通过 `CommandValidator -> CommandExecutor` 消耗行动恢复城防；Command 面板新增修城按钮，Region 面板显示城防。本轮仍不自动破城、不招降、不新增解围命令、不做围城 overlay，不改 `HexTile.controller`、`RegionNode.controller`、`hexToTheater` 或 `hexToFrontZone`。关键文件：`WWIIHexV0/Core/GameState.swift`、`WWIIHexV0/Commands/Command.swift`、`WWIIHexV0/Commands/CommandValidation.swift`、`WWIIHexV0/Commands/WarCommandExecutor.swift`、`WWIIHexV0/Rules/CommandValidator.swift`、`WWIIHexV0/Rules/CommandExecutor.swift`、`WWIIHexV0/App/AppContainer.swift`、`WWIIHexV0/UI/CommandPanelView.swift`、`WWIIHexV0/UI/RegionInspectorView.swift`、`WWIIHexV0/UI/RootGameView.swift`、`README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/v5.0-唐宋迁移/v5.3_rules_siege_grain_record.md`。
- 2026-07-05：推进唐宋 v5.3 解围/驰援命令首轮。新增 `Command.relieveSiege(relieverId:targetRegionId:)`，经 `CommandValidator.validateRelieveSiege` 校验己控且被围的目标州府、守方/友军身份、军队未行动，以及军队在目标州府内或目标 display hexes 距离内；`CommandExecutor.executeRelieveSiege` 按攻防、骑军/禁军、补给状态和是否在州府内计算 relief，只削减 `SiegeRecord.pressure`，pressure 降到 0 时移除围城记录并记录 siege 日志。Command 面板新增解围按钮。本轮不删除敌军、不移动敌军、不改 `HexTile.controller`、`RegionNode.controller`、`hexToTheater` 或 `hexToFrontZone`，不实现自动破城、招降、围城 overlay 或 AI 主动围城指令。关键文件：`WWIIHexV0/Core/GameState.swift`、`WWIIHexV0/Commands/Command.swift`、`WWIIHexV0/Commands/WarCommandExecutor.swift`、`WWIIHexV0/Rules/CommandValidator.swift`、`WWIIHexV0/Rules/CommandExecutor.swift`、`WWIIHexV0/App/AppContainer.swift`、`WWIIHexV0/UI/CommandPanelView.swift`、`WWIIHexV0/UI/RootGameView.swift`、`README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/v5.0-唐宋迁移/v5.3_rules_siege_grain_record.md`。
- 2026-07-05：推进唐宋 v5.3 围城地图 overlay 首轮。新增 `SiegeOverlayState` 和 `MapDisplayAdapter.siegeOverlays(viewerFaction:)`，从 `GameState.siegeState.records` 派生只读地图显示数据，并按观察者模式、攻守相关方或州府可见性过滤；`BoardScene.drawSiegeOverlays` 在非 frontLine 图层绘制被围州府六角描边、代表点围城圆环和“围/城防”短标签。该 overlay 不写回 `GameState`，不改 `HexTile.controller`、`RegionNode.controller`、`hexToTheater` 或 `hexToFrontZone`。本轮不实现自动破城、招降、AI 主动围城或漕运 UI。关键文件：`WWIIHexV0/SpriteKit/MapDisplayAdapter.swift`、`WWIIHexV0/SpriteKit/BoardScene.swift`、`README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/v5.0-唐宋迁移/v5.3_rules_siege_grain_record.md`。
- 2026-07-05：推进唐宋 v5.3 AI 围城指令首轮。`WarCommandExecutor.executeAttack` 在 `ZoneDirective.attack` 目标州府没有可攻击敌军时，会检查目标 region 是否为敌控城池/关隘/高补给粮仓、攻击军队射程是否覆盖目标 display hexes，满足时生成底层 `Command.besiege(attackerId:targetRegionId:)`；实际状态写入仍由 `RuleEngine -> CommandValidator.validateBesiege -> CommandExecutor.executeBesiege` 完成，AI 不直接写 `GameState.siegeState`，不改 `HexTile.controller`、`RegionNode.controller`、`hexToTheater` 或 `hexToFrontZone`。本轮不实现自动破城、招降或漕运 UI。关键文件：`WWIIHexV0/Commands/WarCommandExecutor.swift`、`README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/v5.0-唐宋迁移/v5.3_rules_siege_grain_record.md`。
- 2026-07-05：推进唐宋 v5.3 粮道读法 UI 首轮。新增 `SupplyRouteSummary` 和 `SupplyRules.supplyRouteSummary(for:in:)`，只读汇总当前军队补给状态、补给源数量、最近粮源、可达路径成本/上限和安全退路数；`MapDisplayAdapter.unitInspectorState` 将摘要传给 `UnitInspectorView`，唐宋场景显示“粮道”通断、成本/上限、最近粮源和退路数。本轮不新增 `SupplyState`，不改变补给判定，不实现完整漕运、粮队、仓储容量或地图粮道线。关键文件：`WWIIHexV0/Rules/SupplyRules.swift`、`WWIIHexV0/SpriteKit/MapDisplayAdapter.swift`、`WWIIHexV0/UI/UnitInspectorView.swift`、`README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/v5.0-唐宋迁移/v5.3_rules_siege_grain_record.md`。
- 2026-07-05：推进唐宋 v5.3 围城招降命令首轮。新增 `Command.demandSurrender(negotiatorId:targetRegionId:)`，经 `CommandValidator.validateDemandSurrender` 校验围城方军队、目标仍由原守方控制、距离合法、`pressure >= 10`、`fortification == 0`、目标州府内没有仍为 `supplied` 的守军，并至少有可交割 capturable hex；`CommandExecutor.executeDemandSurrender` 移除目标州府内已断粮/被围守军，交割目标州府可占 hex 给围城方，移除 `SiegeRecord`，标记招降军队已行动，并调用 `StrategicStateSynchronizer` 刷新 Region / Theater / FrontLine / WarDeployment。Command 面板新增招降按钮。本轮不做结束回合自动破城、不做完整外交归附、不做 AI 主动招降。关键文件：`WWIIHexV0/Commands/Command.swift`、`WWIIHexV0/Commands/CommandValidation.swift`、`WWIIHexV0/Rules/CommandValidator.swift`、`WWIIHexV0/Rules/CommandExecutor.swift`、`WWIIHexV0/Commands/WarCommandExecutor.swift`、`WWIIHexV0/App/AppContainer.swift`、`WWIIHexV0/UI/CommandPanelView.swift`、`WWIIHexV0/UI/RootGameView.swift`、`README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/v5.0-唐宋迁移/v5.3_rules_siege_grain_record.md`。
- 2026-07-05：推进唐宋 v5.3 AI 主动招降指令首轮。`WarCommandExecutor.executeAttack` 在 `ZoneDirective.attack` 路径中先尝试 `demandSurrenderCommand`：若当前目标州府已有满足条件的 `SiegeRecord`，则生成底层 `Command.demandSurrender(negotiatorId:targetRegionId:)`；若招降不合法，仍按原顺序攻击可见敌军、生成 `Command.besiege` 或移动/固守。AI 不直接写 `GameState.siegeState`、不直接改 `HexTile.controller`、`RegionNode.controller`、`hexToTheater` 或 `hexToFrontZone`，招降成败继续由 `RuleEngine -> CommandValidator -> CommandExecutor` 决定。本轮不做自动破城、完整外交归附或 AI 解释文案。关键文件：`WWIIHexV0/Commands/WarCommandExecutor.swift`、`README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/v5.0-唐宋迁移/v5.3_rules_siege_grain_record.md`。
- 2026-07-05：根据唐宋 v5.0-v5.9 总提示词整理项目 `md` 大纲，不作为业务源码迁移。`md/plan/plan.md` 明确承担阶段文档包清单和交接口径，补充首发体验锚点、v5.4-v5.9 阶段记录拆分、v5.3 待续小切片、发布验收边界和文档-only 轻量检查入口；本轮未修改 Swift / JSON / project 文件。关键文件：`md/plan/plan.md`、`update_log.md`。
- 2026-07-05：推进唐宋 v5.4 AI 军议显示桥首轮。`DirectiveType`、`CommandCategory`、`TacticName` 新增 `displayName(isTangSongScenario:)`，唐宋场景下把 attack/defend、offense/defense 和 `standardAttack`、`blitzkrieg`、`pincerMovement`、`fireCoverage` 等 raw case 显示为进军、固守、攻势、防务、骑军突进、合围、弓弩压制、死守城关等；`AgentPanelView` 接收 `isTangSongScenario` 后显示“军议”“方面军令”“军令结果”和唐宋战术名，`CommandResultSummary.directiveCommand` 在唐宋场景保存底层命令的唐宋显示名。底层 Codable schema、AI 决策、`ZoneDirective -> WarCommandExecutor -> RuleEngine` 执行权限不变；完整皇帝/朝廷/枢密/节度使/转运使/州府守臣/外交使者 schema、simulated rationale 唐宋化和真实 LLM 接入仍待后续。关键文件：`WWIIHexV0/Commands/WarDirective.swift`、`WWIIHexV0/Agents/AgentDecisionRecord.swift`、`WWIIHexV0/UI/AgentPanelView.swift`、`WWIIHexV0/UI/RootGameView.swift`、`WWIIHexV0/Turn/TurnManager.swift`、`WWIIHexV0/App/AppContainer.swift`、`md/prompt/v5.0-唐宋迁移/v5.4_agent_schema_record.md`、`README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`。
- 2026-07-05：推进唐宋 v5.4 simulated marshal JSON 文案唐宋化首轮。`MarshalAgentConfig.automatic` 在 `jianlong_960_unification` 场景下把 legacy `.allies` / `.germany` 桥显示为 `marshal_song_privy_council` / 宋枢密院和 `marshal_separatist_command` / 割据行营；`MarshalBattlefieldSummary` 新增 `scenarioId`，`SimulatedMarshalLLMClient` 据此在唐宋场景输出枢密院令、方面军令 summary 和“军议：进军/固守、兵势比、州府目标、粮道状态”的 rationale。`TheaterCommanderPool` fallback 的自动方面主将和 theaterContext 也改为唐宋口径，`AppContainer` 的空 registry fallback 改为复用该自动池。非唐宋场景保持 Rundstedt / Eisenhower 与英文 simulated marshal 文案；`TheaterDirectiveEnvelope` / `ZoneDirective` schema、decoder/validator、`ZoneDirective -> WarCommandExecutor -> RuleEngine` 执行权限不变。关键文件：`WWIIHexV0/Agents/ZoneCommanderAgent.swift`、`WWIIHexV0/App/AppContainer.swift`、`README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/v5.0-唐宋迁移/v5.4_agent_schema_record.md`。
- 2026-07-05：推进唐宋 v5.4 元帅 envelope 解释字段首轮。`TheaterDirectiveEnvelope` 新增可选 `mandateIntent`、`courtPolicy`、`pacificationTargets`、`supplyPriorities` 字段；`TheaterDirectiveDecoder` 会校验其中 region id 是否存在。`MarshalBattlefieldSummary` 新增唐宋首都、被威胁首都、围城、粮道优先和招抚候选 region 摘要，`SimulatedMarshalLLMClient` 在唐宋场景下填充天命/正朔意图、中书枢密方针、招抚候选州府和粮道优先支应州府。新增字段只解释上游 AI 意图，不参与 `TheaterDirectiveCompiler`、`WarCommandExecutor` 或 `RuleEngine`，不直接改变外交、补给、控制权或战斗结果。关键文件：`WWIIHexV0/Commands/WarDirective.swift`、`WWIIHexV0/Agents/ZoneCommanderAgent.swift`、`README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/v5.0-唐宋迁移/v5.4_agent_schema_record.md`。
- 2026-07-05：推进唐宋 v5.4 AI 面板解释摘要首轮。新增 `TheaterDirectiveExplanationSummary` 并挂到 `AgentDecisionRecord.theaterDirectiveSummary`；`TurnManager.runMarshalDirectiveTurn` 从元帅 `TheaterDirectiveEnvelope` 复制 `mandateIntent`、`courtPolicy`、`pacificationTargets`、`supplyPriorities` 和 summary；`AgentPanelView` 在唐宋场景下结构化显示“诏令 / 朝议 / 招抚 / 转运 / 摘要”。这些字段仍只用于复盘解释，不参与 `TheaterDirectiveCompiler`、`WarCommandExecutor`、`RuleEngine`，不直接改变外交、补给、控制权或战斗结果。关键文件：`WWIIHexV0/Agents/AgentDecisionRecord.swift`、`WWIIHexV0/Turn/TurnManager.swift`、`WWIIHexV0/UI/AgentPanelView.swift`、`README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/v5.0-唐宋迁移/v5.4_agent_schema_record.md`。
- 2026-07-05：推进唐宋 v5.4 默认 AI issuer 唐宋化首轮。新增 `GameAgent.defaultCommander(for:from:state:)`，唐宋场景下为 `.allies` 生成 `marshal_song_privy_council` / 宋枢密院、为 `.germany` 生成 `marshal_separatist_command` / 割据行营；`AppContainer.bootstrap` 与动态 `turnManager(for:)` 改用该工厂，避免默认唐宋 `AgentDecisionRecord.agentId` 和 `WarDirectiveRecord.commanderAgentId` 继续显示 Guderian 或 Allied Mock Commander。legacy 阿登路径仍保留 `GameAgent.guderian(from:state:)`、`guderianFallback` 和 `allied_mock_commander`，默认战争执行仍收口到 `MarshalDirective -> ZoneDirective -> WarCommandExecutor -> RuleEngine`。关键文件：`WWIIHexV0/Agents/GameAgent.swift`、`WWIIHexV0/Agents/AgentConfiguration.swift`、`WWIIHexV0/App/AppContainer.swift`、`README.md`、`md/flow/flow.md`、`md/plan/plan.md`、`md/prompt/v5.0-唐宋迁移/v5.4_agent_schema_record.md`。
- 2026-07-05：推进唐宋 v5.5 默认主界面术语桥首轮，并按总提示词更新项目 `md` 大纲。`MapDisplayLayer`、`GamePhase` 和 `GameState.phaseDisplayName` 提供唐宋场景显示桥；`RootGameView` 的图层、观战、面板按钮、compact tabs 和棋盘 accessibility label 改为唐宋口径；`HUDView` 显示新局、结束回合、回合、政权、阶段、胜负和队列；`CommandPanelView` 显示军令、固守、可退、整补和唐宋状态提示；`EventLogView` 显示战报、暂无战报、回合/系统/开局，以及战斗、退却、整补、合围、围城、粮道、前线、方面、州府、外交、事件等分类。新增 `v5.5_ui_visual_record.md` 并同步 `README.md`、`md/flow/*`、`md/plan/plan.md`。本轮只改显示读法，不改变 raw case、命令、日志结构、AI 或规则执行；完整发布级视觉、截图和布局验收仍待后续。关键文件：`WWIIHexV0/Core/MapDisplayLayer.swift`、`WWIIHexV0/Core/GamePhase.swift`、`WWIIHexV0/Core/GameState.swift`、`WWIIHexV0/UI/RootGameView.swift`、`WWIIHexV0/UI/NewGameButton.swift`、`WWIIHexV0/UI/HUDView.swift`、`WWIIHexV0/UI/CommandPanelView.swift`、`WWIIHexV0/UI/EventLogView.swift`、`README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/v5.0-唐宋迁移/v5.5_ui_visual_record.md`。
- 2026-07-05：推进唐宋 v5.5 地图视觉 token 与军旗棋子首轮。`TerrainStyle` 新增唐宋场景 palette，覆盖墨绿地图底、绢帛/青绿/石灰/铜土/城池/关隘地形、赭石道路、石青河流、朱印宋军、铜褐割据和补给/部署色；`HexNode`、`RegionOverlayNode`、`MapDisplayAdapter`、`MapLayerOverlayNode` 和 `BoardScene` 按 `GameState.isTangSongScenario` 只读切换地块、州府边界、前线、部署、围城圈和计划箭头颜色；`UnitNode` 在唐宋场景下从 NATO APP-6 符号切为内置军旗轮廓和禁/骑/弩/械/守/军兵种字标，legacy 阿登路径保持旧符号。该切片仍不接外部美术资产、不改规则/命令/存档、不做运行截图或布局验收。关键文件：`WWIIHexV0/SpriteKit/TerrainStyle.swift`、`WWIIHexV0/SpriteKit/HexNode.swift`、`WWIIHexV0/SpriteKit/RegionOverlayNode.swift`、`WWIIHexV0/SpriteKit/UnitNode.swift`、`WWIIHexV0/SpriteKit/MapDisplayAdapter.swift`、`WWIIHexV0/SpriteKit/MapLayerOverlayNode.swift`、`WWIIHexV0/SpriteKit/BoardScene.swift`、`README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/v5.0-唐宋迁移/v5.5_ui_visual_record.md`。
- 2026-07-05：推进唐宋 v5.5 只读粮道地图 overlay 首轮，并按用户要求启用并发子 Agent 审计加速。新增 `SupplyRouteOverlayState` 和 `MapDisplayAdapter.supplyRouteOverlays(viewerFaction:)`，从既有 `SupplyRules.supplyRouteSummary(for:in:)` 派生唐宋场景可见友方军队到最近可见粮源的显示数据；`BoardScene.drawSupplyRouteOverlays` 在道路/河流之后、围城/计划/单位之前绘制抽象粮道虚线、粮源“粮”标记和短标签。普通玩家只看己方可见军队与可见粮源，observer/revealAll 才显示全阵营；该 overlay 不写回 `GameState`，不改变 `SupplyState`、补给判定、命令、AI 或规则执行，也不表示真实逐 hex 路径。同步 `README.md`、`md/flow/*`、`md/plan/plan.md`、`v5.3_rules_siege_grain_record.md` 和 `v5.5_ui_visual_record.md`，并在大纲中记录 v5.6 进入前必须先做外交/归附/天命规则合同的风险。关键文件：`WWIIHexV0/SpriteKit/MapDisplayAdapter.swift`、`WWIIHexV0/SpriteKit/BoardScene.swift`、`README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/v5.0-唐宋迁移/v5.3_rules_siege_grain_record.md`、`md/prompt/v5.0-唐宋迁移/v5.5_ui_visual_record.md`。
- 2026-07-05：推进唐宋 v5.6a 外交归附与天命规则合同首轮，并按用户要求使用并发子 Agent 审计规则、数据和文档边界。`DiplomaticStatus` 扩展 `tributary`、`submitting`、`negotiating`；新增 `PacificationRecord` 与 `MandateState`，`GameState` 以 `decodeIfPresent` 兼容旧存档；唐宋默认剧本初始化宋/割据天命分数。新增 `Command.proposeSubmission(negotiatorId:targetCountryId:targetRegionIds:)`，经 `CommandValidator` 校验 phase、谈判军队、国家关系、目标州府、天命阈值、低 warSupport 或围城压力，再由 `CommandExecutor` 写入 `DiplomacyState`、`MandateState` 和 diplomacy 日志；`WarCommandExecutor` 仅补充该命令的行动军队和影响 region 识别，用于既有指令记录辅助，不自动生成归附。本轮不交割 hex/region 控制权，不转换部队，不改变 `TurnOrderState.relations` 的 `.allies/.germany` 全局战争关系，不让 `pacificationTargets` 自动执行，也不实现唐宋胜利规则。关键文件：`WWIIHexV0/Core/DiplomacyState.swift`、`WWIIHexV0/Core/GameState.swift`、`WWIIHexV0/Data/DataLoader.swift`、`WWIIHexV0/Commands/Command.swift`、`WWIIHexV0/Commands/CommandValidation.swift`、`WWIIHexV0/Commands/WarCommandExecutor.swift`、`WWIIHexV0/Rules/CommandValidator.swift`、`WWIIHexV0/Rules/CommandExecutor.swift`、`README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/v5.0-唐宋迁移/v5.6a_diplomacy_mandate_contract_record.md`。
- 2026-07-05：推进唐宋 v5.6b 玩家招抚入口与外交面板只读展示首轮，并按用户要求继续使用并发子 Agent 审计文档、规则链和轻量检查边界。`CommandPanelView` 新增“招抚”按钮，`RootGameView` 接入按钮回调；`AppContainer.proposeSubmissionSelected()` 只把玩家操作转换为 `Command.proposeSubmission` 并交给 `submit -> RuleEngine`，目标优先使用当前选中的外国首府，否则扫描当前可通过 `CommandValidator` 的外国首府候选；`DiplomacyPanelView` 只读展示 `MandateState`、诸国关系和最近 `PacificationRecord`。本轮不交割 hex/region 控制权，不转换部队，不改变 `TurnOrderState.relations`，不自动执行 AI `pacificationTargets`，也不让天命影响胜利；当前 UI 仍只能从首府 region 推断目标国家。关键文件：`WWIIHexV0/App/AppContainer.swift`、`WWIIHexV0/UI/CommandPanelView.swift`、`WWIIHexV0/UI/RootGameView.swift`、`WWIIHexV0/UI/DiplomacyPanelView.swift`、`README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/flow/01_overall_core_flow.mermaid`、`md/plan/plan.md`、`md/prompt/v5.0-唐宋迁移/v5.6b_player_submission_diplomacy_panel_record.md`。
- 2026-07-05：推进唐宋 v5.6c AI 招抚候选到规则命令安全桥首轮，并按用户要求继续使用并发子 Agent 审计加速。`TurnManager.runMarshalDirectiveTurn` 读取 `TheaterDirectiveEnvelope.pacificationTargets`，在战争 `ZoneDirective` 执行后、`.endTurn` 前由 `executePacificationTargets` 把首府候选反查为外国 `CountryProfile`，选择当前 AI faction 未行动、未撤退、可行动军队作为谈判军队，生成辅助 `Command.proposeSubmission(negotiatorId:targetCountryId:targetRegionIds:)` 并交给 `commandHandler.execute -> RuleEngine`；成功、规则拒绝或跳过写入 `AgentDecisionRecord.commandResults`，每个 AI 回合最多 1 个成功招抚提议。`CommandResultSummary` 新增 AI auxiliary command / skipped 记录工厂。本轮不改变 `Command.proposeSubmission` 语义，不改 `TheaterDirectiveCompiler` 或 `WarCommandExecutor`，不交割 hex/region 控制权，不转换部队，不改变 `TurnOrderState.relations`，也不让天命影响胜利。关键文件：`WWIIHexV0/Turn/TurnManager.swift`、`WWIIHexV0/Agents/AgentDecisionRecord.swift`、`README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/flow/01_overall_core_flow.mermaid`、`md/plan/plan.md`、`md/prompt/v5.0-唐宋迁移/v5.4_agent_schema_record.md`、`md/prompt/v5.0-唐宋迁移/v5.6c_ai_pacification_submission_record.md`。
- 2026-07-05：推进唐宋 v5.6d 天命/国威胜利评价桥首轮。`VictoryReason` 新增 `tangSongUnificationByMandate` 与 `tangSongSeparatistSurvival`；`VictoryRules.updateVictoryState` 在唐宋场景先走 `updateTangSongVictoryState`，宋控制开封、洛阳、太原、金陵、成都、杭州中的至少四处且宋天命不低于 60 时判定宋统一胜利，割据阵营若到最大回合仍控制太原、金陵、成都中的至少两处且割据天命不低于 35，则判定割据生存。阿登 legacy Bastogne / St. Vith / 单位损失 / 装甲断补胜利逻辑保持非唐宋路径。本轮不读取 JSON `victoryConditions` 动态生成规则，不实现治理政策、不交割归附控制权、不转换部队、不改变 `MandateState` 调整来源。关键文件：`WWIIHexV0/Core/VictoryState.swift`、`WWIIHexV0/Rules/VictoryRules.swift`、`README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/v5.0-唐宋迁移/v5.6d_tangsong_victory_mandate_record.md`。
- 2026-07-05：推进唐宋 v5.6e 外交关系到 power 战争关系保守投影首轮。`DiplomacyState.projectedPowerRelationStatus(between:and:)` 会聚合两个 legacy faction 之间的国家级关系，只要仍有任一跨 faction 国家关系是 `hostile` / `atWar` 就投影为 `.atWar`；`TurnOrderState.setRelationStatus` 提供稳定 upsert；`CommandExecutor.executeProposeSubmission` 成功写入国家关系后同步该投影到 `TurnOrderState.relations`，供 `WarRelationRules.canTarget` 继续作为攻击、补给通行和围城合法性来源。本轮不实现吴越等单国 tactical neutral，不新增国家级 `PowerId`，不交割 hex/region 控制权，不转换部队，不实现治理政策。关键文件：`WWIIHexV0/Core/DiplomacyState.swift`、`WWIIHexV0/Core/Faction.swift`、`WWIIHexV0/Rules/CommandExecutor.swift`、`README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/v5.0-唐宋迁移/v5.6e_diplomacy_turn_order_projection_record.md`。
- 2026-07-06：推进唐宋 v5.6f 战术候选关系感知首轮，并按用户要求使用并发子 Agent 审计 UI 与 AI/执行器残留。`AppContainer` 的点击攻击、攻击高亮、将领 attack target 和 command zone 推断改为先读 `WarRelationRules.canTarget`；`WarCommandExecutor` 的敌强、敌区、敌军可见、围城目标和战术移动/占领候选改为按 `canTarget` 判断，且战争移动目的地会排除非己方且非敌对 controller 的 hex；`ZoneCommanderAgent`、`MarshalBattlefieldSummarizer` 和 `MockAICommander` 的敌情估算与 `weightedRegions` 来源同步改为关系感知。招抚/谈判候选保持外交规则口径，继续由 `CommandValidator.validateProposeSubmission` 判断；本轮不实现单国 tactical neutral，不交割控制权，不转换部队，不新增国家级 `PowerId`。关键文件：`WWIIHexV0/App/AppContainer.swift`、`WWIIHexV0/Commands/WarCommandExecutor.swift`、`WWIIHexV0/Agents/ZoneCommanderAgent.swift`、`WWIIHexV0/Agents/MockAICommander.swift`、`README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/v5.0-唐宋迁移/v5.6f_relation_aware_war_candidates_record.md`。
- 2026-07-06：推进唐宋 v5.6g 数据驱动胜利条件首轮，并按用户要求继续使用并发子 Agent 审计代码和文档口径。`VictoryConditionDefinition` 新增可选 `mandateThreshold`；`GameState` 保存从场景 JSON 读取的 `victoryConditions`，旧状态缺字段时兼容为空数组；`DataLoader.loadGameState` 将唐宋 JSON 的胜利条件写入运行态，并对 objective 引用、胜利条件 faction/type/status/count 和 objective id 做轻量校验；`MapState` 增加按 objective id 查询控制方；`VictoryRules.updateTangSongVictoryState` 优先按 `controlObjectives` / `holdObjectives` 的 objective id、count、turn / turns 和 `mandateThreshold` 判定宋统一或割据生存，缺失条件时保留 v5.6d 硬编码 fallback。唐宋 JSON 为宋统一和割据生存条件补充 `mandateThreshold`。本轮不实现治理政策、归附纳土、单国胜负、部队转换、控制权交割或完整胜利评分/统一结算。关键文件：`WWIIHexV0/Data/ScenarioDefinition.swift`、`WWIIHexV0/Core/GameState.swift`、`WWIIHexV0/Core/MapState.swift`、`WWIIHexV0/Data/DataLoader.swift`、`WWIIHexV0/Rules/VictoryRules.swift`、`WWIIHexV0/Data/tangsong_jianlong_960_scenario.json`、`README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/flow/01_overall_core_flow.mermaid`、`md/plan/plan.md`、`md/prompt/v5.0-唐宋迁移/v5.6g_data_driven_victory_conditions_record.md`。
- 2026-07-06：推进唐宋 v5.6h 胜负原因显示与战报只读摘要首轮，并按用户要求继续使用并发子 Agent 审计 UI 与规则边界。`VictoryReason` 新增显示桥和结算摘要文案，保留 enum raw value 与 Codable 兼容；`HUDView` 的胜负栏读取 `VictoryState.reason`，唐宋路径下可显示“宋胜利：关键州府与天命达标”；`EventLogView` 接收 `VictoryState` 并在战报顶部派生只读胜负摘要，`RootGameView` 负责传入当前状态。本轮不改变 `VictoryRules` 判定语义，不新增胜利条件，不向 `eventLog` 写权威结算事件，不做完整胜利面板、评分档位、治理评价或单国胜负。关键文件：`WWIIHexV0/Core/VictoryState.swift`、`WWIIHexV0/UI/HUDView.swift`、`WWIIHexV0/UI/EventLogView.swift`、`WWIIHexV0/UI/RootGameView.swift`、`README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/flow/01_overall_core_flow.mermaid`、`md/plan/plan.md`、`md/prompt/v5.0-唐宋迁移/v5.6h_victory_reason_battle_report_record.md`。
- 2026-07-06：推进唐宋 v5.6i 胜利目标进度只读显示首轮，并按用户要求继续使用并发子 Agent 审计 UI 与规则/数据边界。新增 `VictoryObjectiveProgress` 和 `VictoryRules.objectiveProgress(in:)` 纯查询入口，从 `GameState.victoryConditions`、objective 所在 hex controller、`MandateState` 和当前回合派生州府控制、天命阈值与回合门槛进度；旧状态缺胜利条件时使用 v5.6d 关键州府/天命 fallback。`HUDView` 显示主要统一条件的州府与天命进度；`EventLogView` 接收进度快照并在战报面板只读展示主要胜利目标摘要，`RootGameView` 负责传入当前查询结果。本轮不调用会写 `VictoryState` 的胜负更新逻辑，不写 `eventLog`，不新增胜利条件，不改变胜负判定，不做完整胜利面板、评分档位、治理评价、单国胜负或统一结算。关键文件：`WWIIHexV0/Rules/VictoryRules.swift`、`WWIIHexV0/UI/HUDView.swift`、`WWIIHexV0/UI/EventLogView.swift`、`WWIIHexV0/UI/RootGameView.swift`、`README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/flow/01_overall_core_flow.mermaid`、`md/plan/plan.md`、`md/prompt/v5.0-唐宋迁移/v5.6i_victory_objective_progress_record.md`。
- 2026-07-06：推进唐宋 v5.7a 首屏“下一步”只读提示首轮，并按用户要求继续使用并发子 Agent 审计 UI 与文档口径。`RootGameView.nextActionHint` 从当前胜负、观战模式、回合权限、选中军队、围城/招降/招抚/解围/修城候选派生一句唐宋场景专用行动建议；`HUDView` 接收 `nextActionHint` 并在 HUD 顶部显示“下一步”，帮助玩家发现既有选军、行军、围城、招抚、解围、修城、结束回合和查看战报入口。本轮不新增命令，不调用 `RuleEngine`，不提交 `Command`，不写 `GameState` 或 `eventLog`，不做完整教程系统、势力选择、每回合战报摘要、新局包装、截图或布局验收。关键文件：`WWIIHexV0/UI/HUDView.swift`、`WWIIHexV0/UI/RootGameView.swift`、`README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/flow/01_overall_core_flow.mermaid`、`md/plan/plan.md`、`md/prompt/v5.0-唐宋迁移/v5.7a_next_action_hint_record.md`。
- 2026-07-06：推进唐宋 v5.7b 首屏统一目标锚点首轮，并按用户要求继续使用并发子 Agent 审计 UI 与数据/规则边界。`HUDView.objectiveGuideText` 复用 `VictoryRules.objectiveProgress(in:)` 的主要 `majorVictory` 条件，并通过 `MapState.controllerOfObjective(named:)` 判断关键州府是否已由宋控制；HUD 新增“目标”只读锚点，把开封、洛阳、太原、金陵、成都、杭州等统一目标拆成“已据/待取”短列表，帮助玩家把 `统一进度` 数字对应到地图州府。本轮不新增 victory condition，不改变 `VictoryRules` 判定，不新增地图高亮或点击定位，不提交 `Command`，不写 `GameState` 或 `eventLog`，不做完整教程、势力选择、每回合战报摘要或截图布局验收。关键文件：`WWIIHexV0/UI/HUDView.swift`、`README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/flow/01_overall_core_flow.mermaid`、`md/plan/plan.md`、`md/prompt/v5.0-唐宋迁移/v5.7b_objective_anchor_record.md`。
- 2026-07-06：推进唐宋 v5.7c 目标锚点定位首轮，并按用户要求继续使用并发子 Agent 审计 UI 与文档口径。`HUDView` 将主要统一目标锚点渲染为横向小按钮，按钮使用 objective id 作为稳定标识并保留“已据 / 待取”读法；`RootGameView` 将点击回调传入 `AppContainer.focusObjective(id:)`；`AppContainer.focusObjective(id:)` 只读取 `MapState.objective(id:)`，更新 `selectedHex` 和 `selectedRegionId`，并写一条交互日志，复用既有地图选中高亮与州府面板来聚焦目标州府。本轮不新增 victory condition，不改变 `VictoryRules` 判定，不提交 `Command`，不调用 `RuleEngine`，不写 `GameState`、`eventLog`、hex/region/theater/front/deploy 或 diplomacy，不做自动镜头移动、路线指引、完整教程、势力选择、每回合战报摘要或截图布局验收。关键文件：`WWIIHexV0/UI/HUDView.swift`、`WWIIHexV0/UI/RootGameView.swift`、`WWIIHexV0/App/AppContainer.swift`、`README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/flow/01_overall_core_flow.mermaid`、`md/plan/plan.md`、`md/prompt/v5.0-唐宋迁移/v5.7c_objective_focus_record.md`。
- 2026-07-06：推进唐宋 v5.7d 目标州府地图 spotlight 首轮，并按用户要求继续使用并发子 Agent 审计 UI 与文档边界，同时遵守“不要在本地测试，都去云端测试”的新约束。新增 `ObjectiveOverlayState` 与 `MapDisplayAdapter.objectiveOverlays()`，从 `VictoryRules.objectiveProgress(in:)` 的主要 `majorVictory` 条件和 `MapState.objective` 只读派生 objective id、名称、坐标、region 与已据/待取状态；`BoardScene.drawObjectiveOverlays` 在非 frontLine 图层绘制目标 hex outline、据/取标记和短标签；`AppContainer.focusObjective(id:)` 额外维护 UI-only 的 `focusedObjectiveId`，经 `BoardRenderState` 传入 SpriteKit 后只让当前 HUD 聚焦目标多一圈强调。本轮不新增 victory condition，不改变 `VictoryRules` 判定，不提交 `Command`，不调用 `RuleEngine`，不写 `GameState` 或 `eventLog`，不参与移动/攻击/围城/外交合法性判断，不做自动镜头移动、路线指引、完整教程、势力选择、每回合战报摘要或截图布局验收。关键文件：`WWIIHexV0/SpriteKit/MapDisplayAdapter.swift`、`WWIIHexV0/SpriteKit/BoardScene.swift`、`WWIIHexV0/SpriteKit/BoardSceneAdapter.swift`、`WWIIHexV0/App/AppContainer.swift`、`README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/flow/01_overall_core_flow.mermaid`、`md/plan/plan.md`、`md/prompt/v5.0-唐宋迁移/v5.7d_objective_spotlight_record.md`。
- 2026-07-06：推进唐宋 v5.7e 每回合战报摘要首轮，并按用户要求继续使用并发子 Agent 审计 UI 与文档边界，同时遵守“不在本地测试、只走云端测试”的新约束。`EventLogView` 新增 `TurnReportSummary` 只读摘要，从 `gameState.eventLog` 统计本回合或最近回合的战斗、州府、围城、粮道、外交、前线、方面、退却、整补与合围事件，并额外读取最近 `AgentDecisionRecord` 与 `WarDirectiveRecord` 展示军议/方面军令摘要；`RootGameView` 继续用 `container.displayEventLog` 渲染日志列表，但单独把 `container.gameState.eventLog` 传给摘要统计，避免点击、选中和目标聚焦等 `interactionLog` 混入战报。本轮不新增日志事件，不写 `GameState.eventLog`，不改变 `RuleEngine`、`CommandValidator`、`CommandExecutor`、`TurnManager`、`VictoryRules`、`Command` 或 `ZoneDirective`，不做完整结算页、评分、教程任务链、截图或布局验收。关键文件：`WWIIHexV0/UI/EventLogView.swift`、`WWIIHexV0/UI/RootGameView.swift`、`README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/flow/01_overall_core_flow.mermaid`、`md/plan/plan.md`、`md/prompt/v5.0-唐宋迁移/v5.7e_turn_report_summary_record.md`。
- 2026-07-06：推进唐宋 v5.7f 新局确认与指挥身份/观战包装首轮，并按用户要求继续使用并发子 Agent 审计 UI 与文档边界，同时遵守“不在本地测试、只走云端测试”的新约束。`HUDView` 新增 `playerFaction` 与 `observerModeEnabled` 只读输入，在唐宋场景显示“指挥 / 模式”短状态，区分宋可下令、宋待命、观战各方、玩家亲征或只读观战；`NewGameButton` 唐宋显示改为“重开剧本”；`RootGameView` 在唐宋场景下先弹出确认，再调用既有 `AppContainer.resetGame()` 重新载入建隆剧本并清空 UI/交互态。本轮不实现真实多势力选择，不改变 `AppContainer.playerFaction`，不新增存档槽，不改变 `resetGame()`、`GameState` schema、`RuleEngine`、`TurnManager`、`Command` 或 `ZoneDirective`。关键文件：`WWIIHexV0/UI/HUDView.swift`、`WWIIHexV0/UI/NewGameButton.swift`、`WWIIHexV0/UI/RootGameView.swift`、`README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/flow/01_overall_core_flow.mermaid`、`md/plan/plan.md`、`md/prompt/v5.0-唐宋迁移/v5.7f_new_game_identity_observer_record.md`。
- 2026-07-06：推进唐宋 v5.7g 下一步提示读取移动/攻击高亮数量首轮，并按用户要求继续使用并发子 Agent 审计 UI 与文档边界，同时遵守“不在本地测试、只走云端测试”的新约束。`RootGameView.nextActionHint` 在选中可行动宋军且无更高优先级的招降、围城、招抚、解围或修城目标时，读取既有 `AppContainer.attackHighlights.count` 与 `movementHighlights.count`，提示当前可攻击目标和可行军格数量，让 HUD 下一步提示更贴近地图红色目标与高亮格。本轮不新增命令，不调用 `RuleEngine`，不写 `GameState` 或 `eventLog`，不新增 `CommandValidator` dry-run，不替代按钮提交后的真实规则校验。关键文件：`WWIIHexV0/UI/RootGameView.swift`、`README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/flow/01_overall_core_flow.mermaid`、`md/plan/plan.md`、`md/prompt/v5.0-唐宋迁移/v5.7g_next_action_highlight_counts_record.md`。
- 2026-07-06：推进唐宋 v5.7h 亲征势力/观战轻量入口首轮，并按用户要求继续使用并发子 Agent 审计代码与文档边界，同时遵守“不在本地测试、只走云端测试”的约束。`DataLoader.initialTurnOrderState` 的唐宋路径读取场景 JSON 的 `playerFaction` / `aiFaction` 初始化 `PowerProfile.controlMode` 和 `TurnOrderState.playerControlledPowerIds`；`AppContainer.playerFaction` 改为运行时 UI 状态，默认从运行态 player-controlled power 推导；`RootGameView` 在唐宋场景显示“亲征”分段选择并保留“观战”切换，`setPlayerFaction(_:)` 会同步 `playerFaction`、`TurnOrderState.playerControlledPowerIds` 和 legacy profile controlMode，清空当前选中军队与移动/攻击高亮，并在当前回合需要 AI 时继续推进；下一步提示文案读取当前亲征势力名称，不再全部硬写宋军。本轮不新增 `Faction` case，不实现吴越/南唐/后蜀等完整多政权选择器，不新增存档槽或持久化配置，不改变 `Command`、`RuleEngine`、`TurnManager`、`WarCommandExecutor` 或 Hex / Region / Theater / Front / Deploy 权威边界。关键文件：`WWIIHexV0/Data/DataLoader.swift`、`WWIIHexV0/App/AppContainer.swift`、`WWIIHexV0/UI/RootGameView.swift`、`README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/flow/01_overall_core_flow.mermaid`、`md/plan/plan.md`、`md/prompt/v5.0-唐宋迁移/v5.7h_start_power_observer_entry_record.md`。
- 2026-07-06：推进唐宋 v5.7i 胜负后结算预览/评分估算首轮，并按用户要求继续使用并发子 Agent 审计代码与文档边界，同时遵守“不在本地测试、只走云端测试”的约束。`EventLogView` 在唐宋场景且 `VictoryState.winner` 已存在时，于胜负摘要下方显示“评分估算”只读摘要；摘要从 `VictoryState.winner/reason`、传入战报面板且匹配胜者自己的 `VictoryRules.objectiveProgress(in:)` 快照、当前回合、州府进度和天命门槛估算 0-100 分，并给出天命归一、山河大定、功业初成、守成有余、割据稳固等短档位。本轮不调用或改变 `VictoryRules.updateVictoryState`，不写 `VictoryState`、`GameState.eventLog`、存档、hex/region/theater/front/deploy 或 diplomacy，不新增权威结算事件，不实现完整胜利面板、正式评分系统、治理评分、单国胜负、外交纳土结算、自动破城或部队转换。关键文件：`WWIIHexV0/UI/EventLogView.swift`、`README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/flow/01_overall_core_flow.mermaid`、`md/plan/plan.md`、`md/prompt/v5.0-唐宋迁移/v5.7i_victory_settlement_score_summary_record.md`。
- 2026-07-06：推进唐宋 v5.7j 下一步有限合法性预校验首轮，并按用户要求继续使用并发子 Agent 审计代码与文档边界，同时遵守“不在本地测试、只走云端测试”的约束。`AppContainer.selectedValidatedCommandHint` 在唐宋场景下只读构造当前 UI 候选命令并调用 `CommandValidator.validate`，用于 HUD “下一步”优先提示规则确认可执行的围城、招抚、解围、修城、招降、攻击和行军入口；`AppContainer` 的围城、修城、解围和招降候选过滤同步收口到 `CommandValidator`，减少 UI 复制规则条件。本轮不提交 `Command`，不调用 `RuleEngine.execute`，不写 `GameState`、`GameState.eventLog`、存档、hex/region/theater/front/deploy 或 diplomacy，不改变 `CommandValidator` / `CommandExecutor` / `RuleEngine` 语义，不实现通用 dry-run 系统、完整逐命令教程、规则模拟器或发布级布局验收。关键文件：`WWIIHexV0/App/AppContainer.swift`、`WWIIHexV0/UI/RootGameView.swift`、`README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/flow/01_overall_core_flow.mermaid`、`md/plan/plan.md`、`md/prompt/v5.0-唐宋迁移/v5.7j_next_action_legality_hint_record.md`。
- 2026-07-06：推进唐宋 v5.7k 军队/州府检查面板唐宋读法补齐首轮，并按用户要求继续使用并发子 Agent 审计 v5.7 可玩闭环与 v5.8 发布硬化残留，同时遵守“不在本地测试、只走云端测试”的约束。`RootGameView` 向 `UnitInspectorView` 和 `RegionInspectorView` 传入 `isTangSongScenario` 与 `GameState.displayName(for:)`，让军队详情在唐宋场景显示军队、政权、指挥、地块、州府、动态方面、防区、粮道、兵力、退却口径、补给、状态和编成，并把底层 ARM/MOT/INF/ART 显示为禁军、骑军、厢军、器械；州府详情显示地块控制、控制政权、地形、城池、城级、关隘、粮草、围城、工坊、产出、方面、防区、前线压力、道路、目标、己方军队和可见敌军，产出读作丁口、钱帛、粮草，围城摘要不再在唐宋路径露出 `Germany/Allies` 或 `unit(s)`；`RootGameView.nextActionHint` 的已行动提示继续读取当前亲征势力名称，`CommandPanelView` 把唐宋非玩家所控单位显示为“非亲征军队”。本轮不改 `Division`、`RegionNode`、`ComponentType`、`EconomyResources`、`Faction` 或存档 schema，不改 `GameState`、`Command`、`CommandValidator`、`CommandExecutor`、`RuleEngine`、`WarCommandExecutor`、`VictoryRules`、hex/region/theater/front/deploy 权威边界，不实现将领面板唐宋化、真实多政权选择器或截图布局验收。关键文件：`WWIIHexV0/UI/RootGameView.swift`、`WWIIHexV0/UI/CommandPanelView.swift`、`WWIIHexV0/UI/UnitInspectorView.swift`、`WWIIHexV0/UI/RegionInspectorView.swift`、`README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/flow/01_overall_core_flow.mermaid`、`md/plan/plan.md`、`md/prompt/v5.0-唐宋迁移/v5.7k_inspector_tangsong_reading_record.md`。
- 2026-07-06：推进唐宋 v5.7l 将领指挥/档案面板唐宋读法补齐首轮，并按用户要求继续使用并发子 Agent 审计将领面板残留与文档口径，同时遵守“不在本地测试、只走云端测试”的约束。`RootGameView` 向 `GeneralCommandPanelView` 传入 `isTangSongScenario`，向 `GeneralProfileView` 传入 `isTangSongScenario` 与 `GameState.displayName(for:)`；`GeneralCommandPanelView` 在唐宋场景显示将领军令、方面防区、未选择亲征方面防区、忠诚、军心、亲征干预、查看档案、所属军队、本营州府受敌压迫、目标州府、固守防线、进攻州府和已拟军令，并把计划摘要中的 `attack/defend` 显示为进攻/固守；`GeneralProfileView` 在唐宋场景显示将领档案、关闭、履历、用兵、所辖方面、朝廷关系、忠诚、军心、亲征干预、特长和辖下军队，并通过运行态政权显示桥避免直接露出 `Germany/Allies`。本轮不改 `GeneralData`、`GeneralAssignment`、`FrontZone`、`PlayerPlannedOperation` 或存档 schema，不改将领分配、AI 决策、`ZoneDirective`、`WarCommandExecutor`、`Command`、`CommandValidator`、`RuleEngine`、胜负规则或 hex/region/theater/front/deploy 权威边界，不实现完整技能唐宋词典、真实多政权选择器或截图布局验收。关键文件：`WWIIHexV0/UI/RootGameView.swift`、`WWIIHexV0/UI/GeneralCommandPanelView.swift`、`WWIIHexV0/UI/GeneralProfileView.swift`、`README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/flow/01_overall_core_flow.mermaid`、`md/plan/plan.md`、`md/prompt/v5.0-唐宋迁移/v5.7l_general_panels_tangsong_reading_record.md`。
- 2026-07-06：推进唐宋 v5.7m 常驻军队 tooltip 唐宋读法补齐首轮，并按用户要求继续使用并发子 Agent 只读扫描 v5.8 残留，同时遵守“不在本地测试、只走云端测试”的约束。`RootGameView` 向 `UnitTooltipView` 传入 `isTangSongScenario`；`UnitTooltipView` 在唐宋场景把右下角选中军队摘要显示为兵种、兵力、补给、退却和本回合，并把 ART/ARM/MOT/INF 显示为器械、禁军、骑军、厢军，把 Supplied/Low/Encircled 显示为有粮、缺粮、被围，把 Retreatable/Hold 显示为可退、固守，把行动状态显示为已行动/未行动；accessibility label 同步改为唐宋读法。本轮不改 `Division`、`ComponentType`、`SupplyState`、`RetreatMode`、命令、补给、退却、AI 决策、胜负规则或 hex/region/theater/front/deploy 权威边界，不做截图、布局或 VoiceOver 实机验收。并发子 Agent 还指出 AI 面板 raw id、外交状态英文、EventLog 原始日志、MapEditor 英文错误和 README legacy 段落等 v5.8 RC 审计候选，留后续处理。关键文件：`WWIIHexV0/UI/UnitTooltipView.swift`、`WWIIHexV0/UI/RootGameView.swift`、`README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/flow/01_overall_core_flow.mermaid`、`md/plan/plan.md`、`md/prompt/v5.0-唐宋迁移/v5.7m_unit_tooltip_tangsong_reading_record.md`。
- 2026-07-06：推进唐宋 v5.8a AI 面板默认主路径残留硬化首轮，并按用户要求继续使用并发子 Agent 只读审查，同时遵守“不在本地测试、只走云端测试”的约束。`AgentPanelView` 在唐宋场景下把主事、来源、君主、将令、全局军令、防区、州府目标、legacy order type、命令结果标题和 ruler posture fallback 显示为宋枢密院、割据行营、确定性军议、方面主将、全局军令、行军、进攻、固守、整补、进取、维系诸国等读法；`RootGameView` 向 AI 面板传入运行态州府和方面防区名称查找，减少默认主路径 raw id 暴露。本轮不改 `AgentDecisionRecord`、`WarDirectiveRecord`、`TheaterDirectiveEnvelope`、`Command`、`ZoneDirective`、`TheaterDirectiveCompiler`、`WarCommandExecutor`、`RuleEngine`、AI 决策算法或 Codable raw schema，不处理全部 diagnostics、错误原文、raw JSON 调试区、外交/EventLog/MapEditor/README legacy 段落，也不做截图、布局或 VoiceOver 实机验收。本机未运行任何测试、build、Swift parse、Markdown 检查或 `git diff --check`；等待 push 后由 GitHub Actions 云端验证并下载未加密 artifact 核对。关键文件：`WWIIHexV0/UI/AgentPanelView.swift`、`WWIIHexV0/UI/RootGameView.swift`、`README.md`、`md/plan/plan.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/flow/01_overall_core_flow.mermaid`、`md/prompt/v5.0-唐宋迁移/v5.4_agent_schema_record.md`、`md/prompt/v5.0-唐宋迁移/v5.7m_unit_tooltip_tangsong_reading_record.md`、`md/prompt/v5.0-唐宋迁移/v5.8a_ai_panel_default_path_hardening_record.md`。
- 2026-07-06：推进唐宋 v5.8b AI 面板玩家态/开发态分层首轮，并按用户要求继续使用并发子 Agent 只读审查，同时遵守“不在本地测试、只走云端测试”的约束。`AgentPanelView` 在唐宋场景下默认显示军议摘要、方面军令和命令执行/拒绝摘要；diagnostics、错误原文和 raw JSON 改为折叠调试区，避免默认铺开英文诊断、schema key、内部 id 或 validation rawValue；`resultLine(_:)` 唐宋路径改为“已执行 / 规则拒绝 / 映射失败 / 未执行”等摘要；意图和战况优先读取 `TheaterDirectiveExplanationSummary` 或本地化兜底；运行态州府/防区名称缺失时显示“未命名州府 / 未命名方面”。本轮不改 `AgentDecisionRecord`、`WarDirectiveRecord`、`TheaterDirectiveEnvelope`、`Command`、`ZoneDirective`、`TheaterDirectiveDecoder`、`TheaterDirectiveCompiler`、`WarCommandExecutor`、`RuleEngine`、AI 决策算法或 Codable raw schema，不处理外交/EventLog/MapEditor/README 全局残留，也不做截图、布局或 VoiceOver 实机验收。本机未运行任何测试、build、Swift parse、Markdown 检查或 `git diff --check`；等待 push 后由 GitHub Actions 云端验证并下载未加密 artifact 核对。关键文件：`WWIIHexV0/UI/AgentPanelView.swift`、`README.md`、`md/plan/plan.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/flow/01_overall_core_flow.mermaid`、`md/prompt/v5.0-唐宋迁移/v5.8b_ai_panel_debug_player_dev_split_record.md`。
- 2026-07-06：推进唐宋 v5.8c 外交面板默认主路径读法硬化首轮，并按用户要求继续使用并发子 Agent 只读审查，同时遵守“不在本地测试、只走云端测试”的约束。`DiplomacyPanelView` 在唐宋场景下把国家副标题、关系状态、归附结果、君主主事、国策、重点方面、归附州府和国家/集团/州府/方面 fallback 显示为唐宋读法；`RootGameView` 向外交面板传入运行态州府与方面防区名称查找，减少 raw id 和英文状态在默认外交主路径中暴露。本轮不改 `DiplomacyState`、`MandateState`、`Command.proposeSubmission`、`CommandValidator`、`CommandExecutor`、`RuleEngine`、`TurnOrderState.relations`、`WarRelationRules.canTarget`、JSON/Codable schema 或 hex/region/theater/front/deploy 控制权。本机未运行任何测试、build、Swift parse、Markdown 检查或 `git diff --check`；等待 push 后由 GitHub Actions 云端验证并下载未加密 artifact 核对。关键文件：`WWIIHexV0/UI/DiplomacyPanelView.swift`、`WWIIHexV0/UI/RootGameView.swift`、`README.md`、`md/plan/plan.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/flow/01_overall_core_flow.mermaid`、`md/prompt/v5.0-唐宋迁移/v5.8c_diplomacy_panel_default_path_hardening_record.md`。
- 2026-07-06：推进唐宋 v5.8d 战报日志默认主路径读法硬化首轮，并按用户要求继续使用并发子 Agent 只读审查，同时遵守“不在本地测试、只走云端测试”的约束。`EventLogView` 在唐宋场景下把战报列表正文和“本回合战报 / 最近战报”摘要 highlight 统一经过 `TangSongEventLogMessage` 显示桥，常见命令接受/驳回、validation rawValue、选中地块/州府/军队、移动、战斗、退却、补给和 AI 执行日志显示为唐宋读法，减少英文事件与内部枚举在默认战报主路径中暴露。本轮不改 `GameLogEntry.message`、`CommandResultLogEntry`、`CommandValidator`、`CommandExecutor`、`RuleEngine`、事件写入职责、日志 Codable schema 或任何规则结果；MapEditor 英文错误和 README/flow 历史定位残留留后续切片。本机未运行任何测试、build、Swift parse、Markdown 检查或 `git diff --check`；等待 push 后由 GitHub Actions 云端验证并下载未加密 artifact 核对。关键文件：`WWIIHexV0/UI/EventLogView.swift`、`README.md`、`md/plan/plan.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/flow/01_overall_core_flow.mermaid`、`md/prompt/v5.0-唐宋迁移/v5.8d_event_log_default_path_hardening_record.md`。
- 2026-07-06：推进唐宋 v5.8e MapEditor 默认路径读法硬化首轮，并按用户要求继续使用并发子 Agent 只读审查，同时遵守“不在本地测试、只走云端测试”的约束。`MapEditorGameResourceBridge` 的编辑器默认读取路径不再静默回退 legacy 阿登资源，缺少唐宋 960 默认 JSON 时显式报中文错误；MapEditor 新建草案、导出错误、补给点 fallback、导出注记、州府数据 displayName、状态栏、州府/方面选择器、检查面板和单位短标改为唐宋读法，减少 `MapEditor Scenario`、`City q,r`、`Supply q,r`、`Regions`、raw id、完整本机路径和 `ARM/ART/MOT/INF` 在默认工具路径中暴露。本轮不改主游戏 `DataLoader` 的 legacy fallback，不改 JSON/Codable schema、底层 `Faction` / `RegionId` / `TheaterId` / `Division` 兼容桥、规则系统或 MapEditor 测试夹具。本机未运行任何测试、build、Swift parse、Markdown 检查或 `git diff --check`；等待 push 后由 GitHub Actions 云端验证并下载未加密 artifact 核对。关键文件：`MapEditor/MapEditorDocument.swift`、`MapEditor/MapEditorGameResourceBridge.swift`、`MapEditor/MapEditorExporter.swift`、`MapEditor/MapEditorViewModel.swift`、`MapEditor/MapEditorView.swift`、`MapEditor/MapEditorCanvasScene.swift`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/flow/04_mapeditor_to_game_data.mermaid`、`md/prompt/v5.0-唐宋迁移/v5.8e_mapeditor_default_path_hardening_record.md`。

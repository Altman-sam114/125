# WWIIHexV0 — 唐宋迁移中的 iOS / macOS AI 战略战棋

> **当前状态：v5.6 唐宋外交、归附、天命规则/UI 与战术候选关系感知首轮已接入；此前 v5.3 唐宋生产/府库显示桥、古代兵种战斗修正、粮道供给/读法、围城城防、修城、解围、招降、地图围城 overlay 与 AI 围城/招降指令首轮，v5.4 AI 军议显示桥、模拟元帅 JSON 文案唐宋化和可选解释字段首轮。默认启动优先加载 `jianlong_960_unification`（建隆元年：陈桥兵变与山河一统）唐宋 JSON；MapEditor 默认读取/覆盖唐宋 960 资源；生产、府库和经济规则日志在唐宋路径下显示为军备、丁口、钱帛、粮草、禁军/厢军/骑军/攻城器械营；唐宋场景下骑军、弓弩守军、攻城器械营和守军已有最小战斗差异；受控高补给州府/粮仓、道路、山林和跨河成本已影响补给判定，单位详情可显示粮道通断、路径成本/上限、最近粮源和安全退路，地图可从同一摘要只读绘制友方可见军队到最近可见粮源的抽象粮道虚线；玩家可通过统一 `Command.besiege -> RuleEngine` 对敌方城池/关隘/粮仓州府登记围城压力并损耗城防，守方可通过 `Command.repairFortification -> RuleEngine` 消耗军队行动修城，也可通过 `Command.relieveSiege -> RuleEngine` 让州府内或近旁友军削减围城压力直至解围；围城压力达标、城防归零且守军不再 supplied 后，围城方可通过 `Command.demandSurrender -> RuleEngine` 招降目标州府，规则层会移除纳降守军、交割目标州府可占 hex，并刷新 region/theater/front/deploy；`ZoneDirective.attack -> WarCommandExecutor` 会在目标州府满足纳降条件时优先生成底层 `Command.demandSurrender`，否则在目标州府可围且无可攻击单位时生成底层 `Command.besiege`；地图从 `SiegeState` 只读绘制围城圈、压力和城防标签；唐宋场景下 AI 面板显示为“军议/方面军令”，战术名显示为进军、骑军突进、合围、弓弩压制、死守城关等，模拟元帅 raw JSON 的默认主事、strategicIntent、summary 和 rationale 也改用宋枢密院/割据行营与州府粮道口径；`TheaterDirectiveEnvelope` 新增可选 `mandateIntent`、`courtPolicy`、`pacificationTargets`、`supplyPriorities` 解释字段，唐宋 simulated marshal 会从首都、围城、粮道和外交候选摘要填充这些字段，`AgentDecisionRecord` 会保存只读军议解释摘要，`AgentPanelView` 在唐宋场景下结构化显示诏令、朝议、招抚、转运与摘要；`GameAgent.defaultCommander` 在唐宋场景下使用宋枢密院/割据行营作为默认 AI issuer，不再把默认唐宋主路径记录成 Guderian 或 Allied Mock Commander；`Command.proposeSubmission -> RuleEngine` 已能记录招抚、更新国家关系投影和天命分数，玩家命令面板已提供“招抚”入口，外交面板只读显示天命与归附记录；UI 攻击候选、攻击高亮、AI 敌强/敌区估算、`WarCommandExecutor` 敌军/敌控 region 和战术移动候选已改为读取 `WarRelationRules.canTarget`。底层 `TacticName` raw case 和执行权限保持兼容；除 v5.6c 的 `pacificationTargets -> TurnManager -> Command.proposeSubmission` 辅助桥外，新增解释字段不直接改规则结果。阿登数据保留为 legacy fallback。战争 AI 仍收口到 `ZoneDirective -> WarCommandExecutor -> RuleEngine`，AI 招抚辅助桥也只生成底层 `Command` 后交给 `RuleEngine`；Hex / Region / Theater / Front / Deploy 的权威边界不变。历史测试基线曾达到 v0.37 Probe 18/0、Stage Regression 69/0、Full 226/0；当前工作流默认不跑 Xcode / XCTest / 模拟器测试，只按 `md/test/test.md` 做轻量检查并由 GitHub Actions 云端重验证。**

> **v5.6c 状态补充：** AI 元帅 `pacificationTargets` 现在可由 `TurnManager` 在 `.endTurn` 前尝试生成辅助 `Command.proposeSubmission`，仍通过 `RuleEngine -> CommandValidator -> CommandExecutor` 决定成败，并把成功、规则拒绝或跳过写入 `AgentDecisionRecord.commandResults`。该桥不改 `TheaterDirectiveCompiler` 或 `WarCommandExecutor`，不交割控制权、不转换部队、不改全局战争关系。

> **v5.6d 状态补充：** 唐宋场景下 `VictoryRules` 已有首轮天命/国威胜利评价桥：宋控制开封、洛阳、太原、金陵、成都、杭州中的至少四处且天命不低于 60 时胜利；割据阵营若到最大回合仍控制太原、金陵、成都中的至少两处且天命不低于 35，则判定割据生存。阿登 legacy 胜利逻辑保持原样。

> **v5.6e 状态补充：** `Command.proposeSubmission` 成功写入国家外交关系后，会把 `DiplomacyState` 中跨 legacy faction 的国家关系保守投影回 `TurnOrderState.relations`：只要宋与割据阵营之间仍有任一国家关系是 hostile/atWar，`.allies/.germany` power 关系继续保持 `atWar`，避免吴越等单国归附导致全体割据势力提前不可攻击。

> **v5.6f 状态补充：** UI 与 AI 战术候选生成现在前置读取 `WarRelationRules.canTarget`：`AppContainer` 的点击攻击、攻击高亮和将领目标区推断，`WarCommandExecutor` 的敌强、敌区、可见敌军、围城与战术移动候选，`ZoneCommanderAgent` / `MarshalBattlefieldSummarizer` / `MockAICommander` 的敌情估算都不再只靠 `faction !=` 或 `Faction.opponent`。招抚和谈判候选仍保留外交规则口径，不用 `canTarget` 粗暴过滤。

> **v5.5 前序小切片：** 默认唐宋主界面的 HUD、图层、观战、面板 tabs、军令按钮和战报分类已加入唐宋场景显示桥，显示为回合、政权、阶段、胜负、地块、州府、方面、军队、将领、战报、府库、军议、固守、整补、围城和粮道等读法；SpriteKit 地图新增唐宋视觉 token，唐宋场景使用墨绿底、绢帛/青绿/石青/铜/朱印色系、赭石道路、石青河流、朱印/青绿势力色，棋子从 NATO 符号切为内置军旗轮廓和禁/骑/弩/械/守/军兵种字标，并从 `SupplyRules.supplyRouteSummary` 只读绘制友方可见军队到最近可见粮源的抽象粮道虚线。该切片只改玩家可见术语与视觉读法，不改变底层 raw case、命令、日志结构、补给判定或规则执行；完整截图、布局验收、外部美术资产和授权清单仍待后续。

> **v5.6a 前序小切片：** 新增外交归附与天命规则合同首轮。`DiplomacyState` 支持 `tributary`、`submitting`、`negotiating` 并保存 `PacificationRecord`；`GameState` 新增向后兼容的 `MandateState`；唐宋默认剧本初始化宋/割据天命分数；`Command.proposeSubmission -> CommandValidator -> CommandExecutor -> RuleEngine` 可在满足国家关系、天命、目标州府、低 warSupport 或围城压力条件后，把目标国家关系写为 `submitting`、记录招抚并增加天命。该切片不交割 hex/region 控制权，不转换部队，不改变 `.allies/.germany` 全局战争关系，也不把 AI `pacificationTargets` 自动执行为归附命令。

> **v5.6b 前序小切片：** 玩家命令面板新增“招抚”按钮，只提交 `Command.proposeSubmission -> RuleEngine`，目标优先取当前选中外国首府，若未选中合法首府则自动扫描当前可招抚首府；开局理论上可对低 warSupport 的吴越发起归附提议。外交面板只读显示天命分数和最近归附记录，并在唐宋场景下显示为外交、天命、诸国、集团、关系和归附记录。该切片仍不交割 hex/region 控制权、不转换部队、不改全局战争关系，也不让天命影响胜利。

> **v5.6c 前序小切片：** AI 元帅 envelope 的 `pacificationTargets` 进入安全编译桥：`TurnManager` 在战争 `ZoneDirective` 执行后、`.endTurn` 前，把合法首府候选尝试生成辅助 `Command.proposeSubmission`，仍通过 `RuleEngine -> CommandValidator -> CommandExecutor` 决定成败，并把成功、规则拒绝或跳过记录进 `AgentDecisionRecord.commandResults`。每个 AI 回合最多 1 个成功招抚提议；该切片不改 `TheaterDirectiveCompiler`、不让 `WarCommandExecutor` 承担外交语义、不交割控制权、不转换部队、不改 `TurnOrderState.relations`。

> **v5.6d 前序小切片：** `VictoryRules.updateVictoryState` 在唐宋场景先走唐宋专用判定，不再套用 Bastogne / St. Vith legacy 条件；宋统一胜利同时要求关键州府控制与天命阈值，割据生存胜利同时要求核心都城保有与割据天命阈值。该切片不新增治理政策、不改变 `MandateState` 调整来源、不改 UI 胜利面板结构，也不做归附后的控制权或部队交割。

> **v5.6f 最新小切片：** v5.6e 的 power 级关系投影已前移到战术候选层，减少非敌对对象被 UI 高亮或被 AI 编译成无效战争命令的情况。该切片不实现单国 tactical neutral，不新增国家级 `PowerId`，不交割控制权，不转换部队，也不改变最终 `CommandValidator` / `RuleEngine` 权威。

---

## 项目定位

一款 iOS / macOS 回合制历史策略游戏，当前正从二战阿登原型迁移为唐宋时代 AI Agent 策略游戏。目标结合战棋（六角格操作感）、大战略（州府占领、粮道、前线）与角色扮演（LLM 驱动的将领/朝廷 AI）。

**核心参考：**
- 《统一指挥2》：六角格战棋、补给、攻击（战术层参照）
- 《钢铁雄心4》：大战略、省份占领、前线、补给、生产、国家管理（战略层参照）
- EasyTech《钢铁命令》：战役推进、将领、战术操作
- 《世界征服者4》：移动端轻量化策略体验

**核心创新：本地部署 LLM 驱动游戏 AI**
- 将领、元帅已进入当前指挥链；国家统治者、部长只作为后续方向预留
- agent 根据视野、战况摘要、性格和历史背景输出结构化 JSON 命令
- 游戏规则系统负责校验并执行，LLM 不直接绕过规则修改状态

---

## 地图 / 战区架构（核心决策）

**分层叠加，不是替换。** 六角格保留作战术/战斗层，州府/Region 与方面/Theater 负责战略聚合。

```
Hex（战术层 / 真实占领与移动）
  ↓ hexToRegion
Region（州府规则层 / 资源、丁口、粮草、胜利点聚合）
  ↓ regionToTheater（初始战区基本单位，只读基准）
Initial Theater Layout（地图编辑器初始划分 / 只读 snapshot）
  ↓ hexToTheater
Dynamic Theater State（运行时动态战区 / 随 hex 推进变化）
  ↓ 动态 hex 邻接
FrontLine / FrontSegment（前线与分段，按动态战区接触生成）
  ↓
WarDeploymentState（FRONT / DEPTH / GARRISON 部署池）
  ↓
ZoneDirective / WarCommandExecutor / RuleEngine
```

**为什么分层：**
- 全球地图纯 hex ≈ 16 万节点，iOS 跑不动（尤其带 LLM agent）
- HOI4 证明：省是规则原子，全球 ~1-2 万省可实时跑
- 战术级 hex（UC2 风格）提供精细操作，战略级省提供全球性能
- **同一局内可切换**：大战略模式看省，zoom 进某省切 hex 板战术微操
- **v0.358 之后的关键语义**：
  - `regionToTheater` = 初始战区基本单位，服务地图编辑器、动态战区生成/合并/消亡的参照，不是运行时推进层。
  - `hexToTheater` = 运行时动态战区权威映射。单位占领一个 hex，只推进这个 hex 的动态战区归属，不能把整个 region 拉走。
  - 前线 = 我方动态战区与敌方动态战区的 hex 邻接接触，按 region 形成 `FrontSegment`。

**v0.2 以来的长期原则**：Region 作为战略层叠加，**不替换** hex 坐标系。现有 hex 规则全保留，州府/省级规则只作为聚合视图并行运行。

---

## 技术栈

| 层级 | 技术 |
|------|------|
| 平台 | iOS；v1.1 新增 macOS 主游戏 target `WWIIHexV0Mac` |
| 语言 | Swift |
| UI 框架 | SwiftUI（面板、按钮、日志、单位详情） |
| 地图渲染 | SpriteKit（六角格地图、单位显示、移动/攻击反馈） |
| AI 接口 | `DecisionProvider` 协议（MockAI 已实现，预留本地 LLM） |

---

## 项目架构

```
WWIIHexV0/
├── Core/          — 核心数据模型（Division、GameState、HexTile、HexCoord、MapState 等）
├── Commands/      — 命令系统（Command、CommandResult、CommandValidation、GameCommandHandling）
├── Rules/         — 规则引擎（RuleEngine、CombatRules、SupplyRules、MovementRules、VictoryRules、CommandExecutor、CommandValidator）
├── Agents/        — AI Agent 管线（旧 Agent D + ZoneCommanderAgent / MarshalAgent）
├── Turn/          — 回合管理器（TurnManager，德军 AI 回合编排）
├── SpriteKit/     — 地图渲染（BoardScene、UnitNode、HexNode、HexLayout、TerrainStyle、BoardSceneAdapter）
├── UI/            — 界面组件（UnitInspectorView、EventLogView、HUDView、CommandPanelView、AgentPanelView、RootGameView）
├── App/           — 入口（AppContainer、WWIIHexV0App、WWIIHexV0MacApp）
├── Data/          — 场景数据（DataLoader、唐宋/legacy ScenarioDefinition JSON、unit templates、characters/generals、terrain_rules.json）
├── Probes/        — 历史高速探针测试 target（默认不执行）
└── Tests/         — 历史单元测试 / 集成测试 / 真实战局模拟（默认不执行）
```

### 核心架构原则

- **规则与 UI 解耦**：游戏状态只能由 `RuleEngine` 修改，UI 只读取状态
- **命令管线**：玩家 / AI → `Command` → `CommandValidator` 校验 → `CommandExecutor` 执行 → 日志
- **AI 接口可替换**：`DecisionProvider` 协议，MockAI 已实现，未来可插入本地 LLM
- **地图分层**：hex（战术层，`HexCoord`）+ region（省份层，`RegionId`）+ dynamic theater（运行时战区，`hexToTheater`），不替换
- **AI 命令与玩家命令共用同一管线**：都经 `RuleEngine` 校验执行

---

## AI / 指令管线接口（已落地）

当前同时保留两条管线：

- **Legacy Agent D 管线**：`AgentContextBuilder → DecisionProvider → AgentDecisionParser → AgentCommandMapper → RuleEngine`。已保留作回归参考，默认不再作为战争 AI 主路径。
- **ZoneDirective 管线（执行权威）**：`ZoneDirective → WarCommandExecutor → RuleEngine → WarDirectiveRecord`。`WarCommandExecutor.execute(_ directive:in:)` 不依赖具体 `ZoneCommanderAgent` 实例，手写合法 `ZoneDirective` 也可执行。
- **v0.5 元帅管线（默认上游）**：`MarshalAgent → MarshalBattlefieldSummarizer → SimulatedMarshalLLMClient → TheaterDirectiveDecoder → TheaterDirectiveCompiler → DirectiveEnvelope / ZoneDirective`。它只做战略意图、JSON I/O、解码校验和 fallback，不直接修改 `GameState`。
- **后续统治者层（未接入 v0.5 主链路）**：未来只能位于元帅上游，输出国家级姿态或约束条件；不得绕过 `ZoneDirective -> WarCommandExecutor -> RuleEngine`。

| 文件 | 职责 | 关键类型/协议 |
|------|------|--------------|
| `Agents/DecisionProvider.swift` | 统一 AI 接口 | `protocol DecisionProvider { func decide(context:) async throws -> AgentDecisionEnvelope }` |
| `Agents/GameAgent.swift` | 运行时 agent 模型 | `GameAgent`（精简版，无 Cabinet/DirectiveDomain，v0.5 污染已剔除） |
| `Agents/AgentConfiguration.swift` | agent 加载 | `GameAgent.defaultCommander(for:from:state:)`；唐宋场景使用宋枢密院/割据行营，legacy 阿登保留 Guderian / Allied Mock fallback |
| `Agents/AgentContexts.swift` | agent 能看到的摘要 | `AgentContext` + `AgentContextBuilder`（无 organization，适配 v0.1） |
| `Agents/AgentDecision.swift` | 结构化决策 DTO | `AgentDecisionEnvelope` / `AgentOrder` / `AgentOrderType`（move/attack/hold/resupply） |
| `Agents/AgentDecisionParser.swift` | JSON → envelope | 校验 schemaVersion / agentId / turn，malformed 抛 typed error |
| `Agents/AgentCommandMapper.swift` | order → Command | `AgentCommandMapper.map(_:agentId:) -> IssuedCommand`，缺字段抛 error |
| `Agents/AgentDecisionRecord.swift` | 决策记录 | `AgentDecisionRecord` / `CommandResultSummary` / `TheaterDirectiveExplanationSummary`（UI 读） |
| `Agents/MockAIClient.swift` | legacy 默认 provider | 启发式：resupply → attack → move(向 Bastogne) → hold；唐宋默认主路径只把它作为 deterministic provider 壳，指令上游走 MarshalDirective |
| `Agents/LLMClient.swift` | Legacy LLM 接口预留 | `protocol LLMClient` + `LLMRequest`（旧 Agent D 用，默认不启用） |
| `Agents/LocalLLMDecisionProvider.swift` | 本地 LLM provider | 注入 `LLMClient` + `AgentPromptBuilder` + parser，失败由上层 fallback MockAI |
| `Agents/AgentPromptBuilder.swift` | prompt 构造 | system + user prompt，强制 JSON 输出 |
| `Turn/TurnManager.swift` | 德军 AI 回合编排 | `runGermanAITurn(state:) async -> AgentTurnOutcome`（含 endTurn 推进） |
| `App/AppContainer.swift` | AI 接线 | `runAIIfNeeded()`（guard germany+germanAI → Task → 写 state/record），`lastAgentDecisionRecord` |
| `UI/AgentPanelView.swift` | 决策展示 | 读 `record` 与 `WarDirectiveRecord`；唐宋场景显示为军议、诏令朝议、方面军令和唐宋战术名 |
| `UI/RootGameView.swift` | 启动触发 | `.task { container.runAIIfNeeded() }` |

**Legacy MockAI 行为（guderian，装甲突破风格）：**
跳过已行动单位 → 低补给/包围优先 resupply → 射程内低 hp 敌军优先 attack（炮兵优先打城市/要塞）→ 装甲沿道路向 Bastogne move → 否则 hold

**v0.7 ZoneDirective 战术行为：**
`ZoneCommanderAgent` 读取所属 `FrontZone` 的前线/部署摘要，`BinaryTacticClassifier` 会结合兵力比、机动兵力、炮兵支援、纵深预备队、压力和补给警告，在 `standardAttack`、`blitzkrieg`、`spearhead`、`breakthrough`、`pincerMovement`、`fireCoverage`、`feint`、`guerrillaWarfare`、`holdPosition`、`elasticDefense`、`defenseInDepth`、`lastStand` 之间分类；`WarCommandExecutor` 将这些战术降级为 `move / attack / hold / allowRetreat`，并在唐宋围城链路中可生成 `besiege / demandSurrender`，仍统一交给 `RuleEngine` 校验执行。`WarDirectiveRecord` 记录 `category` / `tactic` / `commanderAgentId` / `commandTarget`，便于后续接真 LLM 回放与审计。v5.4 已新增 `displayName(isTangSongScenario:)` 显示桥、`AgentPanelView` 唐宋军议读法、唐宋场景下 simulated marshal strategicIntent / rationale / summary 的军议文案，以及 `mandateIntent` / `courtPolicy` / `pacificationTargets` / `supplyPriorities` 可选解释字段；这些字段会通过 `TheaterDirectiveExplanationSummary` 在 AI 面板显示为诏令、朝议、招抚和转运摘要。v5.6c 起 `pacificationTargets` 还可由 `TurnManager` 辅助生成 `Command.proposeSubmission`，但不改变 `TheaterDirectiveCompiler`、`WarCommandExecutor` 或底层 raw case 权限。

**v0.5 MarshalDirective 行为：**
`MarshalBattlefieldSummarizer` 把 `GameState` 降维为元帅摘要，只包含 front zone、strength ratio、补给警告、目标和事件，不把全量 hex 网格喂给模型；v5.4 起摘要携带 `scenarioId`、首都 region、被威胁首都、围城 region、粮道优先 region 和招抚候选 region，让 simulated marshal 在唐宋场景用宋枢密院/割据行营、州府、粮道和军议口径生成 strategicIntent、summary、rationale 与可选解释字段。`GameAgent.defaultCommander` 让唐宋默认 `TurnManager` issuer 与 `MarshalAgentConfig` 对齐为宋枢密院或割据行营；`TurnManager` 会把这些解释字段复制进 `AgentDecisionRecord.theaterDirectiveSummary`，让 AI 面板结构化展示诏令、朝议、招抚和转运。v5.6c 起 `TurnManager` 还会把唐宋 `pacificationTargets` 在 `.endTurn` 前尝试生成辅助 `Command.proposeSubmission`，仍经 `RuleEngine` 校验执行。`SimulatedMarshalLLMClient` 生成 fenced JSON 形式的 `TheaterDirectiveEnvelope`；`TheaterDirectiveDecoder` 提取并校验 JSON；`TheaterDirectiveCompiler` 把元帅意图编译成现有 `ZoneDirective`。v0.7 后 `TheaterDirective` 可携带 `convergenceRegionId` / `coordinatedZoneIds` 支持钳形会师意图；解码或编译失败时 fallback 到 `TheaterCommanderPool`，不执行半成品 LLM 输出。

**后续 Ruler / Diplomacy 边界：**
统治者 agent 不在 v0.5 当前主链路中。v5.6a 已先建立 `MandateState`、`PacificationRecord` 和 `Command.proposeSubmission` 规则合同，v5.6b 补玩家“招抚”入口与外交面板只读展示，v5.6c 补 AI `pacificationTargets -> Command.proposeSubmission` 安全桥，v5.6d 让唐宋 `VictoryRules` 同时读取关键州府控制与天命阈值，v5.6e 将国家级外交关系保守投影回 `TurnOrderState.relations` 的 legacy power 关系；战术敌我仍由 legacy `Faction.germany` / `Faction.allies` 与 `TurnOrderState.relations` 决定。后续如要加入统治者 agent、单国 tactical neutral、完整纳土或治理政策，仍必须保持底层战争规则收口到 `Command` / `ZoneDirective`、`WarCommandExecutor` 和 `RuleEngine`。

---

## 当前完成进度

### ✅ v0：六角格测试板（已完成）

**场景**：阿登测试战场（Ardennes），德军 vs 盟军，11×9 六角格地图

| 功能模块 | 状态 |
|----------|------|
| 六角格 axial 坐标系统 | ✅ |
| 地形系统（平原/森林/山地/城市/道路/河流/要塞） | ✅ |
| 移动系统（地形消耗、道路加成、跨河惩罚、敌方阻挡） | ✅ |
| 战斗系统（近战/炮兵远程、地形防御修正、反击） | ✅ |
| 侧翼/背后加成 | ✅ |
| 占领系统（城市控制权变更） | ✅ |
| 补给系统（supplied / lowSupply / encircled） | ✅ |
| 包围判定与惩罚 | ✅ |
| 回合系统（德军 AI 先手 → 盟军玩家 → 结算） | ✅ |
| MockAI 将领 agent（guderian，装甲突破风格） | ✅ |
| 结构化 JSON 命令解析与校验 | ✅ |
| AI 决策日志面板（AgentPanelView 读 AgentDecisionRecord） | ✅ |
| 胜利条件（巴斯托涅占领 / 消灭 3 单位 / 切断补给） | ✅ |

---

### ✅ v0.1：strength、撤退与补员（已完成）

| 功能模块 | 状态 |
|----------|------|
| `Division` 升级为 strength/maxStrength，保留 hp/maxHP 兼容 | ✅ |
| 战斗改为 strength 伤害（organization 已移除） | ✅ |
| 撤退状态：自动寻找安全相邻格撤退 | ✅ |
| 撤退失败施加额外惩罚 | ✅ |
| `resupply/rest` 恢复 strength | ✅ |
| 包围每回合扣 strength | ✅ |
| UI 显示 Strength、Retreating 状态 | ✅ |
| 日志按 combat/retreat/reinforce/encircle/supply 分类 | ✅ |
| 死守 / 允许撤退（RetreatMode）按钮与 HOLD 防御加成 | ✅ |

**v0.1 最终模型：** 只看兵力，无 organization。`RetreatMode`（retreatable/hold）控制撤退：HOLD 防御 +20%，RETREATABLE 单次损失比例 ≥ 35% 自动撤退。

---

### ✅ Agent D：AI/Agent 决策管线（已完成）

| 功能模块 | 状态 |
|----------|------|
| `DecisionProvider` 协议（MockAI + LocalLLM 共用） | ✅ |
| `AgentContext` / `AgentContextBuilder`（Codable 摘要，无 UI/SpriteKit 对象） | ✅ |
| `AgentDecisionEnvelope` / `AgentOrder` JSON schema | ✅ |
| `AgentDecisionParser`（校验 schema/agent/turn） | ✅ |
| `AgentCommandMapper`（order → Command，缺字段抛 error） | ✅ |
| `MockAIClient`（guderian 启发式，向 Bastogne 推进） | ✅ |
| `LLMClient` / `LocalLLMDecisionProvider` / `AgentPromptBuilder`（预留，v0 默认关） | ✅ |
| `TurnManager`（德军 AI 回合编排，含 endTurn） | ✅ |
| `AppContainer.runAIIfNeeded()`（启动自动跑 AI 回合） | ✅ |
| `AgentDecisionRecord` + `AgentPanelView`（UI 读决策记录） | ✅ |
| `AgentPipelineTests`（8 测试：context/MockAI/parser/mapper/provider 失败/非法命令） | ✅ |

---

### ✅ v0.2 Agent 1：省份图架构（已完成）

省份图规则层模型。**叠加，不替换 hex。** hex 仍战术层权威坐标，province 是战略层聚合。

| 文件 | 职责 |
|------|------|
| `Core/Region.swift` | `RegionId`（RawRepresentable<String>）、`RegionNode`、`RegionEdge`、`RegionGraph`、`CityInfo`、`ResourceAmount`、`ResourceType`、`OccupationState`、`RegionEdgeKey`（对称键）、`RegionValidationError`（9 case） |
| `Core/MapState.swift`（改） | 加 `regions`/`hexToRegion`/`regionEdges` 字段（默认空）；加 province 查询：`region(for:)`/`region(id:)`/`neighbors(of:)`/`areAdjacent`/`edgeBetween`/`representativeHex`/`regionDistance`/`regionGraph`；加 `validateRegionGraph()` |
| `Core/Terrain.swift`（改） | `HexTile` 加 `regionId: RegionId?`（默认 nil） |
| `RegionGraph.validate()` | idMismatch/emptyDisplayHexes/representativeHexNotInDisplayHexes/neighborNotFound/neighborNotBidirectional/edgeEndpointNotFound/edgeNotInNeighbors |
| `MapState.validateRegionGraph()` | 复用上图校验 + hexToRegionPointsToMissingRegion + displayHexesOverlap |
| `Tests/RegionGraphTests.swift` | 19 测试：编解码/neighbors/areAdjacent/hexToRegion/representativeHex/validate 全错误类型+valid+empty |

**设计约束（Agent 1 已守）：**
- hex 规则全保留，province 默认空不破现有行为
- `MapState.ardennesV0()` 不改（保持纯 hex，测试用）
- 省份挂载在 Data 层（DataLoader），Core 不依赖 Data

---

### ✅ v0.2 Agent 2：省份数据层（已完成）

阿登 v0.2 省份图数据 + 加载。17 省覆盖全部 99 hex，零重叠，邻接双向一致。

| 文件 | 职责 |
|------|------|
| `Data/ardennes_v02_regions.json` | 17 省/41 边/99 hex 映射/2 补给源/4 目标。schemaVersion 2 |
| `Data/RegionDataSet.swift` | `RegionDataSet` + Codable 定义（`RegionNodeDefinition`/`CityInfoDefinition`/`ResourceAmountDefinition`/`OccupationStateDefinition`/`RegionEdgeDefinition`/`RegionSupplySourceDefinition`/`RegionObjectiveDefinition`）+ 映射 `toRegions()`/`toRegionEdges()`/`toHexToRegion()` |
| `Data/DataLoader.swift`（改） | 加 `loadArdennesV02Regions()` + `validate(_ regionData:)`（复用 validateRegionGraph）；`loadInitialGameState()` 叠加省份数据（try? 失败 fallback 纯 hex）+ 反向填 HexTile.regionId |

**省份设计：**
- 德方控制：german_east_depot（补给源）、eifel_approach、schnee_eifel
- 盟方控制：allied_west_depot（补给源）、bastogne（主目标 VP5）、bastogne_fortress、st_vith、western_approach
- 中立（原 allies 领土中立化，owner/controller null 映射回退 .allies）：meuse_approach、houffalize、luxembourg_road、ardennes_forest_north/central/south、northern_ridge、southern_ridge、northern_frontier
- 路径：german_east_depot→bastogne=2，allied_west_depot→bastogne=3

| `Tests/ArdennesV02DataTests.swift` | 17 测试：解码/region 数/hexToRegion 覆盖/validate/邻接双向/repHex/路径连通/补给源/目标/关键省/控制权 |

---

### ✅ v0.3：战区、前线、部署、战争指令（当前主线，已推进至 v0.37）

| 版本 | 主题 | 关键内容 |
|------|------|----------|
| **v0.31** | Theater 战区层 | 四战区初始化、控制比例、70% 阈值、扩张/退役接口 |
| **v0.32** | FrontLine 前线层 | 动态前线、segment、dirty 更新、简化包围识别 |
| **v0.33** | WarDeployment 部署层 | FRONT / DEPTH / GARRISON 分层，FrontZone 单元池 |
| **v0.34** | 地图编辑器 | 默认地图与项目 schema 打通 |
| **v0.351** | 初级战争指令 | `ZoneDirective` / `WarCommandExecutor` / `MockAICommander` |
| **v0.352** | 新管线唯一化 | `WarPipelineMode.zoneDirective` 默认，观察者模式，分层战略 UI |
| **v0.353** | 默认地图验收 | hex controller 成为归属权威，补给归属跟随占领者 |
| **v0.354** | 联动修复 | 占领→region→theater→frontline 同回合联动，ZOC 友军穿越修正，拒绝率治理 |
| **v0.355** | 动态/初始战区分离 | `initialSnapshot` 与运行时动态战区分离，前线 overlay 与观察者 UI |
| **v0.356-v0.357** | 地图/前线 UI 修正 | 编辑器与游戏视角统一、开局单位越界检查、前线按战区/segment 着色 |
| **v0.358** | hex 动态战区语义收口 | 动态战区改跟 `hexToTheater`，region 基础战区只作初始/生成参照；AI/部署/前线测试同步更新 |
| **v0.36** | 命令层扩展与多将领 MockAI | `CommandCategory` / `TacticName` / `DirectiveTarget` / `ZoneCommanderAgent` / `TheaterCommanderPool` |
| **v0.37** | 命令层统一整合 | 移除 `TurnManager` 的 `MockAICommander` fallback，默认路径收口到 `TheaterCommanderPool`；补 issuer-agnostic executor 探针 |
| **v0.5** | 元帅层与模拟 LLM JSON | `MarshalAgent` / `TheaterDirectiveEnvelope` / decoder / compiler / marshal fallback |
| **v0.7** | 高级战术与命令扩展 | 闪电战、定点矛头、突破、钳形攻势、火力覆盖、佯攻、游击战、弹性防御、纵深防御、死守 |

### ⏳ 后续方向

| 版本 | 主题 | 关键内容 |
|------|------|----------|
| **v0.4** | 聊天命令与角色服从 | 玩家通过聊天框命令将领；将领根据性格/忠诚回应；命令可被质疑/拖延/抗命 |
| **v0.5** | 元帅决策链与模拟 LLM JSON | `MarshalAgent`、`TheaterDirectiveEnvelope`、JSON decoder、compiler、fallback；统治者只预留为后续上游，不恢复 Cabinet/Minister |
| **v1.0** | 大战略原型 | 经济/科技/生产；空军实体化；简化海军；天气；多国家多战区；全球地图；美术资源 |
| **v1.x** | 多回合战术行动 | 撤退命令、突破/闪电战、装甲差异化、`AttackIntensity` 深度分流等复杂多回合行动骨架 |

**v0.37 决策记录：** 撤退、突破、闪电战、装甲差异化和 `AttackIntensity` 深度分流推迟至 1.x。v1.0 只先把 `infiltration` 解释为默认低投入上限，不引入额外伤害、绕规则推进或多回合追踪行动。

---

## 核心设计约束

**LLM 使用原则（必须始终遵守）：**
1. 不让每个单位每回合都调用 LLM
2. LLM 只读取摘要，不读取完整地图
3. LLM 输出必须经过 `CommandValidator` 校验才能执行
4. 非法命令先尝试自动修复，修复失败则丢弃并记录日志
5. 没有 LLM 时，MockAI 接管所有决策

**架构扩展约束（后续 agent 必须遵守）：**
- 不要跳过命令管线直接修改 `GameState`
- **不要替换 HexCoord 坐标系**：hex 是战术层，province 是叠加的战略层，两者共存
- **不要把 `regionToTheater` 当动态战区推进层**：运行时战区归属看 `hexToTheater`，突破只推进 hex。
- **不要给 Division 加回 organization**：v0.1 已移除，只看兵力
- **不要引入 v0.5 Cabinet/StrategicDirective/Minister 污染**：v0.5 误删事件已发生，GameAgent 保持精简版
- 新增系统通过 `DecisionProvider` / `RuleEngine` / `Command` 接入，不直接改核心规则
- 保持核心语义不退步；默认只做轻量检查，Xcode / XCTest / 模拟器等重测试必须由人工明确授权。

---

## 文档索引

```
md/
├── plan/plan.md
│   └── 当前 md 大纲、唐宋迁移路线索引、阶段文档建议和轻量检查入口
├── flow/
│   ├── flow.md
│   ├── flowchart.md
│   └── *.mermaid
│       当前真实核心逻辑、数据流、命令流和云端协作流
├── test/test.md
│   └── 本地轻量检查、云端重验证、CI artifact 验收和禁止本机重测试规则
└── prompt/
    ├── README.md
    │   Agent A/B/C 召唤、阶段 prompt 写法、main 直推和 CI artifact 要求
    ├── v5.0-唐宋迁移/
    │   唐宋 v5.0-v5.9 总提示词、v5.0 审计合同和后续阶段记录
    ├── v2.0-三国迁移/
    ├── v3.0-拿战迁移/
    ├── v3.0-隋唐迁移/
    ├── v4.0-明末迁移/
    ├── v5.0-维多利亚迁移/
    ├── v6.0-现代战争迁移/
    ├── anti生成/
    ├── v0.2（已完成）/
    ├── v0.3（已完成）/
    ├── v0测试（已完成）/
    └── old/
```

> 历史 prompt 仅作上下文；若旧 prompt 与 `AGENTS.md`、`md/test/test.md` 或 `md/plan/plan.md` 冲突，以当前入口文档和真实源码为准。

---

## 给后续 Claude Code 的提示

**你接手时的代码库状态：**
- v0.5 分支已引入元帅层与模拟 LLM JSON/decoder/ compiler；历史测试基线曾达到 v0.37 Probe 18/0、Stage Regression 69/0、Full 226/0。当前默认不跑重测试，只做 `md/test/test.md` 允许的轻量检查。
- 战斗模型：兵力伤害为主，`RetreatMode`（retreatable/hold）控制撤退，无 organization。
- 默认战争 AI 管线：`MarshalAgent` 读取摘要并模拟输出 `TheaterDirectiveEnvelope` JSON，经 `TheaterDirectiveDecoder` 与 `TheaterDirectiveCompiler` 降级成 `ZoneDirective`，再走 `WarCommandExecutor`。`TheaterCommanderPool` / `ZoneCommanderAgent` 仍作为 fallback 和显式 `.zoneDirective` 路径。
- Legacy Agent D 管线保留但默认不调用。
- 地图坐标系：hex 仍是战术权威；Region 是省份规则层；动态战区看 `hexToTheater`。

**继续开发前请先阅读：**
1. 本 README（地图架构三层决策 + Agent D 接口表）
2. `WWIIHexV0/Core/Division.swift`（当前 Division 模型）
3. `WWIIHexV0/Core/MapState.swift` / `Region.swift` / `Theater.swift`
4. `WWIIHexV0/Rules/TheaterSystem.swift` / `FrontLineManager.swift` / `WarDeploymentManager.swift`
5. `WWIIHexV0/Commands/WarDirective.swift` / `WarCommandExecutor.swift`
6. `WWIIHexV0/Agents/ZoneCommanderAgent.swift` / `MockAICommander.swift`
7. `md/prompt/anti生成/v0.5/anti/0.50_v0.5_marshal_implementation_record.md`

**当前必须遵守：**
- 不删 `HexCoord`，不把运行时战区推进退回 region 粒度。
- `Initial Theater Layout` / `regionToTheater` 是地图编辑器与动态演化基准，不是实时前线。
- `Dynamic Theater State` / `hexToTheater` 是游戏战区层权威。
- 前线 UI 和 AI target 选择必须基于动态 hex 邻接；历史测试 fixture / 语义文档也必须构造真实相邻 hex，不能只声明 region 邻接。
- `ZoneDirective` 新字段必须保持 Codable 向后兼容。
- 元帅层和未来统治者层不得绕过 `ZoneDirective -> WarCommandExecutor -> RuleEngine`。
- 当前 v0.5 只模拟 LLM JSON 接口，不接真实模型；真实 LLM 接入必须保留 decoder 校验与 fallback。

## 协作与云端验证

当前协作制度固定使用 `main` 作为上传、提交、推送和云端验证分支。Agent B 本地只跑 `md/test/test.md` 允许的轻量检查，提交后直接 push 到 `origin/main` 触发 GitHub Actions；Agent C 通过 GitHub CLI 下载未加密 CI 结果包，核对 manifest、JUnit、构建日志和失败摘要后再验收。详细规则见 `AGENTS.md`、`md/test/test.md` 和 `md/prompt/README.md`。

**轻量检查**（每轮先读 [`md/test/test.md`](md/test/test.md)，本机默认只做轻量检查，重验证交给 GitHub Actions）：
```bash
rg -n "[[:blank:]]+$" AGENTS.md README.md update_log.md md/test/test.md md/flow/flow.md
```
旧测试口径残留、JSON / project / scheme 检查按 `md/test/test.md` 追加执行。未获人工授权时，不跑历史 Probe / Stage / Full。

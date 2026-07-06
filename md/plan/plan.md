# 项目 md 大纲：唐宋迁移版

本文是 `md/` 目录的当前大纲、唐宋迁移路线索引和后续阶段文档包清单。它只整理文档结构、版本规划和交接口径，不表示本轮已经修改业务源码。

依据文件：

- `AGENTS.md`
- `update_log.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v5.0-唐宋迁移/codex-v5.0-唐宋aiagent历史策略迁移总提示词.md`

## 0. 使用方式

后续 Agent 接手唐宋迁移时，先用本文判断“当前做到哪一层、下一步该改哪些文档”，再回到 `md/flow/flow.md`、`md/flow/flowchart.md` 和源码确认真实实现。本文不是功能验收报告，也不能替代 GitHub Actions artifact；它只作为 `md/` 目录的大纲、阶段索引、文档包清单和交接清单。

每轮涉及唐宋迁移时：

1. 先读 `AGENTS.md`、`update_log.md`、`md/test/test.md`、`md/flow/flow.md`、`md/flow/flowchart.md` 和本文件。
2. 再读 `md/prompt/v5.0-唐宋迁移/` 下对应阶段记录。
3. 若源码行为、默认数据、AI 管线、UI 文案、检查规则或云端验证口径变化，必须同步更新本文件或说明为什么不需要更新。
4. 本文只写当前真实进度和下一步队列，不把未实现愿景写成已完成事实。

## 1. 当前项目基线

当前工程仍是 `WWIIHexV0`：Swift + SwiftUI + SpriteKit 的 iOS / macOS hex 战棋工程。已有成熟资产包括：

- Hex 战术权威：`HexTile.controller`、`Division.coord`。
- Region 战略聚合：州府/省份类信息只能从 hex 状态聚合，不替代 hex。
- 动态战区：`hexToTheater` 是运行时权威，`regionToTheater` 只是初始/基础映射。
- 部署层：`hexToFrontZone` 是部署动态归属权威。
- 统一命令管线：玩家、AI、聊天命令、MockAI 都必须落到 `Command` / `ZoneDirective -> WarCommandExecutor -> RuleEngine`。
- MapEditor、iOS 主游戏、macOS 主游戏方向保留。
- Legacy Agent D 保留作回归参考，默认战争 AI 主路径不得退回旧管线。

唐宋迁移不是换皮，也不是一次性大改所有类型名。后续实现必须先建兼容层和迁移合同，再分版本收口。

## 2. 唐宋迁移目标

暂定产品名：`山河一统 Agent`。

首发剧本：

```text
id: jianlong_960_unification
displayName: 建隆元年：陈桥兵变与山河一统
时间范围：960-979 抽象统一战争窗口
核心冲突：赵宋中原根基、北汉与辽压力、南唐/后蜀/吴越/荆南/南汉等割据政权
```

首发范围：

- 默认可玩势力优先保证 `power_song`。
- 地图建议 140-220 hex、45-70 州府/关隘/仓城、8-14 方面/路/行营。
- 玩家可微操军队，也可通过将领/方面/枢密院面板下达宏观命令。
- AI Agent 输出必须是 Codable JSON / directive，不能直接改 `GameState`。
- 默认主路径不显示 Germany、Allies、Ardennes、Panzer、Bastogne、Guderian、German AI、Allied Player 等二战文案。

首发体验锚点：

- 打开应用后第一屏应是可操作地图、回合、当前政权、资源、军令、AI 战报，不做 landing page。
- 玩家至少能用宋完成开局、选军、行军、战斗、围城/占领、粮草、AI 回合、外交/归附事件、战报复盘和胜负判断的完整闭环。
- UI 视觉目标是发布级唐宋历史策略质感：地图可读，州府、粮道、围城、战线和军议可解释，不是调试面板。
- iOS 主游戏、macOS 主游戏和 MapEditor 方向都保留；若某方向暂未完成，必须在阶段记录里写明。

## 3. 当前迁移进度快照

截至当前工作树，唐宋迁移已经进入 v5.6 外交、归附与天命规则/UI 首轮：

- v5.0 已建立迁移总提示词和审计合同，明确首发 960 剧本、架构边界、版本路线、禁止项和验收标准。
- v5.1 已加入 `PowerId` / `PowerProfile` / `PowerRelation` / `TurnOrderState` / `WarRelationRules` 兼容地基，回合和 AI 控制权主路径开始脱离硬编码 Germany/Allies。
- v5.2 已新增唐宋 960 场景、州府/方面、单位模板和人物 JSON；默认加载优先唐宋资源，阿登保留 legacy fallback；MapEditor 默认资源桥和工具术语已迁到唐宋口径。
- v5.3 已完成生产、府库和经济日志显示桥首轮：唐宋路径显示军备、丁口、钱帛、粮草、禁军、厢军、骑军、攻城器械营。
- v5.3 已加入唐宋场景专用古代兵种战斗修正首轮：骑军平原/道路进攻、弓弩守军守城、攻城器械攻城/野战差异和守军城防差异已经由 `CombatRules` 处理。
- v5.3 已加入粮道供给与读法首轮：唐宋场景下受控高 `supplyValue` 州府/粮仓可作为补给源，道路、城关、山林、跨河成本会影响 `SupplyRules` 补给判定；单位详情可读粮道通断、路径成本/上限、最近粮源和安全退路数。
- v5.3 已加入围城城防、修城、解围、招降、地图围城 overlay 与 AI 围城/招降指令首轮：`Command.besiege` 经 `RuleEngine` 登记 `SiegeState` 并损耗 `fortification`；`Command.repairFortification` 让守方军队在被围州府内消耗行动修城；`Command.relieveSiege` 让守方或友军削减围城 pressure，pressure 降到 0 时解除围城记录；`Command.demandSurrender` 让围城方在 pressure 达标、城防归零且守军不再 `supplied` 后，经规则层移除纳降守军、交割目标州府可占 hex 并刷新 Region / Theater / FrontLine / WarDeployment；`ZoneDirective.attack -> WarCommandExecutor` 可在目标敌控州府满足纳降条件时生成底层 `Command.demandSurrender`，否则在目标可围且无可攻击单位时生成底层 `Command.besiege`；Region 面板可读围城压力和城防，地图可从 `SiegeState` 只读绘制围城圈、压力和城防标签。
- v5.4 已完成 AI 军议显示桥、simulated marshal 文案唐宋化与解释字段首轮：`DirectiveType`、`CommandCategory`、`TacticName` 提供唐宋场景感知显示名；`AgentPanelView` 在唐宋场景下显示军议、诏令朝议、方面军令、进军、骑军突进、合围、弓弩压制和死守城关等读法；`MarshalBattlefieldSummary` 携带 `scenarioId`、首都、围城、粮道优先和招抚候选 region 摘要，让 `SimulatedMarshalLLMClient` 在唐宋场景下输出宋枢密院/割据行营、州府、粮道口径的 strategicIntent、summary、rationale，以及 `mandateIntent`、`courtPolicy`、`pacificationTargets`、`supplyPriorities` 可选解释字段；`TurnManager` 会把这些字段复制到 `AgentDecisionRecord.theaterDirectiveSummary`，AI 面板只读显示诏令、朝议、招抚、转运和摘要；`GameAgent.defaultCommander` 在唐宋场景下使用宋枢密院/割据行营作为默认 AI issuer，不再把默认唐宋主路径记录成 Guderian 或 Allied Mock Commander；底层 raw case 和 `ZoneDirective -> WarCommandExecutor -> RuleEngine` 权限边界不变。
- v5.5 已完成默认唐宋主界面术语桥、地图视觉 token 与只读粮道 overlay 首轮：`MapDisplayLayer`、`GamePhase` 和 `GameState.phaseDisplayName` 提供唐宋场景显示名；`RootGameView` 的图层、观战、面板按钮、compact tabs、棋盘 accessibility label 改为唐宋口径；`HUDView`、`CommandPanelView`、`EventLogView` 显示回合、政权、军令、战报、围城和粮道等读法；`TerrainStyle`、`HexNode`、`RegionOverlayNode`、`UnitNode`、`MapLayerOverlayNode` 和 `BoardScene` 提供唐宋墨绿底、青绿/石青/铜/朱印 palette、赭石道路、石青河流、军旗棋子和禁/骑/弩/械/守/军兵种字标；`SupplyRouteOverlayState` / `MapDisplayAdapter.supplyRouteOverlays` / `BoardScene.drawSupplyRouteOverlays` 从既有 `SupplyRules.supplyRouteSummary` 派生可见友方军队到最近可见粮源的抽象虚线。底层 raw case、命令、日志结构、补给规则和规则执行不变。
- v5.6a 已完成外交归附与天命规则合同首轮：`DiplomaticStatus` 支持 `tributary`、`submitting`、`negotiating`；`DiplomacyState` 保存 `PacificationRecord`；`GameState` 保存向后兼容的 `MandateState`；`Command.proposeSubmission -> CommandValidator -> CommandExecutor -> RuleEngine` 可在满足国家关系、天命、首府、低 warSupport 或围城压力条件后写入关系、归附记录和天命变化。
- v5.6b 已完成玩家招抚入口与外交面板只读展示首轮：`CommandPanelView` 新增“招抚”按钮，`AppContainer.proposeSubmissionSelected` 只提交底层 `Command.proposeSubmission`；目标优先使用选中外国首府，否则扫描当前可招抚首府；`DiplomacyPanelView` 只读展示天命分数和最近归附记录。
- v5.6c 已完成 AI `pacificationTargets -> Command.proposeSubmission` 安全编译桥首轮：`TurnManager` 在战争 `ZoneDirective` 执行后、`.endTurn` 前，把唐宋元帅 envelope 的首府招抚候选尝试生成辅助 `Command.proposeSubmission`，仍由 `RuleEngine -> CommandValidator -> CommandExecutor` 决定成功、拒绝或跳过，并写入 `AgentDecisionRecord.commandResults`。该切片不交割地图控制权、不转换部队、不改全局战争关系。
- v5.6d 已完成唐宋天命/国威胜利评价桥首轮：`VictoryRules` 在唐宋场景读取关键 objective 控制方与 `MandateState`，宋统一胜利需要关键州府控制数与天命阈值同时达标，割据生存需要最大回合时核心都城保有数与割据天命同时达标；阿登 legacy 胜利逻辑保持原样。
- v5.6e 已完成国家外交关系到 `TurnOrderState.relations` 的保守投影同步首轮：`DiplomacyState` 会把跨 legacy faction 的国家关系聚合成 power 级状态，只要仍有任一国家 hostile/atWar，`.allies/.germany` 仍保持 `atWar`；`Command.proposeSubmission` 成功后同步该投影，避免单国归附误停全局战争。
- v5.6f 已完成战术候选关系感知首轮：UI 点击攻击、攻击高亮、将领目标区推断，AI 敌情估算、敌区/敌强排序，以及 `WarCommandExecutor` 可见敌军、敌控州府和战术移动候选都先读取 `WarRelationRules.canTarget`；战争移动候选会排除非己方且非敌对 controller 的 hex，减少非敌对对象被生成成战争候选；招抚/谈判候选仍保留外交规则口径。
- v5.6g 已完成数据驱动唐宋胜利条件首轮：`GameState` 保存场景 JSON `victoryConditions`，`VictoryRules` 优先按 objective id、count、turn / turns 与 `mandateThreshold` 判定 `controlObjectives` / `holdObjectives`，并保留 v5.6d 硬编码 fallback。
- v5.6h 已完成胜负原因显示首轮：`VictoryReason` 提供唐宋显示桥，HUD 胜负栏和战报面板只读显示 `VictoryState.reason`，不改变胜利判定或写权威事件。
- v5.6i 已完成胜利目标进度只读显示首轮：`VictoryRules.objectiveProgress(in:)` 从 `GameState.victoryConditions`、objective 所在 hex controller 和 `MandateState` 派生进度快照；HUD 展示主要统一条件的州府/天命进度，战报面板展示主要胜利条件的州府、天命和回合门槛，不写 `VictoryState` 或 `eventLog`。
- v5.7a 已完成首屏“下一步”只读提示首轮：`RootGameView.nextActionHint` 从当前胜负、观战、回合权限、选中军队和围城/招抚/解围/修城候选派生一句唐宋场景专用行动建议；`HUDView` 只读展示该提示，不提交命令、不调用 `RuleEngine`、不写 `GameState` 或 `eventLog`。
- v5.7b 已完成首屏统一目标锚点首轮：`HUDView.objectiveGuideText` 复用 `VictoryRules.objectiveProgress(in:)` 和 `MapState.controllerOfObjective(named:)`，把主要宋统一目标拆成“已据/待取”关键州府列表，帮助玩家理解当前 `统一进度` 数字对应哪些地图目标；该提示不新增高亮层、不写状态、不改变胜利规则。
- v5.7c 已完成目标锚点定位首轮：HUD 目标锚点变为可点击按钮，点击后 `AppContainer.focusObjective(id:)` 只更新 `selectedHex` / `selectedRegionId`，复用已有地图选中高亮与州府面板展示目标，不提交命令、不改规则。
- v5.7d 已完成目标州府地图 spotlight 首轮：`MapDisplayAdapter.objectiveOverlays()` 从主要宋统一目标只读派生 `ObjectiveOverlayState`，`BoardScene.drawObjectiveOverlays` 在地图上标出“已据 / 待取”州府；HUD 点击目标后 `focusedObjectiveId` 只作为渲染态强调当前目标，不提交命令、不改规则。
- v5.7e 已完成每回合战报摘要首轮：`EventLogView` 从 `gameState.eventLog`、最近 `AgentDecisionRecord` 和 `GameState.warDirectiveRecords` 只读汇总“本回合战报 / 最近战报”，按战斗、州府、围城、粮道、外交、军议等类别计数并摘取关键消息；该摘要不补写 `eventLog`、不改规则。
- v5.7f 已完成新局/指挥身份包装首轮：HUD 只读显示当前指挥身份与观战/亲征模式，唐宋“重开剧本”按钮先弹出确认再调用既有 `resetGame()`；该切片不实现真实多势力选择、不改变 `playerFaction`。
- v5.7g 已完成下一步提示高亮数量首轮：`RootGameView.nextActionHint` 读取既有 `movementHighlights` / `attackHighlights` 数量，在选中可行动宋军时提示可行军格和可攻击目标数；该提示不新增 `CommandValidator` dry-run，不替代真实规则校验。
- v5.7h 已完成亲征势力/观战轻量入口首轮：`DataLoader` 读取场景 JSON 的 `playerFaction` / `aiFaction` 初始化唐宋 turn order，`RootGameView` 提供唐宋“亲征”分段选择，`AppContainer.setPlayerFaction(_:)` 同步 `playerFaction`、`TurnOrderState.playerControlledPowerIds` 和 legacy profile controlMode；该入口仍只覆盖 `.allies/.germany` 兼容桥，不是完整多政权选择器或持久化配置。

仍未完成的关键项：

- `Faction` 底层仍是 `.allies` / `.germany` legacy 桥，真实多政权数据驱动未收口。
- `ProductionKind`、`EconomyResources`、`Division`、`ComponentType` 的 Codable schema 仍保留二战兼容名。
- 自动破城、完整外交纳土交割、完整漕运/粮队/仓储容量、完整胜利评分/统一结算、治理政策和完整发布级 UI 美术/截图验收仍未落地。
- AI 默认 issuer 与 simulated rationale 的唐宋主路径首轮已迁移，但完整皇帝/朝廷/枢密/节度使/转运使/州府守臣/外交使者 schema、真实多 Agent JSON 和真 LLM 接入仍待后续；legacy Agent D、阿登数据与测试中的 Guderian/Rundstedt/Eisenhower 仍保留作兼容参考。

下一轮可继续推进 v5.7 可玩闭环：完整多政权势力选择/持久化配置、更精确的命令合法性提示、结算页/评分草案或截图/布局验收计划；也可回到 v5.6 继续治理政策、完整胜利评分/统一结算、单国 tactical neutral 或归附后的控制权/部队处理方案。无论走哪条线，真实行动仍必须经 `Command` / `ZoneDirective -> WarCommandExecutor -> RuleEngine`，不得让 UI、事件或 Agent 直接改 `GameState`。

## 4. md 目录职责

```text
md/
├── plan/
│   └── plan.md
│       当前 md 大纲、唐宋迁移路线索引、阶段文档包清单和文档维护口径。
├── flow/
│   ├── flow.md
│   ├── flowchart.md
│   └── *.mermaid
│       当前真实核心逻辑、数据流、命令流和云端协作流。
├── test/
│   └── test.md
│       本地轻量检查、云端重验证、artifact 验收、禁止本机重测试规则。
└── prompt/
    ├── README.md
    │   Agent A/B/C 召唤、阶段 prompt 写法、main 直推和 CI artifact 要求。
    ├── v5.0-唐宋迁移/
    │   唐宋 v5.0-v5.9 总提示词、审计合同、阶段实现记录和验收记录。
    ├── v2.0-三国迁移/
    ├── v3.0-拿战迁移/
    ├── v3.0-隋唐迁移/
    ├── v4.0-明末迁移/
    ├── v5.0-维多利亚迁移/
    ├── v6.0-现代战争迁移/
    ├── anti生成/
    │   已整合或候选分支的实现记录。
    ├── v0.2（已完成）/
    ├── v0.3（已完成）/
    ├── v0测试（已完成）/
    └── old/
        历史 prompt、误删打捞、旧方案和回退记录。
```

文档更新原则：

- `AGENTS.md` 只写入口规则和工作流，不堆阶段细节。
- `update_log.md` 记录版本历史、文档整理、流程制度变更和遗留风险。
- `md/flow/*` 只记录当前真实核心逻辑，不把未来愿景写成已实现。
- `md/test/test.md` 是检查边界权威。
- `md/prompt/v5.0-唐宋迁移/` 放唐宋阶段 prompt、审计记录、实现记录和验收记录。

## 5. 唐宋 v5.0-v5.9 路线

| 版本 | 主题 | 当前状态 | 目标 | 主要文档产物 |
|---|---|---|---|---|
| v5.0 | 迁移审计与合同冻结 | 已建档 | 不改玩法，先审计二战残留、冻结唐宋迁移合同、明确首发剧本与边界 | `v5.0_audit_and_contract.md`、词汇表、风险清单 |
| v5.1 | 多势力与通用回合地基 | 已完成首轮 | 解耦 `germany/allies`、`Faction.opponent`、`germanAI/alliedPlayer`，建立 `PowerId` / turn order / relation 兼容层 | `v5.1_powers_turn_order_record.md` |
| v5.2 | 首发剧本数据与 MapEditor 语义 | 已完成首轮 | 默认数据迁到 `jianlong_960_unification`，MapEditor 术语迁到地块/州府/方面/军队/人物 | `v5.2_scenario_mapeditor_record.md` |
| v5.3 | 古代军制、粮草、围城与经济 | 进行中 | 兵种、生产、补给、粮道、围城最小闭环，资源显示迁为丁口/钱帛/粮草 | `v5.3_rules_siege_grain_record.md` |
| v5.4 | 唐宋 AI Agent 分层 | 进行中 | 皇帝/朝廷/枢密/节度使/转运使/州府守臣/外交使者分层，保留 directive 管线 | `v5.4_agent_schema_record.md` |
| v5.5 | 发布级 UI 与地图视觉 | 已完成术语桥、视觉 token、只读粮道 overlay 首轮 | 第一屏地图、HUD、军令、州府、府库、外交、战报、军议可读；移除默认二战文案 | `v5.5_ui_visual_record.md` |
| v5.6 | 外交、归附、天命与治理 | 已完成规则合同、玩家入口/只读展示、AI 招抚辅助桥、天命胜利评价、关系投影、战术候选关系感知、数据驱动胜利条件、胜负原因和胜利目标进度显示首轮 | 多政权关系、归附、天命/国威、治理和事件闭环 | `v5.6a_diplomacy_mandate_contract_record.md`、`v5.6b_player_submission_diplomacy_panel_record.md`、`v5.6c_ai_pacification_submission_record.md`、`v5.6d_tangsong_victory_mandate_record.md`、`v5.6e_diplomacy_turn_order_projection_record.md`、`v5.6f_relation_aware_war_candidates_record.md`、`v5.6g_data_driven_victory_conditions_record.md`、`v5.6h_victory_reason_battle_report_record.md`、`v5.6i_victory_objective_progress_record.md`、`v5.6_diplomacy_mandate_record.md` |
| v5.7 | 教程、剧本包装与可玩闭环 | 已开始：v5.7a 下一步提示、v5.7b 统一目标锚点、v5.7c 目标定位、v5.7d 地图目标 spotlight、v5.7e 每回合战报摘要、v5.7f 新局/指挥身份包装、v5.7g 高亮数量提示、v5.7h 亲征/观战入口首轮 | 开局引导、势力选择、战报、新局/重置，让普通玩家能完成首发剧本 | `v5.7a_next_action_hint_record.md`、`v5.7b_objective_anchor_record.md`、`v5.7c_objective_focus_record.md`、`v5.7d_objective_spotlight_record.md`、`v5.7e_turn_report_summary_record.md`、`v5.7f_new_game_identity_observer_record.md`、`v5.7g_next_action_highlight_counts_record.md`、`v5.7h_start_power_observer_entry_record.md`、`v5.7_playable_loop_record.md` |
| v5.8 | 发布候选硬化 | 未开始 | 玩家可见残留扫描、资源授权、性能和文档口径收口 | `v5.8_release_candidate_audit.md` |
| v5.9 | 可发布版本收口 | 未开始 | 首发剧本可完整试玩，Agent C 验收通过，README/flow/update_log 反映唐宋产品 | `v5.9_release_acceptance.md` |

阶段状态只能按真实源码和真实检查结果推进。一个阶段可以有多轮“小切片”，但不能因为写了路线或 prompt 就把状态写成已完成。

## 5.1 v5.4-v5.9 文档包拆分

后续不要把所有实现、验收和风险继续堆进总提示词。每个阶段应有独立记录，且记录要把“源码真实完成项”和“未来目标”分开。

| 阶段 | 阶段记录必须回答 | 验收锚点 | 不应写成已完成的内容 |
|---|---|---|---|
| v5.4 AI Agent 分层 | 新增或迁移了哪些 Agent schema、JSON 字段、fallback、展示文案；是否仍编译到 `ZoneDirective` / `Command` | 默认 AI 不展示二战人物；JSON 解码失败能安全 fallback；AI 不直接改 `GameState` | 真实 LLM、外交归附或战斗胜利，除非规则层已落地 |
| v5.5 UI 与视觉 | 哪些玩家可见二战词已移除；地图、HUD、军队、州府、府库、外交、战报、军议怎么显示 | 第一屏地图可操作；文本不溢出；围城、粮道、前线、计划图层可读 | 未经运行截图或人工授权的“发布级 UI 已验收” |
| v5.6 外交天命治理 | 多政权关系、归附、天命/国威、治理事件如何经规则层落地 | 归附/外交记录可查；天命影响胜利或统一评价；Agent 不能直接改控制权 | 绕过 command/rule 的事件式占领 |
| v5.7 可玩闭环 | 开局引导、势力选择、每回合战报、新局/重置和玩家下一步提示 | 新玩家不读 README 也能完成第一场行动；每回合有可解释战报 | 大段说明页或营销页 |
| v5.8 RC 审计 | 玩家可见残留扫描、JSON 检查、project/XML 检查、资源授权、性能/重测试授权状态 | 默认启动唐宋剧本；主要 UI 无二战残留；资源授权清单明确 | 未授权的本机 build/test/simulator 结果 |
| v5.9 发布验收 | 首发剧本完整试玩状态、Agent C artifact 核对、README/flow/update_log 是否统一 | `origin/main` 最新 commit 对应 Actions run 和未加密 artifact 已核对 | 只凭本地文字说明宣称可发布 |

## 6. v5.3 剩余切片队列

v5.3 当前不应直接跳到大规模 UI 或完整外交。优先把“古代军制、粮草、围城与经济”闭合到可解释、可验证的小循环。

| 优先级 | 切片 | 目标 | 必须更新的文档 | 禁止越界 |
|---|---|---|---|---|
| P0 | 城防耐久 | 已完成首轮：`SiegeRecord.fortification / maxFortification`，围城损耗城防，城防归零后才断粮 | `v5.3_rules_siege_grain_record.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、本文、`update_log.md` | 后续仍不自动改 hex/region 控制权，不绕过移动占领 |
| P0 | 修城命令 | 已完成首轮：`Command.repairFortification` 让守方在被围州府内消耗行动恢复城防 | 同上 | 不把修城写成 UI 直接改状态 |
| P1 | 解围 / 驰援 | 已完成首轮：`Command.relieveSiege` 让守方或友军削减 pressure，pressure 归零时解除 siege record | 同上 | 不用事件直接删除敌军或改变归属 |
| P1 | 围城 UI/overlay | 已完成首轮：Region 面板显示围城摘要，地图从 `SiegeState` 只读绘制围城圈、压力和城防标签 | `README.md`、`md/flow/*`、`v5.3_rules_siege_grain_record.md` | 不把视觉层写成规则层 |
| P1 | AI 围城/招降指令 | 已完成首轮：`ZoneDirective.attack -> WarCommandExecutor` 在目标州府可招降时生成底层 `Command.demandSurrender`，否则在可围且无可攻击单位时生成 `Command.besiege` | `v5.3_rules_siege_grain_record.md`、后续 v5.4 记录 | 不让 AI 直接写 `GameState.siegeState` 或 controller |
| P1 | 围城招降 | 已完成首轮：`Command.demandSurrender` 在 pressure 达标、城防归零且守军不再 `supplied` 后，交割目标州府可占 hex 并刷新派生层 | `v5.3_rules_siege_grain_record.md`、`md/flow/*`、本文、`update_log.md` | 不做自动破城；不把招降扩展成完整外交归附 |
| P2 | 漕运 / 粮道读法 | 已完成读法首轮：单位详情显示粮道通断、成本/上限、最近粮源和安全退路数；完整漕运仍待后续 | `md/flow/*`、`README.md`、`v5.3_rules_siege_grain_record.md` | 不新增复杂仓储系统，除非另开切片 |
| P2 | 漕运深化 | 已完成只读地图粮道线首轮：地图从 `SupplyRouteSummary` 派生友方军队到最近可见粮源的抽象虚线；完整漕运、仓储容量、粮队实体和逐 hex 路径仍待后续 | `md/flow/*`、`README.md`、`v5.3_rules_siege_grain_record.md`、本文 | 不引入全局复杂物流系统；不让 UI 直接修改补给状态 |
| P2 | 围城结果显示与胜利结算 | 待做：在显式招降、占领或合法胜利规则触发后，让战报/日志/胜利面板解释结果 | `md/flow/*`、`README.md`、`v5.3_rules_siege_grain_record.md`、`update_log.md` | 不做结束回合自动改控制权；不绕过 `VictoryRules` 或命令管线 |
| P3 | 围城 AI 解释文案 | 已完成首轮：AI 面板在唐宋场景显示军议、诏令朝议、方面军令和唐宋战术名；simulated marshal strategicIntent、summary 与 rationale 已转为宋枢密院/割据行营、州府和粮道口径；mandate/court/pacification/supply 解释字段已从 raw JSON 进入只读面板摘要；后续仍可继续细分围城/修城/解围/招降原因 | `v5.3_rules_siege_grain_record.md`、`v5.4_agent_schema_record.md` | 不改变 AI 执行权限；解释文案不能替代规则结果 |

v5.3 收口标准：

- 默认唐宋生产、资源、战斗、补给和围城链路没有主要二战显示词。
- 围城至少具备登记、压力、城防/断粮效果、修城、解围/失效、招降、面板和地图读法。
- 所有新动作都经 `Command -> RuleEngine -> CommandValidator -> CommandExecutor` 或 `ZoneDirective -> WarCommandExecutor -> Command`。
- 阿登 legacy 数据仍可保留；不为完成唐宋迁移而删除旧兼容路径。

## 7. 迁移词汇总表

短期源码可保留 legacy 类型名，但玩家可见路径和新文档必须按唐宋语义书写。

| 二战/旧词 | 唐宋显示或目标语义 |
|---|---|
| Faction | Power / 政权 |
| Germany / Allies | 宋、北汉、辽、南唐、后蜀、吴越、荆南、南汉、地方豪强 |
| Division | 军队、军团、行营、守军 |
| Region / Province | 州府、军州、关隘、仓城 |
| Theater | 方面、路、行营、节镇 |
| FrontZone | 方面防区、行营辖区、节镇防区 |
| Manpower | 丁口 |
| Industry | 钱帛 / 工役 |
| Supplies | 粮草 |
| Panzer / motorized | 骑军、禁军、厢军、弓弩、器械、水师 |
| MarshalAgent | 枢密使、行营都部署、大将、谋主 |
| RulerAgent | 皇帝、国主、太后、权臣 |
| General | 将领、节度使、州府主将 |
| Diplomacy | 外交、称臣、纳土、归附、和议 |

## 8. 后续阶段进入条件

为避免“路线看起来进入下一版，实际核心闭环没完成”，后续阶段按以下条件推进：

- 进入 v5.4 前：v5.3 的围城/粮草/军制最小闭环必须有阶段记录，AI 只能通过 directive 或 command 触发这些规则。
- 进入 v5.5 前：v5.4 至少完成唐宋 AI 层展示与 deterministic fallback，不再默认展示二战人物作为唐宋主路径。
- 进入 v5.6 前：主界面和地图术语应基本迁出二战口径，玩家能看懂州府、军队、府库、军议和战报。
- 进入 v5.8 前：默认数据、UI、AI 文案和 README/flow/update_log 必须统一指向唐宋首发剧本，而不是阿登主产品。
- 进入 v5.9 前：Agent C 必须核对 `origin/main` 最新 commit 对应的 GitHub Actions run 和未加密 artifact，不能只看本地文字汇报。

### 8.1 v5.6 当前状态与后续风险

v5.6 外交、归附、天命与治理不能只做 UI 或 Agent 文案。当前已完成 v5.6a 规则合同首轮、v5.6b 玩家入口/只读展示首轮、v5.6c AI 招抚辅助桥首轮、v5.6d 天命胜利评价桥首轮、v5.6e 关系投影同步首轮、v5.6f 战术候选关系感知首轮、v5.6g 数据驱动胜利条件首轮、v5.6h 胜负原因显示首轮和 v5.6i 胜利目标进度只读显示首轮：

- 新增 `MandateState`，在 `GameState` 中向后兼容保存 faction 级天命/合法性分数。
- `DiplomacyState` 扩展 `tributary`、`submitting`、`negotiating`，并保存 `PacificationRecord`。
- 新增 `Command.proposeSubmission(negotiatorId:targetCountryId:targetRegionIds:)`，经 `CommandValidator -> CommandExecutor -> RuleEngine` 写入国家关系、归附记录、天命变化和 diplomacy 日志。
- 唐宋默认剧本初始化宋/割据天命分数。
- 新增玩家“招抚”按钮，只通过 `AppContainer.submit` 提交底层命令；外交面板只读展示天命和归附记录。
- AI 元帅 `pacificationTargets` 可由 `TurnManager` 在 `.endTurn` 前尝试生成辅助 `Command.proposeSubmission`，仍由 `RuleEngine` 决定成功、拒绝或跳过。
- 唐宋 `VictoryRules` 优先读取场景 JSON `victoryConditions`，按 objective id、控制数量、回合门槛和 `MandateState` 天命阈值判定宋统一胜利与割据生存；缺失条件时仍保留 v5.6d 硬编码 fallback。
- HUD 与战报面板会从 `VictoryState.reason` 只读显示胜负原因，便于玩家理解“为何胜利/为何存续”。
- 国家级外交关系会保守投影回 `TurnOrderState.relations`：只有跨 legacy faction 的 hostile/atWar 国家关系全部消失后，power 级关系才会脱离 `atWar`。
- UI/AI/`WarCommandExecutor` 的攻击、高亮、敌区、敌强、可见敌军和战术移动候选会先读取 `WarRelationRules.canTarget`；招抚候选仍走外交规则，不用战术敌我关系过滤。
- 当前不交割 hex / region controller，不转换部队，不让 `pacificationTargets` 自动纳土、停战或改变控制权。

仍保留的风险：

- `DiplomacyState` 与 `TurnOrderState.relations` 已有保守同步桥，但仍是 legacy `.allies/.germany` power 级聚合，不能表达吴越等单国 tactical neutral。
- v5.6f 只是把 power 级关系前移到候选层，不能替代国家级部队归属、单国停战、纳土交割或治理政策。
- `VictoryRules` 已有唐宋 JSON `victoryConditions` 读取首轮，并能只读展示 objective 控制、回合门槛和天命阈值进度；评价等级、治理评分、单国胜负和完整统一结算仍需继续设计。
- v5.6h/v5.6i 只补胜负原因和目标进度展示，不是完整胜利面板、结算页或每回合战报系统。
- v5.4 的 `mandateIntent`、`courtPolicy` 和 `supplyPriorities` 仍是解释字段；v5.6c 只把 `pacificationTargets` 桥接为规则校验的招抚提议，且目标仍限于可从首府 region 反查的外国国家。
- 当前唐宋政权仍桥接到 legacy `.allies/.germany`，不能宣称吴越等单国已经实现 tactical neutral 或独立战争关系。
- 当前 UI 只能从首府 region 推断目标国家，不能从吴越其他州府推断吴越。

建议下一轮并发切片：

- Core/Rules 单一 owner：继续设计 `GovernancePolicy`、完整胜利评分/统一结算和单国归附后的控制权/部队处理方案。
- Data/AI 只读 owner：审计 `DiplomacyState` 与 `TurnOrderState.relations` 同步方案，规定 `mandateIntent`、`courtPolicy` 和 `supplyPriorities` 后续是否需要落到规则命令。
- UI owner：等规则状态确定后，只读展示归附记录、天命/国威和治理政策，不写 `GameState`。

### 8.2 v5.7 当前状态与后续风险

v5.7 可玩闭环已从最小首屏提示切入。当前 v5.7a/v5.7b/v5.7c/v5.7d/v5.7e/v5.7f/v5.7g/v5.7h 已完成：

- HUD 在唐宋场景下显示“下一步”提示，帮助新玩家发现选军、围城、招降、招抚、解围、修城、结束回合和查看战报等既有入口。
- 提示由 `RootGameView.nextActionHint` 只读派生，优先判断胜负、观战、当前是否允许玩家下令、是否选中己方可行动军队，以及当前选区是否存在围城/招抚/解围/修城候选。
- 该提示不进入 `CommandValidator`，也不替代命令按钮的真实合法性；玩家实际行动仍由既有按钮提交底层 `Command` 后交给 `RuleEngine`。
- HUD 在唐宋场景下显示主要统一目标锚点，把关键州府拆成“已据”和“待取”，让玩家能把统一进度数字对应到开封、洛阳、太原、金陵、成都、杭州等地图目标。
- 目标锚点复用 `VictoryRules.objectiveProgress(in:)` 和 `MapState.controllerOfObjective(named:)`，不新增胜利条件或地图高亮权威。
- 目标锚点按钮可聚焦目标州府：`AppContainer.focusObjective(id:)` 只更新选中 hex / region，复用已有地图选中高亮和 Region inspector，不提交命令。
- 地图目标 spotlight 从同一主要统一目标只读派生，标出已据和待取州府；`focusedObjectiveId` 只影响地图强调显示，不进入规则层。
- 战报面板从现有规则日志、最近 AI 军议和方面军令记录只读汇总本回合或最近回合摘要，不新增事件源，不改 `RuleEngine` 或 `GameState.eventLog`。
- HUD 只读显示当前指挥身份与亲征/观战模式；唐宋“重开剧本”入口增加确认后再调用既有 `resetGame()`。
- 下一步提示会读取既有移动/攻击高亮数量，让选中可行动宋军后的提示更贴近当前地图可点项。
- 唐宋主界面可切换当前亲征 legacy 阵营，并与观战模式并列；唐宋 turn order 初始化读取场景 JSON 的 `playerFaction` / `aiFaction`，切换后同步 `playerFaction`、`TurnOrderState.playerControlledPowerIds` 和 legacy profile controlMode，清空当前选中/高亮并让 AI 按当前回合继续推进。

仍保留的风险：

- v5.7a 是 broad guidance，不是逐命令 legality 教程；少数情况下提示可能比 `CommandValidator` 更宽泛。
- v5.7d 是只读 spotlight 和当前目标强调，不是自动镜头移动、路线指引或持续目标追踪系统。
- v5.7e 是展示层摘要，不是完整结算页、评分系统或教程任务链；历史 AI 高层摘要仍只保留最近一条 `AgentDecisionRecord`。
- v5.7f 是新局与身份口径包装；v5.7h 只补上 legacy 两阵营亲征入口，不是完整吴越/南唐/后蜀等多政权选择器、AI-only 配置页或存档槽。
- v5.7g 只读使用已有 highlights 数量，不是完整 legality 教程，也没有新增 `CommandValidator` dry-run 面板。
- v5.7h 同步的是运行时 UI/turn order 状态，不新增 `GameState` schema，不替代后续数据驱动多政权系统。
- 未做截图、iPhone/iPad 横竖屏布局验收或 VoiceOver 验收，HUD 空间压力仍需后续 UI 验证。
- 尚未实现完整多政权势力选择、持久化配置、结算页/评分、截图验收或持久化存档。

建议下一轮并发切片：

- UI owner：可继续做镜头/缩放辅助或小屏布局优化，继续保持只读定位，不改规则。
- Rules/UI owner：若要做精确合法性提示，应通过 `CommandValidator` 对候选命令做 dry-run 校验，不让提示自行复制规则。
- Docs/QA owner：补截图/布局验收计划、玩家可见残留扫描和 v5.7 playability checklist。

## 9. 后续阶段文档建议

唐宋迁移进入实现后，建议按版本追加这些文件，避免把所有记录堆进总提示词：

```text
md/prompt/v5.0-唐宋迁移/
├── codex-v5.0-唐宋aiagent历史策略迁移总提示词.md
├── v5.0_audit_and_contract.md              # 已创建：当前二战残留审计与 v5.1 合同
├── v5.1_powers_turn_order_record.md        # 已创建：Power/TurnOrder/Relation 兼容地基
├── v5.2_scenario_mapeditor_record.md       # 已创建：唐宋默认剧本数据、MapEditor 资源桥与术语迁移
├── v5.3_rules_siege_grain_record.md        # 已创建：生产/府库、兵种战斗、粮道供给、围城城防、修城、解围和招降首轮
├── v5.4_agent_schema_record.md
├── v5.5_ui_visual_record.md              # 已创建：默认唐宋主界面术语桥和视觉 token 首轮
├── v5.6a_diplomacy_mandate_contract_record.md # 已创建：外交归附与天命规则合同首轮
├── v5.6b_player_submission_diplomacy_panel_record.md # 已创建：玩家招抚入口与外交面板只读首轮
├── v5.6c_ai_pacification_submission_record.md # 已创建：AI 招抚候选到规则命令安全桥首轮
├── v5.6d_tangsong_victory_mandate_record.md # 已创建：唐宋天命/国威胜利评价桥首轮
├── v5.6e_diplomacy_turn_order_projection_record.md # 已创建：外交关系到 power 战争关系保守投影首轮
├── v5.6f_relation_aware_war_candidates_record.md # 已创建：战术候选关系感知首轮
├── v5.6g_data_driven_victory_conditions_record.md # 已创建：数据驱动唐宋胜利条件首轮
├── v5.6h_victory_reason_battle_report_record.md # 已创建：胜负原因显示和战报只读摘要首轮
├── v5.6i_victory_objective_progress_record.md # 已创建：胜利目标进度只读显示首轮
├── v5.6_diplomacy_mandate_record.md
├── v5.7a_next_action_hint_record.md # 已创建：首屏下一步只读提示首轮
├── v5.7b_objective_anchor_record.md # 已创建：首屏统一目标锚点首轮
├── v5.7c_objective_focus_record.md # 已创建：目标锚点定位首轮
├── v5.7d_objective_spotlight_record.md # 已创建：目标州府地图 spotlight 首轮
├── v5.7e_turn_report_summary_record.md # 已创建：每回合战报摘要首轮
├── v5.7f_new_game_identity_observer_record.md # 已创建：新局确认与指挥身份/观战包装首轮
├── v5.7g_next_action_highlight_counts_record.md # 已创建：下一步提示读取移动/攻击高亮数量首轮
├── v5.7h_start_power_observer_entry_record.md # 已创建：亲征势力/观战轻量入口首轮
├── v5.7_playable_loop_record.md
├── v5.8_release_candidate_audit.md
└── v5.9_release_acceptance.md
```

每个阶段记录至少包含：

- 目标和非目标。
- 关键文件。
- 接口 / schema / public API 变化。
- 本地轻量检查命令和结果。
- 云端 workflow run / artifact 核对结果，如本轮执行了 main push。
- 未跑本机重测试的原因。
- 遗留风险和下一步。

## 10. 文档同步触发规则

出现以下变化时，需要更新对应 `md` 文件：

| 变化 | 必须同步的文档 |
|---|---|
| 默认数据、剧本、资源路径变化 | `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、阶段记录、`update_log.md` |
| 命令、规则、AI directive 管线变化 | `md/flow/*`、阶段记录、本文、`update_log.md` |
| 本地检查或云端 artifact 规则变化 | `md/test/test.md`、`AGENTS.md`、`md/prompt/README.md`、`update_log.md` |
| 唐宋迁移阶段状态变化 | 本文、对应 `md/prompt/v5.0-唐宋迁移/*.md`、`update_log.md` |
| 玩家可见 UI 术语或默认产品定位变化 | `README.md`、本文、`md/flow/*`、阶段记录 |
| GitHub Actions run / artifact 形成正式验收结论 | `update_log.md`、对应阶段记录；必要时 `md/test/test.md` |

原则：如果文档与源码冲突，以当前源码和真实检查结果为准；本轮结束时必须把冲突写清楚或修正文档。

## 11. 轻量检查入口

默认只做本地轻量检查，重验证交给 GitHub Actions。文档-only 大纲修改建议：

```sh
git diff --check
rg -n "[[:blank:]]+$" AGENTS.md README.md update_log.md md/test/test.md md/flow/flow.md md/flow/flowchart.md md/prompt/README.md md/plan/plan.md
rg -n "^(<<<<<<<|=======|>>>>>>>)" md README.md update_log.md AGENTS.md
```

若修改 workflow，再加：

```sh
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'
```

未获人工明确授权，不在本机运行 Xcode build/test、模拟器、Probe、Smoke、Stage Regression、Dynamic Theater Regression、Full 或性能测试。

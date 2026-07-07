# 山河一统 Agent — 唐宋迁移中的 iOS / macOS AI 战略战棋

> **当前状态：v5.7 可玩闭环的首屏“下一步”只读提示、统一目标锚点、目标锚点定位、地图目标高亮层、每回合战报摘要、新局/指挥身份包装、高亮数量行动提示、亲征势力/观战轻量入口、胜负后结算预览/评分估算、下一步有限合法性预校验、检查面板、将领面板和常驻军队 tooltip 唐宋读法补齐首轮已接入；v5.8a/v5.8b/v5.8n AI 面板默认主路径残留硬化、玩家态/开发态分层与原始文本兜底首轮已接入；v5.8c 外交面板默认主路径读法硬化首轮已接入；v5.8d 战报日志默认主路径读法硬化首轮已接入；此前 v5.6 唐宋外交、归附、天命规则/UI、战术候选关系感知、数据驱动胜利条件、胜负原因显示与胜利目标进度只读显示首轮已接入；此前 v5.3 唐宋生产/府库显示桥、古代兵种战斗修正、粮道供给/读法、围城城防、修城、解围、招降、地图围城 overlay 与 AI 围城/招降指令首轮，v5.4 AI 军议显示桥、模拟元帅 JSON 文案唐宋化和可选解释字段首轮。默认启动只加载 `jianlong_960_unification`（建隆元年：陈桥兵变与山河一统）唐宋 JSON，缺失时进入唐宋错误态并记录中文日志，不再静默回退阿登；MapEditor 默认读取/覆盖唐宋 960 资源；生产、府库和经济规则日志在唐宋路径下显示为军备、丁口、钱帛、粮草、禁军/厢军/骑军/攻城器械营；唐宋场景下骑军、弓弩守军、攻城器械营和守军已有最小战斗差异；受控高补给州府/粮仓、道路、山林和跨河成本已影响补给判定，单位详情可显示粮道通断、路径成本/上限、最近粮源和安全退路，地图可从同一摘要只读绘制友方可见军队到最近可见粮源的抽象粮道虚线；玩家可通过统一 `Command.besiege -> RuleEngine` 对敌方城池/关隘/粮仓州府登记围城压力并损耗城防，守方可通过 `Command.repairFortification -> RuleEngine` 消耗军队行动修城，也可通过 `Command.relieveSiege -> RuleEngine` 让州府内或近旁友军削减围城压力直至解围；围城压力达标、城防归零且守军不再 supplied 后，围城方可通过 `Command.demandSurrender -> RuleEngine` 招降目标州府，规则层会移除纳降守军、交割目标州府可占 hex，并刷新 region/theater/front/deploy；`ZoneDirective.attack -> WarCommandExecutor` 会在目标州府满足纳降条件时优先生成底层 `Command.demandSurrender`，否则在目标州府可围且无可攻击单位时生成底层 `Command.besiege`；地图从 `SiegeState` 只读绘制围城圈、压力和城防标签；唐宋场景下 AI 面板显示为“军议/方面军令”，战术名显示为进军、骑军突进、合围、弓弩压制、死守城关等，模拟元帅 raw JSON 的默认主事、strategicIntent、summary 和 rationale 也改用宋枢密院/割据行营与州府粮道口径；`TheaterDirectiveEnvelope` 新增可选 `mandateIntent`、`courtPolicy`、`pacificationTargets`、`supplyPriorities` 解释字段，唐宋 simulated marshal 会从首都、围城、粮道和外交候选摘要填充这些字段，`AgentDecisionRecord` 会保存只读军议解释摘要，`AgentPanelView` 在唐宋场景下结构化显示诏令、朝议、招抚、转运与摘要；v5.8a 起 `AgentPanelView` 的默认唐宋主路径会把 agent/provider/ruler/zone/region/order/posture fallback 显示为宋枢密院、割据行营、确定性军议、全局军令、州府和唐宋军令读法，`RootGameView` 传入运行态州府/防区名称查找；v5.8b 起 `AgentPanelView` 在唐宋场景下把 diagnostics、错误原文和 raw JSON 放入折叠调试区，玩家默认只看到军令执行/拒绝摘要、军议原文入口和“未命名州府/方面”兜底，不直接铺开英文诊断、内部 id 或 schema key；v5.8n 起 `AgentPanelView` 对唐宋军议摘要、诏令、朝议、战况、命令标题、diagnostics、errors 和 raw JSON 增加原始文本兜底，遇到 Latin、JSON 痕迹、schema key 或旧英文 fallback 时默认显示中文摘要或留存提示；v5.8o 起 `GeneralCommandPanelView` 与 `RegionInspectorView` 继续收口唐宋玩家态 ASCII 分隔符，地块坐标、目标/军队列表、围城城防、将领副标题和已拟军令摘要改用中文读法；v5.8p 起府库、HUD、战报、军队详情、将领档案、常驻 tooltip、棋子标记和地图围城/粮道标签继续收口兵力、粮道、城防、评分、回合与成本读法中的 ASCII 分隔符；v5.8q 起 `AppContainer` 常见交互反馈写入端改用唐宋文案，命令反馈、无可行动军队、围城/修城/解围/招降/招抚、将领军令、府库观战拒绝、选中军队和地块坐标不再默认写入英文或 raw id 摘要；v5.8r 起 HUD / EventLog / UnitInspector / Economy 继续收口胜利进度、天命进度、粮道近源坐标、军备资源分隔符和军议摘要 raw fallback；v5.8c 起 `DiplomacyPanelView` 在唐宋场景下把外交状态、集团、君主、国策、重点方面和归附州府 fallback 显示为唐宋读法，未知对象显示为未知政权、未命名集团、未命名州府或未命名方面；v5.8d 起 `EventLogView` 在唐宋场景下对战报正文与本回合摘要中的常见命令、选中、战斗、退却、补给、AI 执行和规则拒绝 raw 文案做只读显示桥，减少英文事件和 raw validation 暴露；`GameAgent.defaultCommander` 在唐宋场景下使用宋枢密院/割据行营作为默认 AI issuer，不再把默认唐宋主路径记录成 Guderian 或 Allied Mock Commander；`Command.proposeSubmission -> RuleEngine` 已能记录招抚、更新国家关系投影和天命分数，玩家命令面板已提供“招抚”入口，外交面板只读显示天命与归附记录；UI 攻击候选、攻击高亮、AI 敌强/敌区估算、`WarCommandExecutor` 敌军/敌控 region 和战术移动候选已改为读取 `WarRelationRules.canTarget`；唐宋 `VictoryRules` 优先读取场景 JSON 的 `victoryConditions`，按 objective id、count、turn 和 `mandateThreshold` 判定宋统一或割据生存，缺失数据时保留 v5.6d 硬编码 fallback；HUD 与战报面板会从 `VictoryState.reason` 只读显示“关键州府与天命达标”等胜负原因，并从同一胜利条件只读派生州府/天命/回合进度；HUD 会按当前回合、选中军队、围城/招抚/解围/修城候选和胜负状态只读显示“下一步”提示，并把主要统一目标拆成可点击的“已据/待取”关键州府锚点，点击后只更新 `selectedHex` / `selectedRegionId` 来聚焦目标州府；SpriteKit 地图会从同一主要统一目标只读绘制“已据/待取”州府 spotlight；战报面板会从已有 `eventLog`、最近 `AgentDecisionRecord` 和 `WarDirectiveRecord` 只读汇总本回合/最近回合摘要，并在胜负已定后从 `VictoryState` 与胜者自己的 `VictoryRules.objectiveProgress` 只读估算预览分和档位；HUD 会显示当前指挥身份和观战/亲征模式，唐宋“重开剧本”会先弹出确认再调用既有重置；下一步提示会读取既有移动/攻击高亮数量，并对当前 UI 候选的围城、招抚、解围、修城、招降、攻击和行军做有限 `CommandValidator` 预校验后提示可执行项；RootGameView 可在唐宋场景切换当前亲征 legacy 阵营和观战模式，AppContainer 同步 `playerFaction` 与 `TurnOrderState.playerControlledPowerIds`，不新增多政权 schema；军队详情、州府详情、将领军令、将领档案面板和右下角常驻军队 tooltip 在唐宋场景下补齐军队、政权、指挥、地块、州府、方面、防区、粮道、兵力、编成、产出、围城、用兵、朝廷关系、辖下军队、补给、退却和本回合行动等显示桥，并通过 `GameState.displayName(for:)` 读取当前政权名。底层 `TacticName` raw case、AI 决策记录 raw id、JSON schema 和执行权限保持兼容；除 v5.6c 的 `pacificationTargets -> TurnManager -> Command.proposeSubmission` 辅助桥外，新增解释字段不直接改规则结果。阿登数据保留为显式 legacy 资源和历史回归参考，不再作为默认启动 fallback。战争 AI 仍收口到 `ZoneDirective -> WarCommandExecutor -> RuleEngine`，AI 招抚辅助桥也只生成底层 `Command` 后交给 `RuleEngine`；Hex / Region / Theater / Front / Deploy 的权威边界不变。历史测试基线曾达到 v0.37 Probe 18/0、Stage Regression 69/0、Full 226/0；当前工作流按用户要求不跑本地测试，推送后由 GitHub Actions 云端重验证。**

> **v5.6c 状态补充：** AI 元帅 `pacificationTargets` 现在可由 `TurnManager` 在 `.endTurn` 前尝试生成辅助 `Command.proposeSubmission`，仍通过 `RuleEngine -> CommandValidator -> CommandExecutor` 决定成败，并把成功、规则拒绝或跳过写入 `AgentDecisionRecord.commandResults`。该桥不改 `TheaterDirectiveCompiler` 或 `WarCommandExecutor`，不交割控制权、不转换部队、不改全局战争关系。

> **v5.6d 状态补充：** 唐宋场景下 `VictoryRules` 已有首轮天命/国威胜利评价桥：宋控制开封、洛阳、太原、金陵、成都、杭州中的至少四处且天命不低于 60 时胜利；割据阵营若到最大回合仍控制太原、金陵、成都中的至少两处且天命不低于 35，则判定割据生存。阿登 legacy 胜利逻辑保持原样。

> **v5.6e 状态补充：** `Command.proposeSubmission` 成功写入国家外交关系后，会把 `DiplomacyState` 中跨 legacy faction 的国家关系保守投影回 `TurnOrderState.relations`：只要宋与割据阵营之间仍有任一国家关系是 hostile/atWar，`.allies/.germany` power 关系继续保持 `atWar`，避免吴越等单国归附导致全体割据势力提前不可攻击。

> **v5.6f 状态补充：** UI 与 AI 战术候选生成现在前置读取 `WarRelationRules.canTarget`：`AppContainer` 的点击攻击、攻击高亮和将领目标区推断，`WarCommandExecutor` 的敌强、敌区、可见敌军、围城与战术移动候选，`ZoneCommanderAgent` / `MarshalBattlefieldSummarizer` / `MockAICommander` 的敌情估算都不再只靠 `faction !=` 或 `Faction.opponent`。招抚和谈判候选仍保留外交规则口径，不用 `canTarget` 粗暴过滤。

> **v5.6g 状态补充：** 唐宋场景下 `VictoryRules` 已优先读取运行态 `GameState.victoryConditions`，这些条件由 `DataLoader` 从 `tangsong_jianlong_960_scenario.json` 加载；当前支持 `controlObjectives` / `holdObjectives`，按 objective id、`count`、`turn` / `turns` 和 `mandateThreshold` 判定 `majorVictory` / `survival`。若旧存档或场景缺少条件，仍回退到 v5.6d 的硬编码关键州府与天命阈值。

> **v5.6h 状态补充：** `VictoryReason` 新增唐宋显示桥，HUD 胜负栏和战报面板会从 `VictoryState.winner/reason` 派生显示胜负原因；战报面板的胜负摘要是只读派生展示，不写入 `eventLog`，也不改变 `VictoryRules` 判定语义。

> **v5.6i 状态补充：** `VictoryRules.objectiveProgress(in:)` 新增纯只读胜利目标进度快照，HUD 显示统一州府与天命进度，战报面板显示主要胜利条件的州府、天命和回合门槛。该展示只读取 `GameState.victoryConditions`、objective 所在 hex controller 和 `MandateState`，不调用会写状态的胜负更新逻辑，不写 `eventLog`。

> **v5.7a 状态补充：** HUD 顶部新增唐宋场景“下一步”只读提示，按当前胜负、观战、回合权限、选中军队和围城/招抚/解围/修城候选给出一句行动建议。该提示不调用 `RuleEngine`，不写 `GameState`，只帮助玩家发现既有命令入口。

> **v5.7b 状态补充：** HUD 顶部新增唐宋场景“目标”只读锚点，复用主要宋统一胜利条件，把关键州府显示为已据与待取，帮助玩家理解统一进度数字对应哪些州府。该锚点不新增胜利条件、不改地图高亮、不写 `GameState`。

> **v5.7c 状态补充：** HUD “目标”锚点变为可点击按钮，点击后通过 `AppContainer.focusObjective(id:)` 选中目标所在 hex / region，复用已有地图选中高亮与州府面板。该定位不提交 `Command`，不调用 `RuleEngine`，不改 `GameState`。

> **v5.7d 状态补充：** SpriteKit 地图新增唐宋统一目标 spotlight，只读标出主要宋统一目标的“已据 / 待取”州府。该层由 `MapDisplayAdapter.objectiveOverlays()` 从 `VictoryRules.objectiveProgress(in:)` 与 `MapState.objective` 派生，不新增目标、不提交命令、不改规则。

> **v5.7e 状态补充：** 战报面板新增唐宋“本回合战报 / 最近战报”摘要，只读汇总已有 `eventLog`、最近 AI 军议和方面军令记录，按战斗、州府、围城、粮道、外交、军议等类别计数并摘取关键消息。该摘要不补写日志、不新增事件源、不改规则。

> **v5.7f 状态补充：** HUD 新增唐宋当前“指挥 / 模式”短状态，显示宋可下令、宋待命、玩家亲征或只读观战；“重开剧本”按钮先弹出确认，再调用既有 `resetGame()` 重新载入建隆剧本。该切片不实现真实多势力选择、不改 `playerFaction`、不改变存档或规则。

> **v5.7g 状态补充：** HUD “下一步”提示读取既有 `movementHighlights` 与 `attackHighlights` 数量，在选中可行动宋军时说明当前有多少可行军格和可攻击目标。该提示不调用 `RuleEngine`，不提交命令，不替代按钮与 `CommandValidator` 的真实校验。

> **v5.7h 状态补充：** 唐宋主界面新增“亲征”分段选择，与既有“观战”入口并列；`DataLoader` 会读取场景 JSON 的 `playerFaction` / `aiFaction` 初始化 turn order，切换亲征势力会更新 `AppContainer.playerFaction`、同步 `TurnOrderState.playerControlledPowerIds` 和 legacy profile controlMode，并清空当前军队选择/高亮。该切片仍只覆盖 `.allies/.germany` legacy 桥，不新增吴越、南唐等真实多政权选择，不新增存档槽或规则 schema。

> **v5.7i 状态补充：** 战报面板在唐宋胜负已定后新增只读“评分估算”摘要，只匹配胜者自己的 `VictoryRules.objectiveProgress(in:)`，再结合 `VictoryState.winner/reason`、当前回合和天命门槛估算 0-100 分与短档位文案。该摘要不写 `VictoryState`、`GameState.eventLog` 或存档，不改变 `VictoryRules` 判定，也不是完整治理评分、单国胜负或正式结算页。

> **v5.7j 状态补充：** HUD “下一步”提示新增有限合法性预校验：`AppContainer.selectedValidatedCommandHint` 只读构造当前 UI 候选命令并调用 `CommandValidator.validate`，用于确认围城、招抚、解围、修城、招降、攻击和行军候选是否能执行。该提示不提交 `Command`，不写 `GameState` 或 `eventLog`，不改变 `CommandValidator` 语义，也不是通用 dry-run 系统或完整逐命令教程。

> **v5.7k 状态补充：** 唐宋检查面板读法补齐首轮：`UnitInspectorView` 在唐宋场景显示“军队详情 / 政权 / 指挥 / 地块 / 州府 / 动态方面 / 防区 / 粮道 / 兵力 / 退却口径 / 补给 / 编成”等字段，并把 ARM/MOT/INF/ART 读作禁军、骑军、厢军、器械；`RegionInspectorView` 显示“州府详情 / 地块控制 / 控制政权 / 城池 / 城级 / 关隘 / 粮草 / 工坊 / 产出 / 围城 / 己方军队 / 可见敌军”，产出读作丁口、钱帛、粮草，围城摘要不再在唐宋路径露出 `Germany/Allies` 或 `unit(s)`。该切片只改显示桥和面板参数，不改底层 Codable schema、规则、命令、地图控制或围城状态。

> **v5.7l 状态补充：** 唐宋将领面板读法补齐首轮：`GeneralCommandPanelView` 在唐宋场景显示“将领军令 / 方面防区 / 查看档案 / 所属军队 / 固守防线 / 进攻州府 / 已拟军令”等读法，`GeneralProfileView` 显示“将领档案 / 履历 / 用兵 / 所辖方面 / 朝廷关系 / 忠诚 / 军心 / 亲征干预 / 特长 / 辖下军队”，并通过 `GameState.displayName(for:)` 显示将领所属政权。该切片只补玩家可见显示桥，不改 `GeneralData`、`GeneralAssignment`、`FrontZone`、`PlayerPlannedOperation`、AI 决策或规则执行。

> **v5.7m 状态补充：** 唐宋常驻军队 tooltip 读法补齐首轮：`UnitTooltipView` 接收 `isTangSongScenario`，右下角选中军队摘要在唐宋场景显示“兵种 / 兵力 / 补给 / 退却 / 本回合”，并把 ART/ARM/MOT/INF 显示为器械、禁军、骑军、厢军，把 Supplied/Low/Encircled 显示为有粮、缺粮、被围，把 Retreatable/Hold 显示为可退、固守；accessibility label 也同步为唐宋读法。该切片只补常驻提示显示桥，不改 `Division`、`SupplyState`、`RetreatMode` schema 或任何规则。

> **v5.8a 状态补充：** 唐宋 AI 面板默认主路径残留硬化首轮：`AgentPanelView` 在唐宋场景下把 agent、provider、ruler、commander、global zone、legacy order type、ruler posture、target region fallback 读作宋枢密院、割据行营、确定性军议、全局军令、行军/进攻/固守/整补、进取/维系诸国等显示名；`RootGameView` 向面板传入运行态州府和防区名称查找。该切片只改显示桥，不改变 `AgentDecisionRecord`、`WarDirectiveRecord`、`TheaterDirectiveEnvelope`、`Command`、`ZoneDirective`、`TheaterDirectiveCompiler`、`WarCommandExecutor`、`RuleEngine` 或 raw JSON schema；诊断文本、错误原文、raw JSON 调试区和外交/EventLog/MapEditor/README legacy 段落仍留后续 RC 审计。

> **v5.8b 状态补充：** 唐宋 AI 面板玩家态/开发态分层首轮：`AgentPanelView` 在唐宋场景下优先显示军议摘要和命令执行状态，diagnostics、错误原文和 raw JSON 改为折叠调试区，默认不铺开英文诊断、内部 id 或 schema key；命令结果行显示“已执行 / 规则拒绝 / 映射失败”等摘要，找不到州府/防区名时显示“未命名州府 / 未命名方面”。该切片只改 UI 展示层，不改变 AI 记录、raw JSON schema、编译器、执行器、规则或日志记录职责。

> **v5.8c 状态补充：** 唐宋外交面板默认主路径读法硬化首轮：`DiplomacyPanelView` 在唐宋场景下把国家副标题、外交关系、归附结果、君主主事、国策、重点方面和归附州府详情显示为唐宋读法，关系状态显示为盟好、称臣、协战、中立、敌对、交战、归附中或议和，未知国家/集团/州府/方面使用本地化 fallback。该切片只改只读显示桥，不改变 `DiplomacyState`、`MandateState`、`Command.proposeSubmission`、关系投影、天命规则、战术敌我或任何控制权。

> **v5.8d 状态补充：** 唐宋战报日志默认主路径读法硬化首轮：`EventLogView` 在唐宋场景下让战报列表正文和“本回合战报/最近战报”摘要 highlight 统一经过显示桥，把常见英文交互拒绝、选中军队/州府、命令接受/驳回、validation rawValue、移动、战斗、退却、补给和 AI 执行摘要转为唐宋读法。该切片只改 UI 展示层，不改变 `GameLogEntry.message`、`CommandResult`、`CommandValidator`、`CommandExecutor`、`RuleEngine`、事件写入职责或 Codable schema。

> **v5.5 前序小切片：** 默认唐宋主界面的 HUD、图层、观战、面板 tabs、军令按钮和战报分类已加入唐宋场景显示桥，显示为回合、政权、阶段、胜负、地块、州府、方面、军队、将领、战报、府库、军议、固守、整补、围城和粮道等读法；SpriteKit 地图新增唐宋视觉 token，唐宋场景使用墨绿底、绢帛/青绿/石青/铜/朱印色系、赭石道路、石青河流、朱印/青绿势力色，棋子从 NATO 符号切为内置军旗轮廓和禁/骑/弩/械/守/军兵种字标，并从 `SupplyRules.supplyRouteSummary` 只读绘制友方可见军队到最近可见粮源的抽象粮道虚线。该切片只改玩家可见术语与视觉读法，不改变底层 raw case、命令、日志结构、补给判定或规则执行；完整截图、布局验收、外部美术资产和授权清单仍待后续。

> **v5.6a 前序小切片：** 新增外交归附与天命规则合同首轮。`DiplomacyState` 支持 `tributary`、`submitting`、`negotiating` 并保存 `PacificationRecord`；`GameState` 新增向后兼容的 `MandateState`；唐宋默认剧本初始化宋/割据天命分数；`Command.proposeSubmission -> CommandValidator -> CommandExecutor -> RuleEngine` 可在满足国家关系、天命、目标州府、低 warSupport 或围城压力条件后，把目标国家关系写为 `submitting`、记录招抚并增加天命。该切片不交割 hex/region 控制权，不转换部队，不改变 `.allies/.germany` 全局战争关系，也不把 AI `pacificationTargets` 自动执行为归附命令。

> **v5.6b 前序小切片：** 玩家命令面板新增“招抚”按钮，只提交 `Command.proposeSubmission -> RuleEngine`，目标优先取当前选中外国首府，若未选中合法首府则自动扫描当前可招抚首府；开局理论上可对低 warSupport 的吴越发起归附提议。外交面板只读显示天命分数和最近归附记录，并在唐宋场景下显示为外交、天命、诸国、集团、关系和归附记录。该切片仍不交割 hex/region 控制权、不转换部队、不改全局战争关系，也不让天命影响胜利。

> **v5.6c 前序小切片：** AI 元帅 envelope 的 `pacificationTargets` 进入安全编译桥：`TurnManager` 在战争 `ZoneDirective` 执行后、`.endTurn` 前，把合法首府候选尝试生成辅助 `Command.proposeSubmission`，仍通过 `RuleEngine -> CommandValidator -> CommandExecutor` 决定成败，并把成功、规则拒绝或跳过记录进 `AgentDecisionRecord.commandResults`。每个 AI 回合最多 1 个成功招抚提议；该切片不改 `TheaterDirectiveCompiler`、不让 `WarCommandExecutor` 承担外交语义、不交割控制权、不转换部队、不改 `TurnOrderState.relations`。

> **v5.6d 前序小切片：** `VictoryRules.updateVictoryState` 在唐宋场景先走唐宋专用判定，不再套用 Bastogne / St. Vith legacy 条件；宋统一胜利同时要求关键州府控制与天命阈值，割据生存胜利同时要求核心都城保有与割据天命阈值。该切片不新增治理政策、不改变 `MandateState` 调整来源、不改 UI 胜利面板结构，也不做归附后的控制权或部队交割。

> **v5.8i 小切片：** 唐宋默认主路径的命令反馈与战报元数据继续硬化：`CommandValidationError` 增加唐宋中文显示名，`RuleEngine` 唐宋拒绝原因不再拼 raw validation key；AI 回合、将领方面军令、选中州府日志和命令面板反馈改为唐宋文案；`EventLogView` 唐宋 metadata 不再展示内部 `relatedRecordId`。该切片只改玩家可见反馈/日志显示桥，不改变 `CommandValidationError` raw case、`CommandResult` schema、AI 决策、命令执行或规则判定。

> **v5.8j 小切片：** 唐宋检查面板 raw id 与目标状态继续硬化：`MapDisplayAdapter` 为 `UnitInspectorStrategicState` / `RegionInspectorState` 补州府、动态方面、防区和粮源显示名，`RegionInspectorView` 与 `UnitInspectorView` 在唐宋场景优先显示运行态名称，缺名时显示“未知州府 / 未命名方面 / 未命名防区”；军队详情的战线摘要改为“相关战线 N 条”，粮道来源不再直接展示补给源 raw id；州府详情目标状态改为“无目标 / 某政权控制”。该切片只改 UI 派生显示，不改变 `RegionId`、`TheaterId`、`FrontZoneId`、`FrontLineId`、补给规则、目标控制或任何命令执行语义。

> **v5.8k 小切片：** 唐宋命令面板与战报 raw 英文兜底继续硬化：`CommandPanelView` 的唐宋命令反馈复用 `TangSongEventLogMessage` 显示桥，`EventLogView` 补退却路线、被围损耗、玩家方面军令诊断、州府归属和动态方面变更等常见英文事件映射；若唐宋显示桥处理后仍含拉丁字母，默认降级为中文“战报已更新”提示，不再把 raw 英文/内部 key 直接展示给玩家；HUD 已行动提示中的 `AI` 改为“各方军议”。该切片只改玩家可见 UI 兜底，不改变 `GameLogEntry.message`、事件写入端、命令执行、AI 决策、规则判定或 Codable schema。

> **v5.8l 小切片：** 唐宋将领计划摘要与固定英文 UI 继续硬化：`GeneralCommandPanelView` 的“已拟军令”在唐宋路径通过运行态州府/方面名称显示目标，缺名时显示“未命名州府 / 未命名方面”，不再默认展示 `targetRegionId/sourceRegionId/zoneId.rawValue`；`BoardScene` 空棋盘标题改为“舆图加载中”，macOS 菜单改为“军务 / 结束回合 / 重新开局”，`InfoPanelToggle` 固定 `[ INFO ]` 改为“详情”并补中文 accessibility label。该切片只改玩家可见 UI 文案和显示桥，不改变 `PlayerPlannedOperation`、将领命令、地图渲染状态、macOS app 生命周期、规则或存档 schema。

> **v5.8m 小切片：** 唐宋外交面板 Latin 名称与 ASCII 连接符继续硬化：`DiplomacyPanelView` 在唐宋路径对国家名和集团名增加 `CountryId` / `DiplomaticBlocId` 显示映射与 Latin guard，旧存档或 fallback 数据中的 `German Reich`、`United States`、`Axis`、`Allied Coalition` 等不再默认直出；外交关系行改为“甲 与 乙”，归附记录改为“甲 招抚 乙”，国家副标题使用“·”，归附州府和君主目标列表使用“、”。该切片只改外交面板只读显示桥，不改变 `DiplomacyState`、`PacificationRecord`、外交关系投影、命令、规则或 Codable schema。

> **v5.8n 小切片：** 唐宋 AI 面板原始文本兜底继续硬化：`AgentPanelView` 在唐宋路径对军议摘要、诏令、朝议、战况、命令标题、诊断、错误和 raw JSON 增加玩家态中文兜底；遇到 Latin、JSON 痕迹、schema key、raw id 或旧英文 fallback 时，不在默认玩家态直出原文，改为军议摘要、诏令朝议、战况汇总或详文留存提示。该切片只改 AI 面板只读显示桥，不改变 `AgentDecisionRecord`、`WarDirectiveRecord`、`TheaterDirectiveEnvelope`、raw JSON 存储、命令、规则或 Codable schema。

> **v5.8o 小切片：** 唐宋固定英文 / ASCII UI 继续硬化：`GeneralCommandPanelView` 的将领副标题和已拟军令摘要改用“·”与“：”，`RegionInspectorView` 的地块坐标、目标/军队列表和围城城防改用中文读法与“、”“／”。该切片只改将领面板与州府详情面板的玩家可见显示桥，不改变 `PlayerPlannedOperation`、`RegionInspectorState`、围城规则、命令、AI 决策、事件写入或 Codable schema，也不等于完成 VoiceOver、截图或发布级布局验收。

> **v5.8p 小切片：** 唐宋兵力、粮道与数值标记 ASCII UI 继续硬化：`EconomyPanelView` 的军备成本行改用中文逗号读法，`HUDView` 回合进度、`EventLogView` 评分/metadata/方面军议摘要、`UnitInspectorView` / `UnitTooltipView` / `GeneralProfileView` / `UnitNode` / `MapDisplayAdapter` 在唐宋路径把兵力、粮道成本、围城城防、地图粮道标签和评分回合中的 ASCII `/`、`|`、` - ` 或 ` / ` 改为“／”、中文分号、中文逗号或“：”，军队详情地块坐标改为中文列/行读法。该切片只改玩家可见显示桥和地图标签，不改变 `Division`、`SupplyRouteSummary`、`SiegeOverlayState`、生产、补给、围城、命令、规则、AI 决策或 Codable schema。

> **v5.8q 小切片：** 唐宋 `AppContainer` 源头反馈中文化首轮：`submit(_:)` 的 `lastCommandMessage` 与交互日志在唐宋路径改用动作级中文摘要和中文标点，常见无可行动军队、围城/修城/解围/招降/招抚、将领军令、府库观战拒绝、选中军队与地块坐标反馈从写入端分流为唐宋文案。该切片只改 AppContainer 反馈写入与 legacy fallback，不改变 `Command`、`CommandResult`、`GameLogEntry`、`RuleEngine`、`CommandValidator`、`WarCommandExecutor`、AI 决策或 Codable schema。

> **v5.8r 小切片：** 唐宋胜利进度、粮道坐标与军议摘要继续硬化：`VictoryObjectiveProgress.summary`、HUD 统一/天命进度和战报评分估算改用“／”，`EconomyResources.summary` 唐宋路径改用“、”，军队详情粮道近源坐标和旧日志地块坐标改用中文列/行读法，战报本回合军议摘要遇到 Latin、JSON 痕迹或 raw key 时降级为中文摘要。该切片只改主游戏玩家可见显示桥，不改变胜利规则、经济规则、补给规则、AI 决策记录、事件 schema 或 Codable raw 值。

> **v5.8s 小切片：** MapEditor 玩家/编辑器可见 raw 技术词继续硬化：资源区按钮和状态栏不再默认显示“JSON”或 `.json` 文件名，默认资源说明改为“建隆元年剧本 / 州府数据”，信息面板、状态栏和导出错误中的地块坐标改用“第 q 列，第 r 行”，底图区只显示底图文件名，导出校验错误不再直出州府 raw id、地形 rawValue 或底层英文编码错误，自动州城/粮仓 fallback 改用中文读法。该切片只改 MapEditor 显示桥和错误包装，不改变导出的 JSON schema、`Faction.allies/germany`、`GamePhase.alliedPlayer`、`RegionId`、`TheaterId` 或主游戏规则。

> **v5.8t 小切片：** accessibility / VoiceOver 可读文案硬化首轮：主游戏信息面板按钮和通用详情按钮补充展开/收起状态与提示，棋盘 accessibility value 显示当前选中地块/州府，唐宋将领档案头像占位不再被读屏朗读，MapEditor 底图偏移输入框和地图编辑画布补中文可访问名称/提示。该切片只改 SwiftUI 可读语义和文案，不改变地图交互、focus order、布局、hit target、规则、导出 JSON schema 或任何 Codable raw 值；完整 VoiceOver 实机验收、截图验收、iPhone/iPad 横竖屏布局和发布级 UI 验收仍未完成。

> **v5.8u 小切片：** accessibility 控件状态提示继续硬化：军令按钮补可用/停用值和停用原因提示，府库军备按钮把费用与观战/阶段/资源不足原因绑定到读屏提示，亲征选择与观战切换说明会影响指挥权限，统一目标锚点按钮补“查看目标”和地图聚焦提示。该切片只改 SwiftUI 控件可读语义，不改变命令、经济、胜利、地图聚焦逻辑、focus order、hit target、规则或 Codable schema；完整 VoiceOver 实机验收、截图验收、横竖屏布局和发布级 UI 验收仍未完成。

> **v5.8v 小切片：** MapEditor 错误与输入可访问性继续硬化：读取/覆盖默认资源和资源预览失败时不再把 raw `Error`、系统路径或底层解码描述直接显示给玩家/读屏，已知导出/资源桥错误继续保留中文说明；新建州府、方面和军队名称改为空输入加自动命名 fallback，不再把示例文字误写成真实名称；MapEditor 新建/编辑输入框和错误区补上下文 accessibility label/hint。该切片只改 MapEditor 显示、输入默认值和 SwiftUI 可读语义，不改变导出 JSON schema、资源桥路径、`Faction.allies/germany`、`RegionId`、`TheaterId`、主游戏规则或 Codable raw 值；完整 VoiceOver 实机验收、截图验收、横竖屏布局和发布级 UI 验收仍未完成。

> **v5.8w 小切片：** 主棋盘 VoiceOver 自定义动作继续硬化：`RootGameView` 的 `BoardSceneView` 包装层新增“攻击下一处红色目标”“行军到下一处高亮地块”和“打开信息面板”读屏动作，读屏 value 补充选中地块、州府、控制政权、当前已选军队以及高亮攻击/行军数量；动作只复用既有 `AppContainer.handleBoardTap(_:)` 点击链路，真实命令仍由 `CommandValidator` / `RuleEngine` 判定。该切片不改变 SpriteKit 渲染、地图命中测试、规则、命令、JSON schema 或 legacy `Faction` 桥；完整逐 hex focus tree、VoiceOver 实机、截图和布局验收仍未完成。

> **v5.8x 小切片：** 面板控件 accessibility 与 fallback 继续硬化：地图图层选择器和紧凑信息面板分页补当前值与用途提示；将领档案入口、固守防线和进攻州府按钮补可用/停用状态与停用原因；外交/军议面板在唐宋路径下缺少州府或方面名称时改用“未知州府 / 未命名方面”，不再回退显示 raw id。该切片只改 SwiftUI 可读语义和缺名兜底，不改变棋盘 custom actions、命令、规则、外交/AI 记录、JSON schema 或 legacy `Faction` 桥；完整 VoiceOver 实机、截图和布局验收仍未完成。

> **v5.8y 最新小切片：** tooltip 与检查面板读法继续硬化：常驻军队 tooltip 的读屏 value 补充兵力、补给、退却和本回合状态；军队检查面板收口英文 `FrontZone` / `FrontLine` / `Deploy` 标签与 `FRONT` / `DEPTH` / `GARRISON` 部署码，唐宋编成比例改为“占 N／100”；州府检查面板收口英文 `FrontZone`、`MP/IC/SUP` 资源缩写，并把唐宋围城摘要改成攻方/守方/压力/城防/围城军队口径。该切片只改 tooltip 和检查面板显示/读屏语义，不改变 `Division`、`ComponentType`、`RegionInspectorState`、围城规则、补给规则、命令、AI 决策或 Codable schema；完整 VoiceOver 实机、截图和布局验收仍未完成。

---

## 项目定位

一款 iOS / macOS 回合制历史策略游戏，当前主线是 `jianlong_960_unification`（建隆元年：陈桥兵变与山河一统）。仓库名和部分底层类型仍沿用 `WWIIHexV0` legacy 工程名，但默认产品目标是唐宋时代 AI Agent 历史策略游戏：六角格战棋操作、州府/粮道/方面大战略、将领与朝廷 AI 军议共同驱动。

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
统治者 agent 不在 v0.5 当前主链路中。v5.6a 已先建立 `MandateState`、`PacificationRecord` 和 `Command.proposeSubmission` 规则合同，v5.6b 补玩家“招抚”入口与外交面板只读展示，v5.6c 补 AI `pacificationTargets -> Command.proposeSubmission` 安全桥，v5.6d 让唐宋 `VictoryRules` 同时读取关键州府控制与天命阈值，v5.6e 将国家级外交关系保守投影回 `TurnOrderState.relations` 的 legacy power 关系，v5.6g 让唐宋胜利评价优先读取场景 JSON `victoryConditions`；战术敌我仍由 legacy `Faction.germany` / `Faction.allies` 与 `TurnOrderState.relations` 决定。后续如要加入统治者 agent、单国 tactical neutral、完整纳土或治理政策，仍必须保持底层战争规则收口到 `Command` / `ZoneDirective`、`WarCommandExecutor` 和 `RuleEngine`。

---

## 当前完成进度

当前主线是唐宋 v5.x 迁移，不再以阿登 v0.x 原型作为默认产品叙述。v0.x 内容保留为工程地基和 legacy fallback。

### 唐宋 v5.x 主线

| 版本 | 状态 | 当前事实 |
|---|---|---|
| v5.0 | 已建档 | 唐宋迁移总提示词、审计合同、首发 960 剧本目标、架构边界和禁止项已建立。 |
| v5.1 | 已完成首轮 | `PowerId` / `PowerProfile` / `PowerRelation` / `TurnOrderState` / `WarRelationRules` 兼容地基已接入。 |
| v5.2 | 已完成首轮 | 默认数据优先加载 `jianlong_960_unification`；唐宋场景、州府/方面、单位模板、人物 JSON 与 MapEditor 默认资源桥已接入。 |
| v5.3 | 已完成多轮首轮闭环 | 唐宋生产/府库显示桥、古代兵种战斗修正、粮道供给/读法、围城城防、修城、解围、招降、地图围城 overlay 与 AI 围城/招降指令已接入。 |
| v5.4 | 已完成首轮 | AI 军议显示桥、simulated marshal 唐宋文案、`mandateIntent` / `courtPolicy` / `pacificationTargets` / `supplyPriorities` 解释字段与默认宋枢密院/割据行营 issuer 已接入。 |
| v5.5 | 已完成首轮 | HUD、图层、面板、战报、地图视觉 token、军旗棋子和只读粮道 overlay 已改为唐宋场景读法。 |
| v5.6 | 已完成多轮首轮闭环 | 外交归附、天命、玩家招抚、AI 招抚辅助桥、关系投影、战术候选关系感知、数据驱动胜利条件、胜负原因和目标进度只读显示已接入。 |
| v5.7 | 已完成多轮可玩性首轮 | 下一步提示、统一目标锚点/定位/spotlight、每回合战报摘要、新局确认、亲征/观战入口、结算预览、合法性提示、检查面板、将领面板和 tooltip 唐宋读法已接入。 |
| v5.8a-v5.8y | 进行中 | AI 面板、外交面板、战报日志、MapEditor 默认路径、README/plan/flow 文档定位、主游戏 DataLoader 默认启动 fallback、唐宋将领注册表默认路径、命令反馈/战报元数据、检查面板 raw id / 目标状态、命令/战报 raw 英文兜底、将领计划摘要、固定英文 UI、外交 Latin/ASCII 显示、AI 面板原始文本兜底、将领/州府面板 ASCII 显示、兵力/粮道/地图数值标记、AppContainer 源头交互反馈、胜利/粮道/军议摘要、MapEditor raw UI、accessibility / VoiceOver 可读文案、控件状态提示、MapEditor 错误/输入可访问性、主棋盘 VoiceOver 自定义动作、面板控件 accessibility/fallback、tooltip 与检查面板读法硬化已做默认主路径首轮。完整 RC 审计仍未完成。 |
| v5.9 | 未开始 | 可发布验收、完整 artifact 审计、README/flow/update_log 统一发布口径仍待后续。 |

### 当前仍未完成

- `Faction`、`ProductionKind`、`EconomyResources`、`Division`、`ComponentType` 等底层 Codable schema 仍保留 legacy 名称或二战兼容桥。
- 真实多政权数据驱动、完整吴越/南唐/后蜀等势力选择、持久化配置和存档槽仍未收口。
- 自动破城、完整外交纳土交割、完整漕运/粮队/仓储容量、治理政策、正式评分系统、完整统一结算页仍未落地。
- 完整皇帝/朝廷/枢密/节度使/转运使/州府守臣/外交使者 schema、真实多 Agent JSON 与真 LLM 接入仍待后续。
- 截图、iPhone/iPad 横竖屏布局、完整 VoiceOver 实机、资源授权和发布级 UI 验收仍未完成；当前验证以 GitHub Actions 云端 build/artifact 为准。

### 历史地基

v0.x 阿登原型提供了仍在使用的工程地基：hex 坐标、移动、战斗、占领、补给、包围、`Division` 兵力/撤退模型、Region 聚合层、Theater / FrontLine / WarDeployment 派生层、Agent D legacy 管线、`ZoneDirective` / `WarCommandExecutor` / `RuleEngine` 统一命令管线、MapEditor 和模拟 LLM JSON 接口。阿登数据、Guderian / Allied Mock Commander、Bastogne 等内容只作为显式 legacy 资源、历史测试夹具和回归参考，不是唐宋默认产品主线。

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
    │   唐宋 v5.0-v5.9 总提示词、v5.0 审计合同、v5.7a 下一步提示、v5.7b 目标锚点、v5.7c 目标定位、v5.7d 地图目标高亮、v5.7e 战报摘要、v5.7f 新局身份包装、v5.7g 高亮数量提示、v5.7h 亲征/观战入口、v5.7i 结算预览/评分估算、v5.7j 合法性提示、v5.7k 检查面板读法、v5.7l 将领面板读法、v5.7m 常驻 tooltip 读法、v5.8a AI 面板默认主路径硬化、v5.8b AI 面板玩家态/开发态分层、v5.8c 外交面板读法硬化、v5.8d 战报读法硬化、v5.8e MapEditor 默认路径硬化、v5.8f 文档定位收口、v5.8j 检查面板 raw id 硬化、v5.8k 命令/战报 raw 英文兜底硬化、v5.8l 将领计划和固定英文 UI 硬化、v5.8m 外交 Latin/ASCII 显示硬化、v5.8n AI 面板原始文本兜底、v5.8o 固定英文/ASCII UI 硬化、v5.8p 兵力粮道数值标记硬化、v5.8q AppContainer 源头反馈中文化、v5.8r 胜利粮道军议摘要硬化等阶段记录
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
- 当前主线是唐宋 v5.x 迁移，默认剧本为 `jianlong_960_unification`；v5.8r 已继续收口胜利/天命进度、粮道近源坐标、军备资源分隔符和战报军议摘要 fallback，等待本轮推送后的 GitHub Actions 云端验证。
- v0.5 元帅层与模拟 LLM JSON/decoder/compiler 是仍在使用的历史架构地基；历史测试基线曾达到 v0.37 Probe 18/0、Stage Regression 69/0、Full 226/0。当前按用户要求不在本机测试，推送后由 GitHub Actions 云端验证。
- 战斗模型：兵力伤害为主，`RetreatMode`（retreatable/hold）控制撤退，无 organization。
- 默认战争 AI 管线：`MarshalAgent` 读取摘要并模拟输出 `TheaterDirectiveEnvelope` JSON，经 `TheaterDirectiveDecoder` 与 `TheaterDirectiveCompiler` 降级成 `ZoneDirective`，再走 `WarCommandExecutor`。`TheaterCommanderPool` / `ZoneCommanderAgent` 仍作为 fallback 和显式 `.zoneDirective` 路径。
- Legacy Agent D 管线保留但默认不调用。
- 地图坐标系：hex 仍是战术权威；Region 是省份规则层；动态战区看 `hexToTheater`。

**继续开发前请先阅读：**
1. `AGENTS.md`、`update_log.md`、`md/test/test.md`、`md/plan/plan.md`
2. `md/flow/flow.md` / `md/flow/flowchart.md`
3. `md/prompt/v5.0-唐宋迁移/codex-v5.0-唐宋aiagent历史策略迁移总提示词.md`
4. `md/prompt/v5.0-唐宋迁移/` 下最新 v5.8 阶段记录和云端 artifact 记录
5. `WWIIHexV0/Core/Division.swift`、`MapState.swift`、`Region.swift`、`Theater.swift`
6. `WWIIHexV0/Rules/TheaterSystem.swift`、`FrontLineManager.swift`、`WarDeploymentManager.swift`
7. `WWIIHexV0/Commands/WarDirective.swift`、`WarCommandExecutor.swift`
8. `WWIIHexV0/Agents/ZoneCommanderAgent.swift`、`MockAICommander.swift`

**当前必须遵守：**
- 不删 `HexCoord`，不把运行时战区推进退回 region 粒度。
- `Initial Theater Layout` / `regionToTheater` 是地图编辑器与动态演化基准，不是实时前线。
- `Dynamic Theater State` / `hexToTheater` 是游戏战区层权威。
- 前线 UI 和 AI target 选择必须基于动态 hex 邻接；历史测试 fixture / 语义文档也必须构造真实相邻 hex，不能只声明 region 邻接。
- `ZoneDirective` 新字段必须保持 Codable 向后兼容。
- 元帅层和未来统治者层不得绕过 `ZoneDirective -> WarCommandExecutor -> RuleEngine`。
- 当前只模拟 LLM JSON 接口，不接真实模型；真实 LLM 接入必须保留 decoder 校验与 fallback。
- v0.x / 阿登 / Guderian / Bastogne 文档只能作为 legacy 参考，不再作为默认产品主线叙述。

## 协作与云端验证

当前协作制度固定使用 `main` 作为上传、提交、推送和云端验证分支。Agent B 本地只跑 `md/test/test.md` 允许的轻量检查，提交后直接 push 到 `origin/main` 触发 GitHub Actions；Agent C 通过 GitHub CLI 下载未加密 CI 结果包，核对 manifest、JUnit、构建日志和失败摘要后再验收。详细规则见 `AGENTS.md`、`md/test/test.md` 和 `md/prompt/README.md`。

**轻量检查**（每轮先读 [`md/test/test.md`](md/test/test.md)；若用户要求“不在本地测试”，则本机不跑检查，直接 push 后等云端 Actions）：
```bash
rg -n "[[:blank:]]+$" AGENTS.md README.md update_log.md md/test/test.md md/flow/flow.md
```
旧测试口径残留、JSON / project / scheme 检查按 `md/test/test.md` 追加执行。未获人工授权时，不跑历史 Probe / Stage / Full。

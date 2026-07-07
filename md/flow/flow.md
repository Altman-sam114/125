# 山河一统 Agent / 唐宋 v5.x 核心流程文档（main 当前主线）

> 本文是项目当前核心逻辑的接手文档。目标不是复述历史设计，而是按当前代码真实链路说明：数据如何进入游戏，hex / region / theater / front / deploy 如何派生，主游戏和地图编辑器如何共同维护同一套地图语义，AI / 玩家命令如何落到规则系统。

资料依据：`AGENTS.md`、`README.md`、`update_log.md`、`md/test/test.md`、`md/plan/plan.md`、`md/prompt/v5.0-唐宋迁移/` 阶段记录、当前 `origin/main` git / GitHub Actions artifact 口径，以及当前源码中的 `Core/`、`Rules/`、`Commands/`、`Agents/`、`Turn/`、`App/`、`SpriteKit/`、`UI/`、`MapEditor/`。v0.355/v0.36/v0.37 和 v0.5 文档只作历史架构与回归参考。

---

## 0. 一句话总览

当前主链路是：

```text
MapEditor / JSON 数据
  -> DataLoader
  -> GameState
  -> Hex controller / Division coord
  -> Region 聚合
  -> EconomyState 收入 / 生产 / 补员
  -> DiplomacyState / MandateState 外交归附记录与天命总账
  -> TurnOrderState / PowerProfile 回合与控制权桥
  -> Initial Theater snapshot + runtime hexToTheater
  -> FrontLine 动态 hex 接触
  -> WarDeployment hexToFrontZone + FRONT/DEPTH/GARRISON
  -> MarshalAgent / TheaterDirective JSON
  -> TheaterDirectiveDecoder
  -> TheaterDirectiveCompiler
  -> ZoneCommanderAgent fallback / 手写 ZoneDirective
  -> WarCommandExecutor
  -> RuleEngine
  -> CommandExecutor
  -> StrategicStateSynchronizer
  -> UI overlay / 日志 / WarDirectiveRecord
```

最关键的铁律：

- `HexTile.controller` 和 `Division.coord` 是战术层权威。
- `RegionNode.controller` 是从 region 内 hex controller 加权聚合出来的战略快照。
- `regionToTheater` 是初始/基础战区归属，不是运行时推进层。
- `hexToTheater` 是运行时动态战区权威。
- `hexToFrontZone` 是部署层动态归属权威。
- `EconomyState` 是 faction 级经济总账；收入来自受控 region、城市、工厂、基础设施和补给值，但战术占领仍以 hex 为准。
- `DiplomacyState` 是国家级外交投影，v5.6a 起保存 `PacificationRecord`；`MandateState` 是 faction 级天命/合法性总账。
- v5.1 新增 `TurnOrderState`，用于保存 power order、active power、控制模式和 power relations；`activeFaction` / `phase` 仍保留为 legacy 执行桥。
- 玩家、AI、后续聊天命令最终都必须经过 `Command` / `ZoneDirective -> WarCommandExecutor -> RuleEngine`，不能直接改 `GameState`。
- v0.5 默认战争 AI 上游是 `MarshalAgent -> TheaterDirective JSON -> TheaterDirectiveDecoder -> TheaterDirectiveCompiler`，下游执行收口到 `ZoneDirective -> WarCommandExecutor -> RuleEngine`。
- 统治者层只作为后续方向预留；当前 v0.5 主链路不调用 `RulerAgent`，也不写统治者决策记录。

---

## 1. 核心状态对象

### 1.1 GameState

源码：`WWIIHexV0/Core/GameState.swift`

`GameState` 是运行时总状态，主要字段：

```text
scenarioId
turn / maxTurns
activeFaction
phase
turnOrderState
map: MapState
theaterState: TheaterState
frontLineState: FrontLineState
warDeploymentState: WarDeploymentState
economyState: EconomyState
diplomacyState: DiplomacyState
mandateState: MandateState
siegeState: SiegeState
victoryConditions: [VictoryConditionDefinition]
divisions: [Division]
victoryState
eventLog
warDirectiveRecords
playerCommandState
```

状态含义：

- `map` 保存地图、hex、region、补给源和目标点。
- `divisions` 保存所有单位。单位当前位置在 `Division.coord`，不是 region 或 theater。
- `theaterState` 保存初始战区快照与运行时动态战区。
- `frontLineState` 从动态战区相邻 hex 派生。
- `warDeploymentState` 从动态战区/前线/单位位置派生，供 AI 调度单位。
- `economyState` 保存 manpower、industry、supplies、生产队列、上回合收入/维护费/补员消耗，不直接改变战术占领权。
- `diplomacyState` 保存国家、集团、国家间关系、统治者记录和 v5.6a 的 `PacificationRecord`；它是外交/AI/UI 的国家级投影，不替代战术敌我判断。
- `mandateState` 保存 faction 级天命/合法性分数；v5.6a 起由 `Command.proposeSubmission` 调整，v5.6d 起参与唐宋专用胜利评价。
- `victoryConditions` 保存从场景 JSON 读取的胜利条件；v5.6g 起唐宋 `VictoryRules` 优先按 objective id、count、turn 和 `mandateThreshold` 读取这些条件。
- `siegeState` 保存围城压力、城防和围城军队记录。
- `turnOrderState` 保存 `PowerId` / `PowerProfile` / `PowerRelation` / power order。旧状态缺失时由 `TurnOrderState.legacy(...)` 从 `activeFaction`、`phase` 和当前 turn 派生。
- `eventLog` 给 UI 和调试看。
- `warDirectiveRecords` 记录战争指令执行回放，供 v0.36+ 后续接 LLM / 聊天命令审计。

### 1.2 MapState / Hex

源码：`WWIIHexV0/Core/MapState.swift`、`WWIIHexV0/Core/Terrain.swift`

`MapState` 的底层是 hex：

```text
width / height
tiles: [HexCoord: HexTile]
supplySources: [SupplySource]
objectives: [Objective]
regions: [RegionId: RegionNode]
hexToRegion: [HexCoord: RegionId]
regionEdges: Set<RegionEdge>
```

`HexTile` 关键字段：

```text
coord
baseTerrain
hasRoad
riverEdges
controller: Faction?
cityName / fortressName
isPassable
regionId: RegionId?
```

当前语义：

- `HexCoord` 是 axial q/r 坐标，移动、攻击、距离、邻接都基于 hex。
- `HexTile.controller` 是真实占领权威；中立 hex 的 controller 为 `nil`。
- `HexTile.regionId` 是聚合标记，不参与寻路/战斗权威判断。
- `MapState.region(for:)` 优先读 `hexToRegion`，fallback 读 `tile.regionId`。
- `MapState.supplySources(for:)` 会通过 `controllingFaction(for:)` 判断补给源当前归属，优先看 supply hex 的 controller，再 fallback region controller，再 fallback 原始 supply faction。

### 1.3 Region

源码：`WWIIHexV0/Core/Region.swift`

`RegionNode` 是省份/区块规则层：

```text
id / name
owner
controller
terrain
neighbors
displayHexes
representativeHex
city
infrastructure / supplyValue / factories / resources
coreOf
occupationState
isPassable
```

当前语义：

- Region 是战略聚合层，不替代 hex。
- `displayHexes` 声明该 region 覆盖哪些 hex。
- `representativeHex` 是 UI 和某些 region->hex 转换的默认点。
- `neighbors` / `regionEdges` 是省份邻接图，但 v0.358 后不能单独拿它判断动态前线。前线必须看真实 hex 邻接。
- `RegionNode.controller` 不是直接推进权威。它由 `RegionOccupationRules.aggregateControl` 从 hex controller 加权派生。

### 1.4 Theater

源码：`WWIIHexV0/Core/Theater.swift`、`WWIIHexV0/Rules/TheaterSystem.swift`

`TheaterState` 关键字段：

```text
initialSnapshot: TheaterInitialSnapshot?
theaters: [TheaterId: TheaterNode]
hexToTheater: [HexCoord: TheaterId]
regionToTheater: [RegionId: TheaterId]
lastUpdatedTurn
```

`TheaterNode` 关键字段：

```text
id / name / status
regionIds
neighborTheaterIds
controllingFaction
controlRatios
victoryPointArea
frontWeight
unitIds
supportEligibleUnitIds
spilloverPolicy
recentThreats
```

当前语义必须分清三件事：

1. `initialSnapshot.regionToTheater`
   - 开局时捕获。
   - 只读初始战区布局。
   - UI 的 `initialTheater` 图层读取这里。
   - 地图编辑器导出的 region->theater assignment 会进入这里。

2. `regionToTheater`
   - 当前基础/初始战区单位。
   - 作为动态战区生成、合并、formalization、退役的参照。
   - 不代表运行时推进结果。
   - 不允许“占领一个 hex 后把整个 region 的 `regionToTheater` 改掉”。

3. `hexToTheater`
   - 运行时动态战区权威。
   - 单位突破进入某个 hex 后，只把这个 hex 改到进攻方动态战区。
   - 前线、动态战区图层、部署层都应以它为准。

`TheaterSystem.updateTheaters` 的派生刷新包括：

```text
seedMissingHexAssignments
  -> 给未填的 hexToTheater 填基础 regionToTheater
rebuildDynamicRegionMembership
  -> TheaterNode.regionIds 变为“该动态战区当前覆盖到的 region 集合”
rebuildNeighborTheaters
  -> 按 hexToTheater 的真实 hex 邻接生成战区邻接
assignUnits
  -> 按单位所在 hex 的 dynamicTheaterId 分配 theater.unitIds
calculateMetrics
  -> 按动态 theater 内 hex controller 计算 controlRatios / controllingFaction / frontWeight
```

`formalizationThreshold` 当前默认 0.70。它用于 formalized / provisional 状态判断，不阻止前线按单个 hex 推进。

### 1.5 FrontLine

源码：`WWIIHexV0/Core/FrontLine.swift`、`WWIIHexV0/Core/FrontSegment.swift`、`WWIIHexV0/Core/FrontLineState.swift`、`WWIIHexV0/Rules/FrontLineManager.swift`

`FrontLineState` 关键字段：

```text
frontLines: [FrontLineId: FrontLine]
regionStates: [RegionId: RegionFrontState]
enemyNeighborCache: [RegionId: [RegionId]]
dirtyRegionIds
diagnostics
```

`FrontLine`：

```text
id
theaterId
opposingTheaterIds
factionA / factionB
segments: [FrontSegment]
type: normal / breakthrough / encirclement
state: stable / pressured / collapsing 等
```

`FrontSegment`：

```text
regionA
regionB
edgeType
pressureLevel
supplyImpact
isEncirclementCandidate
```

当前前线生成逻辑：

```text
对每个 active theater:
  对 theater.regionIds 中的每个 region:
    只看该 region 内 dynamicTheaterId == theater.id 的 hex
    扫描这些 hex 的六向邻接 hex
    如果邻接 hex 属于另一个 dynamic theater
       且对方 theater 的 sourceFaction 不是 friendlyFaction:
         形成 enemy region 接触
         生成 FrontSegment(regionA: friendly region, regionB: enemy region)
```

重要结论：

- 前线不是 region 边界。
- 前线不是 initial theater 边界。
- 前线不是 `regionToTheater` 的邻接。
- 前线是真实动态战区 hex 接触。
- 同一个 region 被两个动态战区切开时，允许出现 `regionA == regionB` 的突破前线。这是 v0.358 后确认的合法状态。
- `FrontLine.type == .breakthrough` 的一个来源是：segment 的 `regionA` 仍由敌方 region controller 控制，但已有我方动态 theater hex 突入。

### 1.6 WarDeployment / FrontZone

源码：`WWIIHexV0/Core/WarDeploymentState.swift`、`WWIIHexV0/Core/FrontZone.swift`、`WWIIHexV0/Core/FrontZoneSegment.swift`、`WWIIHexV0/Rules/WarDeploymentManager.swift`

`WarDeploymentState` 关键字段：

```text
frontZones: [FrontZoneId: FrontZone]
hexToFrontZone: [HexCoord: FrontZoneId]
regionToFrontZone: [RegionId: FrontZoneId]
dirtyRegionIds
diagnostics
```

`FrontZone`：

```text
id / name
faction
regionIds
neighbors
frontSegments
unitsFront
unitsDepth
unitsGarrison
pressure
state
isCoreZone
```

当前部署层权威：

- `hexToFrontZone` 是动态部署归属权威。
- `regionToFrontZone` 是 dominant / fallback，不是突破推进权威。
- `FrontZoneId` 当前通常复用 `TheaterId.rawValue`。
- `WarDeploymentManager.advanceHex` 只推进一个 hex 的 zone 归属。
- `DeploymentLayer` / `UnitDeploymentRole` 当前落地为：
  - `frontUnit`
  - `depthUnit`
  - `garrisonUnit`

单位分配逻辑要点：

```text
每个 division:
  先按 division.coord 查 hexToFrontZone，fallback regionToFrontZone
  如果该 zone.faction == division.faction:
    使用该 zone
  否则如果所在 region 周边有己方 zone:
    分到相邻己方 zone
  否则 fallback 到该 faction 的 primary combat zone

  如果 hex 接触敌 zone
     或 assignedZoneId != 当前 hex zoneId
     或所在 hex controller != assignedZone.faction:
       unitsFront
  否则如果 zone.isCoreZone 或 region 有 city/factory/core:
       unitsGarrison
  否则:
       unitsDepth
```

这层是 AI 调度能否“看见部队”的关键。历史上的“AI 看起来不动”根因之一就是突破后的单位被误判成 garrison，从 `unitsFront` 调度池消失。现在前线/敌区/敌控 hex 会强制把这种单位归到 front。

### 1.7 后续统治者层预留与 v5.6 外交/天命入口

v0.5 当前不接入统治者层。工作树中存在 `WWIIHexV0/Core/DiplomacyState.swift`、`WWIIHexV0/Agents/RulerAgent.swift` 等其他版本方向文件，但 `TurnManager` 当前不调用 `RulerAgent`。v5.6a 已把最小外交归附合同接入规则层，但这不等于统治者 agent 已接入主链路。

v5.6a 当前已落地：

- `DiplomaticStatus` 支持 `tributary`、`submitting`、`negotiating`。
- `DiplomacyState` 保存 `PacificationRecord`，记录招抚/归附提议的 actor country、target country、target regions、前后关系、天命变化和原因。
- `GameState.mandateState` 保存 faction 级天命分数；旧存档缺字段时默认 `.empty`，读取时按 faction fallback 到 50。
- 唐宋默认剧本由 `DataLoader` 初始化宋/割据的天命分数。
- `Command.proposeSubmission(negotiatorId:targetCountryId:targetRegionIds:)` 通过 `CommandValidator` 校验 phase、谈判军队、国家关系、目标州府、天命阈值、低 warSupport 或围城压力，再由 `CommandExecutor` 写入 `DiplomacyState`、`MandateState` 和 diplomacy 日志。

v5.6b 当前已落地：

- `CommandPanelView` 提供玩家“招抚”按钮，但它不直接写外交状态。
- `AppContainer.proposeSubmissionSelected()` 将按钮操作转换为 `Command.proposeSubmission` 并交给 `submit -> RuleEngine`。
- `AppContainer.selectedSubmissionTarget` 只从外国首府 region 推断目标国家；优先使用当前选中首府，否则自动扫描当前可通过 `CommandValidator` 的首府候选。
- `DiplomacyPanelView` 只读展示 `MandateState` 和最近 `PacificationRecord`，唐宋场景下显示外交、天命、诸国、集团、关系和归附记录。

v5.6c 当前已落地：

- `TurnManager.runMarshalDirectiveTurn` 会读取元帅 envelope 的 `pacificationTargets`。
- `TurnManager.executeDirectiveEnvelope` 在战争 `ZoneDirective` 执行后、`.endTurn` 前调用 `executePacificationTargets`。
- `executePacificationTargets` 只在唐宋场景中运行，并把首府 region 候选反查为外国 `CountryProfile`。
- AI 招抚候选会选择当前 faction 的未行动、未撤退、可行动军队作为谈判军队，生成辅助 `Command.proposeSubmission(negotiatorId:targetCountryId:targetRegionIds:)`。
- 辅助命令仍通过 `commandHandler.execute -> RuleEngine -> CommandValidator -> CommandExecutor` 决定成败；成功、规则拒绝或跳过都会写入 `AgentDecisionRecord.commandResults`。
- 每个 AI 回合最多 1 个成功招抚提议，避免单轮把多个国家关系同时推进。

v5.6d 当前已落地：

- `VictoryReason` 新增唐宋专用 `tangSongUnificationByMandate` 和 `tangSongSeparatistSurvival`。
- `VictoryRules.updateVictoryState` 在唐宋场景先进入 `updateTangSongVictoryState`，不会套用 Bastogne / St. Vith legacy 胜利条件。
- 宋胜利要求控制开封、洛阳、太原、金陵、成都、杭州中的至少四处，且宋天命不低于 60。
- 割据生存要求到最大回合仍控制太原、金陵、成都中的至少两处，且割据天命不低于 35。
- v5.6g 后，以上硬编码条件只作为 `victoryConditions` 缺失时的 fallback。

v5.6e 当前已落地：

- `DiplomacyState.projectedPowerRelationStatus(between:and:)` 会把国家级外交关系聚合为 legacy power 级 `PowerRelationStatus`。
- 聚合规则保守：只要两个 legacy faction 之间仍有任一国家关系为 `hostile` / `atWar`，投影结果就是 `.atWar`。
- `TurnOrderState.setRelationStatus` 提供排序稳定的关系 upsert。
- `CommandExecutor.executeProposeSubmission` 成功写入国家关系后，会同步投影到 `TurnOrderState.relations`，供 `WarRelationRules.canTarget` 继续读取。

v5.6f 当前已落地：

- `AppContainer` 的点击攻击、攻击高亮、将领 attack target 和玩家 command zone 推断改为先读 `WarRelationRules.canTarget`，避免把非敌对单位或方面显示成可攻击候选。
- `WarCommandExecutor` 的 `enemyStrength`、`enemyRegions`、`hasEnemyPresence`、`visibleEnemyDivision`、`siegeCommand` 和 `tacticalDestination` 改为按 `canTarget` 判断敌军、敌控州府和可优先占领 hex；战争移动目的地会排除非己方且非敌对 controller 的 hex，不再依赖简单 `faction !=` 或 `Faction.opponent`。
- `ZoneCommanderAgent`、`MarshalBattlefieldSummarizer` 和 `MockAICommander` 的敌情估算、可见敌区和 `weightedRegions` 来源改为按 `canTarget` 判断战争目标。
- 招抚/谈判候选仍保留外交语义，继续由 `CountryProfile`、`pacificationTargets` 和 `CommandValidator.validateProposeSubmission` 判断，不用 `WarRelationRules.canTarget` 过滤。

v5.6g 当前已落地：

- `ScenarioDefinition.VictoryConditionDefinition` 支持可选 `mandateThreshold`。
- `DataLoader.loadGameState` 会把场景 JSON 的 `victoryConditions` 写入 `GameState.victoryConditions`；旧状态缺字段时解码为空数组。
- `DataLoader.loadGameState` 会对 scenario objective 引用、胜利条件 faction/type/status/count 和 objective id 做轻量校验，避免默认唐宋路径静默吞掉坏数据。
- `MapState.objective(id:)` / `controllerOfObjective(id:)` 支持按 objective id 查询控制方，避免胜利规则依赖中文 objective 名称。
- `VictoryRules.updateTangSongVictoryState` 优先读取 `state.victoryConditions`，当前支持 `controlObjectives` 与 `holdObjectives`。
- `majorVictory` 映射为 `.tangSongUnificationByMandate`，`survival` 映射为 `.tangSongSeparatistSurvival`；当前不支持的 type/status 会在加载校验中报错。

v5.6h 当前已落地：

- `VictoryReason.displayName(isTangSongScenario:)` 提供唐宋/legacy 胜负原因显示桥，不改变 enum raw value 或 Codable 兼容。
- `HUDView.victoryText` 会读取 `VictoryState.reason`，唐宋场景显示为“宋胜利：关键州府与天命达标”等短文案。
- `EventLogView` 接收 `VictoryState` 并在战报顶部派生只读胜负摘要；该摘要不写入 `eventLog`，不作为规则权威。
- `RootGameView` 只把当前 `gameState.victoryState` 传入战报面板，胜负仍只由 `VictoryRules.updateVictoryState` 写入。

v5.6i 当前已落地：

- `VictoryObjectiveProgress` 是从当前 `GameState` 派生的只读快照，不存入 `GameState`。
- `VictoryRules.objectiveProgress(in:)` 读取 `GameState.victoryConditions`、`MapState.controllerOfObjective(id:)` 和 `MandateState.legitimacy(for:)`，按与 v5.6g 一致的 objective id、count、turn / turns、`mandateThreshold` 口径生成进度。
- 旧场景或旧存档缺少 `victoryConditions` 时，进度展示使用 v5.6d 的关键州府/天命 fallback，和唐宋胜负 fallback 保持同一口径。
- `HUDView` 只读显示主要统一条件的州府进度与天命进度；`EventLogView` 在战报中只读列出主要胜利目标、门槛与当前达成状态。
- 该查询不调用 `updateVictoryState(in:)`，不写 `VictoryState`、`eventLog`、hex、region、theater 或 diplomacy。

v5.7a 当前已落地：

- `RootGameView.nextActionHint` 是唐宋场景专用的 UI 派生提示，不存入 `GameState`。
- 它只读取当前 `GameState`、`observerModeEnabled`、`selectedDivision`、`selectedDemandSurrenderTargetName`、`selectedBesiegeTargetName`、`selectedSubmissionTargetName`、`selectedRelieveSiegeTargetName` 和 `selectedRepairFortificationTargetName`。
- `HUDView` 接收 `nextActionHint` 后在首屏 HUD 中显示“下一步”提示，帮助玩家发现选军、行军、围城、招抚、解围、修城、结束回合和查看战报等既有入口。
- 该提示不调用 `RuleEngine`，不提交 `Command`，不写 `eventLog`，不改变任何规则判定；真实执行仍必须由玩家点击命令后进入 `Command -> RuleEngine`。

v5.7b 当前已落地：

- `HUDView.objectiveGuideText` 是唐宋场景专用的统一目标锚点，不存入 `GameState`。
- 它复用 `VictoryRules.objectiveProgress(in:)` 的主要 `majorVictory` 条件，并通过 `MapState.controllerOfObjective(named:)` 把关键州府拆成“已据”和“待取”。
- HUD 在首屏显示“目标”提示，例如开封、洛阳已据，太原、金陵、成都、杭州待取，帮助玩家理解 `统一进度 2/4` 对应哪些地图目标。
- 该提示不新增 objective，不改变 `VictoryRules`，不提交 `Command`，不写 `eventLog`，不修改 hex / region / theater / front / diplomacy。

v5.7c 当前已落地：

- `HUDView.objectiveGuideItems` 把主要统一目标渲染为“已据 / 待取”小按钮，按钮使用 objective id 作为稳定标识。
- `RootGameView` 将按钮点击传给 `AppContainer.focusObjective(id:)`。
- `AppContainer.focusObjective(id:)` 只读取 `MapState.objective(id:)`，把 `selectedHex` 和 `selectedRegionId` 设为目标所在 hex / region，并写一条交互日志；它不改 `GameState`、不提交 `Command`、不调用 `RuleEngine`。
- 地图已有 selected hex / selected region 高亮和 Region inspector 链路会自然显示该目标州府，形成轻量开局导览。

v5.7d 当前已落地：

- `MapDisplayAdapter.objectiveOverlays()` 在唐宋场景下复用 `VictoryRules.objectiveProgress(in:)` 的主要 `majorVictory` 条件，把 objective id / name / coord / 控制状态派生为 `ObjectiveOverlayState`。
- `BoardScene.drawObjectiveOverlays` 在非 frontLine 图层只读绘制目标州府 spotlight，用“已据 / 待取”短标签和 hex outline 标出主要统一目标；若 HUD 点击过某个目标，`focusedObjectiveId` 只作为渲染态让该目标多一圈强调。
- 该 spotlight 不新增 objective，不改变 `VictoryRules`，不提交 `Command`，不写 `GameState` 或 `eventLog`，不参与移动/攻击/围城/外交合法性判断。
- HUD 目标按钮仍只负责选中聚焦；地图 spotlight 只是帮助玩家在地图上识别统一目标州府，不做自动镜头移动、路线指引或持续追踪系统。

v5.7e 当前已落地：

- `EventLogView` 新增唐宋场景“本回合战报 / 最近战报”摘要区。
- 摘要统计只读取 `summaryEntries`，由 `RootGameView` 传入 `gameState.eventLog`，避免把 `displayEventLog` 中的点击、选中、定位等 `interactionLog` 当成规则战报。
- 摘要额外读取最近 `AgentDecisionRecord` 和 `GameState.warDirectiveRecords`，把 AI 军议与方面军令作为“军议”计入展示。
- 该摘要只读聚合战斗、州府、围城、粮道、外交、前线、方面、军议等已有记录，不写 `GameState.eventLog`，不新增事件源，不改变 `WarDirectiveRecord` / `AgentDecisionRecord` 生成职责，也不参与规则、胜负或 AI 决策。

v5.7f 当前已落地：

- `HUDView` 接收 `playerFaction` 与 `observerModeEnabled`，在唐宋场景显示“指挥 / 模式”短状态：宋可下令、宋待命、观战各方、玩家亲征或只读观战。
- `NewGameButton` 在唐宋场景显示“重开剧本”；`RootGameView` 在调用 `AppContainer.resetGame()` 前弹出确认，避免误清空当前剧本进度。
- 该切片只包装 UI 入口和当前身份读法，不改变 `AppContainer.playerFaction`，不实现真实多势力选择，不写 `GameState` schema，不改变 `resetGame()`、`RuleEngine`、`TurnManager`、命令合法性或存档。

v5.7g 当前已落地：

- `RootGameView.nextActionHint` 在选中可行动宋军且无围城/招抚/解围/修城等更高优先级目标时，读取 `AppContainer.attackHighlights.count` 与 `movementHighlights.count`。
- 提示会说明当前可攻击目标数量和可行军格数量，帮助玩家把“下一步”与地图红色目标/高亮格对应起来。
- 这些数量来自既有 UI 高亮派生结果：行军高亮由 `MovementRules.movementRange` 生成，攻击高亮由敌对关系和射程筛出；提示不新增命令、不调用 `RuleEngine`、不写 `GameState` 或 `eventLog`，也不替代真实按钮提交后的 `CommandValidator` / `RuleEngine` 校验。

v5.7h 当前已落地：

- `RootGameView` 在唐宋场景把“亲征”分段选择与既有“观战”入口并列，玩家可在当前 legacy `.allies/.germany` 桥上切换亲征阵营。
- `DataLoader.initialTurnOrderState` 的唐宋路径读取场景 JSON 的 `playerFaction` / `aiFaction`，初始化 `PowerProfile.controlMode` 与 `playerControlledPowerIds`；`AppContainer` 默认从运行态 `playerControlledPowerIds` 推导初始亲征势力。
- `AppContainer.playerFaction` 从初始化常量变为运行时 UI 状态；`setPlayerFaction(_:)` 同步 `TurnOrderState.playerControlledPowerIds` 和带 legacy bridge 的 `PowerProfile.controlMode`，清空当前选中军队与移动/攻击高亮，并在当前回合需要 AI 时继续调用 `runAIIfNeeded()`。
- `RootGameView.nextActionHint` 的唐宋文案读取当前亲征势力名称，不再把所有可行动提示硬写为宋军。
- 该切片不新增 `Faction` case，不新增真实吴越/南唐/后蜀等多政权选择，不写新的 `GameState` schema，不新增存档槽，不改变 `Command`、`RuleEngine`、`TurnManager` 或 `WarCommandExecutor` 的执行边界。

v5.7i 当前已落地：

- `EventLogView` 在唐宋场景且 `VictoryState.winner` 已存在时，在胜负摘要下方显示“评分估算”只读摘要。
- 摘要从 `VictoryState.winner/reason`、传入战报面板且匹配胜者自己的 `VictoryRules.objectiveProgress(in:)` 快照、当前回合、州府进度和天命门槛估算 0-100 分，并给出“天命归一 / 山河大定 / 功业初成”或“守成有余 / 割据稳固 / 勉强自保”等短档位。
- 该摘要不调用 `VictoryRules.updateVictoryState`，不写 `VictoryState`、`GameState.eventLog`、hex / region / theater / front / deploy 或 diplomacy，不新增权威结算事件，也不替代正式胜负规则。
- 该切片不是完整胜利面板、治理评分、单国胜负、外交纳土结算、自动破城或正式评分系统；它只是战报面板的展示层复盘提示。

v5.7j 当前已落地：

- `AppContainer.selectedValidatedCommandHint` 在唐宋场景下只读构造当前 UI 候选命令，并用 `CommandValidator.validate` 有限预校验围城、招抚、解围、修城、招降、攻击和行军候选。
- `RootGameView.nextActionHint` 优先显示“规则确认可执行”的地图或军令入口，减少仅靠高亮数量或目标名导致的宽泛提示。
- `AppContainer` 的围城、修城、解围和招降候选过滤也收口到同一 `CommandValidator` 入口，减少 UI 层复制规则条件。
- 该切片不提交 `Command`，不调用 `RuleEngine.execute`，不写 `GameState`、`eventLog`、hex / region / theater / front / deploy 或 diplomacy，不改变 `CommandValidator` 语义；它不是通用 dry-run 系统、完整逐命令教程或规则模拟器。

v5.7k 当前已落地：

- `UnitInspectorView` 接收 `isTangSongScenario` 与 `factionDisplayName`，唐宋场景下把军队详情字段显示为军队、政权、指挥、地块、州府、动态方面、防区、粮道、兵力、退却口径、补给、状态和编成，并把底层组件显示为禁军、骑军、厢军、器械。
- `RegionInspectorView` 接收 `isTangSongScenario` 与 `factionDisplayName`，唐宋场景下把州府详情字段显示为地块控制、控制政权、地形、城池、城级、关隘、粮草、围城、工坊、产出、方面、防区、前线压力、道路、目标、己方军队和可见敌军；产出读作丁口、钱帛、粮草，围城摘要使用当前 `GameState.displayName(for:)` 的政权名。
- `RootGameView.nextActionHint` 的已行动提示继续读取当前亲征势力名称，不再硬写“宋军”；`CommandPanelView` 在唐宋场景下把非玩家所控单位显示为“非亲征军队”，减少多政权入口下的误导。
- 该切片只补玩家可见显示桥，不改 `Division` / `RegionNode` / `ComponentType` / `EconomyResources` / `Faction` Codable schema，不改 `GameState`、命令、围城、补给、胜负或地图控制规则，也未做截图/布局验收。

v5.7l 当前已落地：

- `GeneralCommandPanelView` 接收 `isTangSongScenario`，唐宋场景下把将领操作面板显示为将领军令、方面防区、未选择亲征方面防区、忠诚、军心、亲征干预、查看档案、所属军队、目标州府、固守防线、进攻州府和已拟军令。
- `GeneralProfileView` 接收 `isTangSongScenario` 与 `factionDisplayName`，唐宋场景下把档案页显示为将领档案、关闭、履历、用兵、所辖方面、朝廷关系、忠诚、军心、亲征干预、特长和辖下军队，并通过 `GameState.displayName(for:)` 显示将领所属政权，避免默认唐宋路径直接露出 `Germany` / `Allies`。
- 计划摘要在唐宋场景下把 `DirectiveType.attack/defend` 显示为进攻/固守，将领用兵风格显示为锐进、持重或谨慎。
- 该切片只补玩家可见显示桥，不改 `GeneralData`、`GeneralAssignment`、`FrontZone`、`PlayerPlannedOperation` schema，不改变将领分配、AI 决策、`ZoneDirective`、`WarCommandExecutor`、`RuleEngine` 或规则执行。

v5.7m 当前已落地：

- `RootGameView` 向右下角 `UnitTooltipView` 传入 `isTangSongScenario`，让常驻选中军队摘要跟随唐宋场景显示桥。
- `UnitTooltipView` 在唐宋场景下把字段显示为兵种、兵力、补给、退却和本回合，并把底层 ART/ARM/MOT/INF 显示为器械、禁军、骑军、厢军，把 Supplied/Low/Encircled 显示为有粮、缺粮、被围，把 Retreatable/Hold 显示为可退、固守。
- tooltip 的 accessibility label 同步改为唐宋读法，避免读屏时仍输出英文 type / strength 口径。
- 该切片只补玩家可见显示桥，不改 `Division`、`ComponentType`、`SupplyState`、`RetreatMode`、命令、补给、退却或任何规则执行。

v5.8a 当前已落地：

- `AgentPanelView` 在唐宋场景下对主事、来源、君主、将令、全局军令、防区、州府目标、legacy order type 和 ruler posture fallback 做显示桥，把默认主路径残留读作宋枢密院、割据行营、确定性军议、方面主将、全局军令、行军、进攻、固守、整补、进取和维系诸国等玩家可读文案。
- `RootGameView` 向 `AgentPanelView` 传入运行态州府与方面防区名称查找，让 `WarDirectiveRecord.targetRegionIds` 和 `preferredFrontZoneId` 优先显示州府/防区名，而不是 raw id。
- 唐宋命令结果标题会把 `Move(...)`、`Attack(...)`、`Besiege(...)`、`ProposeSubmission(...)` 或对应中文命令显示为动作名，避免把单位 id、国家 id 或 region id 当作玩家标题展示。
- 该切片只改 AI 面板显示桥，不改 `AgentDecisionRecord`、`WarDirectiveRecord`、`TheaterDirectiveEnvelope`、`Command`、`ZoneDirective`、`TheaterDirectiveCompiler`、`WarCommandExecutor`、`RuleEngine` 或任何 Codable raw schema。diagnostics、错误原文和 raw JSON 调试区仍是后续 v5.8 RC 风险。

v5.8b 当前已落地：

- `AgentPanelView` 在唐宋场景下把军议复盘拆为玩家态摘要和开发态调试信息：玩家态默认显示军议摘要、方面军令、命令执行/拒绝摘要和折叠的军议详文入口；diagnostics、错误原文和 raw JSON 放入折叠调试区。
- `resultLine(_:)` 在唐宋场景下不再直接铺开规则/执行层 message 或 validation rawValue，而显示“已执行 / 规则拒绝 / 映射失败 / 未执行”等摘要。
- `AgentPanelView` 的唐宋意图与战况优先读取 `theaterDirectiveSummary.summary / strategicIntent` 和本地化战况兜底，避免显示 `marshal directives`、`json` 等上游 fallback 字符串。
- 运行态州府/防区名称缺失时，AI 面板唐宋路径显示“未命名州府 / 未命名方面”，不直接暴露 raw id。
- 该切片只改 UI 展示和调试折叠，不改变 `WarDirectiveRecord.diagnostics`、`AgentDecisionRecord.errors/rawJSON` 的记录职责，也不改变 decoder、compiler、executor、`RuleEngine`、命令、AI 算法或 Codable raw schema。

v5.8n 当前已落地：

- `AgentPanelView` 在唐宋玩家态对军议摘要、诏令、朝议、战况、命令标题、diagnostics、errors 和 raw JSON 增加显示层兜底；含 Latin、JSON 痕迹、schema key、raw id 或旧英文 fallback 的文本不再作为默认军议文案直出。
- 防区重点显示统一走运行态防区显示桥，唐宋列表连接符改用“、”或“·”，减少 ASCII 分隔符残留。
- diagnostics、errors 和 raw JSON 在唐宋路径显示为计数或“原文已记录”提示，原始数据仍留在 `AgentDecisionRecord` / `WarDirectiveRecord` 中供调试追溯。
- 该切片只改 AI 面板只读显示桥，不改变 `AgentDecisionRecord`、`WarDirectiveRecord`、`TheaterDirectiveEnvelope`、raw JSON 存储、decoder、compiler、executor、`RuleEngine`、命令、AI 算法或 Codable raw schema。

v5.8o 当前已落地：

- `GeneralCommandPanelView` 在唐宋场景下把将领副标题从 ASCII `/` 改为“·”，把已拟军令摘要从“动作 / 目标”改为“动作：目标”。
- `RegionInspectorView` 在唐宋场景下把地块坐标从 `q,r` 改为中文列/行读法，把目标和军队列表分隔符改为“、”，把围城城防从 ASCII `/` 改为“／”。
- 该切片只改将领面板和州府详情面板的只读显示桥，不改变 `PlayerPlannedOperation`、`RegionInspectorState`、`SiegeRecord`、命令、围城规则、AI 决策、事件写入职责、VoiceOver 实机结果或 Codable schema。

v5.8p 当前已落地：

- `EconomyPanelView` 在唐宋场景下把军备成本行从 ASCII `|` 改为中文逗号读法。
- `HUDView` 和 `EventLogView` 在唐宋场景下把回合进度、结算评分、战报 metadata 和方面军议 highlight 中的 ASCII `/`、` - ` 或 ` / ` 改为“／”、中文分号或“：”。
- `UnitInspectorView`、`UnitTooltipView`、`GeneralProfileView` 和 `UnitNode` 在唐宋场景下把兵力 `strength/maxStrength` 显示从 ASCII `/` 改为“／”，军队详情地块坐标改为中文列/行读法，粮道成本、编成列表和多状态列表也改用“／”或“、”。
- `MapDisplayAdapter` 在唐宋地图 overlay 上把围城城防和粮道成本标签中的 ASCII `/` 改为“／”。
- 该切片只改玩家可见 UI 与地图标签的只读显示桥，不改变 `Division`、`SupplyRouteSummary`、`SiegeOverlayState`、生产、补给、围城、命令、AI 决策、事件写入职责或 Codable schema。

v5.8q 当前已落地：

- `AppContainer.submit(_:)` 在唐宋场景下把 `lastCommandMessage` 和交互日志改为动作级中文摘要，避免默认把 `Command.displayName` 中的单位 id、region id 或 ASCII 标点写给玩家。
- `AppContainer` 的常见本地 guard 反馈已做唐宋分流：无可行动军队、围城/修城/解围/招降/招抚目标缺失、将领军令入口拒绝、府库观战拒绝、选中军队、敌方/非敌对军队和地块坐标均优先写入中文文案。
- 非唐宋路径继续保留 legacy 英文 fallback，便于阿登历史回归；该切片不改变 `CommandResult`、`GameLogEntry`、`CommandValidator`、`RuleEngine`、`WarCommandExecutor`、AI 决策、事件 schema 或 Codable raw 值。

v5.8r 当前已落地：

- `VictoryObjectiveProgress.summary`、`HUDView` 和 `EventLogView` 在唐宋场景下把统一进度、天命进度和胜负后评分估算中的 ASCII `/` 改为“／”。
- `EconomyResources.summary(isTangSongScenario:)` 的唐宋路径改用“、”连接丁口、钱帛、粮草；`EconomyPanelView` 继续复用该显示桥。
- `UnitInspectorView` 粮道近源坐标与 `EventLogView` 旧英文 `Selected hex` 日志显示桥改用“第 q 列，第 r 行”。
- `EventLogView` 本回合战报的军议摘要遇到 Latin、JSON 痕迹、schema key 或 raw id 风险时降级为“军议摘要已形成 / 已形成方面军令”，不直接把上游原文铺给玩家。
- 该切片只改主游戏玩家可见显示桥，不改变胜利规则、经济规则、补给规则、`AgentDecisionRecord`、`WarDirectiveRecord`、事件写入职责、AI 决策或 Codable raw 值。

v5.8s 当前已落地：

- MapEditor 信息面板、状态栏和导出错误统一通过 `HexCoord.mapEditorDisplayName` 显示“第 q 列，第 r 行”，不再默认显示 `q,r` 坐标。
- MapEditor 资源区把“导出 JSON 到内存”改为“生成资源预览”，默认资源说明显示为“建隆元年剧本 / 州府数据”；覆盖和导出状态也改为唐宋资源口径，不默认铺开 `.json` 文件名。
- MapEditor 底图区只显示底图文件名，不在默认侧栏直出完整本机路径。
- MapEditor 导出错误和默认资源桥错误改为中文包装，避免默认暴露州府 raw id、地形 rawValue 或底层英文编码错误。
- 自动州城名、粮仓 fallback、默认州府/方面名继续收口为中文读法。
- 该切片只改 MapEditor 玩家/编辑器可见显示桥和错误包装，不改变导出的 JSON schema、`Faction.allies/germany`、`GamePhase.alliedPlayer`、`RegionId`、`TheaterId`、主游戏 `DataLoader`、规则系统、AI 决策或 Codable raw 值。

v5.8t 当前已落地：

- `RootGameView` 的信息面板按钮补充 accessibility label/value/hint，唐宋路径会朗读“信息面板”、展开/收起状态和面板用途。
- 主棋盘 `BoardSceneView` 的 accessibility value 会从 `AppContainer.selectedHex` / `selectedRegionId` 只读派生当前选中地块与州府名称；未选中时朗读“尚未选中地块”。
- `InfoPanelToggle` 的通用“详情”按钮补充展开/收起状态和展开/收起提示，避免读屏只听到静态按钮名。
- `GeneralProfileView` 的头像占位改为装饰性元素，不再把“头像占位 / portrait placeholder”作为玩家可读内容重复朗读。
- MapEditor 底图偏移输入框使用“底图横向偏移 / 底图纵向偏移”可访问标签，地图编辑画布补“地图编辑画布”名称和编辑提示。
- 该切片只改 SwiftUI 可读语义和文案，不改变 SpriteKit 地图交互、逐 hex focus、focus order、hit target、布局、规则、导出 JSON schema 或 Codable raw 值；完整 VoiceOver 实机、截图、横竖屏布局和发布级 UI 验收仍未完成。

v5.8u 当前已落地：

- `CommandPanelView` 的固守、可退、整补、围城、修城、解围、招降、招抚和结束回合按钮补充 accessibility value/hint；唐宋路径会朗读“可用 / 停用”，并说明观战、阶段不对、未选军队、已行动或缺少目标等停用原因。
- `EconomyPanelView` 的军备按钮补充 accessibility value/hint，把费用、建造回合、观战模式、当前阶段不可下令和资源不足原因绑定到按钮读法。
- `RootGameView` 的亲征选择与观战切换补充当前值和提示，说明切换亲征政权会清空选择/高亮，观战会停用军令和府库命令。
- `HUDView` 的统一目标锚点按钮补充“查看目标”可访问标签、已据/待取状态和地图聚焦提示。
- 该切片只改 SwiftUI 控件可读语义，不改变命令执行、经济规则、胜利目标、地图聚焦逻辑、SpriteKit 地图交互、逐 hex focus、focus order、hit target、布局、JSON schema 或 Codable raw 值；完整 VoiceOver 实机、截图、横竖屏布局和发布级 UI 验收仍未完成。

v5.8v 当前已落地：

- `MapEditorViewModel` 的读取默认唐宋资源、覆盖默认唐宋资源和生成资源预览失败路径不再使用 `String(describing: error)` 直出 raw 错误；已知 `MapEditorExportError` / `MapEditorGameResourceBridgeError` 继续展示中文说明，其他系统/解码错误统一落到中文 fallback。
- MapEditor 新建州府、方面和军队名称默认改为空输入，继续由既有自动命名生成“州府 N / 方面 N / 军 N”，避免把示例文字误写入真实草案。
- `MapEditorView` 的新建州府、新建方面、新建军队、选中地块州府/方面编辑框补充上下文 accessibility label/hint；错误区显示和读屏都带“错误：”前缀。
- 该切片只改 MapEditor 显示、输入默认值和 SwiftUI 可读语义，不改变导出 JSON schema、默认资源路径、`Faction.allies/germany`、`GamePhase.alliedPlayer`、`RegionId`、`TheaterId`、主游戏规则、AI 决策或 Codable raw 值；完整 VoiceOver 实机、截图、横竖屏布局和发布级 UI 验收仍未完成。

v5.8w 当前已落地：

- `RootGameView` 的 `BoardSceneView` SwiftUI 包装层新增 VoiceOver custom actions：攻击下一处红色目标、行军到下一处高亮地块、打开信息面板。
- 棋盘 accessibility value 在唐宋场景下补充选中地块中文列/行、州府名、控制政权、当前已选军队、红色攻击目标数量和高亮行军格数量。
- 攻击/行军读屏动作只调用既有 `AppContainer.handleBoardTap(_:)`，随后继续走玩家点击同一链路；若形成移动或攻击命令，仍由 `CommandValidator` / `RuleEngine` 决定合法性和状态修改。
- 该切片不改变 `BoardScene`、`HexNode`、`UnitNode`、SpriteKit 命中测试、地图渲染、`Command`、`RuleEngine`、JSON schema 或 legacy `Faction` 桥；逐 hex / 逐军队 focus tree、VoiceOver 实机、截图和布局验收仍未完成。

v5.8x 当前已落地：

- `RootGameView` 的地图图层选择器和紧凑信息面板分页补充 accessibility label/value/hint，读屏可获知当前图层、当前面板和切换用途。
- `RootGameView` 传给外交与军议面板的唐宋州府/方面缺名 fallback 改为“未知州府 / 未命名方面”，不再在缺名情况下回退显示 `RegionId` 或 `FrontZoneId` rawValue。
- `GeneralCommandPanelView` 的将领档案入口、固守防线和进攻州府按钮补充可用/停用状态与提示；头像入口读屏名与“查看档案”按钮区分。
- 该切片只改 SwiftUI 可读语义和缺名兜底，不改变棋盘 custom actions、SpriteKit 渲染、命令执行、将领计划、外交/AI 记录、JSON schema、规则系统或 legacy `Faction` 桥；完整 VoiceOver 实机、截图和布局验收仍未完成。

v5.8y 当前已落地：

- `UnitTooltipView` 的合并读屏内容拆分为 label/value，value 补充兵力、补给、退却和本回合状态；英文 low supply tooltip 不再只显示 `Low`。
- `UnitInspectorView` 的英文 `FrontZone` / `FrontLine` / `Deploy` 标签改为自然读法，英文部署状态不再直出 `FRONT` / `DEPTH` / `GARRISON`；唐宋编成比例从百分号改为“占 N／100”。
- `RegionInspectorView` 的英文 `FrontZone` 标签与 `MP/IC/SUP` 资源缩写改为自然读法；唐宋围城摘要改为攻方、守方、压力、城防和围城军队数量的结构化读法。
- 该切片只改 tooltip 和检查面板显示/读屏语义，不改变 `Division`、`ComponentType`、`RegionInspectorState`、围城规则、补给规则、命令、AI 决策或 Codable schema；完整 VoiceOver 实机、截图和布局验收仍未完成。

v5.8z 当前已落地：

- `GeneralProfileView` 的关闭按钮补充“关闭将领档案 / Close General Profile” accessibility label 和返回提示，避免只读出通用关闭按钮。
- 忠诚与军心 `metricBar` 合并为单个可访问元素，value 显示“满百 / out of 100”；技能项补“特长 / Skill”上下文，HQ 受压补警告读法。
- 辖下军队行补完整 accessibility label/value，唐宋路径读作军队名与“兵力 x，满额 y”，避免只读数字比例。
- 唐宋头像占位在 legacy Latin 名称下显示“将”，所辖方面名为空或含 Latin 时 fallback 为“未命名方面”，减少默认唐宋路径的 Latin 残留。
- 该切片只改将领档案 SwiftUI 可读语义和缺名 fallback，不改变 `GeneralData`、`GeneralAssignment`、`FrontZone`、`Division`、将领分配、命令、规则、AI 决策或 Codable schema；完整 VoiceOver 实机、截图和布局验收仍未完成。

v5.8aa 当前已落地：

- `MapEditorSpriteView` 的地图编辑画布补充 accessibility value，读出当前模式、编辑状态、地块/州府/方面/军队数量、选中地块、待加入/待部署数量和底图状态。
- `MapEditorView` 的底图导入、移除、缩放、横向/纵向偏移和应用参数控件补充 accessibility label/value/hint，说明底图只是绘制参考，不改变游戏规则数据。
- MapEditor 帮助文案去掉 `Option+左键`、`N`、`M` 这类 ASCII 快捷键表达，底图偏移输入框去掉可见 `X/Y` 轴字母。
- 该切片只改 MapEditor SwiftUI 可读语义和说明文字，不改变 `MapEditorDocument`、导出 JSON schema、资源桥路径、SpriteKit 画布交互、快捷键处理、主游戏规则或 Codable raw 值；完整 VoiceOver 实机、截图和布局验收仍未完成。

v5.8ab 当前已落地：

- `MapEditorCanvasScene` 的粮源画布标记从“补”改为“粮”，更贴近唐宋资源口径。
- MapEditor 军队模板画布标记从单字 `禁/骑/弩/械/守/州/军` 改为“禁军、骑军、弩兵、器械、守军、州军、军队”，减少过短调试符号。
- 底图 SpriteKit 节点不再写 `name = "底图"`，避免保留无用的调试命名；SwiftUI 画布 accessibility value 仍由 `MapEditorSpriteView` 提供。
- 该切片只改 MapEditor SpriteKit 画布显示标签，不改变 `MapEditorDocument`、单位模板 id、导出 JSON schema、资源桥路径、画布交互、快捷键处理、主游戏规则或 Codable raw 值；完整截图、布局和符号系统验收仍未完成。

v5.8ac 当前已落地：

- `AppContainer.playerDirectiveMessage` 在唐宋路径下把方面军令部分执行摘要从 `N/M` 改为“已执行 N 道，未执行 M 道”，避免默认玩家反馈继续露出 ASCII 比例。
- `CommandPanelView.commandMessageText` 对旧式 `General order executed...` 反馈做完整中文兜底，能解析数量时显示已执行/未执行，解析失败时显示“方面军令已执行。”
- `AgentPanelView` 唐宋玩家态把“军议原文”改称“军议详文”，raw JSON 仍只在 legacy/开发态路径按既有逻辑显示。
- 该切片只改玩家可见反馈和显示桥，不改变 `Command`、`ZoneDirective`、`WarDirectiveRecord`、`AgentDecisionRecord.rawJSON`、命令执行、AI 决策、规则或 Codable schema；完整全项目写入端本地化和发布级 UI 验收仍未完成。

v5.8ad 当前已落地：

- `EconomyPanelView` 在唐宋路径下把军备队列未就绪项从裸数字改为“尚需 N 回合”，就绪项继续显示“就绪”，减少府库队列里的调试式数字残留。
- 府库本回合指标从“入丁 / 入帛 / 耗粮”改为“本回合丁口 / 本回合钱帛 / 本回合耗粮”，并为指标行补充合并后的 accessibility label/value。
- 军备按钮补充“下达军备令：军备名”读屏动作名，队列行补充“军备队列：军备名”和剩余回合 accessibility value。
- 该切片只改府库面板显示和 SwiftUI accessibility 语义，不改变 `ProductionOrder`、`ProductionKind`、`EconomyRules`、`Command.queueProduction`、资源扣除、队列执行、日志结构或 Codable schema；完整 VoiceOver 实机、截图布局和发布级 UI 验收仍未完成。

v5.8ae 当前已落地：

- `HUDView` 在唐宋路径下把库存指标从裸数字改为“丁口 N / 钱帛 N / 粮草 N”，让首屏资源读法与府库面板一致。
- HUD 军备队列指标从裸数字改为“暂无军备”或“军备队列 N 项”，减少首屏调试式数量残留。
- HUD 指标行补充合并后的 accessibility label/value，读屏时按单个指标读出当前标签和值。
- 该切片只改 HUD 显示和 SwiftUI accessibility 语义，不改变 `EconomyState`、生产队列、资源规则、胜利规则、命令执行、日志结构或 Codable schema；完整 VoiceOver 实机、截图布局和发布级 UI 验收仍未完成。

v5.8af 当前已落地：

- `GeneralCommandPanelView` 的忠诚/军心指标补充合并 accessibility 语义，唐宋路径读作“数值，满百”。
- 亲征干预不再显示裸数字，唐宋路径显示“N 次”并读出次数。
- 所属军队行保留简洁名称显示，同时读屏补充兵力与满额；已拟军令行补“已拟军令：进攻/固守”和目标值。
- 该切片只改将领军令面板显示和 SwiftUI accessibility 语义，不改变 `GeneralData`、`GeneralAssignment`、`Division`、`PlayerPlannedOperation`、命令按钮、AI 决策、规则系统或 Codable schema；完整 VoiceOver 实机、截图布局和发布级 UI 验收仍未完成。

v5.8ag 当前已落地：

- `EventLogView` 的最近战报列表行补充合并 accessibility 语义，读屏时把分类徽标、回合/势力/阶段 metadata 和正文作为一条战报朗读。
- 唐宋路径下战报行 label 读作“战报：战斗 / 粮道 / 州府”等分类，value 复用既有 `metadata(for:)` 与 `displayMessage(for:)`，继续经过 `TangSongEventLogMessage` 显示桥。
- 该切片只改战报列表行 SwiftUI accessibility 语义，不改变 `GameLogEntry`、`TangSongEventLogMessage` 映射、事件写入端、命令执行、AI 决策、规则系统或 Codable schema；完整 VoiceOver 实机、截图布局和发布级 UI 验收仍未完成。

v5.8ah 当前已落地：

- `EventLogView` 的“本回合战报 / 最近战报”摘要卡片补充合并 accessibility 语义，读屏时把标题、回合、汇总文字和重点条目作为一个摘要读出。
- 唐宋路径下摘要卡片 label 读作“战报摘要：本回合战报 / 最近战报”，value 复用既有 `TurnReportSummary` 的 `turnText`、`summaryText` 和 highlights。
- 该切片只改战报摘要卡片 SwiftUI accessibility 语义，不改变 `GameLogEntry`、`TurnReportSummary` 派生逻辑、`TangSongEventLogMessage` 映射、事件写入端、命令执行、AI 决策、规则系统或 Codable schema；完整 VoiceOver 实机、截图布局和发布级 UI 验收仍未完成。

v5.8ai 当前已落地：

- `EventLogView` 的胜负卡片补充合并 accessibility 语义，读屏时把“胜负”和胜负原因作为一个胜负摘要读出。
- 唐宋评分估算卡片补充合并 accessibility 语义，读屏时把分数、档位和估算依据说明作为一个评分摘要读出。
- 该切片只改战报顶部胜负/评分卡片 SwiftUI accessibility 语义，不改变 `VictoryState`、`VictoryReason`、`VictoryRules.objectiveProgress(in:)`、评分估算算法、`GameLogEntry`、事件写入端、命令执行、AI 决策、规则系统或 Codable schema；完整 VoiceOver 实机、截图布局和发布级 UI 验收仍未完成。

v5.8aj 当前已落地：

- `EventLogView` 的胜利目标进度行补充合并 accessibility 语义，读屏时把目标标题、达成/推进中状态、进度摘要和目标详情作为一条胜利目标读出。
- 唐宋路径下胜利目标行 label 读作“胜利目标：宋统一 / 守成”等现有标题，value 复用既有 `VictoryObjectiveProgress.summary`、`detail` 和达成状态文案。
- 该切片只改战报胜利目标行 SwiftUI accessibility 语义，不改变 `VictoryState`、`VictoryReason`、`VictoryRules.objectiveProgress(in:)`、`VictoryObjectiveProgress` 计算逻辑、胜利目标排序、可见 UI 文案、`GameLogEntry`、事件写入端、命令执行、AI 决策、规则系统或 Codable schema；完整 VoiceOver 实机、截图布局和发布级 UI 验收仍未完成。

v5.8ak 当前已落地：

- `HUDView` 的目标提示摘要补充合并 accessibility 语义，读屏时以“目标提示”读出当前已据/待取关键州府摘要。
- 目标州府 chips / 按钮继续保留独立 accessibility label/value/hint 与独立焦点，点击仍只调用既有 `onFocusObjective` 聚焦目标州府。
- `HUDView` 的“下一步”提示卡片补充合并 accessibility 语义，读屏时把标题和 `nextActionHint` 作为一个提示读出。
- 该切片只改 HUD SwiftUI accessibility 语义，不改变 `VictoryRules.objectiveProgress(in:)`、`objectiveGuideItems` 生成、目标排序、地图 spotlight / focus、`RootGameView.nextActionHint` 派生、`CommandValidator`、命令执行、AI 决策、规则系统或 Codable schema；完整 VoiceOver 实机、截图布局、主棋盘逐地块/逐军队 focus tree 和发布级 UI 验收仍未完成。

v5.8al 当前已落地：

- `AgentPanelView` 的“军令结果”列表行补充合并 accessibility 语义，读屏时把命令标题和执行状态作为一条军令结果读出。
- 唐宋路径下军令结果行 label 读作“军令结果：行军 / 进攻 / 围城”等现有命令标题，value 复用既有 `resultLine(_:)` 的“已执行 / 规则拒绝 / 映射失败 / 未执行”等状态。
- 该切片只改 AI 面板 SwiftUI accessibility 语义，不改变 `AgentDecisionRecord`、`CommandResultSummary`、`WarDirectiveRecord`、`TheaterDirectiveEnvelope`、`ZoneDirective`、`Command`、命令执行、AI 决策、规则系统、日志结构、raw JSON 存储或 Codable schema；完整 VoiceOver 实机、截图布局、方面军令卡片、诏令朝议摘要块、外交/命令面板复合行和发布级 UI 验收仍未完成。

v5.8am 当前已落地：

- `CommandPanelView` 的军令状态文本补充 accessibility label/value，读屏时以“军令状态”读出当前可下令、观战、阶段不可下令、非亲征军队或已行动等状态。
- 结束回合按钮补充可用状态 value；最近军令反馈文本补充“军令反馈” label，并复用 `commandMessageText(_:)` 的唐宋显示桥作为读屏 value。
- 该切片只改命令面板 SwiftUI accessibility 语义，不改变 `Command`、`CommandValidator`、`CommandExecutor`、`RuleEngine`、`lastCommandMessage` 写入端、按钮启停条件、命令反馈映射、AI 决策、规则系统、日志结构或 Codable schema；完整 VoiceOver 实机、截图布局、外交面板复合行、AI 方面军令卡片和发布级 UI 验收仍未完成。

v5.8c 当前已落地：

- `DiplomacyPanelView` 在唐宋场景下把外交状态、国家/集团副标题、君主主事、国策、重点方面、归附状态和归附目标州府 fallback 做显示桥，关系状态显示为盟好、称臣、协战、中立、敌对、交战、归附中或议和。
- `RootGameView` 向外交面板传入运行态州府与方面防区名称查找，归附记录和君主重点防区优先显示州府/防区名；缺失时唐宋路径显示“未命名州府 / 未命名方面 / 未命名集团 / 未知政权”，不直接把 raw id 当作默认玩家文案。
- 该切片只改外交面板只读展示，不改变 `DiplomacyState`、`MandateState`、`Command.proposeSubmission`、`CommandValidator`、`CommandExecutor`、`RuleEngine`、`TurnOrderState.relations`、`WarRelationRules.canTarget`、JSON/Codable schema 或 hex/region/theater/front/deploy 控制权。

v5.8d 当前已落地：

- `EventLogView` 在唐宋场景下让战报正文 `GameLogEntry.message` 和本回合摘要 highlight 统一经过 `TangSongEventLogMessage` 显示桥，常见英文命令、交互、战斗、退却、补给、AI 执行和 validation rawValue 显示为唐宋读法。
- 该显示桥覆盖 `Command accepted/rejected`、选中地块/州府/军队、`attacked/counterattacked`、`strength`、自动退却、整补、退却失败、AI command result 和常见 `CommandValidationError.rawValue`，减少默认战报主路径英文和内部枚举外露。
- 该切片只改战报 UI 读法，不改变 `GameLogEntry.message`、`CommandResultLogEntry`、`CommandValidator`、`CommandExecutor`、`RuleEngine`、事件写入职责、日志 Codable schema 或任何规则结果。v5.8q 已覆盖常见 AppContainer 交互反馈写入端；v5.8ag 进一步让最近战报列表行合并分类、元数据和正文读屏；v5.8ah 进一步让本回合/最近战报摘要卡片合并标题、回合、汇总和重点条目读屏；v5.8ai 进一步让胜负和评分估算卡片合并胜负原因、分数、档位和说明读屏；v5.8aj 进一步让胜利目标行合并标题、状态、摘要和详情读屏；v5.8ak 进一步让 HUD 目标摘要和下一步提示合并读屏；v5.8al 进一步让 AI 面板军令结果行合并命令标题和执行状态读屏；v5.8am 进一步让命令面板军令状态、结束回合状态和最近军令反馈补读屏上下文；更完整的结构化 event payload、真 LLM 输出本地化和全项目写入端唐宋化仍留后续。

v5.8k 当前已落地：

- `CommandPanelView` 在唐宋场景下把未命中的命令反馈继续交给 `TangSongEventLogMessage.display`，让命令面板和战报面板共用同一套默认显示桥。
- `EventLogView` 对退却路线、被围损耗、玩家方面军令诊断、州府归属变化、动态方面变更等常见英文事件补中文映射；显示桥处理后若仍含拉丁字母，唐宋路径降级为“战报已更新；原始记录留在调试日志中。”，不把 raw 英文、内部 key 或 legacy 术语直接展示给玩家。
- `RootGameView.nextActionHint` 的已行动提示改为“各方军议推进”，不再在唐宋 HUD 提示中显示 `AI`。该切片只改 UI 兜底，不改变 `GameLogEntry.message`、事件写入端、命令执行、AI 决策、规则判定或 Codable schema。

v5.8l 当前已落地：

- `GeneralCommandPanelView` 新增运行态州府/方面显示名查找，唐宋“已拟军令”优先显示目标州府、来源州府或方面名称；缺名时显示“未命名州府 / 未命名方面”，不再默认展示 `targetRegionId`、`sourceRegionId` 或 `zoneId.rawValue`。
- `BoardScene` 空棋盘占位标题改为“舆图加载中”；macOS app 菜单改为“军务 / 结束回合 / 重新开局”；`InfoPanelToggle` 固定 `[ INFO ]` 改为“详情”并补中文 accessibility label。
- 该切片只改玩家可见 UI 文案和显示桥，不改变 `PlayerPlannedOperation` schema、将领命令执行、地图渲染状态、macOS app 生命周期、规则或存档。

v5.8m 当前已落地：

- `DiplomacyPanelView` 在唐宋路径对国家名和集团名增加 `CountryId` / `DiplomaticBlocId` 显示映射与 Latin guard，旧存档或 fallback 数据里的 `German Reich`、`United States`、`Axis`、`Allied Coalition` 等不再默认直出。
- 外交关系行改为“甲 与 乙”，归附记录改为“甲 招抚 乙”，国家副标题使用“·”，归附州府和君主目标列表使用“、”。
- 该切片只改外交面板只读显示桥，不改变 `DiplomacyState`、`PacificationRecord`、外交关系投影、命令、规则或 Codable schema。

v5.6b 的 UI 到规则链路：

```text
CommandPanelView
  -> AppContainer.proposeSubmissionSelected
  -> Command.proposeSubmission
  -> RuleEngine
  -> CommandValidator / CommandExecutor
  -> DiplomacyState + MandateState
  -> DiplomacyPanelView read-only
```

`DiplomacyPanelView` 保持只读展示端。v5.8c 只在 `DiplomacyState + MandateState -> DiplomacyPanelView` 这段补唐宋读法和 fallback 名称，不让面板写状态，也不绕过 `CommandValidator` / `RuleEngine`。

v5.6c 的 AI 招抚辅助链路：

```text
TheaterDirectiveEnvelope.pacificationTargets
  -> TurnManager.executeDirectiveEnvelope
  -> TurnManager.executePacificationTargets
  -> Command.proposeSubmission
  -> RuleEngine
  -> CommandValidator / CommandExecutor
  -> AgentDecisionRecord.commandResults
  -> DiplomacyState + MandateState on success
  -> v5.6e conservative projection to TurnOrderState.relations
```

v5.6f 的战术候选关系感知链路：

```text
TurnOrderState.relations
  -> WarRelationRules.canTarget
  -> UI attack target / highlight
  -> ZoneCommanderAgent / MarshalBattlefieldSummarizer visible enemy regions
  -> WarCommandExecutor enemy regions / enemy divisions / tactical destination
  -> Command
  -> RuleEngine
```

v5.6g 的唐宋胜利条件读取链路：

```text
tangsong_jianlong_960_scenario.json victoryConditions
  -> ScenarioDefinition.VictoryConditionDefinition
  -> DataLoader.loadGameState
  -> GameState.victoryConditions
  -> VictoryRules.updateTangSongVictoryState
  -> MapState.controllerOfObjective(id:)
  -> VictoryState.winner / reason
```

v5.6h 的胜负说明显示链路：

```text
VictoryRules.updateVictoryState
  -> VictoryState.winner / reason
  -> VictoryReason.displayName
  -> HUDView.victoryText
  -> EventLogView 只读胜负摘要
```

v5.6a/v5.6b/v5.6c/v5.6d/v5.6e/v5.6f/v5.6g/v5.6h 当前没有做：

- 不实现吴越、南唐、后蜀、北汉等单国 tactical neutral；v5.6e 只同步 legacy `.allies/.germany` power 级保守投影。
- 不交割 hex / region controller，不转换或删除部队，不刷新 theater/front/deploy。
- 不让 `TheaterDirectiveEnvelope.pacificationTargets` 自动纳土、停战或改变控制权；v5.6c 只尝试生成经规则校验的归附提议命令。
- 不实现完整治理政策、民心、治安、税粮、叛乱或归附后的纳土交割；v5.6g 只让唐宋胜利条件可从 JSON 读取，不改变天命调整来源或控制权交割来源。
- 不实现完整评分档位、单国胜负、胜利面板重构或统一结算战报；当前只识别唐宋 JSON 已使用的 `majorVictory` 与 `survival`，v5.6h 只显示原因摘要。

后续若加入统治者层，必须满足这些边界：

- 统治者只能位于元帅上游，输出国家级姿态、优先方向或约束条件。
- 统治者不得直接生成底层 `Command`，不得绕过 `MarshalAgent` / `ZoneDirective`。
- 统治者不得直接修改 `HexTile.controller`、`Division.coord`、`regionToTheater`、`hexToTheater` 或 `hexToFrontZone`。
- 若需要审计记录，必须单独设计数据 schema，并在 `md/flow/*`、`README.md`、`update_log.md` 中同步说明。

当前唐宋地图、部队和战术敌我仍通过 legacy 二元 `Faction` 桥运行。`DiplomacyState` 是国家级投影，`TurnOrderState.relations` 是当前 `WarRelationRules` 读取的 power 级战争合法性来源。v5.6e 会把国家关系保守聚合回 power 关系，v5.6f 再把该关系用于 UI/AI/WarCommandExecutor 的战术候选生成，避免外交记录、候选高亮和最终规则长期分叉；但吴越等国家虽然能在外交记录中进入 `submitting`，在完成更细粒度 `PowerId` / `CountryId` 归属迁移前，仍不能宣称其已经获得 tactical neutral 或独立战争关系。

### 1.8 EconomyState / EconomyRules

源码：`WWIIHexV0/Core/EconomyState.swift`、`WWIIHexV0/Rules/EconomyRules.swift`

v0.8 新增初级回合经济层。它是 faction 级总账，不是第三套地图权威。

`EconomyState`：

```text
ledgers: [Faction: FactionEconomyLedger]
lastResolvedTurn
```

`FactionEconomyLedger`：

```text
faction
stockpile: EconomyResources
lastIncome
lastUpkeep
lastReinforcementSpend
productionQueue: [ProductionOrder]
lastUpdatedTurn
```

`EconomyResources` 只包含三项：

```text
manpower
industry
supplies
```

v5.3 开始，唐宋默认场景在显示层和经济日志中把这三项映射为：

```text
manpower -> 丁口
industry -> 钱帛
supplies -> 粮草
```

源码字段名仍保留 legacy 英文，避免大规模 schema 迁移；`EconomyResources.summary(isTangSongScenario:)` 和 `ProductionKind.displayName(isTangSongScenario:)` 是当前显示桥。

收入算法：

```text
对 faction 控制且 passable 的每个 region:
  如果该 region 没有任何真实己方控制 hex，跳过
  cityLevel = EconomyRules.cityLevel(region, map)
  coreBonus = region.coreOf 为空或包含 faction ? 1 : 0
  manpower = max(1, cityLevel.manpowerGrowth + coreBonus * 4 + infrastructure)
  industry = max(0, factories + cityLevel.industryValue + infrastructure / 3)
  supplies = max(1, supplyValue * 3 + factories + infrastructure / 2)
```

城市等级不是单独 JSON schema，当前从既有字段推导：

- capital、victoryPoints >= 5 或 factories >= 5 -> `metropolis`。
- victoryPoints >= 2、factories >= 2 或 supplyValue >= 3 -> `town`。
- 有 city / fortress / factory 但不满足上面条件 -> `village`。
- 没有城市、堡垒或工厂信号 -> `none`。

生产队列由 `Command.queueProduction(kind:)` 进入规则系统：

```text
EconomyPanelView
  -> AppContainer.queueProduction
  -> Command.queueProduction
  -> RuleEngine
  -> CommandValidator.validateProduction
  -> CommandExecutor.executeQueueProduction
  -> EconomyRules.queueProduction
```

排产时预付资源，完成时才部署单位或发放 supply stockpile。完成单位只能放到本方控制、passable、空置、非敌邻，且位于首都、城镇/大都会、工厂、高基建、高补给 region 或 supply source 的后方 hex。找不到安全部署点时订单保留到下回合继续尝试。

v5.3 当前唐宋生产显示桥：

```text
infantryDivision   -> 募厢军，完成后命名为厢军
panzerDivision     -> 募禁军，完成后命名为禁军
motorizedDivision  -> 募骑军，完成后命名为骑军
artilleryDivision  -> 造器械，完成后命名为攻城器械营
supplyStockpile    -> 整备粮草，完成后增加粮草
```

这些仍是 `ProductionKind` 的兼容显示，不代表底层 enum 已重命名。`Command.displayName(isTangSongScenario:)`、`RuleEngine`、`AppContainer`、`EconomyRules` 和 `EconomyPanelView` 已读取该显示桥，唐宋默认路径的排产、部署、补员、缺粮和结束回合日志不再直接输出 `Panzer Division`、`Germany`、`MP/IC/SUP`。

自动补员在 active faction 结束回合时发生，只处理：

```text
本阵营
未毁灭
未撤退
supplied
strength < maxStrength
不与敌军相邻
```

每个单位每回合最多恢复 2 strength，并按装甲、摩托化、火炮权重扣 manpower / industry / supplies；唐宋显示为丁口、钱帛、粮草。v0.8/v5.3 均不恢复 organization。

---

## 2. 数据启动流程

### 2.1 默认启动路径

源码：`WWIIHexV0/Data/DataLoader.swift`、`WWIIHexV0/App/AppContainer.swift`

主入口：

```text
AppContainer.bootstrap()
  -> DataLoader().loadInitialGameState()
  -> RuleEngine()
  -> GameAgent.defaultCommander(...)
  -> StrategicStateBootstrapper().bootstrapIfNeeded(...)
  -> TurnManager(... commanderPool: buildCommanderPool(state: bootstrappedState))
  -> AppContainer(...)
```

`DataLoader.loadInitialGameState()` v5.8g 后默认只走唐宋首发剧本 JSON：

```text
loadGameState(
  scenarioName: "tangsong_jianlong_960_scenario",
  regionName: "tangsong_jianlong_960_regions",
  unitTemplateName: "tangsong_unit_templates"
)
```

如果唐宋资源缺失、JSON 解码失败、引用校验失败或单位模板缺失，默认启动会进入唐宋错误态并写入中文日志，不再静默回退 legacy 阿登。显式历史回归仍可调用 `loadLegacyArdennesGameState()`、`loadArdennesDataSet()` 或指定 `loadGameState(ardennes...)`。当前唐宋底层仍用 `Faction.allies` 表示宋、`Faction.germany` 表示北方与割据 AI 桥；`TurnOrderState` 的 `PowerProfile` 负责默认显示名。

### 2.2 loadGameState 的完整链条

源码：`WWIIHexV0/Data/DataLoader.swift`

```text
loadScenarioDefinition(named:)
loadRegionDataSet(named:)
loadUnitTemplates(named:)
  -> makeMapState(from: scenario)
     - ScenarioTileDefinition -> HexTile
     - tile.controller 字符串转 Faction；"neutral" 转 nil
     - tile.regionId 写入 HexTile.regionId
     - supply source / objective 写入 MapState
  -> apply(regionData, to: map)
     - regionData.toRegions()
     - regionData.toHexToRegion()
     - regionData.toRegionEdges()
     - 反填 HexTile.regionId
     - validateRegionGraph()
  -> RegionOccupationRules().mapByAggregatingControllers(in: map)
     - 从 hex controller 派生 region controller
  -> makeDivisions(from: scenario.initialUnits, templates:)
  -> makeTheaterState(map, regionData, divisions, turn)
     - 优先使用 regionData.regions[].theaterId
     - 没有 assignment 时使用 TheaterSystem.makeInitialFixedTheaters
     - TheaterSystem.updateTheaters seed hexToTheater 并刷新派生字段
     - capture initialSnapshot
  -> FrontLineManager.makeInitialState(...)
  -> WarDeploymentManager.makeInitialState(...)
  -> GameState(...)
```

DEBUG 下资源读取优先源码目录 `WWIIHexV0/Data/*.json`，不是旧 bundle。旧 simulator 进程不会自动重载，改默认地图后需要重新运行 app。

### 2.3 StrategicStateBootstrapper

源码：`WWIIHexV0/Core/StrategicStateBootstrapper.swift`

它有两个用途：

1. `bootstrapIfNeeded`
   - 只补缺失层。
   - 先用 `EconomyRules.bootstrapIfNeeded` 为旧状态补 faction 经济总账。
   - 如果 state 有 region 但缺 theater/front/deployment，会从当前 map/divisions 生成。
   - App 初始化、命令提交后会用它兜底。

2. `refreshRuntimeState`
   - 强制刷新运行时派生层。
   - 先聚合 region controller。
   - 强制 `TheaterSystem.updateTheaters(force: true)`。
   - 重新 `FrontLineManager.makeInitialState`。
   - 重新 `WarDeploymentState.bootstrapFrontZones`。
   - AI 行动前会调用，确保指令读取的是当前动态层。

---

## 3. 地图编辑器流程

### 3.1 MapEditorDocument

源码：`MapEditor/MapEditorDocument.swift`

编辑器自己的文档模型：

```text
id / displayName
width / height
hexes: [HexCoord: MapEditorHex]
regions: [RegionId: MapEditorRegionDraft]
theaters: [TheaterId: MapEditorTheaterDraft]
regionTheaterAssignments: [RegionId: TheaterId]
initialUnits: [MapEditorUnitDraft]
backgroundImage
```

四种编辑模式：

```text
hexPainter         地块
regionBuilder      州府
theaterAssignment  方面
unitPlanner        军队
```

编辑动作：

```text
idle
adding
deleting
```

地块工具：

```text
paint   覆盖已有 hex
extend  在已有 hex 邻位扩展稀疏地图
```

关键行为：

- `MapEditorDocument.contains(_:)` 判断实际存在的 hex，支持稀疏地图。
- `addHex(at:)` 只能在已有 hex 邻位扩展，避免凭空造孤岛。
- `deleteHex(at:)` 会删除该 hex 上初始军队；如果某 region 已无 hex，会删除 region 和 theater assignment。
- `resize` 会裁剪外部 hex、清理无效 region assignment 和越界单位。
- 底图 `backgroundImage` 只存在编辑器文档，不写入游戏 JSON。

### 3.2 编辑会话

源码：`MapEditor/MapEditorViewModel.swift`

典型流程：

```text
选择 mode
  -> beginAdding / beginDeleting
  -> 点击或拖拽 canvas
  -> applyPrimaryAction(at:)
  -> stage 或直接编辑
  -> finishEditing
  -> commitPendingRegion / commitPendingTheater / commitPendingUnits
```

不同模式行为：

- `hexPainter`
  - adding + paint：写 terrain、road、controller、supply。
  - adding + extend：尝试在相邻空位生成 plain hex。
  - deleting：删除 hex。

- `regionBuilder`
  - adding：把点击 hex 先放进 `pendingRegionHexes`，完成时统一 assign 到选中或新建 region。
  - deleting / erase：把 hex 的 regionId 清空。

- `theaterAssignment`
  - 点击 hex 后先取该 hex 的 regionId。
  - adding：把 region 放进 `pendingTheaterRegions`，完成时统一 assign 到选中或新建 theater。
  - deleting：清除 region 的 theater assignment。

- `unitPlanner`
  - adding：点击 hex 放入 `pendingUnitHexes`，完成时按唐宋军队模板、政权、朝向、兵力生成初始单位。
  - 同一 hex 新 stamp 会先删除原单位。
  - deleting / erase：删除该 hex 上初始单位。

快捷键：

- `N`：添加。
- `M`：完成。

### 3.3 导出链路

源码：`MapEditor/MapEditorExporter.swift`

导出产物：

```text
ScenarioDefinition JSON
RegionDataSet JSON
```

导出前校验：

- 所有 hex 必须有 regionId，否则 `unassignedHex`。
- 所有被引用 region 必须在 `document.regions` 里定义。
- 每个导出的 region 必须至少有一个 hex，否则 `emptyRegion`。

`ScenarioDefinition` 写入：

- map width/height/isSparse。
- 每个 `MapEditorHex` 写为 `ScenarioTileDefinition`。
- terrain / road / controller / city / fortress / supply / objective / regionId。
- factions、initialTurn、initialPhase、playerFaction、aiFaction。
- `initialUnits` 从 `MapEditorUnitDraft` 写入。
- 底图不写入。

`RegionDataSet` 写入：

```text
hexToRegion:
  每个 hex 的 coord key -> regionId

regions:
  每个 MapEditorRegionDraft -> RegionNodeDefinition
  theaterId = document.regionTheaterAssignments[draft.id]
  displayHexes = 属于该 region 的 hex
  representativeHex = displayHexes 几何中心最近 hex
  terrain = region 内 dominant terrain
  city = 第一处 city / fortress / city terrain
  neighbors = 从 hex 邻接自动推导

edges:
  从跨 region hex 邻接自动推导
  两侧 hex 都有 road 时 hasRoad = true

supplySources / objectives:
  从对应 hex 自动归到 region
```

重要：region 邻接和 edge 不是人工手填权威，而是在导出时从真实 hex 邻接推导。这和运行时前线必须看 hex 邻接是一致的。

### 3.4 默认资源桥

源码：`MapEditor/MapEditorGameResourceBridge.swift`

默认读写路径：

```text
WWIIHexV0/Data/tangsong_jianlong_960_scenario.json
WWIIHexV0/Data/tangsong_jianlong_960_regions.json
```

读取默认资源时，编辑器只读取唐宋 960 文件。若 `tangsong_jianlong_960_scenario.json` 或 `tangsong_jianlong_960_regions.json` 缺失，编辑器直接报错，不再静默回退到 legacy 阿登资源；阿登数据只保留为显式 legacy 入口和历史回归参考。覆盖保存始终写回唐宋默认文件名，不覆盖 legacy 阿登数据。

流程：

```text
loadDefaultDocument()
  -> 优先读取唐宋 ScenarioDefinition + RegionDataSet
  -> makeDocument(...)
     - scenario tile -> MapEditorHex
     - regionData.toHexToRegion 优先填 regionId
     - region definitions -> MapEditorRegionDraft
     - region theaterId -> regionTheaterAssignments
     - scenario initialUnits -> MapEditorUnitDraft

overwriteDefaultGameResources(document:)
  -> MapEditorExporter.export(... 固定唐宋默认文件名)
  -> 写回 WWIIHexV0/Data
```

v5.8e 当前编辑器可见术语继续硬化到唐宋口径：地块、州府、方面、军队、粮仓、关隘、宋、割据诸政权。新建草案默认显示为“唐宋地图草案”，城市 fallback 为“州城编号”，导出错误、数据注记和州府数据 displayName 使用中文；州府/方面选择器和检查面板默认显示名称，不直接暴露 raw id；编辑器棋盘单位标签显示为禁军、骑军、弩兵、器械、守军、州军、军队。底层 `Faction.allies` / `Faction.germany`、`RegionId` / `TheaterId` 与 `Division` 类型名仍保留作兼容桥。

相关测试确认：

- 编辑器 document、导出 JSON、游戏加载后的 `hexToRegion` / `regionToTheater` / `tile.regionId` / `region.name` 必须一致。
- 游戏和编辑器 hex layout 的垂直方向必须一致。
- 默认开局单位不能出现在敌对初始 theater 中。
- App bootstrap 不应自动跑 AI 或移动开局单位。

---

## 4. 主游戏 UI 与输入流程

### 4.1 AppContainer

源码：`WWIIHexV0/App/AppContainer.swift`

`AppContainer` 是 SwiftUI 和规则层之间的中介。它持有：

```text
@Published gameState
selectedUnitId / selectedHex / selectedRegionId
movementHighlights / attackHighlights
interactionLog
lastCommandMessage
lastAgentDecisionRecord
lastWarDirectiveRecords
observerModeEnabled
mapDisplayLayer
```

玩家提交命令：

```text
submit(command)
  -> commandHandler.execute(command, in: gameState)
  -> StrategicStateBootstrapper.bootstrapIfNeeded(result.state)
  -> 唐宋路径 lastCommandMessage = 动作级中文反馈
  -> appendInteractionEvent(唐宋路径写入中文反馈，legacy 路径保留旧文案)
  -> refreshSelectionAfterStateChange()
  -> runAIIfNeeded()
```

点击地图：

```text
handleBoardTap(coord)
  -> selectedHex = coord
  -> selectedRegionId = MapDisplayAdapter.regionId(for: coord)
  -> 如果已有己方可行动单位选中，且点击处有敌军:
       submit(.attack)
     else 如果点击处有单位:
       handleDivisionTap
     else 如果已有己方可行动单位选中:
       submit(.move)
     else:
       清空选择
```

玩家可行动单位必须满足：

- 非 observer mode。
- 单位属于 `playerFaction`。
- 当前 activeFaction 是 `playerFaction`。
- 当前 phase 是 `.alliedPlayer`。
- 未行动。

### 4.2 RootGameView

源码：`WWIIHexV0/UI/RootGameView.swift`

主界面元素：

- `BoardSceneView`：SpriteKit 地图。
- `HUDView`：剧本、回合、当前政权、阶段、胜负、资源、队列、结束回合、新局。
- `MapDisplayLayer` segmented picker：
  - legacy 显示：`Hex` / `Province` / `Initial` / `Dynamic` / `Front` / `Deploy`
  - 唐宋显示：`地块` / `州府` / `初始方面` / `动态方面` / `前线` / `部署`
- `Observer` toggle；唐宋场景显示为 `观战`。
- Info / 面板按钮，内含 compact panel：
  - legacy tabs：`Unit` / `Region` / `General` / `Log` / `Economy` / `Diplomacy` / `AI`
  - 唐宋 tabs：`军队` / `州府` / `将领` / `战报` / `府库` / `外交` / `军议`
- `UnitTooltipView`：右下角选中军队摘要；v5.7m 起唐宋场景显示兵种、兵力、补给、退却和本回合读法。

v5.5 首轮术语桥只改变唐宋场景的玩家可见读法：

- `GameState.phaseDisplayName` 在唐宋场景下按当前 `PowerProfile.shortName` 显示为“宋行动”“割据军议”等，不再在 HUD/命令状态中显示 `Player Command` / `AI Command`。
- `CommandPanelView` 在唐宋场景下显示 `军令`、`固守`、`可退`、`整补`、`结束回合` 和对应不可下令原因；底层命令仍是 `Command`。
- `EventLogView` 在唐宋场景下显示 `战报`，分类显示为战斗、退却、整补、合围、围城、粮道、前线、方面、州府、外交、事件；日志数据结构不变。
- `TerrainStyle` 提供唐宋视觉 token：墨绿底、绢帛平地、青绿林地、石青河流、赭石道路、朱印宋军、铜褐割据和多色州府/方面 overlay。
- `UnitNode` 在唐宋场景下不画 NATO APP-6 符号，改画内置军旗轮廓和禁/骑/弩/械/守/军兵种字标；legacy 阿登路径仍保留 NATO 符号。
- `HexNode` / `RegionOverlayNode` / `MapLayerOverlayNode` / `BoardScene` 只读使用唐宋 palette，围城圈、计划箭头、前线和部署色随场景切换。
- `SupplyRouteOverlayState` / `MapDisplayAdapter.supplyRouteOverlays` / `BoardScene.drawSupplyRouteOverlays` 只读绘制友方可见军队到最近可见粮源的唐宋粮道虚线；它复用 `SupplyRules.supplyRouteSummary`，不重新实现补给规则，也不表示真实逐 hex 路径。
- 这不是完整发布级 UI 收口，尚未做运行时截图、布局烟测、外部美术资产或正式可访问性验收。

当前开局不会在 `RootGameView` 自动 `.task { runAIIfNeeded() }`。AI 行动由 `advanceOrRunAI()` 或命令提交后的 `runAIIfNeeded()` 触发。

### 4.3 v1.1 主游戏 macOS target

源码：

- `WWIIHexV0/App/WWIIHexV0MacApp.swift`
- `WWIIHexV0/SpriteKit/BoardSceneView.swift`
- `WWIIHexV0/SpriteKit/BoardScene.swift`
- `WWIIHexV0/UI/PlatformStyles.swift`

v1.1 新增独立 macOS 主游戏 target：

```text
WWIIHexV0Mac
  -> WWIIHexV0MacApp
  -> AppContainer.bootstrap()
  -> RootGameView(container:)
  -> BoardSceneView
  -> BoardScene
```

这个 target 和既有 target 的边界：

- `WWIIHexV0`：iOS 主游戏 target。
- `WWIIHexV0Mac`：macOS 主游戏 target。
- `MapEditorMac`：macOS 地图编辑器 target，不是主游戏入口。

`WWIIHexV0Mac` 复用主游戏数据和规则，不新增一套 mac 专用规则。resource phase 包含：

```text
tangsong_jianlong_960_scenario.json
tangsong_jianlong_960_regions.json
tangsong_unit_templates.json
tangsong_characters.json
ardennes_v0_scenario.json
ardennes_v02_regions.json
general_agents.json
generals.json
terrain_rules.json
unit_templates.json
```

DEBUG 下 `DataLoader` 仍优先读源码目录 `WWIIHexV0/Data/*.json`；bundle resources 是 release / fallback 路径。

v5.8h 起，唐宋主游戏默认路径按 `scenarioId == jianlong_960_unification` 调用 `DataLoader.loadGeneralRegistry(for:)` 读取 `tangsong_characters.json` 并映射为兼容 `GeneralRegistry`。`generals.json` 仍保留给显式 legacy 阿登和历史回归参考，不再作为唐宋默认将领池。

`BoardSceneView` 现在有平台分支：

```text
iOS:
  UIViewRepresentable
  -> SKView
  -> BoardScene touch input

macOS:
  NSViewRepresentable
  -> BoardEventSKView
  -> BoardScene mouse / scroll / magnify input
```

macOS 输入桥接逻辑：

```text
鼠标点击
  -> BoardScene.mouseDown / mouseUp
  -> layout.pixelToHex
  -> onHexTapped(coord)
  -> AppContainer.handleBoardTap

鼠标拖拽
  -> BoardScene.mouseDragged
  -> camera.position 更新
  -> clampCamera

滚轮 / 触控板缩放
  -> BoardEventSKView.scrollWheel / magnify
  -> scene.convertPoint(fromView:)
  -> BoardScene.handleScrollWheel / handleMagnify
  -> zoomCamera(anchor:)
  -> clampCamera
```

注意：macOS 点击仍只进入 `AppContainer.handleBoardTap`。移动、攻击、结束回合和 AI 行动仍由 `RuleEngine` / `WarCommandExecutor` 处理；v1.1 不允许通过 AppKit 或 SpriteKit 直接修改 `GameState`。

---

## 5. 命令执行流程

### 5.1 Command / RuleEngine

源码：`WWIIHexV0/Commands/Command.swift`、`WWIIHexV0/Rules/RuleEngine.swift`、`WWIIHexV0/Rules/CommandValidator.swift`、`WWIIHexV0/Rules/CommandExecutor.swift`

底层 `Command` 当前包括：

```text
move(divisionId, destination)
attack(attackerId, targetId)
hold(divisionId)
allowRetreat(divisionId)
resupply(divisionId)
queueProduction(kind)
endTurn
```

执行总入口：

```text
RuleEngine.execute(command, in: state)
  -> EconomyRules.bootstrapIfNeeded(state)
  -> CommandValidator.validate(command, in: preparedState)
  -> invalid: 返回 CommandResult，state 不变
  -> valid: CommandExecutor.execute(command, in: preparedState)
```

v5.8i 起，唐宋场景下 `CommandValidationError.displayName(isTangSongScenario:)` 会把 `wrongPhase`、`wrongFaction`、`regionNotFound`、`submissionNotReady` 等 raw validation key 显示为中文拒绝原因；`RuleEngine` 仍保留原始 enum case 和 Codable raw 值，不改变校验语义。`AppContainer` 的 AI 回合完成、玩家方面军令反馈、选中州府日志和 `CommandPanelView.lastCommandMessage` 也优先显示唐宋文案；`EventLogView` 唐宋 metadata 不再展示内部 `relatedRecordId`，legacy 阿登路径保持旧 metadata。v5.8q 起，`AppContainer` 的常见玩家交互反馈进一步从写入端分流为唐宋文案：命令接受/驳回、无可行动军队、围城/修城/解围/招降/招抚目标缺失、将领军令、府库观战拒绝、选中军队和地块坐标不再默认写入英文或 raw id 摘要。v5.8r 起，胜利/天命进度、评分估算、粮道近源坐标、府库资源摘要和本回合军议摘要继续在显示层收口，减少 `/`、`,`、`q,r`、Latin、JSON 痕迹和 raw key 直出。

v5.8j 起，唐宋军队/州府检查面板不再默认把 `RegionId`、`TheaterId`、`FrontZoneId`、`FrontLineId`、补给源 id 或 `MapDisplayAdapter` 生成的英文 `None/controlled` 作为玩家文案。`MapDisplayAdapter` 仍保存 raw id 供逻辑和 legacy 显示使用，同时为 inspector state 补运行态州府、动态方面、防区和粮源名称；`UnitInspectorView` / `RegionInspectorView` 在唐宋路径优先显示这些名称，缺失时使用“未知州府 / 未命名方面 / 未命名防区 / 无目标”等兜底。该变化只影响 UI 派生显示，不改变任何 id schema、目标控制、补给判定或命令执行。

### 5.2 校验规则

`CommandValidator` 的关键校验：

移动：

```text
phaseAllowsCommands
division exists
division.faction == activeFaction
division 未行动、未撤退、canAct
destination 在地图内
destination passable
destination 没有其他单位
忽略 movement 的最短路径 cost <= division.movement
真实 shortestPath 存在
```

攻击：

```text
attacker 可行动
target exists
target.faction != attacker.faction
distance <= attacker.range
```

恢复/姿态：

```text
phase 合法
division exists
faction 匹配 activeFaction
未行动、未毁灭、未撤退
```

结束回合：

```text
phaseAllowsCommands
```

生产排队：

```text
phaseAllowsCommands
active faction economy ledger 有足够 manpower / industry / supplies
```

### 5.3 移动与占领

`CommandExecutor.executeMove` 真实链路：

```text
记录 origin
sourceZoneId = warDeploymentState.zoneId(for: origin)
更新 facing
division.coord = destination
division.hasActed = true

if OccupationRules.canOccupy(division, destination, state):
  tile.controller = division.faction
  map.setTile(tile)

  if destinationRegionId && sourceZoneId:
    applyStrategicAdvance(
      regionId: destinationRegionId,
      hex: destination,
      sourceZoneId: sourceZoneId,
      faction: division.faction
    )

  StrategicStateSynchronizer.synchronizeAfterOccupationChange(
    affectedRegionIds: [destinationRegionId]
  )

appendEvent("moved")
```

`OccupationRules.canOccupy` 很小，但非常关键：

```text
tile exists
tile.isCapturable
tile.controller != division.faction
destination 没有其他单位
```

注意：

- 只有移动会触发占领。
- 攻击造成伤害/撤退/消灭，不会自动把攻击者推进到目标 hex。
- 移动进敌控空 hex 时，先改 hex controller，再同步战略层。
- 移动进有敌单位的 hex 会在 validator 被 `destinationOccupied` 拒绝。

### 5.4 动态战区推进

`CommandExecutor.applyStrategicAdvance` 的语义：

```text
advancingTheaterId = TheaterId(sourceZoneId.rawValue)
如果 theater 不存在，return
如果 destination hex 已经属于 advancingTheater，return
如果 shouldAdvanceDynamicTheater == false，return

TheaterSystem.expandDynamicTheater(
  breakthroughHex: destination,
  advancingTheaterId,
  faction
)

oldZoneId = warDeploymentState.zoneId(for: destination)
如果 oldZoneId != sourceZoneId:
  WarDeploymentManager.advanceHex(destination, from: oldZoneId, to: sourceZoneId)

appendEvent("Hex q,r reassigned to dynamic theater ...")
```

`shouldAdvanceDynamicTheater` 当前判断：

- 如果目标 hex 当前 zone 属于其他 faction，则可以推进。
- 否则如果目标 hex controller 不是本方，也可以推进。
- 否则不推进。

这确保动态推进是 hex 级，不会把整个 region 拉走。

### 5.5 Region / Theater / Front / Deploy 同步

源码：`WWIIHexV0/Rules/StrategicStateSynchronizer.swift`

占领变化后：

```text
RegionOccupationRules.aggregateControl(in: &state)
  -> changedRegionIds

affected = affectedRegionIds + changedRegionIds

TheaterSystem.updateTheaters(force: true)

FrontLineManager.update(
  events:
    changed -> regionControllerChanged
    unchanged -> occupationChanged
)

WarDeploymentManager.update(
  events: affected.map(regionControllerChanged)
)

可选写 region owner change event
```

Region controller 聚合权重：

- 每个已控制 hex 基础权重 1。
- `representativeHex` 加 region city VP。
- city / fortress / city terrain / fortress terrain 再加权。
- 中立 hex 不计入。
- 并列第一时不改 region controller。

### 5.6 攻击、撤退、补给、结束回合

攻击流程：

```text
计算 attackDamage
attacker.hasActed = true
attacker.facing = 面向 defender
对 defender 扣 strength
resolveCombatResult
  -> retreatable 且 lossRatio >= 0.35 时 shouldRetreat
  -> hold 模式追加损失
  -> encircled 且撤退触发追加损失
  -> destroyed 则 removeDivision + victory record
如果 defender 没撤退且可反击:
  defender counterattack
  attacker 也可能撤退/毁灭
```

v5.3 唐宋场景下，`CombatRules` 在不改底层 `ComponentType` Codable schema 的前提下增加了古代兵种最小修正。角色由 `Division.tangSongCombatRoles` 从单位 id、生产 kind id 和现有组件权重推导，仅在 `state.isTangSongScenario == true` 时启用：

```text
cavalry
  -> 进攻平原或道路目标 +15%
  -> 进攻城池、关隘、森林、山地 -15%

siegeEngine
  -> 攻击 city / fortress / 具名城市或关隘 +35%
  -> 野战攻击 -25%，野战防御 -1

crossbowGarrison
  -> 守 city / fortress / 具名城市或关隘 +2 防御

garrison
  -> 守 city / fortress / 具名城市或关隘 +1 防御
```

这只是 v5.3 的战斗数值切片：攻击、反击、撤退、消灭仍由 `CommandExecutor` / `RuleEngine` 执行；攻击不会直接占领 hex。围城状态、城防耐久、修城、解围、招降、地图围城 overlay 和 AI 围城/招降指令首轮已通过 `Command.besiege` / `Command.repairFortification` / `Command.relieveSiege` / `Command.demandSurrender`、`SiegeState`、只读 `SiegeOverlayState`、`WarCommandExecutor.siegeCommand` 和 `WarCommandExecutor.demandSurrenderCommand` 落地；v5.6a 另行新增 `Command.proposeSubmission` 作为外交归附规则合同首轮，但它只写外交记录和天命，不交割地图控制权；v5.6g 已把唐宋胜利评价桥推进为优先读取场景 JSON `victoryConditions`。自动破城、完整外交归附、完整漕运、治理评分和完整统一结算仍未实现。

v5.3 围城城防、修城、解围与招降首轮：

```text
Command.besiege(attackerId, targetRegionId)
  -> CommandValidator.validateBesiege
  -> 只允许围困敌对控制的城池 / 关隘 / 高 supplyValue 粮仓州府
  -> 攻击军队必须在目标 region 覆盖 hex 的 range 距离内
  -> CommandExecutor.executeBesiege
  -> 写入 GameState.siegeState.records
  -> 累积 pressure，并按攻城器械/守方城防损耗 fortification
  -> 标记攻击军队 hasActed
  -> EventLog 记 siege 分类

Command.repairFortification(defenderId, targetRegionId)
  -> CommandValidator.validateRepairFortification
  -> 守方军队必须位于己方控制且正在被围的目标州府内
  -> 只允许修复未满的 fortification
  -> CommandExecutor.executeRepairFortification
  -> 消耗该军队行动，恢复 SiegeRecord.fortification

Command.relieveSiege(relieverId, targetRegionId)
  -> CommandValidator.validateRelieveSiege
  -> 解围军队必须属于原守方，目标州府必须己控且有活跃 SiegeRecord
  -> 解围军队可在目标州府内，或位于目标 display hex 的 range 距离内
  -> CommandExecutor.executeRelieveSiege
  -> 消耗该军队行动，按攻防、骑军/禁军、补给状态削减 SiegeRecord.pressure
  -> pressure 降为 0 时移除 SiegeRecord

Command.demandSurrender(negotiatorId, targetRegionId)
  -> CommandValidator.validateDemandSurrender
  -> 招降军队必须属于围城方，目标州府仍由原守方控制
  -> 招降军队必须在目标 display hex 的 range 距离内
  -> SiegeRecord.pressure >= 10，fortification == 0
  -> 目标州府内不能存在仍为 supplied 的守方军队
  -> CommandExecutor.executeDemandSurrender
  -> 移除目标州府内已断粮/被围的守方军队，交割可占 hex 给围城方
  -> 移除 SiegeRecord，消耗招降军队行动，并调用 StrategicStateSynchronizer 刷新派生层

SiegeRecord
  -> targetRegionId
  -> attackerFaction / defenderFaction
  -> startedTurn / lastUpdatedTurn
  -> pressure
  -> fortification / maxFortification
  -> besiegingDivisionIds

MapDisplayAdapter.siegeOverlays(viewerFaction)
  -> 从 GameState.siegeState.records 派生只读 SiegeOverlayState
  -> 只在观察者模式、相关攻守方或可见州府中显示
  -> BoardScene.drawSiegeOverlays 绘制围城 hex 描边、代表点圆环和“围 pressure / 城防”短标签

ZoneDirective.attack
  -> WarCommandExecutor.executeAttack
  -> 先尝试 WarCommandExecutor.demandSurrenderCommand
  -> 若目标 SiegeRecord 已满足招降条件，生成底层 Command.demandSurrender
  -> 若不能招降，再攻击可见敌军
  -> 若无可攻击敌军，且目标 region 是敌控城池 / 关隘 / 高 supplyValue 粮仓州府，则生成 Command.besiege
  -> Command.demandSurrender / Command.besiege 仍交给 RuleEngine / CommandValidator 最终校验执行
```

围城压力、城防损耗和解围不会直接改 `HexTile.controller`、`RegionNode.controller`、`hexToTheater` 或 `hexToFrontZone`，也不会删除敌军。招降首轮会改变目标州府内可占 hex 控制权，但它必须通过显式 `Command.demandSurrender -> CommandValidator -> CommandExecutor` 执行，并在交割后调用 `StrategicStateSynchronizer` 刷新 Region / Theater / FrontLine / WarDeployment；它不是结束回合自动破城，也不是外交归附系统。`SiegeRecord` 新增城防字段时使用 `decodeIfPresent` 兼容旧存档；旧围城记录缺少城防时按默认城防和既有 pressure 推导。

结束回合：

```text
SupplyRules.updateSupplyStates
CommandExecutor.applySiegeSupplyPressure
  -> 仍有有效围困军队、pressure >= 10 且 fortification == 0 时，被围州府内 supplied 守军降为 lowSupply
  -> fortification > 0 时，只记录城防尚存，断粮压力暂未突破
  -> 原守方失去控制或围困军队消失时解除 SiegeRecord
EconomyRules.resolveFactionTurn(for: activeFaction)
  -> 收入入账
  -> 支付战略补给维护费
  -> supplies 短缺时 supplied 单位降为 lowSupply
  -> 安全后方自动补员
  -> 推进生产队列并部署完成单位
SupplyRules.advanceRetreats
SupplyRules.applyEncirclementAttrition
VictoryRules.updateVictoryState
  -> 唐宋场景：优先读取 GameState.victoryConditions
     -> controlObjectives / holdObjectives 按 objective id、count、turn 和 mandateThreshold 判断
     -> majorVictory 映射为宋统一胜利，survival 映射为割据生存
     -> 条件缺失时 fallback 到 v5.6d 关键州府与天命阈值
  -> 非唐宋场景：沿用 Bastogne / St. Vith / 单位损失 / 装甲断补 legacy 条件
  -> HUD 和战报面板只读显示 VictoryState.reason，不反向改胜负
VictoryRules.objectiveProgress
  -> 只读派生胜利目标进度
  -> HUD / 战报显示州府、天命、回合门槛当前达成度
  -> 不写 VictoryState 或 eventLog
RootGameView.nextActionHint
  -> 只读派生唐宋首屏下一步提示
  -> HUD 显示选军、围城、招抚、解围、修城、结束回合等建议
  -> 不提交 Command，不写 GameState 或 eventLog
HUDView.objectiveGuideText
  -> 只读派生唐宋统一目标锚点
  -> 复用 VictoryRules.objectiveProgress + MapState.controllerOfObjective
  -> HUD 显示已据/待取关键州府
  -> 不改变 VictoryRules，不写 GameState 或 eventLog
HUDView.objectiveGuideItems
  -> 目标锚点按钮
  -> AppContainer.focusObjective(id:)
  -> 只更新 selectedHex / selectedRegionId
  -> 地图和 Region inspector 只读聚焦目标州府
MapDisplayAdapter.objectiveOverlays
  -> 复用 VictoryRules.objectiveProgress + MapState.objective
  -> BoardRenderState.focusedObjectiveId 可选强调当前 HUD 聚焦目标
  -> BoardScene.drawObjectiveOverlays
  -> 地图只读绘制已据/待取目标州府 spotlight
  -> 不提交 Command，不写 GameState 或 eventLog
EventLogView.turnReportSummary
  -> 只读读取 gameState.eventLog
  -> 额外读取最近 AgentDecisionRecord / WarDirectiveRecord
  -> 战报面板显示本回合或最近回合摘要
  -> 不写 GameState.eventLog，不改变规则或 AI 记录生成
EventLogView.settlementSummary
  -> 只读读取 VictoryState / VictoryRules.objectiveProgress / currentTurn
  -> 胜负后显示评分估算和短档位
  -> 不写 VictoryState，不写 eventLog，不改变 VictoryRules 判定
HUDView commandIdentity
  -> 只读读取 playerFaction / observerModeEnabled / activeFaction / phase
  -> 显示宋可下令、宋待命、观战各方、玩家亲征或只读观战
RootGameView player faction picker
  -> AppContainer.setPlayerFaction
  -> 同步 AppContainer.playerFaction / TurnOrderState.playerControlledPowerIds / legacy profile controlMode
  -> 清空当前选中军队与移动/攻击高亮，必要时继续 runAIIfNeeded
  -> 不新增真实多政权 schema，不绕过命令规则系统
DataLoader.initialTurnOrderState
  -> 唐宋路径读取 scenario.playerFaction / aiFaction
  -> 初始化 PowerProfile.controlMode 和 playerControlledPowerIds
  -> AppContainer 默认从 playerControlledPowerIds 推导初始亲征势力
RootGameView.nextActionHint
  -> 只读读取 movementHighlights.count / attackHighlights.count
  -> 提示当前可行军格和可攻击目标数量
  -> 不新增 CommandValidator dry-run，不替代真实规则校验
AppContainer.selectedValidatedCommandHint
  -> 对当前 UI 候选构造 Command
  -> 调用 CommandValidator.validate 做有限预校验
  -> HUD 下一步提示显示规则确认可执行项
  -> 不提交 Command，不调用 RuleEngine.execute，不写状态
UnitInspectorView / RegionInspectorView
  -> 唐宋场景读取 isTangSongScenario、GameState.displayName(for:) 和 MapDisplayAdapter 派生显示名
  -> 军队/州府检查面板显示唐宋字段、资源、兵种、围城摘要、运行态方面/防区名称和中文目标状态
  -> 不改底层 schema，不写 GameState，不参与命令执行
GeneralCommandPanelView / GeneralProfileView
  -> 唐宋场景读取 isTangSongScenario 与 GameState.displayName(for:)
  -> 将领军令/档案面板显示唐宋字段、政权名、用兵风格和计划摘要
  -> 不改 GeneralData / FrontZone / PlayerPlannedOperation schema，不改变 AI 或规则
NewGameButton
  -> RootGameView confirmationDialog
  -> 用户确认后调用 AppContainer.resetGame()
  -> resetGame 仍只重载初始剧本并清空 UI/交互态

TurnOrderState.advancedAfterEndTurn
  -> 按 powerOrder 推进 activePowerId
  -> 新 active power 的 controlMode 决定 legacy phase
  -> powerOrder 回到首位时 round += 1
  -> activePowerId 桥接回 legacy activeFaction

resetActionsForActiveFaction
StrategicStateBootstrapper.refreshRuntimeState
appendEvent("Turn advanced ...")
```

v5.1 后，`CommandValidator.phaseAllowsCommands`、`CommandExecutor.executeEndTurn`、`TurnManager.isAITurn` 和 `AppContainer.shouldRunAI` 都读取 `GameState.effectiveTurnOrderState`。`Faction.germany/allies` 和 `GamePhase.germanAI/alliedPlayer` 仍在，但不再是回合推进代码里的直接 switch 权威。

v5.3 唐宋粮道供给首轮仍复用现有 `SupplyState` 三态，不新增 schema：

```text
SupplyRules.effectiveSupplySources
  -> 非唐宋：MapState.supplySources(for:)
  -> 唐宋：MapState supply source + 己方控制且 supplyValue >= 4 的高补给州府/粮仓 region

SupplyRules.supplyPathCost
  -> 非唐宋：沿用 legacy max 7、road 1、mountain 3、default 2、river +2
  -> 唐宋：max 9；road 1；city/fortress 1；plain 2；forest/hill 3；mountain 4；river +2

SupplyRules.supplyRouteSummary
  -> 只读计算当前军队补给状态、补给源数量、最近粮源、可达路径成本/上限和安全退路数
  -> MapDisplayAdapter.unitInspectorState
  -> UnitInspectorView 显示“粮道 通/断、成本/上限、最近粮源、退路数”
  -> MapDisplayAdapter.supplyRouteOverlays(viewerFaction)
  -> BoardScene.drawSupplyRouteOverlays 绘制可见友方军队到最近可见粮源的抽象虚线

canSupplyPass / RegionSupplyRules
  -> 敌控判断改用 WarRelationRules.canTarget
  -> 不再依赖二元 Faction.opponent
```

这让唐宋路径下开封、洛阳、太原、扬州、金陵、成都、杭州等高 `supplyValue` 且己控的州府可作为粮仓源影响补给；缺粮、包围和围城效果仍通过既有 `lowSupply` / `encircled` 影响攻击、防御、移动和 attrition。单位面板已有粮道读法，地图已有只读抽象粮道虚线；完整漕运、粮草运输队、仓储容量、自动破城和逐 hex 粮道路径仍未实现。

---

## 6. AI / 战争指令流程

### 6.1 v0.5 默认元帅决策链

源码：`WWIIHexV0/Turn/TurnManager.swift`、`WWIIHexV0/Agents/ZoneCommanderAgent.swift`、`WWIIHexV0/Commands/WarDirective.swift`、`WWIIHexV0/Commands/WarCommandExecutor.swift`

v0.5 分支默认路径：

```text
AppContainer.runAIIfNeeded
  -> runAISequence
  -> TurnManager.runAITurn(... pipelineMode: .marshalDirective)
  -> MarshalAgent.resolve
  -> MarshalBattlefieldSummarizer.summary
  -> SimulatedMarshalLLMClient.completeTheaterDirectiveJSON
  -> TheaterDirectiveDecoder.parse
  -> TheaterDirectiveCompiler.compile
  -> DirectiveEnvelope / ZoneDirective
  -> WarCommandExecutor.execute(directive, in: state)
  -> RuleEngine.execute(Command)
  -> WarDirectiveRecord
  -> RuleEngine.execute(.endTurn)
```

`MarshalAgent` 是元帅层，不是单位，也不是新规则执行器。它只读取降维摘要并输出 `TheaterDirectiveEnvelope` JSON：

```text
TheaterDirectiveEnvelope
  schemaVersion = 5
  issuerId / turn / faction
  strategicIntent
  mandateIntent / courtPolicy
  pacificationTargets / supplyPriorities
  directives: [TheaterDirective]

TheaterDirective
  zoneId
  category offense/defense
  tactic
  priority
  targetTheaterId
  weightedRegions / focusRegionId / supportRegionIds
  reserveBias
  intensity / maxCommittedUnits / exploitDepth
  rationale
```

v5.4 起，`MarshalBattlefieldSummary` 额外携带 `scenarioId`、首都 region、被威胁首都、围城 region、粮道优先 region 和招抚候选 region。`GameAgent.defaultCommander` 在唐宋默认剧本下把 legacy `.allies` / `.germany` 桥接的默认 AI issuer 改为“宋枢密院”与“割据行营”，legacy 阿登才继续使用 Guderian / Allied Mock Commander；`MarshalAgentConfig.automatic` 也在唐宋默认剧本下把元帅配置显示为“宋枢密院”与“割据行营”。`SimulatedMarshalLLMClient` 会把 `strategicIntent`、envelope `summary` 和每条 `TheaterDirective.rationale` 写成军议、州府、粮道口径，并填充可选解释字段：

```text
mandateIntent        # 天命/正朔意图，只解释统一、护都、恢复州府或招抚方向
courtPolicy          # 中书枢密方针，只解释粮道、府库、攻守节奏
pacificationTargets  # 招抚候选州府 region id；v5.6c 起可尝试生成规则校验的归附提议
supplyPriorities     # 粮道优先支应 region id，不直接改变补给状态
```

这些字段进入 `TheaterDirectiveDecoder` 的 region 存在性校验；`TheaterDirectiveCompiler` 和 `WarCommandExecutor` 当前不读取它们。v5.4 起 `TurnManager` 会把字段复制成 `AgentDecisionRecord.theaterDirectiveSummary`，供 `AgentPanelView` 在唐宋场景只读显示“诏令 / 朝议 / 招抚 / 转运 / 摘要”。v5.8a 起，`AgentPanelView` 还会把默认主路径中的 issuer、provider、ruler、commander、zone、region targets、legacy order fallback 和 ruler posture 显示为唐宋读法，并通过 `RootGameView` 传入的运行态州府/防区名称减少 raw id 暴露；v5.8b 起，diagnostics、错误原文和 raw JSON 在唐宋路径进入玩家态/开发态分层；v5.8n 起，唐宋玩家态进一步对 AI 原始文本做兜底，含 Latin、JSON 痕迹、schema key 或旧英文 fallback 的 summary、intent、context、diagnostics、errors 和 raw JSON 只显示中文摘要或留存提示。这仍只是 UI 读法和调试分层，不改变 `AgentDecisionRecord` / `WarDirectiveRecord` raw 字段、JSON schema、compiler 或 executor。v5.6c 起，`pacificationTargets` 还会在 `TurnManager.executeDirectiveEnvelope` 中、战争 `ZoneDirective` 执行后和 `.endTurn` 前，尝试生成辅助 `Command.proposeSubmission`，再由 `RuleEngine -> CommandValidator -> CommandExecutor` 决定成功、拒绝或跳过；`mandateIntent`、`courtPolicy` 和 `supplyPriorities` 仍只作解释字段。非唐宋场景仍保持 legacy 英文元帅名和模拟 JSON 文案。该变化不改变 decoder 主校验、compiler 降级、WarCommandExecutor 战争语义或地图控制权。

`TheaterDirectiveDecoder` 负责从模拟 LLM 文本中提取 fenced JSON，使用 `JSONDecoder` 解码，并校验 schemaVersion、issuerId、turn、faction、zone 存在性、zone 阵营、region id、target theater/front zone 与 tactic/category 一致性。解码或校验失败时，不执行半成品 JSON，`MarshalAgent` fallback 到 `TheaterCommanderPool`。

`TheaterDirectiveCompiler` 把元帅意图降级到现有 `ZoneDirective`：

- offense -> `ZoneDirective.attack`，保留 target theater、weighted/focus/support regions、intensity、maxCommittedUnits、exploitDepth。
- defense -> `ZoneDirective.defend`，把 reserveBias 转成 targetReserves，把 focus/weighted regions 转成 strongpointRegionIds，把 supportRegionIds 转成 fallbackRegionIds。
- 某个 zone 没有元帅 directive 或编译失败时，使用 `TheaterCommanderPool` 给该 zone 的旧 directive。

最终执行由 `TurnManager.executeDirectiveEnvelope` 统一完成。`.marshalDirective` 和显式 `.zoneDirective` 共享同一段 WarCommandExecutor 执行、WarDirectiveRecord 记录、endTurn 推进逻辑。

统治者层是后续预留方向，当前 v0.5 主路径不调用 `RulerAgent`，也不在 `DirectiveEnvelope` 与执行层之间插入姿态塑形。

Legacy Agent D 仍存在，但只在显式 `.legacyAgentOrder` 分支运行：

```text
AgentContextBuilder
  -> DecisionProvider
  -> AgentDecisionParser
  -> AgentCommandMapper
  -> RuleEngine
```

默认不得把 Legacy 管线接回战争 AI 主路径。

v0.37 直接将军池路径仍可显式使用：

```text
TurnManager.runAITurn(... pipelineMode: .zoneDirective)
  -> TheaterCommanderPool.envelope
  -> ZoneCommanderAgent.makeDirective
  -> DirectiveEnvelope
  -> WarCommandExecutor
```

### 6.2 AI 触发条件

`AppContainer.shouldRunAI`：

```text
TurnOrderState.shouldRunAI
  -> activePowerId 对应 PowerProfile.controlMode == ai 时运行 AI
  -> observerModeEnabled 时，playerControlledPowerIds 也可由 AI 自动跑
  -> TurnManager.isAITurn 只检查当前 active power / phase 是否允许命令
```

`runAISequence`：

- 非 observer mode：最多跑 1 个 AI step。
- observer mode：最多跑 2 个 AI step，因此一次按钮推进可让当前 AI 阵营行动，若回合切到另一个 AI 控制阵营，也继续行动一次。

### 6.3 ZoneCommanderAgent 如何做决策

`TheaterCommanderPool` 会对当前 faction 的每个有 `frontSegments` 的 `FrontZone` 生成 directive。

每个 zone：

```text
visibleEnemyStrengthByRegion
friendlyFrontStrength
mobileFriendlyStrength
artillerySupportStrength
friendlyDepthStrength
pressure / supplyWarningCount
hasContestedForwardPresence
hasRecentStaticDefense
  -> BinaryTacticClassifier.classify
```

`BinaryTacticClassifier`：

```text
ratio = friendlyStrength / visibleEnemyStrength
如果 visibleEnemyStrength == 0，则 ratio = friendlyStrength
styleBoost:
  aggressive +0.15
  balanced 0
  cautious -0.15

shouldAttack =
  adjustedRatio >= attackThreshold(默认 1.2)
  或 hasContestedForwardPresence
  或 hasStaticDefense
```

分类结果：

- offense：
  - `blitzkrieg`：机动兵力占比高且 adjustedRatio >= 1.65。
  - `spearhead`：机动兵力可用，adjustedRatio >= 1.35，且有可见敌 region；用于定点矛头。
  - `breakthrough`：adjustedRatio >= 1.35，向弱点突破。
  - `fireCoverage`：炮兵/远程支援可用但优势不足，先火力覆盖。
  - `feint`：优势不足但需要牵制时少量佯攻。
  - `guerrillaWarfare`：机动兵力可用、敌 region 多、优势有限时袭扰纵深。
  - `standardAttack`：普通进攻 fallback。
- defense：
  - `lastStand`：极端劣势、无纵深预备队且压力高时死守。
  - `defenseInDepth`：有纵深预备队且压力/劣势明显时纵深防御。
  - `elasticDefense`：压力、补给警告或劣势时弹性防御。
  - `holdPosition`：普通防御 fallback。

`TacticConditionChecker` 不再恒放行：闪电战/游击战要求机动单位，火力覆盖要求炮兵或远程单位，佯攻要求前线单位，纵深防御要求 depth 预备队；不满足条件会降级为 `holdPosition`。

进攻 directive：

```text
ZoneDirective(
  zoneId,
  attack: AttackParameters(
    targetTheaterId,
    weightedRegions,
    intensity,
    focusRegionId,
    supportRegionIds,
    convergenceRegionId,
    coordinatedZoneIds,
    maxCommittedUnits,
    exploitDepth
  ),
  category: .offense,
  tactic: blitzkrieg / spearhead / breakthrough / pincerMovement / fireCoverage / feint / guerrillaWarfare / standardAttack,
  commandTarget: .region(focusRegionId) 或 .theater(target)
)
```

定点突破目标选择：

```text
priorityRegions =
  focusRegionId
  + commandTarget.region
  + convergenceRegionId
  + weightedRegions
  + supportRegionIds

若 tactic weakPointFocus:
  对候选 region 评分：
    enemyStrength 越低越优先
    terrain.movementCost 越低越优先
    region 内有 road 越优先
    city victoryPoints + supplyValue + factories + infrastructure 越高越优先
  最优 region 放到候选首位
```

钳形攻势数据层：

```text
pincerMovement 使用 convergenceRegionId + coordinatedZoneIds
每个 zone 仍各自编译成一条 ZoneDirective
执行器只推进本 zone 成功移动的具体 hex
会师/包围效果仍交给补给、前线、动态战区同步派生
```

防御 directive：

```text
ZoneDirective(
  zoneId,
  defense: DefenseParameters(
    targetReserves,
    stance,
    fallbackRegionIds,
    counterattackRegionIds,
    strongpointRegionIds,
    maxFrontCommitment
  ),
  category: .defense,
  tactic: holdPosition / elasticDefense / defenseInDepth / lastStand,
  commandTarget: .theater(self)
)
```

`AttackIntensity` 仍是参数字段；v0.7/v1.0 的真实分流主要由 `tactic` 决定。v1.0 已把 `.infiltration` 解释为默认低投入上限，但执行器不绕过 `RuleEngine` 给强度加直接伤害。

### 6.4 WarCommandExecutor 如何翻译指令

入口：

```swift
func execute(_ directive: ZoneDirective, in state: GameState) -> WarCommandExecutionResult
```

它不需要 `ZoneCommanderAgent` 实例，不需要 issuer。手写合法 `ZoneDirective` 可以直接执行，这是 v0.4 玩家命令 UI / 聊天命令要复用的后端能力。

执行路由：

```text
如果 directive.tactic 存在:
  standardAttack / blitzkrieg / spearhead / breakthrough / pincerMovement / fireCoverage / feint / guerrillaWarfare
    -> executeAttack(tactic)
  holdPosition / elasticDefense / defenseInDepth / lastStand
    -> executeDefense(tactic)
否则按 parameters:
  attack -> executeAttack
  defend -> executeDefense
```

防御翻译：

```text
zone 必须存在且有 frontSegments
lastStand:
  不保留 depth，全力 holdLine
elasticDefense:
  stance 强制 flexible，前线单位优先 allowRetreat
defenseInDepth:
  前线单位 allowRetreat
  保留 targetReserves 个 depth 预备队
  其余 depth 机动单位优先反击可见敌军，否则向 fallback/strongpoint region 移动
普通防御:
  unitIds = unitsFront + 部分 unitsDepth（保留 targetReserves）
对每个可行动单位:
  找 lightestFrontRegion
  如果单位已在该 region:
    holdLine -> .hold
    flexible -> .allowRetreat
  否则如果能找到 tacticalDestination:
    .move
  否则:
    hold / allowRetreat
  run(command, fallback: hold)
```

进攻翻译：

```text
zone 必须存在
targetZoneId = AttackParameters.targetTheaterId.rawValue
segments = 指向 targetZone 的 frontSegments，若为空则用全部 frontSegments

按 tactic 得到 AttackTacticProfile:
  blitzkrieg / spearhead:
    includeDepthUnits = true
    mobileOnlyWhenAvailable = true
    weakPointFocus = true
    holdNonCommittedFront = true
  breakthrough:
    includeDepthUnits = true
    weakPointFocus = true
  pincerMovement:
    includeDepthUnits = true
    mobileOnlyWhenAvailable = true
    convergenceRegionId 可作为深目标
  fireCoverage:
    artilleryFirst = true
    attackOnly = true；没有射程目标则 hold，不主动推进
  feint:
    只投入 maxCommittedUnits 或默认约 1/3 前线单位
  guerrillaWarfare:
    mobileOnlyWhenAvailable = true
    allowDeepTarget = true
    默认只投入约半数前线+纵深单位

attackingUnitIds =
  unitsFront
  + profile.includeDepthUnits ? unitsDepth : unitsFront 为空时 fallback unitsDepth
  -> 过滤可行动单位
  -> 需要时优先机动单位
  -> 按 artillery / mobile / attack / movement / strength 排序
  -> 应用 maxCommittedUnits

对每个可行动单位:
  targetEnemyRegion =
    focus / commandTarget.region / convergence / weighted / support 中仍相邻或允许深目标的 region
    或 front segment 相邻敌 region
    weakPointFocus 时用敌军强度、地形、道路、战略价值重排
  如果射程内有 visible enemy division:
    .attack
  否则如果 fireCoverage:
    .hold
  否则如果能找到 tacticalDestination:
    .move
  否则:
    .hold
  run(command, fallback: hold)
```

`run` 包装层会：

- 先记录 acting division 的 logical source zone。
- 调 `RuleEngine.execute(command, in: state)`。
- 如果被拒绝，写日志；如果原命令非法但 fallback hold 合法，则执行 fallback。
- 成功后做防御性同步：
  - 计算 affected region。
  - 尝试 `applyDirectiveOccupation`（通常普通 `CommandExecutor` 已处理过）。
  - 尝试 `applyStrategicAdvance`（确保 directive move 也推进 dynamic theater）。
  - `StrategicStateSynchronizer.synchronizeAfterOccupationChange`。
  - 记录 region owner change / front change event。

TurnManager 外层会为每条 directive 生成 `WarDirectiveRecord`：

```text
issuerId
turn
faction
zoneId
directiveType
targetRegionIds
commandResults
diagnostics
category
tactic
commanderAgentId
commandTarget
```

直接调用 `WarCommandExecutor.execute` 不会自动写 `WarDirectiveRecord`；记录职责在 `TurnManager.runDirectiveTurn` 外层。v5.4 起，唐宋场景的 `DirectiveType`、`CommandCategory` 和 `TacticName` 通过 `displayName(isTangSongScenario:)` 显示为军议口径，例如进军、固守、骑军突进、合围、弓弩压制和死守城关；simulated marshal raw JSON 的 `strategicIntent`、`summary` 与 `rationale` 也改用宋枢密院/割据行营、州府和粮道读法。`AgentDecisionRecord` 额外保存只读 `TheaterDirectiveExplanationSummary`，AI 面板用它展示诏令、朝议、招抚候选和粮道转运优先项。底层 raw case、Codable schema 和执行权限不变。

---

## 7. UI / 地图显示流程

### 7.1 BoardScene

源码：`WWIIHexV0/SpriteKit/BoardScene.swift`

绘制顺序：

```text
drawTiles
drawLayerOverlay
drawRegionOverlays（仅 hex layer）
drawRoads
drawRivers
drawSupplyRouteOverlays（唐宋场景；非 frontLine layer；只读抽象粮道虚线）
drawSiegeOverlays（非 frontLine layer）
drawPlannedOperations（非 frontLine layer）
drawUnits（frontLine layer 隐藏单位）
```

点击：

```text
touchesEnded
  -> layout.pixelToHex(point)
  -> state.map.contains(coord)
  -> onHexTapped(coord)
```

平移：

- 触摸移动 camera。
- `clampCamera` 限制在地图边界附近。

### 7.2 MapDisplayAdapter

源码：`WWIIHexV0/SpriteKit/MapDisplayAdapter.swift`

职责：

- hex -> region 查询。
- 视野判断。
- 单位显示位置/堆叠。
- 唐宋粮道 overlay state 派生：只显示普通玩家己方可见军队，observer/revealAll 才显示全阵营；粮源坐标也必须对 viewer 可见。
- Region inspector state。
- Unit inspector strategic state。
- Tang Song inspector display names：州府、动态方面、防区、粮源和目标状态的玩家可读名称。

Inspector 中关键字段：

```text
selectedHexController
selectedHexDynamicTheaterId
selectedHexDynamicTheaterName
selectedHexFrontZoneId
selectedHexFrontZoneName
theaterId = dominantDynamicTheaterId(region)
theaterName
frontZoneId = dominantDynamicFrontZoneId(region)
frontZoneName
frontPressure
friendlyDivisions
visibleEnemyDivisions
objectiveStatus = 唐宋“无目标 / 某政权控制”或 legacy 英文状态
```

单位 strategic state：

```text
coord
regionId
regionName
dynamicTheaterId
dynamicTheaterName
frontLineIds
frontZoneId
frontZoneName
deploymentRole
supplySourceName
```

### 7.3 MapDisplayLayer

源码：`WWIIHexV0/Core/MapDisplayLayer.swift`、`WWIIHexV0/SpriteKit/MapLayerOverlayCalculator.swift`、`WWIIHexV0/SpriteKit/MapLayerOverlayNode.swift`

当前 layer：

```text
hex
province
initialTheater
dynamicTheater
frontLine
deployment
```

`MapDisplayLayer.displayName(isTangSongScenario:)` 只提供显示桥，raw case 和存档/图层逻辑不变。唐宋主路径把 `province` 读作州府，把 `initialTheater` / `dynamicTheater` 读作初始方面 / 动态方面。

唐宋场景下 overlay 颜色来自 `MapLayerOverlayNode` 的 Tang Song strategic palette，覆盖朱印、青绿、石青、铜、玉、赭等多组颜色，避免州府/方面/部署图层读成单一米色或单一暗蓝。该 palette 只影响显示，不影响 bucket 归类、前线计算或部署归属。

bucket 来源：

| Layer | 数据来源 |
|---|---|
| `hex` | 每个 hex 自己 |
| `province` | `map.region(for: hex)` |
| `initialTheater` | `theaterState.initialSnapshot?.regionToTheater[regionId]` |
| `dynamicTheater` | `theaterState.dynamicTheaterId(for: hex, map:)` |
| `frontLine` | `frontLineState.regionStates[regionId].frontLines` |
| `deployment` | 该 hex 上单位的 `WarDeploymentManager.deploymentRole` |

前线 overlay 的线段来源：

```text
frontLineSegments()
  -> 遍历 FrontLine.segments
  -> friendlyBoundaryHexes(
       friendlyRegionId: segment.regionA,
       enemyRegionId: segment.regionB,
       friendlyTheaterId: frontLine.theaterId
     )
  -> 只取 friendly region 内、且 dynamicTheaterId == friendly theater 的 hex
  -> 这些 hex 必须邻接 enemy region 中另一个 dynamic theater 的 hex
  -> 用这些 friendly hex center 画线
```

这意味着前线视觉画在我方动态战区侧，不画敌我中间共用边，也不画初始 theater 边界。

`frontLineChains()` 会把相邻 hex 点串成拓扑链。不同 segment 起点有分隔符，多敌 theater 接触会加 dashed overlay。

---

## 8. 关键链路示例

### 8.1 玩家移动占领一个敌控空 hex

```text
玩家点击己方单位
  -> AppContainer.selectDivision
  -> MovementRules 生成 movementHighlights

玩家点击敌控空 hex
  -> AppContainer.submit(.move)
  -> RuleEngine.validate(move)
  -> CommandExecutor.executeMove
     - division.coord = destination
     - tile.controller = division.faction
     - TheaterSystem.expandDynamicTheater 只推进 destination hex
     - WarDeploymentManager.advanceHex 只推进 destination hex 的 FrontZone
     - StrategicStateSynchronizer
       - RegionOccupationRules 聚合 region controller
       - TheaterSystem.updateTheaters
       - FrontLineManager.update dirty region
       - WarDeploymentManager.update dirty region
  -> AppContainer.bootstrapIfNeeded
  -> UI 刷新 dynamic theater / front / deployment overlay
  -> 如果现在轮到 AI，则 runAIIfNeeded
```

不得发生：

- 不得把 destination 所在整个 region 的 `regionToTheater` 改成进攻方。
- 不得绕过 `OccupationRules.canOccupy`。
- 不得只改 region controller 而不改 hex controller。

### 8.2 AI 进攻一个前线 zone

```text
用户点下一回合 / AI faction active
  -> AppContainer.runAIIfNeeded
  -> StrategicStateBootstrapper.refreshRuntimeState
  -> TurnManager.runAITurn(.zoneDirective)
  -> TheaterCommanderPool 选出该 faction 有 frontSegments 的 FrontZone
  -> ZoneCommanderAgent 计算兵力比/可见敌军/前沿存在
  -> 生成 standardAttack ZoneDirective
  -> WarCommandExecutor.execute
     - 找 zone.unitsFront
     - 选 targetEnemyRegion
     - 能打则 attack，不能打则 move，不能 move 则 hold
     - 每个 command 都走 RuleEngine
     - 同步占领/动态战区/前线/部署
  -> TurnManager 写 WarDirectiveRecord
  -> RuleEngine.execute(.endTurn)
  -> AppContainer 写 lastAgentDecisionRecord / lastWarDirectiveRecords
```

AI 看到的前线单位池来自 `WarDeploymentState`。如果某单位没有进入 `unitsFront` / `unitsDepth`，该 zone 的 AI 就不会调度它。

### 8.3 地图编辑器改默认地图后进入游戏

```text
MapEditorGameResourceBridge.loadDefaultDocument
  -> 读现有 scenario + region JSON
  -> 用户编辑 hex / region / theater / unit
  -> overwriteDefaultGameResources
     - MapEditorExporter.export
       - 校验所有 hex 有 region
       - 从 hex 邻接推导 region neighbors / edges
       - 写 scenario JSON
       - 写 region JSON
     - 覆盖 WWIIHexV0/Data 默认资源

重新运行游戏 app
  -> DataLoader DEBUG 优先读源码 JSON
  -> loadGameState
  -> map / regions / theater initialSnapshot / front / deploy 全部重建
```

注意：已经启动的旧 simulator app 不会自动重新加载默认 JSON。

---

## 9. 调试断点与排查顺序

遇到“AI 不动、前线不对、地图不一致、占领不同步、拒绝率异常”时，按这条链查，不要直接改大块逻辑：

```text
1. 数据加载
   - DataLoader 是否读的是源码 JSON 还是旧 bundle？
   - ScenarioDefinition tiles / initialUnits 是否正确？
   - RegionDataSet.hexToRegion / regions[].theaterId 是否正确？
   - map.validateRegionGraph() 是否为空？

2. Hex 层
   - Division.coord 是否真的变化？
   - HexTile.controller 是否真的变化？
   - 目标 hex 是否被其他单位占据？
   - OccupationRules.canOccupy 是否允许？

3. Region 层
   - state.map.region(for: hex) 是否正确？
   - RegionOccupationRules.aggregateControl 后 region.controller 是否改变？
   - 是否出现权重并列导致 controller 不变？

4. Theater 层
   - initialSnapshot.regionToTheater 是否保持不变？
   - regionToTheater 是否被错误当成动态推进层？
   - hexToTheater[destination] 是否只改了目标 hex？
   - dynamicTheaterId(for:) 是否 fallback 到 regionToTheater 造成误读？

5. Front 层
   - FrontLineManager 是否扫描到真实相邻 hex？
   - fixture 是否只写了 Region.neighbors 但没有真实 hex 邻接？
   - split region 是否需要允许 regionA == regionB？
   - frontLineState.diagnostics.updatedRegionIds 是否包含目标 region？

6. Deploy 层
   - hexToFrontZone[destination] 是否更新？
   - regionToFrontZone 是否只是 dominant/fallback？
   - 单位为什么是 front/depth/garrison？
   - zone.unitsFront 是否包含应该行动的单位？

7. Directive 层
   - TheaterCommanderPool 是否为该 faction 生成 directive？
   - ZoneCommanderAgent 是否因为 zone.frontSegments 为空而返回 nil？
   - visibleEnemyStrength / friendlyFrontStrength 是否合理？
   - tactic/category 是否被记录？

8. Executor / RuleEngine 层
   - WarCommandExecutor.generatedCommands 是否为空？
   - CommandValidator 拒绝原因是什么？
   - fallback hold 是否执行？
   - WarDirectiveRecord.diagnostics 是否记录了拒绝？

9. UI 层
   - 当前 MapDisplayLayer 读的是 initial 还是 dynamic？
   - frontLine overlay 是否画在 friendlyBoundaryHexes？
   - observerMode 是否导致玩家不能选中行动单位？
```

---

## 10. 当前已知边界

- 真 LLM 尚未接入；当前只用 `SimulatedMarshalLLMClient` 模拟 fenced JSON 输出和解码流程，唐宋场景下仅做 deterministic 军议文案分支。
- 默认 AI 上游已是 `MarshalAgent -> TheaterDirectiveEnvelope -> TheaterDirectiveDecoder -> TheaterDirectiveCompiler`，下游执行必须是 `ZoneDirective -> WarCommandExecutor -> RuleEngine`。
- 元帅层不能直接输出底层 `Command`，不能直接修改地图、单位、hex controller 或动态战区权威。
- 统治者层只作为未来方向预留，当前 main 主链路不调用 `RulerAgent`。
- 外交、经济和 UI 已作为唐宋 v5.x 主线功能接入，但仍必须按模块边界维护，不能绕过 `Command` / `ZoneDirective -> WarCommandExecutor -> RuleEngine`。
- `AttackIntensity.infiltration` 已在 `WarCommandExecutor` 中解释为默认低投入上限；`.limitedCounter` 和 `.allOut` 仍主要依赖 tactic profile 与显式 `maxCommittedUnits`。
- `TacticConditionChecker` 当前总是允许现有战术。
- 战区互助接口 `requestSupport` / `getAvailableForces` / `notifyThreat` 有模型但没有主流程调用方。
- 攻击不会自动占领目标 hex，只有移动会占领。
- Legacy Agent D 管线仍保留，不应删除，也不应默认接回主战争 AI。
- `RegionCommand` / AgentOrder v2 仍可桥接到 hex command，但当前默认战争 AI 是 ZoneDirective。
- 地图编辑器的 theater assignment 是初始战区划分，不是运行时动态战区脚本。
- 历史回退的 Cabinet/Minister/StrategicDirective 管线仍不得恢复；v0.5 当前实现没有把内阁或部长塞进 `GameState`。

---

## 11. 轻量检查入口与历史回归参考

检查规范以 `md/test/test.md` 为准。当前默认不跑 Xcode / XCTest / 模拟器 / 性能类验证，只做轻量语法、格式和配置检查。

历史上这些回归曾用于守住核心语义，但现在只作只读参考，不作为每轮默认执行项：

- Probe：`WWIIHexV0Probes`
  - 数据启动、region graph、theater、frontline、deployment。
  - v0.358 动态 hex 战区推进。
  - v0.36 tactic/directive。
  - v0.37 手写 directive issuer-agnostic 执行。
- Dynamic Theater Regression：`WWIIHexV0Tests/Stage0355DynamicTheaterTests`
  - 守住 `regionToTheater` 不动态推进、`hexToTheater` 单 hex 推进、split region front、deployment split。
- MapEditor：`WWIIHexV0Tests/MapEditorOutputTests`
  - 守住编辑器输出与游戏加载一致、默认资源一致、视角一致、开局不自动 AI。
- Stage Regression：
  - Theater / FrontLine / WarDeployment / CommandSystem / Agent / Observer / LayeredMap。

默认允许的检查方向：

- 文档改动：尾随空白、旧测试口径残留、人工阅读一致性。
- JSON 改动：对改动文件运行 `jq empty`。
- Xcode project / scheme 改动：运行 `plutil -lint` 或 `xmllint --noout`。
- 少量 Swift 改动：仅在不会触发全项目构建时，对直接改动文件做单文件语法检查。

多分支或多子 Agent 并发后，即使不跑测试，也必须检查文件重叠、public API 分叉、数据 schema 分叉、Xcode project 冲突和文档口径冲突。未完成冲突检查前，不得声称候选分支可合并。

---

## 12. 历史兼容附录：v1.0 UI / AI / Playtest 收口记录

本节是历史分支收口记录，保留为 UI / AI / playtest 架构参考。当前协作制度以 `main` 直推和云端验证为准，不按该分支流推进。

该分支不改变战术权威和命令权威，只让当前主游戏更适合人工初版试玩和后续调参：

```text
GameState / WarDirectiveRecord / EventLog
  -> RootGameView
  -> HUD + Info tabs
  -> AgentPanelView 展示玩家态军议摘要 / 命令结果 / 方面军令，开发态折叠 raw JSON / diagnostics / errors
  -> EventLogView 展示最近 60 条分类日志

BoardScene
  -> 缓存 unit display hex
  -> 排序绘制单位
  -> deployment 图层复用 WarDeploymentManager 计算 role

Marshal / ZoneDirective
  -> AttackParameters.intensity
  -> WarCommandExecutor.attackTacticProfile
  -> infiltration 低投入上限
  -> RuleEngine 仍是唯一执行权威
```

算法变化：

- AI 面板从只展示 `AgentDecisionRecord` 扩展为同时展示 `WarDirectiveRecord`，每条 directive 可看到 zone、attack/defend、tactic、命令成功/拒绝数量和目标 region。v5.4 起，唐宋场景下该面板显示为“军议 / 诏令朝议 / 方面军令”，并使用唐宋战术显示名；其中诏令、朝议、招抚和转运来自元帅 envelope 的解释摘要，只读展示，不改变 `ZoneDirective -> WarCommandExecutor -> RuleEngine`。v5.8a 起，唐宋默认主路径的 AI 面板进一步把主事、来源、君主、将令、全局军令、防区、州府目标、legacy order type 和 ruler posture fallback 显示为唐宋读法；v5.8b 起，diagnostics、错误原文和 raw JSON 调试内容进入玩家态/开发态分层；v5.8n 起，玩家态对含 Latin、JSON 痕迹、schema key 或旧英文 fallback 的原始文本显示中文兜底，不把 raw 内容作为默认军议文案直出。
- 日志面板用 `LogDisplayEntry` 保存 entry + category，避免 body 内对同一条日志重复分类。
- 单位绘制先缓存 `unitDisplayHex` 再排序，避免 comparator 重复计算。
- `AttackIntensity.infiltration` 在无显式 `maxCommittedUnits` 时默认只投入约半数前线/纵深候选单位，避免渗透/袭扰全线压上。

试玩观察重点：

- UI：HUD、Info tabs、Economy、Diplomacy、AI panel 是否可读。
- 地图：hex/province/initial/dynamic/front/deploy 图层是否清晰。
- AI：raw JSON、zone directive、diagnostics 是否能解释 AI 回合。
- 规则：玩家和 AI 行动是否仍能追溯到 `CommandResultSummary` / `WarDirectiveRecord`。
- 性能体感：地图拖动、图层切换、日志面板滚动是否有明显卡顿。

历史限制：

- 未跑 Xcode / XCTest / 模拟器 / 性能测试。
- 若复用该段历史方案，仍需重新审查 `project.pbxproj`、Swift 新文件引用、AI schema 和文档版本口径。

---

## 13. 历史兼容附录：v0.4 将军养成、将军 UI 与玩家双轨命令

本节是历史分支记录，保留为将领 UI、微操锁和宏观军令设计参考。当前主线以唐宋 v5.x / `main` 为准，不再按 v0.4 分支合并流程推进。

该分支把 0.41-0.48 的将军与玩家命令链路收口到当前代码，仍保持命令权威不变：

```text
唐宋默认:
Data/tangsong_characters.json
  -> DataLoader.loadGeneralRegistry(for: jianlong_960_unification)
  -> TangSongCharacterDefinition.toGeneralData()
  -> GeneralRegistry / GeneralDispatcher

legacy 阿登:
Data/generals.json
  -> DataLoader.loadGeneralRegistry(for: legacy or nil)
  -> GeneralRegistry / GeneralDispatcher
  -> FrontZone.generalAssignment
  -> AppContainer.selectedGeneral*
  -> GeneralCommandPanelView / GeneralProfileView

玩家微操单位
  -> AppContainer.submit(Command)
  -> RuleEngine
  -> PlayerCommandState.micromanagedDivisionIds
  -> WarCommandExecutor.execute(... excluding: lockedIds)

玩家宏观将军命令
  -> GeneralCommandPanelView 按钮
  -> AppContainer 组装 ZoneDirective
  -> WarCommandExecutor
  -> RuleEngine
  -> WarDirectiveRecord + PlayerPlannedOperation
  -> BoardScene 计划线 / 金色微操单位圈
```

核心算法：

- 将军数据：`GeneralData` 从 `generals.json` 读取，包含阵营、军衔、倾向、技能、头像占位、履历、偏好 theater/region、忠诚和满意度基线。
- 初始分配：`RegionNodeDefinition.assignedGeneralId` 可由地图 JSON / MapEditor 写入。`DataLoader` 在生成 `WarDeploymentState` 后收集 region 种子，调用 `GeneralDispatcher.assignGenerals`。
- 指派规则：
  1. 如果 FrontZone 已有合法同阵营 `generalAssignment`，保留该将军，只刷新 `assignedDivisionIds`。
  2. 否则优先使用该 zone 下 region 的 `assignedGeneralId`。
  3. 再按将军 `preferredTheaterIds` / `preferredRegionIds` 匹配。
  4. 最后从同阵营未占用将军池取第一名；没有可用将军时安全空岗。
- HQ 逻辑：不生成占格子的 HQ 单位。`GeneralAssignment.hqRegionId` 指向战区内友方城市或最大 region，`GeneralDispatcher.isHQUnderAttack` 通过 region controller 判断 HQ 是否被夺。
- 将军养成初步：`GeneralAssignment` 保存 `loyalty`、`satisfaction`、`interventionCount`。玩家直接微操某个将军辖下单位时，记录干预次数并轻微降低满意度。
- 微操锁：玩家在己方 phase 对具体师执行 move/attack/hold/resupply/allowRetreat 后，该师 id 写入 `PlayerCommandState.micromanagedDivisionIds`。本回合玩家再下达战区宏观命令时，`WarCommandExecutor.execute(... excluding:)` 会跳过这些师，避免同一回合被将军指令覆盖。`endTurn` 或 active faction / turn 改变时清空锁。
- 半自动指令：`GeneralCommandPanelView` 的 `Hold Line` 生成 defense `ZoneDirective`，`Attack Region` 根据当前选中敌方 region 和相邻玩家 FrontZone 生成 attack `ZoneDirective`，直接复用 `WarCommandExecutor -> RuleEngine`，不通过 `TurnManager.runDirectiveTurn`，因此不会自动结束玩家回合。
- 记录与反馈：玩家宏观命令写入 `WarDirectiveRecord` 和 `PlayerPlannedOperation`。`BoardScene` 只读 `PlayerCommandState.plannedOperations`，画源 region 到目标 region 的箭头；防御命令画源点圆环。玩家微操锁定单位在 `UnitNode` 上显示金色底圈。
- UI：`RootGameView` 新增 `General` tab，Unit tab 也嵌入 `GeneralCommandPanelView`。`GeneralProfileView` 用 sheet 展示将军身份、履历、技能、忠诚/满意度、干预次数、HQ 状态和辖下部队。

边界：

- v0.4 不让将军或 UI 直接修改 `GameState` 战术权威；所有行动仍要走 `Command` / `ZoneDirective -> WarCommandExecutor -> RuleEngine`。
- v0.4 没有实现真正抗命、政变、完整 RPG 成长树或真实 LLM 聊天解析；当前是忠诚/满意度和干预次数的可视化与数据底座。
- v0.4 没有做自由手绘前线。采用 region 锚点法：选择战区/目标 region 后自动画箭头，符合 0.44 文档中的移动端妥协方案。
- 若后续复用旧分支方案，必须重新做文件/API/schema/project 冲突审查，不能假定历史分支可直接并入当前 main。

---

## 14. 云端协作与 main 直推验证

本节记录项目协作制度，不改变游戏业务逻辑。当前默认流程固定为 `main` 直推和 GitHub Actions 云端重验证：

```text
人工提出目标
  -> Agent A 读取入口文档、源码和当前 main，写阶段提示词
  -> Agent B 同步 origin/main，在 main 上小步实现
  -> Agent B 本地只跑轻量检查
  -> Agent B commit 并 push 到 origin/main
  -> GitHub Actions 运行静态检查和 Xcode build
  -> GitHub Actions 上传未加密 ci-results artifact
  -> Agent C 用 gh auth login 后下载结果包
  -> Agent C 核对 manifest / JUnit / xcodebuild.log / failure summary
      -> 失败：退回 Agent B 在 main 上追加修复 commit
      -> 通过：Agent C 记录验收并按需更新核心文档
```

### 14.1 角色召唤

- `agenta`、`a:` 或 `A:`：召唤 Agent A；最终回复第一行写 `我是 Agent A。`
- `agentb`、`b:` 或 `B:`：召唤 Agent B；最终回复第一行写 `我是 Agent B。`
- `agentc`、`c:` 或 `C:`：召唤 Agent C；最终回复第一行写 `我是 Agent C。`
- 没有前缀时按普通 Codex 任务处理。

### 14.2 main 直推边界

- `main` 是唯一上传、提交、推送和云端验证分支。
- 默认不使用 `smalldata_test`、`develop`、`codeb/...`、候选分支或 PR 合并流。
- Agent B 每轮开始前必须：

```sh
git fetch origin
git switch main
git pull --ff-only origin main
git status --short
```

- `git push origin main` 前必须确认当前分支是 `main`、目标远端是 `origin/main`、提交范围只包含本轮相关文件。
- Agent C 发现问题时，不回滚远端 main；默认退回 Agent B 在 `main` 上追加修复 commit。

### 14.3 云端结果包

workflow：`.github/workflows/ci-results.yml`

触发：

- `push` 到 `main`
- `workflow_dispatch`

云端执行：

- `git diff --check`
- `plutil -lint WWIIHexV0.xcodeproj/project.pbxproj`
- `xmllint --noout` 检查共享 scheme
- `xcodebuild build`，使用 `WWIIHexV0.xcodeproj` / `WWIIHexV0` / `Debug` / `generic/platform=iOS` / `CODE_SIGNING_ALLOWED=NO`

未加密结果包至少包含：

- `ci-artifact-manifest.json`
- `ci-failure-summary.md`
- `junit.xml`
- `static-checks.log`
- `xcodebuild.log`
- `WWIIHexV0.xcresult`，如果 Xcode 生成 result bundle
- `artifact-name.txt`

manifest 必须记录 `branch`、`commitSha`、`shortSha`、`runId`、`runAttempt`、`workflowName`、`projectName`、`scheme`、`destination`、`resultBundlePath`、`junitPath`、`buildLogPath`、`failureSummaryPath`、`staticChecksOutcome`、`buildOutcome` 和 `testOutcome`。

### 14.4 Agent C 验收入口

Agent C 必须先确保 GitHub CLI 有权限：

```sh
gh auth login
```

下载缓存默认：

```text
/private/tmp/wwiihexv0-c-review-<run_id>/
```

验收时必须核对：

- `origin/main` 最新 commit 与 manifest 的 `commitSha` 一致。
- 当前 run id / run attempt 与 manifest 的 `runId` / `runAttempt` 一致。
- `branch` 是 `main`。
- `junit.xml`、`xcodebuild.log`、`ci-failure-summary.md` 已读取。
- artifact 是本轮 workflow 新生成结果，不是旧 artifact、旧 output 或 checkout 里的历史报告。

### 14.5 与 AITRANS 的取舍

本项目只复用 AITRANS 的协作制度骨架：云端验证、未加密结果包、Agent C 下载复判、失败后在 main 追加修复 commit。不会照搬 AITRANS 的漫画探针、GGUF、模型 Release、`test/1.png`、`smalldata_test` 或其他项目特例。

# WWIIHexV0 Mermaid 核心流程图

> 本图参照 `md/flow/flow.md`。每个图块都用“中文解释 + 关键代码名”标注：先看中文理解逻辑，再用代码名回到源码定位。

## 0. 读图总纲

项目当前最重要的逻辑是：

```text
地图编辑器/JSON 数据
  -> 游戏启动加载为 GameState
  -> hex 是真实战术权威
  -> region / theater / front / deploy 都是从 hex 和单位位置派生出来的战略层
  -> economy 是 faction 级经济总账，收入仍从真实控制的 hex/region 聚合
  -> diplomacy / mandate 是国家级投影和展示来源，不替代战术敌我或控制权；唐宋胜利评价会读取天命
  -> turn order / power profile 是 v5.1 多势力回合桥
  -> v5.6f 起 UI/AI/WarCommandExecutor 的战术候选也读取 WarRelationRules.canTarget
  -> v5.6g 起唐宋胜利评价优先读取场景 JSON victoryConditions
  -> v5.6h 起 HUD/战报只读显示 VictoryState.reason
  -> v5.6i 起 HUD/战报只读显示 VictoryRules.objectiveProgress
  -> v5.7a 起 HUD 只读显示 RootGameView.nextActionHint
  -> v5.7b 起 HUD 只读显示统一目标已据/待取锚点
  -> v5.7c 起 HUD 目标锚点可只读聚焦目标州府
  -> v5.7d 起地图只读绘制目标州府 spotlight
  -> v5.7e 起战报面板只读汇总每回合战报摘要
  -> v5.7f 起 HUD 只读显示指挥身份/观战模式并确认重开剧本
  -> v5.7g 起下一步提示只读读取移动/攻击高亮数量
  -> v5.7h 起唐宋主界面可切换 legacy 亲征阵营与观战模式
  -> v5.7i 起战报面板只读显示胜负后评分估算与短档位
  -> v5.7j 起下一步提示对当前 UI 候选做有限合法性预校验
  -> v5.7k 起军队/州府检查面板补齐唐宋读法
  -> v5.7l 起将领指挥/档案面板补齐唐宋读法
  -> v5.7m 起常驻军队 tooltip 补齐唐宋读法
  -> v5.8a 起 AI 面板默认主路径残留硬化
  -> v5.8b 起 AI 面板玩家态/开发态分层
  -> v5.8c 起外交面板默认主路径读法硬化
  -> v5.8d 起战报日志默认主路径读法硬化
  -> v5.8e 起 MapEditor 默认资源和可见读法硬化
  -> v5.8g 起主游戏默认启动不再静默回退阿登
  -> v5.8h 起唐宋将领注册表默认读取 tangsong_characters
  -> v5.8i 起命令反馈与战报元数据隐藏 raw validation / record id
  -> v5.8j 起军队/州府检查面板隐藏 raw id 与英文目标状态
  -> v5.8k 起命令面板和战报 raw 英文兜底不直出玩家
  -> v5.8l 起将领计划摘要和固定英文 UI 继续硬化
  -> v5.8m 起外交面板 Latin 名称与 ASCII 连接符继续硬化
  -> v5.8n 起 AI 面板原始文本与 Latin 兜底继续硬化
  -> v5.8o 起将领/州府面板固定英文与 ASCII UI 继续硬化
  -> v5.8p 起兵力、粮道与地图数值标记 ASCII UI 继续硬化
  -> v5.8q 起 AppContainer 常见交互反馈写入端继续中文化
  -> v5.8r 起胜利、粮道与军议摘要显示继续硬化
  -> v5.8s 起 MapEditor raw 文件名、坐标、JSON 技术词与导出错误继续硬化
  -> v5.8t 起 accessibility label/value/hint 与 MapEditor 画布可读文案继续硬化
  -> v5.8u 起军令、府库、亲征观战和目标锚点控件状态提示继续硬化
  -> v5.8v 起 MapEditor raw 错误、示例输入和编辑框读屏上下文继续硬化
  -> v5.8w 起主棋盘 VoiceOver 自定义动作继续硬化，读屏动作仍复用 handleBoardTap 与规则链路
  -> v5.8x 起地图图层、紧凑面板、将领军令按钮和面板 fallback 继续硬化
  -> v5.8y 起常驻 tooltip 与军队/州府检查面板读法继续硬化
  -> v5.8z 起将领档案关闭、指标、技能、辖下军队和缺名 fallback 继续硬化
  -> v5.8aa 起 MapEditor 画布 value、底图控件和快捷说明继续硬化
  -> v5.8ab 起 MapEditor 画布粮源与军队符号继续硬化
  -> v5.8ac 起军议与方面军令反馈继续硬化
  -> v5.8ad 起府库军备队列剩余回合、收入指标和读屏语义继续硬化
  -> v5.8ae 起 HUD 库存指标、军备队列数量和指标行读屏继续硬化
  -> v5.8af 起将领军令面板指标、所属军队和已拟军令读屏继续硬化
  -> v5.8ag 起战报列表行分类、元数据和正文整行读屏继续硬化
  -> v5.8ah 起战报摘要卡片标题、回合、汇总和重点条目读屏继续硬化
  -> v0.5 元帅层是战略意图层，不替代战术权威
  -> 玩家和 AI 都必须把命令交给 RuleEngine
  -> 命令执行后再同步刷新战略层和 UI
```

图里颜色含义：

- 红色：权威状态，不能被下游反向覆盖。
- 绿色：派生状态，可以重建，但来源必须清楚。
- 蓝色：初始快照/基准状态，不是运行时推进状态。
- 紫色：命令管线，玩家、AI、未来聊天命令都要走这里。

## 1. 总主线：从地图数据到游戏行动

这张图看全局。左上是地图数据怎么进入游戏；中间是 hex、region、theater、front、deploy 的分层关系；右侧是玩家/AI 命令如何统一进入规则系统；底部是 UI 和日志怎么读取结果。

```mermaid
flowchart TD
    ME["地图编辑器<br/>MapEditor<br/>用来画地块、州府、方面、初始军队"]:::editor
    JSON["游戏数据 JSON<br/>ScenarioDefinition + RegionDataSet<br/>保存地图、单位、州府、初始方面、胜利条件"]:::data
    DL["数据加载器<br/>DataLoader.loadGameState<br/>把 JSON 变成可运行 GameState"]:::loader
    GS["运行时总状态<br/>GameState<br/>一局游戏所有状态都在这里"]:::state

    HEX["战术权威：六角格和单位位置<br/>HexTile.controller + Division.coord<br/>谁占哪个格、单位在哪，先看这里"]:::authority
    REGION["州府战略层<br/>RegionNode<br/>资源、补给、胜利点；控制权由 hex 聚合"]:::derived
    INIT["开局方面快照<br/>TheaterInitialSnapshot<br/>记录地图编辑器给的初始方面"]:::snapshot
    R2T["基础战区映射<br/>regionToTheater<br/>只作初始/基准，不表示战线推进"]:::snapshot
    H2T["动态战区权威<br/>hexToTheater<br/>运行时推进只改具体 hex"]:::authority
    FRONT["前线层<br/>FrontLine / FrontSegment<br/>按双方动态战区的真实相邻 hex 生成"]:::derived
    DEPLOY["部署层<br/>WarDeploymentState<br/>用 hexToFrontZone 把单位分成前线/纵深/驻军"]:::derived
    ECO["经济总账<br/>EconomyState / EconomyRules<br/>收入、维护费、生产队列、自动补员"]:::economy
    DIP["外交与天命<br/>DiplomacyState + MandateState<br/>国家关系、归附记录、天命分数"]:::state
    TURN["回合与势力桥<br/>TurnOrderState / PowerProfile<br/>power order、active power、控制模式、关系表"]:::state
    RELCAND["战术敌我候选<br/>WarRelationRules.canTarget<br/>UI 高亮、AI 敌区、执行器候选先读关系表"]:::rules
    VICT["胜负规则<br/>VictoryRules.updateVictoryState<br/>唐宋优先读取 victoryConditions 与天命；缺失时 fallback；非唐宋沿用阿登条件"]:::rules
    VICTEXT["胜负说明、目标进度与评分估算<br/>VictoryState.reason + VictoryRules.objectiveProgress<br/>HUD/战报只读显示原因、门槛和估算评分"]:::ui
    HINT["下一步提示<br/>RootGameView.nextActionHint + AppContainer.selectedValidatedCommandHint<br/>只读派生选军、候选命令、移动/攻击数量与有限合法性预校验"]:::ui
    INSPECT["检查面板读法<br/>MapDisplayAdapter + UnitInspectorView + RegionInspectorView<br/>唐宋场景显示军队、州府、政权、粮道、编成、产出、围城摘要和运行态方面/防区名称"]:::ui
    GENPANELS["将领面板读法<br/>GeneralCommandPanelView + GeneralProfileView<br/>唐宋场景显示将领军令、档案、用兵、所属政权、辖下军队和 planned operation 目标名称"]:::ui
    TOOLTIP["常驻军队提示<br/>UnitTooltipView<br/>唐宋场景显示兵种、兵力、补给、退却和本回合"]:::ui
    AIPANEL["AI 面板玩家态/开发态分层<br/>AgentPanelView + AgentDecisionRecord + WarDirectiveRecord<br/>玩家态显示军议摘要、方面军令和失败摘要<br/>唐宋 raw/Latin 文本使用中文兜底"]:::ui
    DIPPANEL["外交面板读法硬化<br/>DiplomacyPanelView + DiplomacyState + MandateState<br/>唐宋默认路径显示天命、诸国、关系和归附读法<br/>Latin 国家/集团名与 ASCII 连接符有中文兜底"]:::ui
    GOAL["统一目标锚点<br/>HUDView.objectiveGuideText<br/>按 objective 控制方只读显示已据/待取关键州府"]:::ui
    FOCUS["目标聚焦<br/>AppContainer.focusObjective<br/>只更新 selectedHex / selectedRegionId"]:::ui
    SPOTLIGHT["目标州府 spotlight<br/>MapDisplayAdapter.objectiveOverlays + BoardScene<br/>只读绘制已据/待取目标"]:::ui
    TURNREPORT["战报读法、每回合摘要与读屏<br/>EventLogView + TangSongEventLogMessage<br/>只读汇总并显示 eventLog / AI 军议 / 方面军令<br/>唐宋兜底不直出 raw 英文；列表行和摘要卡片合并读屏"]:::ui
    BOARDVO["主棋盘读屏动作<br/>RootGameView + BoardSceneView accessibility actions<br/>攻击/行军动作复用 handleBoardTap，仍经命令与规则链路"]:::ui
    MAPEDITORUI["地图编辑器读法硬化<br/>MapEditorView + MapEditorExporter + MapEditorGameResourceBridge<br/>默认唐宋资源、中文错误、中文导出说明和军队标签"]:::ui
    SESSIONHUD["指挥身份 / 重开剧本<br/>HUDView + NewGameButton<br/>只读显示模式，确认后 resetGame"]:::ui
    PLAYER["玩家输入<br/>点击地图、移动、攻击、招抚、结束回合"]:::input
    AI["AI 元帅系统<br/>MarshalAgent + TheaterDirective JSON<br/>先做大战役级规划"]:::input
    DEC["元帅 JSON 解码<br/>TheaterDirectiveDecoder<br/>提取 fenced JSON、校验 id 与 schema"]:::command
    COMP["元帅意图编译<br/>TheaterDirectiveCompiler<br/>把 TheaterDirective 降级成 ZoneDirective"]:::command
    AIPAC["AI 招抚辅助命令<br/>pacificationTargets -> Command.proposeSubmission<br/>只提议，仍由规则层决定成败"]:::command
    ZD["战争指令<br/>ZoneDirective<br/>方面级 attack/defend 意图"]:::command
    WCE["指令翻译器<br/>WarCommandExecutor<br/>把方面意图翻成具体单位命令"]:::command
    CMD["底层命令<br/>Command<br/>move / attack / besiege / demandSurrender / proposeSubmission / endTurn"]:::command
    RE["规则引擎<br/>RuleEngine<br/>先校验，再真正修改 GameState<br/>唐宋拒绝原因显示中文 validation 名称"]:::rules
    SYNC["战略同步器<br/>StrategicStateSynchronizer<br/>占领后刷新州府、方面、前线、部署"]:::rules

    UI["地图和面板显示<br/>SpriteKit / SwiftUI Overlay<br/>显示 hex、州府、初始方面、动态战区、前线、部署"]:::ui
    LOG["日志和复盘记录<br/>EventLog / WarDirectiveRecord / AgentDecisionRecord / RulerDecisionRecord<br/>用于 UI 展示和后续调试"]:::ui

    ME --> JSON --> DL --> GS
    GS --> HEX
    HEX --> REGION
    HEX --> ECO
    REGION --> ECO
    REGION --> INIT
    INIT --> R2T
    R2T -.->|缺失时只用来补初始值| H2T
    HEX --> H2T
    H2T --> FRONT --> DEPLOY
    GS --> ECO
    GS --> DIP
    GS --> TURN
    DIP -->|v5.6e 保守投影| TURN
    TURN -->|v5.6f 候选过滤| RELCAND
    JSON -->|v5.6g victoryConditions| VICT

    TURN --> PLAYER
    TURN --> AI
    RELCAND --> PLAYER
    RELCAND --> AI
    RELCAND --> WCE
    PLAYER --> CMD
    AI --> DEC --> COMP --> ZD --> WCE --> CMD
    AI --> AIPAC --> CMD
    CMD --> RE --> HEX
    RE --> ECO
    RE --> DIP
    RE --> VICT
    RE --> SYNC
    HEX --> VICT
    DIP --> VICT
    SYNC --> REGION
    SYNC --> H2T
    SYNC --> FRONT
    SYNC --> DEPLOY

    GS --> UI
    GS --> HINT --> UI
    GS --> INSPECT --> UI
    GS --> GENPANELS --> UI
    GS --> TOOLTIP --> UI
    GS --> BOARDVO --> PLAYER
    GS --> SESSIONHUD --> UI
    VICTEXT --> GOAL --> FOCUS --> UI
    VICTEXT --> SPOTLIGHT --> UI
    LOG --> TURNREPORT --> UI
    LOG --> AIPANEL --> UI
    ME --> MAPEDITORUI --> JSON
    HEX --> UI
    REGION --> UI
    INIT --> UI
    H2T --> UI
    FRONT --> UI
    DEPLOY --> UI
    ECO --> UI
    DIP --> DIPPANEL --> UI
    VICT --> VICTEXT --> UI
    RE --> LOG
    VICT --> LOG
    WCE --> LOG

    classDef editor fill:#f6d365,stroke:#8a5a00,color:#1f1b10
    classDef data fill:#f8f9fb,stroke:#6b7280,color:#111827
    classDef loader fill:#dbeafe,stroke:#2563eb,color:#0f172a
    classDef state fill:#ede9fe,stroke:#7c3aed,color:#1f143d
    classDef authority fill:#fee2e2,stroke:#dc2626,color:#111827
    classDef derived fill:#dcfce7,stroke:#16a34a,color:#052e16
    classDef snapshot fill:#e0f2fe,stroke:#0284c7,color:#082f49
    classDef input fill:#fef3c7,stroke:#d97706,color:#1f1600
    classDef economy fill:#fef9c3,stroke:#ca8a04,color:#292107
    classDef command fill:#fae8ff,stroke:#a21caf,color:#2a0a2f
    classDef rules fill:#ccfbf1,stroke:#0f766e,color:#042f2e
    classDef ui fill:#e5e7eb,stroke:#4b5563,color:#111827
```

## 2. 占领与动态推进：一个单位移动后发生什么

这张图只看最容易出 bug 的链路：单位移动到敌控空格后，游戏如何占领这个 hex，并且只推进这个 hex 的动态战区和部署归属。

核心原则：占一个 hex，只改这个 hex 的 `hexToTheater` / `hexToFrontZone`；不能把整个 region 的 `regionToTheater` 改掉。

```mermaid
flowchart TD
    A["移动命令进入<br/>Command.move<br/>来源可以是玩家，也可以是 WarCommandExecutor"]:::command
    B["移动合法性检查<br/>CommandValidator.validateMove<br/>检查阶段、阵营、行动力、路径、目标是否被占"]:::rules
    C{"移动是否合法?"}:::decision
    R["命令被拒绝<br/>CommandResult rejected<br/>GameState 不变，只记录拒绝原因"]:::stop
    M["执行移动<br/>CommandExecutor.executeMove<br/>更新单位坐标、朝向、已行动标记"]:::rules
    O{"能否占领目标 hex?<br/>OccupationRules.canOccupy<br/>目标可占、非己方控制、没有其他单位"}:::decision
    NO["普通移动<br/>只改变单位位置<br/>不改变目标 hex 控制权"]:::state
    HC["改写真实占领权<br/>HexTile.controller = division.faction<br/>这是占领的权威来源"]:::authority
    SA{"是否需要推进动态战区?<br/>目标属于敌方 zone 或仍是敌控 hex 时才推进"}:::decision
    ET["推进动态战区<br/>TheaterSystem.expandDynamicTheater<br/>只把目标 hex 写入进攻方 hexToTheater"]:::authority
    AF["推进部署归属<br/>WarDeploymentManager.advanceHex<br/>只把目标 hex 写入进攻方 hexToFrontZone"]:::authority
    SS["占领后同步战略层<br/>StrategicStateSynchronizer<br/>把 hex 变化传导到 region/theater/front/deploy"]:::rules
    RO["刷新省份控制权<br/>RegionOccupationRules.aggregateControl<br/>按 region 内 hex 控制权加权计算"]:::derived
    TU["刷新动态战区摘要<br/>TheaterSystem.updateTheaters(force)<br/>重算控制比例、战区邻接、单位池"]:::derived
    FU["刷新前线<br/>FrontLineManager.update<br/>重新扫描动态战区之间的真实 hex 接触"]:::derived
    DU["刷新部署层<br/>WarDeploymentManager.update<br/>重分前线、纵深、驻军单位"]:::derived
    UI["刷新显示和日志<br/>UI overlay / inspector / EventLog<br/>玩家看到地图颜色、前线和面板变化"]:::ui

    A --> B --> C
    C -->|否| R
    C -->|是| M --> O
    O -->|否| NO --> UI
    O -->|是| HC --> SA
    SA -->|目标已经是己方动态战区| SS
    SA -->|目标仍属敌方动态战区| ET --> AF --> SS
    SS --> RO --> TU --> FU --> DU --> UI

    WARN1["绝对不要这样做<br/>占一个 hex 就把整个 regionToTheater 改掉<br/>会导致前线跳到敌军身后"]:::warn
    WARN2["也不要这样做<br/>只改 Region.controller<br/>却不改 HexTile.controller<br/>会破坏玩家/AI 对称性"]:::warn
    ET -.守住.-> WARN1
    HC -.守住.-> WARN2

    classDef command fill:#fae8ff,stroke:#a21caf,color:#2a0a2f
    classDef rules fill:#ccfbf1,stroke:#0f766e,color:#042f2e
    classDef decision fill:#fff7ed,stroke:#ea580c,color:#1f1300
    classDef stop fill:#fee2e2,stroke:#b91c1c,color:#111827
    classDef state fill:#ede9fe,stroke:#7c3aed,color:#1f143d
    classDef authority fill:#fee2e2,stroke:#dc2626,color:#111827
    classDef derived fill:#dcfce7,stroke:#16a34a,color:#052e16
    classDef ui fill:#e5e7eb,stroke:#4b5563,color:#111827
    classDef warn fill:#ffedd5,stroke:#f97316,color:#431407
```

## 3. v0.8 经济、生产与补员链路

这张图看 v0.8 初级经济。经济总账是 faction 级资源池，但收入和部署资格仍回到真实 hex 控制和 region 聚合；生产命令仍走 `RuleEngine`，UI 不直接改 `GameState`。

```mermaid
flowchart TD
    BOOT["经济启动补账<br/>EconomyRules.bootstrapIfNeeded<br/>旧状态缺 economyState 时从地图推导账本"]:::economy
    HEX["真实控制权<br/>HexTile.controller<br/>经济收入必须有己方控制 hex 证据"]:::authority
    REGION["战略聚合<br/>RegionNode<br/>city / factories / infrastructure / supplyValue"]:::derived
    INCOME["收入计算<br/>EconomyRules.income<br/>manpower / industry / supplies<br/>唐宋显示为丁口 / 钱帛 / 粮草"]:::economy
    LEDGER["政权府库总账<br/>FactionEconomyLedger<br/>库存、上回合收入、维护费、补员消耗、队列"]:::economy

    UI["府库面板<br/>EconomyPanelView<br/>展示资源、军备按钮、队列剩余回合和读屏语义"]:::ui
    QUEUE["生产命令<br/>Command.queueProduction<br/>玩家/未来 AI 共用底层命令"]:::command
    VALIDATE["生产校验<br/>CommandValidator.validateProduction<br/>检查 phase 与资源是否足够"]:::rules
    PAY["预付成本并入队<br/>EconomyRules.queueProduction<br/>扣资源，追加 ProductionOrder<br/>唐宋日志使用军备/粮草口径"]:::economy

    END["结束当前阵营回合<br/>Command.endTurn<br/>CommandExecutor.executeEndTurn<br/>按 TurnOrderState 推进 active power"]:::command
    SUPPLY["补给状态刷新<br/>SupplyRules.updateSupplyStates"]:::rules
    RESOLVE["经济结算<br/>EconomyRules.resolveFactionTurn<br/>收入、维护费、短缺、补员、生产推进"]:::economy
    SHORT{"补给库存够吗?"}:::decision
    LOW["战略补给短缺<br/>supplied 单位降为 lowSupply"]:::rules
    REINF["自动补员<br/>安全后方 supplied 非敌邻单位<br/>每回合最多 +2 strength"]:::rules
    PROD["推进生产队列<br/>remainingTurns - 1<br/>ready 后部署军队或整备粮草"]:::economy
    DEPLOY{"有合格后方部署点吗?"}:::decision
    SPAWN["部署新单位<br/>首都/城镇/工厂/高基建/高补给或 supply source<br/>必须己控、空置、非敌邻"]:::rules
    WAIT["保留订单<br/>本回合无安全 hex，等待后续回合"]:::economy
    NEXT["切换阵营并刷新运行时层<br/>StrategicStateBootstrapper.refreshRuntimeState"]:::rules

    BOOT --> LEDGER
    HEX --> REGION --> INCOME --> LEDGER
    UI --> QUEUE --> VALIDATE --> PAY --> LEDGER
    END --> SUPPLY --> RESOLVE
    LEDGER --> RESOLVE
    RESOLVE --> SHORT
    SHORT -->|不足| LOW --> REINF
    SHORT -->|足够| REINF
    REINF --> PROD --> DEPLOY
    DEPLOY -->|有| SPAWN --> NEXT
    DEPLOY -->|没有| WAIT --> NEXT
    RESOLVE --> LEDGER

    WARN["边界<br/>经济系统不能直接占 hex<br/>也不能把中立/空控制 region 收入算给某阵营"]:::warn
    HEX -.守住.-> WARN
    VALIDATE -.守住.-> WARN

    classDef authority fill:#fee2e2,stroke:#dc2626,color:#111827
    classDef derived fill:#dcfce7,stroke:#16a34a,color:#052e16
    classDef economy fill:#fef9c3,stroke:#ca8a04,color:#292107
    classDef command fill:#fae8ff,stroke:#a21caf,color:#2a0a2f
    classDef rules fill:#ccfbf1,stroke:#0f766e,color:#042f2e
    classDef decision fill:#fff7ed,stroke:#ea580c,color:#1f1300
    classDef ui fill:#e5e7eb,stroke:#4b5563,color:#111827
    classDef warn fill:#ffedd5,stroke:#f97316,color:#431407
```

## 3.5 v5.3 唐宋古代兵种战斗修正

这张图看 v5.3 的战斗数值切片。底层 `ComponentType` 仍保留 legacy case；唐宋角色由单位 id、生产 kind id 和现有组件权重推导。修正只在 `state.isTangSongScenario` 为 true 时启用，阿登 legacy 路径仍走原装甲/火炮规则。

```mermaid
flowchart TD
    CMD["攻击命令<br/>Command.attack<br/>玩家或 WarCommandExecutor 生成"]:::command
    VALID["统一校验<br/>CommandValidator<br/>检查阵营、射程、敌我关系"]:::rules
    DIV["军队角色推导<br/>Division.tangSongCombatRoles<br/>id + production kind + 组件权重"]:::state
    SCENE{"唐宋场景?<br/>GameState.isTangSongScenario"}:::decision
    LEGACY["Legacy 战斗修正<br/>装甲平原加成 / 地形减速"]:::rules
    CAV["骑军<br/>平原/道路进攻 +15%<br/>攻城关/山林 -15%"]:::rules
    SIEGE["攻城器械<br/>攻城池/关隘 +35%<br/>野战攻击 -25%，防御 -1"]:::rules
    GARRISON["弓弩守军 / 守军<br/>守城池/关隘 +2 / +1 防御"]:::rules
    DAMAGE["伤害结算<br/>CombatRules.damage<br/>攻防、侧翼、河流、固守"]:::rules
    EXEC["执行结果<br/>CommandExecutor<br/>扣 strength、撤退、反击、消灭"]:::rules
    HEX["边界<br/>攻击不直接占领 hex<br/>占领仍只能由合法移动触发"]:::authority

    CMD --> VALID --> SCENE
    SCENE -->|否| LEGACY --> DAMAGE
    SCENE -->|是| DIV
    DIV --> CAV --> DAMAGE
    DIV --> SIEGE --> DAMAGE
    DIV --> GARRISON --> DAMAGE
    DAMAGE --> EXEC --> HEX

    classDef command fill:#fae8ff,stroke:#a21caf,color:#2a0a2f
    classDef rules fill:#ccfbf1,stroke:#0f766e,color:#042f2e
    classDef state fill:#ede9fe,stroke:#7c3aed,color:#1f143d
    classDef decision fill:#fff7ed,stroke:#ea580c,color:#1f1300
    classDef authority fill:#fee2e2,stroke:#dc2626,color:#111827
```

## 3.6 v5.3 唐宋粮道供给首轮

这张图看 v5.3/v5.5 的粮道供给与地图读法切片。它不新增补给状态，也不实现完整漕运；只是让唐宋场景的高补给州府/粮仓和道路、山林、跨河成本影响既有 `supplied / lowSupply / encircled` 判定，并在单位面板和地图只读 overlay 显示粮道通断、路径成本和最近粮源。

```mermaid
flowchart TD
    START["补给刷新<br/>SupplyRules.updateSupplyStates<br/>结束回合时执行"]:::rules
    DIV["逐支军队<br/>Division.coord + faction<br/>hex 仍是位置权威"]:::authority
    SOURCE["补给源集合<br/>effectiveSupplySources<br/>原 supply source + 唐宋高 supplyValue 州府粮仓"]:::state
    PATH["粮道寻路<br/>SupplyRules.supplyPathCost<br/>道路/城关便宜，山林/跨河更贵"]:::rules
    REL["敌控判断<br/>WarRelationRules.canTarget<br/>不再依赖 Faction.opponent"]:::rules
    STATE{"路径是否可达?<br/>唐宋 max 9 / legacy max 7"}:::decision
    OK["supplied<br/>可补员，保持正常战力"]:::state
    LOW["lowSupply<br/>攻击/防御/移动下降"]:::state
    ENC["encircled<br/>包围 attrition"]:::state
    READ["粮道面板读法<br/>SupplyRouteSummary -> UnitInspectorView<br/>通断、成本/上限、最近粮源、退路数"]:::ui
    MAP["地图粮道 overlay<br/>MapDisplayAdapter.supplyRouteOverlays + BoardScene<br/>可见友方军队到最近可见粮源的抽象虚线"]:::ui
    ECON["府库粮草<br/>EconomyRules.resolveFactionTurn<br/>战略库存短缺仍可压低补给"]:::economy

    START --> DIV --> SOURCE --> PATH --> REL --> STATE
    STATE -->|可达| OK
    STATE -->|不可达但有退路| LOW
    STATE -->|退路不足| ENC
    STATE --> READ
    READ --> MAP
    ECON --> LOW

    WARN["边界<br/>overlay 只读，不是真实逐 hex 路径<br/>没有新增粮队、仓储容量或自动破城"]:::warn
    SOURCE -.守住.-> WARN

    classDef rules fill:#ccfbf1,stroke:#0f766e,color:#042f2e
    classDef authority fill:#fee2e2,stroke:#dc2626,color:#111827
    classDef state fill:#ede9fe,stroke:#7c3aed,color:#1f143d
    classDef decision fill:#fff7ed,stroke:#ea580c,color:#1f1300
    classDef ui fill:#e5e7eb,stroke:#4b5563,color:#111827
    classDef economy fill:#fef9c3,stroke:#ca8a04,color:#292107
    classDef warn fill:#ffedd5,stroke:#f97316,color:#431407
```

## 3.7 v5.3 唐宋围城城防、修城、解围与招降首轮

这张图看 v5.3 的围城最小闭环。围城、修城、解围和招降都是底层 `Command`，仍经 `RuleEngine` 校验执行；围城记录压力与城防，城防归零后才在回合结算压低守军补给，解围只削减 pressure 或移除 SiegeRecord。招降是显式命令，只有 pressure 达标、城防归零且守军不再 supplied 后才交割目标州府可占 hex，并调用战略同步器刷新派生层。地图围城 overlay 只从 `SiegeState` 派生显示，不参与规则写入；AI 围城/招降首轮让 `ZoneDirective.attack` 经 `WarCommandExecutor` 生成底层 `Command.demandSurrender` 或 `Command.besiege`。

```mermaid
flowchart TD
    UI["玩家命令面板<br/>CommandPanelView<br/>选择可行动军队后发起围城、修城、解围或招降"]:::ui
    AI["AI / 方面攻击指令<br/>ZoneDirective.attack<br/>目标州府可招降或可围时"]:::command
    WCE["指令翻译<br/>WarCommandExecutor<br/>生成 demandSurrender 或 besiege，不写 SiegeState"]:::command
    CMD["围城命令<br/>Command.besiege<br/>attackerId + targetRegionId"]:::command
    VALID["统一校验<br/>CommandValidator.validateBesiege<br/>敌对城池/关隘/粮仓州府 + 距离合法"]:::rules
    REPAIR["修城命令<br/>Command.repairFortification<br/>守方军队 + 被围目标州府"]:::command
    RVALID["修城校验<br/>CommandValidator.validateRepairFortification<br/>己控、被围、军队在州府内、城防未满"]:::rules
    RELIEVE["解围命令<br/>Command.relieveSiege<br/>友军 + 被围目标州府"]:::command
    LVALID["解围校验<br/>CommandValidator.validateRelieveSiege<br/>己控、被围、军队在州府内或距离内"]:::rules
    SURRENDER["招降命令<br/>Command.demandSurrender<br/>围城方军队 + 被围目标州府"]:::command
    SVALID["招降校验<br/>CommandValidator.validateDemandSurrender<br/>pressure 达标、城防归零、守军不再 supplied"]:::rules
    PASS{"校验通过?"}:::decision
    REJECT["拒绝命令<br/>CommandResult rejected<br/>GameState 不变"]:::stop
    EXEC["执行围城<br/>CommandExecutor.executeBesiege<br/>标记军队 hasActed，累积 pressure，损耗 fortification"]:::rules
    REXEC["执行修城<br/>CommandExecutor.executeRepairFortification<br/>标记军队 hasActed，恢复 fortification"]:::rules
    LEXEC["执行解围<br/>CommandExecutor.executeRelieveSiege<br/>标记军队 hasActed，削减 pressure；归零则解除记录"]:::rules
    SEXEC["执行招降<br/>CommandExecutor.executeDemandSurrender<br/>移除纳降守军，交割可占 hex，移除 SiegeRecord"]:::rules
    SYNC["战略同步<br/>StrategicStateSynchronizer<br/>刷新 Region / Theater / FrontLine / WarDeployment"]:::rules
    STATE["围城记录<br/>GameState.siegeState / SiegeRecord<br/>目标州府、攻守方、压力、城防、围城军队"]:::state
    DISPLAY["地图围城 overlay<br/>MapDisplayAdapter.siegeOverlays + BoardScene<br/>围城圈、压力、城防标签"]:::ui
    LOG["围城日志<br/>GameLogCategory.siege<br/>EventLog / RegionInspector 可见"]:::ui
    END["结束回合<br/>CommandExecutor.executeEndTurn<br/>补给刷新后处理围城压力"]:::rules
    HOLD{"围城仍有效?<br/>目标仍由原守方控制，围城军队仍在距离内"}:::decision
    LIFT["解除围城记录<br/>原守方失控或围城军队离开"]:::state
    PRESS{"pressure >= 10?"}:::decision
    WALL{"城防归零?<br/>fortification == 0"}:::decision
    BLOCK["城防尚存<br/>断粮压力暂未突破"]:::state
    LOW["断粮压力<br/>目标州府内 supplied 守军降为 lowSupply"]:::state
    HEX["边界<br/>围城/修城/解围/overlay 不写占领<br/>招降只通过显式 Command 交割 hex 并同步派生层"]:::authority

    UI --> CMD --> VALID --> PASS
    AI --> WCE
    WCE --> SURRENDER
    WCE --> CMD
    UI --> REPAIR --> RVALID --> PASS
    UI --> RELIEVE --> LVALID --> PASS
    UI --> SURRENDER --> SVALID --> PASS
    PASS -->|否| REJECT
    PASS -->|围城| EXEC --> STATE --> LOG
    PASS -->|修城| REXEC --> STATE
    PASS -->|解围| LEXEC --> STATE
    PASS -->|招降| SEXEC --> SYNC --> STATE
    STATE --> DISPLAY
    STATE --> END --> HOLD
    HOLD -->|否| LIFT
    HOLD -->|是| PRESS
    PRESS -->|是| WALL
    WALL -->|否| BLOCK --> HEX
    WALL -->|是| LOW --> HEX
    PRESS -->|否| HEX
    STATE -.守住.-> HEX
    DISPLAY -.只读.-> HEX

    classDef ui fill:#e5e7eb,stroke:#4b5563,color:#111827
    classDef command fill:#fae8ff,stroke:#a21caf,color:#2a0a2f
    classDef rules fill:#ccfbf1,stroke:#0f766e,color:#042f2e
    classDef decision fill:#fff7ed,stroke:#ea580c,color:#1f1300
    classDef stop fill:#fee2e2,stroke:#b91c1c,color:#111827
    classDef state fill:#ede9fe,stroke:#7c3aed,color:#1f143d
    classDef authority fill:#fee2e2,stroke:#dc2626,color:#111827
```

## 4. AI / 元帅决策链：AI 怎么下命令

这张图看 v0.5 分支默认 AI 主路径。AI 不直接控制单位，也不直接改地图；元帅先读取降维战场摘要，模拟 LLM 输出 `TheaterDirectiveEnvelope` JSON，经 decoder 校验和 compiler 降级后，形成战区级 `DirectiveEnvelope`。`WarCommandExecutor` 再把这些战术翻译成底层 `Command`，最后交给 `RuleEngine`。v5.6c 另有一条 AI 招抚辅助桥：`pacificationTargets` 不进入 `WarCommandExecutor`，而是由 `TurnManager` 在战争指令后、`.endTurn` 前尝试生成 `Command.proposeSubmission`，仍由 `RuleEngine` 决定成败。

当前 v0.5 的默认 AI 战争主线是 `MarshalAgent -> TheaterDirective JSON -> TheaterDirectiveDecoder -> TheaterDirectiveCompiler -> ZoneDirective -> WarCommandExecutor -> RuleEngine`。v5.6c 的 AI 招抚辅助主线是 `TheaterDirectiveEnvelope.pacificationTargets -> TurnManager.executePacificationTargets -> Command.proposeSubmission -> RuleEngine`。旧 v0.37 `TheaterCommanderPool -> ZoneCommanderAgent` 作为 fallback 和显式 `.zoneDirective` 路径保留。统治者层只作为后续上游预留，当前不在主链路调用。旧 Agent D 管线仍保留，但默认不走。

```mermaid
flowchart TD
    START["触发 AI 行动<br/>AppContainer.advanceOrRunAI / runAIIfNeeded<br/>玩家点下一回合，或命令后轮到 AI"]:::input
    CHECK{"当前势力该由 AI 控制吗?<br/>TurnOrderState / PowerProfile 判断控制权"}:::decision
    STOP["不运行 AI<br/>等待玩家操作或阶段切换"]:::stop
    REFRESH["行动前刷新运行时战略层<br/>StrategicStateBootstrapper.refreshRuntimeState<br/>避免 AI 读到旧前线/旧部署"]:::rules
    TM["AI 回合编排器<br/>TurnManager.runAITurn<br/>默认 pipelineMode = marshalDirective"]:::rules
    SUM["战场摘要<br/>MarshalBattlefieldSummarizer<br/>只给元帅 front/deploy/目标/补给/场景摘要，不给全量 hex"]:::ai
    LLM["模拟 LLM 客户端<br/>SimulatedMarshalLLMClient<br/>输出 fenced JSON；唐宋场景填军议文案与 mandate/court/pacification/supply 解释字段，不接真实网络或模型"]:::ai
    DEC["元帅 JSON 解码器<br/>TheaterDirectiveDecoder<br/>提取 JSON、解码、校验 schema/zone/region/tactic"]:::command
    COMP["元帅意图编译器<br/>TheaterDirectiveCompiler<br/>TheaterDirective -> ZoneDirective<br/>传递 focus/convergence/coordinated 参数"]:::command
    ENV["指令信封<br/>DirectiveEnvelope<br/>收集编译后的 ZoneDirective"]:::command
    TACTIC["高级战术路由<br/>TacticName<br/>raw case 保持 Codable；唐宋显示为进军、骑军突进、合围、弓弩压制等"]:::command
    WCE["指令执行器<br/>WarCommandExecutor.execute<br/>按战术 profile 选择单位、目标和 fallback"]:::command
    BOTTOM["具体单位命令<br/>Command<br/>attack / move / hold / allowRetreat / besiege / demandSurrender"]:::command
    PAC["AI 招抚辅助桥<br/>TurnManager.executePacificationTargets<br/>pacificationTargets -> Command.proposeSubmission<br/>不经过 WarCommandExecutor"]:::command
    RE["统一规则校验执行<br/>RuleEngine<br/>AI 和玩家共用同一套规则"]:::rules
    RECORD["指令复盘记录<br/>AgentDecisionRecord + WarDirectiveRecord<br/>保存诏令朝议摘要、tactic、target、结果、拒绝原因"]:::ui
    PANEL["AI 面板<br/>AgentPanelView<br/>显示军议、诏令/朝议、招抚/转运和方面军令"]:::ui
    END["AI 自动结束回合<br/>RuleEngine.execute(.endTurn)<br/>切换 activeFaction / phase"]:::rules

    START --> CHECK
    CHECK -->|否| STOP
    CHECK -->|是| REFRESH --> TM --> SUM --> LLM --> DEC --> COMP --> ENV
    ENV --> TACTIC --> WCE --> BOTTOM --> RE --> RECORD
    ENV --> PAC --> RE
    RE --> END
    RECORD --> PANEL

    FALLBACK["Fallback 将军池<br/>TheaterCommanderPool + ZoneCommanderAgent<br/>元帅 JSON 无效或某 zone 无指令时使用"]:::ai
    DEC -.解码失败.-> FALLBACK --> ENV
    COMP -.zone 缺指令.-> FALLBACK

    LEGACY["旧 Agent D 管线<br/>AgentContext -> DecisionProvider -> AgentCommandMapper<br/>只在 legacyAgentOrder 显式分支或测试中使用"]:::legacy
    TM -.默认不走.-> LEGACY

    MANUAL["手写战区指令<br/>手工 ZoneDirective<br/>玩家聊天命令也可以直接指定 tactic/focus/convergence"]:::input
    MANUAL --> TACTIC

    classDef input fill:#fef3c7,stroke:#d97706,color:#1f1600
    classDef decision fill:#fff7ed,stroke:#ea580c,color:#1f1300
    classDef stop fill:#fee2e2,stroke:#b91c1c,color:#111827
    classDef rules fill:#ccfbf1,stroke:#0f766e,color:#042f2e
    classDef ai fill:#e0e7ff,stroke:#4f46e5,color:#111827
    classDef command fill:#fae8ff,stroke:#a21caf,color:#2a0a2f
    classDef ui fill:#e5e7eb,stroke:#4b5563,color:#111827
    classDef legacy fill:#f3f4f6,stroke:#6b7280,stroke-dasharray:5 5,color:#111827
```

## 5. MapEditor 到游戏数据：地图怎么进入主游戏

这张图看地图编辑器的输出链路。编辑器里画的是初始地图和初始战区；运行时动态战区仍由游戏里的 `hexToTheater` 推进，不是编辑器脚本控制。

```mermaid
flowchart TD
    DOC["编辑器文档<br/>MapEditorDocument<br/>保存 hex、州府、方面分配、初始军队"]:::editor
    MODE1["地块编辑<br/>hexPainter<br/>画地形、道路、控制政权、粮仓"]:::editor
    MODE2["州府编辑<br/>regionBuilder<br/>把每个 hex 分配给一个 region"]:::editor
    MODE3["初始方面编辑<br/>theaterAssignment<br/>把 region 分配给开局 theater"]:::editor
    MODE4["初始军队编辑<br/>unitPlanner<br/>放置开局军队和模板"]:::editor
    EXPORT["导出器<br/>MapEditorExporter.export<br/>把编辑器文档转成游戏 JSON"]:::loader
    CHECK{"导出校验通过吗?<br/>每个 hex 必须有 region；region 不能为空"}:::decision
    ERR["导出失败<br/>unassignedHex / missingRegion / emptyRegion<br/>先回编辑器补数据"]:::stop
    SCEN["场景 JSON<br/>ScenarioDefinition<br/>保存 hex 地形、控制方、补给、目标、初始单位"]:::data
    REG["州府 JSON<br/>RegionDataSet<br/>保存 hexToRegion、州府、边、初始 theaterId"]:::data
    NEI["自动推导州府邻接<br/>真实 hex 邻接 -> Region.neighbors / RegionEdge<br/>避免手写邻接出错"]:::derived
    BRIDGE["默认资源桥<br/>MapEditorGameResourceBridge<br/>读取或覆盖项目默认地图资源"]:::loader
    FILES["MapEditor 默认数据文件<br/>WWIIHexV0/Data<br/>tangsong_jianlong_960_scenario.json + tangsong_jianlong_960_regions.json<br/>缺失时报错，不静默回退阿登"]:::data
    LOAD["游戏启动加载<br/>DataLoader.loadGameState<br/>DEBUG 下优先读源码 JSON"]:::loader
    MAP["地图状态<br/>MapState<br/>tiles + hexToRegion + RegionGraph"]:::state
    THEATER["战区状态<br/>TheaterState<br/>捕获 initialSnapshot，并 seed hexToTheater"]:::state
    FRONT["初始前线<br/>FrontLineState<br/>按开局动态战区接触生成"]:::derived
    DEPLOY["初始部署<br/>WarDeploymentState<br/>按前线/纵深/驻军分配单位"]:::derived
    GAME["游戏可运行<br/>GameState ready<br/>主游戏 UI 和规则系统开始读取"]:::state

    DOC --> MODE1 --> EXPORT
    DOC --> MODE2 --> EXPORT
    DOC --> MODE3 --> EXPORT
    DOC --> MODE4 --> EXPORT
    EXPORT --> CHECK
    CHECK -->|失败| ERR
    CHECK -->|通过| SCEN
    CHECK -->|通过| REG
    REG --> NEI --> REG
    SCEN --> BRIDGE
    REG --> BRIDGE
    BRIDGE --> FILES
    FILES --> LOAD --> MAP --> THEATER --> FRONT --> DEPLOY --> GAME

    NOTE["重要提醒<br/>MapEditor 的 theater assignment 只定义开局战区<br/>运行时推进看 hexToTheater，不看 regionToTheater"]:::warn
    MODE3 -.语义.-> NOTE

    classDef editor fill:#f6d365,stroke:#8a5a00,color:#1f1b10
    classDef loader fill:#dbeafe,stroke:#2563eb,color:#0f172a
    classDef decision fill:#fff7ed,stroke:#ea580c,color:#1f1300
    classDef stop fill:#fee2e2,stroke:#b91c1c,color:#111827
    classDef data fill:#f8f9fb,stroke:#6b7280,color:#111827
    classDef derived fill:#dcfce7,stroke:#16a34a,color:#052e16
    classDef state fill:#ede9fe,stroke:#7c3aed,color:#1f143d
    classDef warn fill:#ffedd5,stroke:#f97316,color:#431407
```

## 6. v1.1 主游戏 macOS 入口

这张图只说明 v1.1 新增的 macOS 主游戏 target。它复用主游戏数据、UI、SpriteKit 棋盘和规则系统；macOS 输入只是平台桥接，不是新的规则入口。

```mermaid
flowchart TD
    TARGET["macOS 主游戏 target<br/>WWIIHexV0Mac<br/>独立于 iOS target 和 MapEditorMac"]:::platform
    APP["macOS App 入口<br/>WWIIHexV0MacApp<br/>WindowGroup + Game 菜单"]:::platform
    BOOT["游戏容器<br/>AppContainer.bootstrap<br/>加载默认 JSON 并初始化规则/AI"]:::state
    ROOT["主游戏界面<br/>RootGameView<br/>HUD、图层、Info、棋盘"]:::ui
    BRIDGE["macOS SpriteKit 桥<br/>BoardSceneView + BoardEventSKView<br/>NSViewRepresentable 承载 SKView"]:::platform
    SCENE["棋盘场景<br/>BoardScene<br/>鼠标点击、拖拽、滚轮/触控板缩放"]:::ui
    TAP["hex 点击回调<br/>onHexTapped(coord)<br/>只传坐标，不改 GameState"]:::input
    CONTAINER["输入解释<br/>AppContainer.handleBoardTap<br/>选中、移动、攻击意图判断"]:::rules
    COMMAND["统一命令<br/>Command / ZoneDirective<br/>玩家和 AI 共用入口"]:::command
    ENGINE["规则权威<br/>RuleEngine / WarCommandExecutor<br/>校验后修改 GameState"]:::rules
    DATA["默认资源<br/>WWIIHexV0/Data JSON<br/>默认只加载唐宋 960<br/>缺失时报唐宋错误态；阿登仅显式 legacy 入口"]:::data

    TARGET --> APP --> BOOT --> ROOT --> BRIDGE --> SCENE --> TAP --> CONTAINER --> COMMAND --> ENGINE
    DATA --> BOOT
    ENGINE --> ROOT

    WARN["禁止绕过<br/>AppKit / SpriteKit 不得直接改 GameState<br/>仍必须走规则系统"]:::warn
    SCENE -.守住.-> WARN

    classDef platform fill:#e0f2fe,stroke:#0284c7,color:#082f49
    classDef state fill:#ede9fe,stroke:#7c3aed,color:#1f143d
    classDef ui fill:#e5e7eb,stroke:#4b5563,color:#111827
    classDef input fill:#fef3c7,stroke:#d97706,color:#1f1600
    classDef command fill:#fae8ff,stroke:#a21caf,color:#2a0a2f
    classDef rules fill:#ccfbf1,stroke:#0f766e,color:#042f2e
    classDef data fill:#f8f9fb,stroke:#6b7280,color:#111827
    classDef warn fill:#ffedd5,stroke:#f97316,color:#431407
```

## 7. v1.0 UI / AI / 初版试玩链路

这张图说明 v1.0 分支的收口点：它不新增规则入口，只改善 UI 可读性、AI 回放、轻量性能和试玩记录。

```mermaid
flowchart TD
    STATE["运行时状态<br/>GameState + EventLog + WarDirectiveRecord"]:::state
    ROOT["主界面<br/>RootGameView<br/>唐宋场景显示图层、观战、面板与 compact tabs"]:::ui
    HUD["顶部 HUD<br/>HUDView + GameState.phaseDisplayName<br/>显示回合、政权、阶段、胜负、资源、队列"]:::ui
    GOAL["统一目标锚点<br/>HUDView.objectiveGuideText<br/>只读显示已据/待取关键州府"]:::ui
    FOCUS["目标按钮<br/>AppContainer.focusObjective<br/>选中目标 hex / region"]:::ui
    SPOTLIGHT["地图目标 spotlight<br/>MapDisplayAdapter.objectiveOverlays + BoardScene<br/>只读标出统一目标州府"]:::ui
    HINT["下一步提示<br/>RootGameView.nextActionHint -> HUDView<br/>只读提示选军、围城、招抚、解围、修城、高亮数量和有限合法性预校验"]:::ui
    INSPECT["检查面板<br/>MapDisplayAdapter / UnitInspectorView / RegionInspectorView<br/>唐宋场景显示军队详情、州府详情、运行态方面/防区名称、编成、产出和围城摘要"]:::ui
    GENPANELS["将领面板<br/>GeneralCommandPanelView / GeneralProfileView<br/>唐宋场景显示将领军令、将领档案、用兵、指标、特长和辖下军队"]:::ui
    TOOLTIP["常驻军队提示<br/>UnitTooltipView<br/>唐宋场景显示选中军队摘要读法"]:::ui
    SESSIONHUD["亲征势力 / 观战 / 重开剧本<br/>RootGameView + HUDView + NewGameButton<br/>切换 legacy 亲征阵营，显示亲征/观战，确认后重置剧本"]:::ui
    LOG["战报面板<br/>EventLogView<br/>唐宋场景显示战报分类、每回合摘要和胜负后评分估算<br/>metadata 不展示内部 relatedRecordId；raw 英文兜底降级为中文提示<br/>列表行和摘要卡片合并读屏"]:::ui
    AIUI["AI 面板<br/>AgentPanelView<br/>唐宋场景显示军议、诏令朝议、方面军令、唐宋战术名"]:::ui
    BOARD["地图场景<br/>BoardScene + TerrainStyle<br/>唐宋场景使用墨绿底、青绿/朱印/铜色 palette，绘制粮道虚线"]:::ui
    UNIT["军队棋子<br/>UnitNode<br/>legacy NATO；唐宋军旗 + 禁/骑/弩/械/守/军字标"]:::ui
    MARSHAL["模拟元帅 / MockAI<br/>MarshalAgent + SimulatedMarshalLLMClient"]:::ai
    ZD["战区指令<br/>ZoneDirective<br/>tactic / focus / intensity"]:::command
    WCE["执行解释<br/>WarCommandExecutor<br/>infiltration 限制默认投入"]:::command
    RULE["规则权威<br/>RuleEngine<br/>唯一修改 GameState"]:::rules
    PLAYTEST["初版试玩记录<br/>观察 UI、图层、AI diagnostics、拒绝原因"]:::doc

    STATE --> ROOT
    ROOT --> HUD
    HUD --> GOAL --> FOCUS
    BOARD --> SPOTLIGHT
    ROOT --> HINT
    ROOT --> INSPECT
    ROOT --> GENPANELS
    ROOT --> TOOLTIP
    ROOT --> SESSIONHUD
    ROOT --> LOG
    ROOT --> AIUI
    AIUI --> LOG
    ROOT --> BOARD
    BOARD --> UNIT
    MARSHAL --> ZD --> WCE --> RULE --> STATE
    AIUI --> PLAYTEST
    LOG --> PLAYTEST
    BOARD --> PLAYTEST

    WARN["边界<br/>UI / MockAI 不直接改 GameState<br/>仍必须走统一命令管线"]:::warn
    AIUI -.守住.-> WARN
    WCE -.守住.-> WARN

    classDef state fill:#ede9fe,stroke:#7c3aed,color:#1f143d
    classDef ui fill:#e5e7eb,stroke:#4b5563,color:#111827
    classDef ai fill:#e0e7ff,stroke:#4f46e5,color:#111827
    classDef command fill:#fae8ff,stroke:#a21caf,color:#2a0a2f
    classDef rules fill:#ccfbf1,stroke:#0f766e,color:#042f2e
    classDef doc fill:#fef3c7,stroke:#d97706,color:#1f1600
    classDef warn fill:#ffedd5,stroke:#f97316,color:#431407
```

## 8. v0.4 将军与玩家双轨命令

这张图说明 v0.4 分支的新增主线：实体将军从 JSON / region 种子接入 FrontZone；玩家可以微操具体部队，也可以通过将军面板发战区宏观命令。两条路最终仍收口到规则系统。

```mermaid
flowchart TD
    GJSON["将领数据<br/>唐宋默认 tangsong_characters.json<br/>legacy 阿登保留 generals.json"]:::data
    RJSON["Region 种子<br/>唐宋/legacy region JSON assignedGeneralId<br/>开局指定某 region 所属将军"]:::data
    DL["加载器<br/>DataLoader.loadGeneralRegistry(for:)<br/>按 scenarioId 选择人物注册表"]:::loader
    DISP["将军指派器<br/>GeneralDispatcher.assignGenerals<br/>种子 -> 偏好 -> 同阵营后备池"]:::rules
    FZ["战区部署<br/>FrontZone.generalAssignment<br/>generalId、HQ region、辖下 division、忠诚/满意度"]:::state
    POOL["将军池<br/>TheaterCommanderPool<br/>用 GeneralData 生成 ZoneCommanderAgentConfig"]:::ai

    TAP["玩家地图点击<br/>RootGameView / BoardScene<br/>选单位、选 region、选目标"]:::input
    MICRO["全微操<br/>AppContainer.submit(Command)<br/>move / attack / hold / resupply"]:::command
    LOCK["微操锁<br/>PlayerCommandState.micromanagedDivisionIds<br/>本回合玩家亲控单位"]:::state
    GENUI["将军面板<br/>GeneralCommandPanelView<br/>Hold Line / Attack Region"]:::ui
    ZD["玩家战区指令<br/>ZoneDirective<br/>defense holdLine 或 attack selected region"]:::command
    WCE["执行器<br/>WarCommandExecutor.execute(excluding lockedIds)<br/>跳过已微操单位"]:::command
    RE["规则权威<br/>RuleEngine<br/>校验并修改 GameState"]:::rules
    RECORD["记录<br/>WarDirectiveRecord + PlayerPlannedOperation<br/>AI 面板、日志、计划线共用"]:::ui
    BOARD["视觉反馈<br/>BoardScene<br/>进攻箭头、防御圆环、微操单位金色圈"]:::ui
    PROFILE["将军档案<br/>GeneralProfileView<br/>履历、技能、忠诚、满意度、辖下部队"]:::ui

    GJSON --> DL --> DISP
    RJSON --> DISP --> FZ --> POOL
    FZ --> GENUI --> PROFILE
    TAP --> MICRO --> RE --> LOCK
    LOCK --> WCE
    TAP --> GENUI --> ZD --> WCE --> RE --> RECORD --> BOARD
    FZ --> GENUI

    WARN["边界<br/>UI 和将军不直接改 hex / division<br/>行动必须走 Command 或 ZoneDirective"]:::warn
    GENUI -.守住.-> WARN
    WCE -.守住.-> WARN

    classDef data fill:#f8f9fb,stroke:#6b7280,color:#111827
    classDef loader fill:#dbeafe,stroke:#2563eb,color:#0f172a
    classDef state fill:#ede9fe,stroke:#7c3aed,color:#1f143d
    classDef ai fill:#e0e7ff,stroke:#4f46e5,color:#111827
    classDef input fill:#fef3c7,stroke:#d97706,color:#1f1600
    classDef command fill:#fae8ff,stroke:#a21caf,color:#2a0a2f
    classDef rules fill:#ccfbf1,stroke:#0f766e,color:#042f2e
    classDef ui fill:#e5e7eb,stroke:#4b5563,color:#111827
    classDef warn fill:#ffedd5,stroke:#f97316,color:#431407
```

## 9. 云端协作：main 直推与结果包验收

这张图说明当前默认协作制度。它不改变游戏规则，只规定 Agent A/B/C 如何把本地轻量检查、`main` 直推、GitHub Actions 云端重验证和 Agent C 结果包复判串起来。

```mermaid
flowchart TD
    HUMAN["人工目标<br/>说明本轮业务或制度目标"]:::input
    A["Agent A<br/>读取入口文档和源码<br/>写阶段提示词"]:::agent
    PROMPT["阶段提示词<br/>md/prompt/...<br/>包含 main push / CI / artifact 要求"]:::doc
    BSTART["Agent B 开始<br/>git fetch origin<br/>git switch main<br/>git pull --ff-only origin main"]:::git
    WORK["本地实现<br/>只改本轮相关文件<br/>不改无关业务逻辑"]:::work
    LIGHT["本地轻量检查<br/>git diff --check / YAML / plist / JSON<br/>不跑本机重测试"]:::check
    COMMIT["main commit<br/>git add + git commit<br/>提交本轮相关文件"]:::git
    PUSH["push 到 origin/main<br/>git push origin main<br/>触发云端 workflow"]:::git
    GHA["GitHub Actions<br/>WWIIHexV0 CI Results<br/>静态检查 + xcodebuild build"]:::cloud
    ART["未加密结果包<br/>ci-results artifact<br/>manifest / JUnit / xcodebuild.log / failure summary"]:::artifact
    C["Agent C<br/>gh auth login<br/>下载到 /private/tmp/wwiihexv0-c-review-run"]:::agent
    VERIFY["结果包复判<br/>核对 branch=main<br/>commitSha / runId / runAttempt<br/>读取 JUnit 和日志"]:::check
    PASS{"云端 run 和 artifact 是否通过?"}:::decision
    ACCEPT["验收通过<br/>记录结论<br/>按需更新 flow / update_log"]:::done
    REJECT["退回清单<br/>列出失败日志、manifest、修复要求"]:::warn
    FIX["Agent B 追加修复 commit<br/>仍在 main 上小步修复"]:::work

    HUMAN --> A --> PROMPT --> BSTART --> WORK --> LIGHT --> COMMIT --> PUSH --> GHA --> ART --> C --> VERIFY --> PASS
    PASS -->|通过| ACCEPT
    PASS -->|失败| REJECT --> FIX --> LIGHT

    WARN1["禁止<br/>验收旧 artifact 或只看文字汇报"]:::warn
    WARN2["禁止<br/>本轮默认创建 PR、develop、smalldata_test、codeb 分支"]:::warn
    VERIFY -.守住.-> WARN1
    BSTART -.守住.-> WARN2

    classDef input fill:#fef3c7,stroke:#d97706,color:#1f1600
    classDef agent fill:#e0e7ff,stroke:#4f46e5,color:#111827
    classDef doc fill:#f8f9fb,stroke:#6b7280,color:#111827
    classDef git fill:#ede9fe,stroke:#7c3aed,color:#1f143d
    classDef work fill:#dbeafe,stroke:#2563eb,color:#0f172a
    classDef check fill:#ccfbf1,stroke:#0f766e,color:#042f2e
    classDef cloud fill:#dcfce7,stroke:#16a34a,color:#052e16
    classDef artifact fill:#fae8ff,stroke:#a21caf,color:#2a0a2f
    classDef decision fill:#fff7ed,stroke:#ea580c,color:#1f1300
    classDef done fill:#dcfce7,stroke:#15803d,color:#052e16
    classDef warn fill:#ffedd5,stroke:#f97316,color:#431407
```

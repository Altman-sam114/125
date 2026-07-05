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

截至当前工作树，唐宋迁移已经进入 v5.3 小切片迭代：

- v5.0 已建立迁移总提示词和审计合同，明确首发 960 剧本、架构边界、版本路线、禁止项和验收标准。
- v5.1 已加入 `PowerId` / `PowerProfile` / `PowerRelation` / `TurnOrderState` / `WarRelationRules` 兼容地基，回合和 AI 控制权主路径开始脱离硬编码 Germany/Allies。
- v5.2 已新增唐宋 960 场景、州府/方面、单位模板和人物 JSON；默认加载优先唐宋资源，阿登保留 legacy fallback；MapEditor 默认资源桥和工具术语已迁到唐宋口径。
- v5.3 已完成生产、府库和经济日志显示桥首轮：唐宋路径显示军备、丁口、钱帛、粮草、禁军、厢军、骑军、攻城器械营。
- v5.3 已加入唐宋场景专用古代兵种战斗修正首轮：骑军平原/道路进攻、弓弩守军守城、攻城器械攻城/野战差异和守军城防差异已经由 `CombatRules` 处理。
- v5.3 已加入粮道供给与读法首轮：唐宋场景下受控高 `supplyValue` 州府/粮仓可作为补给源，道路、城关、山林、跨河成本会影响 `SupplyRules` 补给判定；单位详情可读粮道通断、路径成本/上限、最近粮源和安全退路数。
- v5.3 已加入围城城防、修城、解围、招降、地图围城 overlay 与 AI 围城/招降指令首轮：`Command.besiege` 经 `RuleEngine` 登记 `SiegeState` 并损耗 `fortification`；`Command.repairFortification` 让守方军队在被围州府内消耗行动修城；`Command.relieveSiege` 让守方或友军削减围城 pressure，pressure 降到 0 时解除围城记录；`Command.demandSurrender` 让围城方在 pressure 达标、城防归零且守军不再 `supplied` 后，经规则层移除纳降守军、交割目标州府可占 hex 并刷新 Region / Theater / FrontLine / WarDeployment；`ZoneDirective.attack -> WarCommandExecutor` 可在目标敌控州府满足纳降条件时生成底层 `Command.demandSurrender`，否则在目标可围且无可攻击单位时生成底层 `Command.besiege`；Region 面板可读围城压力和城防，地图可从 `SiegeState` 只读绘制围城圈、压力和城防标签。

仍未完成的关键项：

- `Faction` 底层仍是 `.allies` / `.germany` legacy 桥，真实多政权数据驱动未收口。
- `ProductionKind`、`EconomyResources`、`Division`、`ComponentType` 的 Codable schema 仍保留二战兼容名。
- 自动破城、完整外交归附、完整漕运/粮队/仓储容量、唐宋专用胜利规则、天命/治理和发布级 UI 仍未落地。
- AI 默认人物和战术 raw case 仍有二战语义残留，需在 v5.4-v5.5 继续迁移。

下一轮优先继续 v5.3 小切片：漕运深化 / 围城结果显示与胜利结算 / 围城 AI 解释文案择一推进，仍必须走 `Command` / `ZoneDirective -> WarCommandExecutor -> RuleEngine`，不得让事件或 Agent 直接改 `GameState`。

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
| v5.4 | 唐宋 AI Agent 分层 | 未开始 | 皇帝/朝廷/枢密/节度使/转运使/州府守臣/外交使者分层，保留 directive 管线 | `v5.4_agent_schema_record.md` |
| v5.5 | 发布级 UI 与地图视觉 | 未开始 | 第一屏地图、HUD、军令、州府、府库、外交、战报、军议可读；移除默认二战文案 | `v5.5_ui_visual_record.md` |
| v5.6 | 外交、归附、天命与治理 | 未开始 | 多政权关系、归附、天命/国威、治理和事件闭环 | `v5.6_diplomacy_mandate_record.md` |
| v5.7 | 教程、剧本包装与可玩闭环 | 未开始 | 开局引导、势力选择、战报、新局/重置，让普通玩家能完成首发剧本 | `v5.7_playable_loop_record.md` |
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
| P2 | 漕运深化 | 待做：可先增加只读地图粮道线、粮源解释或有限运河/道路加权，不急于仓储容量和粮队实体 | `md/flow/*`、`README.md`、`v5.3_rules_siege_grain_record.md`、本文 | 不引入全局复杂物流系统；不让 UI 直接修改补给状态 |
| P2 | 围城结果显示与胜利结算 | 待做：在显式招降、占领或合法胜利规则触发后，让战报/日志/胜利面板解释结果 | `md/flow/*`、`README.md`、`v5.3_rules_siege_grain_record.md`、`update_log.md` | 不做结束回合自动改控制权；不绕过 `VictoryRules` 或命令管线 |
| P3 | 围城 AI 解释文案 | 待做：让 AI 军议说明为何围城、修城、解围或招降，优先接现有 `WarDirectiveRecord` | `v5.3_rules_siege_grain_record.md`、后续 `v5.4_agent_schema_record.md` | 不改变 AI 执行权限；解释文案不能替代规则结果 |

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
├── v5.5_ui_visual_record.md
├── v5.6_diplomacy_mandate_record.md
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

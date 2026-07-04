# 项目 md 大纲：唐宋迁移版

本文是 `md/` 目录的当前大纲和唐宋迁移路线索引。它只整理文档结构和版本规划，不表示本轮已经修改业务源码。

依据文件：

- `AGENTS.md`
- `update_log.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v5.0-唐宋迁移/codex-v5.0-唐宋aiagent历史策略迁移总提示词.md`

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

## 3. md 目录职责

```text
md/
├── plan/
│   └── plan.md
│       当前 md 大纲、唐宋迁移路线索引和文档维护口径。
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
    │   唐宋 v5.0-v5.9 总提示词、v5.0 审计合同和后续阶段记录。
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

## 4. 唐宋 v5.0-v5.9 路线

| 版本 | 主题 | 目标 | 主要文档产物 |
|---|---|---|---|
| v5.0 | 迁移审计与合同冻结 | 不改玩法，先审计二战残留、冻结唐宋迁移合同、明确首发剧本与边界 | `v5.0_audit_and_contract.md`、词汇表、风险清单 |
| v5.1 | 多势力与通用回合地基 | 解耦 `germany/allies`、`Faction.opponent`、`germanAI/alliedPlayer`，建立 `PowerId` / turn order / relation 兼容层 | 多势力合同记录、回合迁移记录 |
| v5.2 | 首发剧本数据与 MapEditor 语义 | 默认数据迁到 `jianlong_960_unification`，MapEditor 术语迁到地块/州府/方面/军队/人物 | 剧本数据记录、地图编辑器迁移记录 |
| v5.3 | 古代军制、粮草、围城与经济 | 兵种、生产、补给、粮道、围城最小闭环，资源显示迁为丁口/钱帛/粮草 | 规则迁移记录、数据检查记录 |
| v5.4 | 唐宋 AI Agent 分层 | 皇帝/朝廷/枢密/节度使/转运使/州府守臣/外交使者分层，保留 directive 管线 | AI schema 记录、fallback 记录 |
| v5.5 | 发布级 UI 与地图视觉 | 第一屏地图、HUD、军令、州府、府库、外交、战报、军议可读；移除默认二战文案 | UI/视觉迁移记录、可访问性记录 |
| v5.6 | 外交、归附、天命与治理 | 多政权关系、归附、天命/国威、治理和事件闭环 | 外交治理记录、事件规则记录 |
| v5.7 | 教程、剧本包装与可玩闭环 | 开局引导、势力选择、战报、新局/重置，让普通玩家能完成首发剧本 | 教程与可玩闭环记录 |
| v5.8 | 发布候选硬化 | 玩家可见残留扫描、资源授权、性能和文档口径收口 | 发布候选审计报告 |
| v5.9 | 可发布版本收口 | 首发剧本可完整试玩，Agent C 验收通过，README/flow/update_log 反映唐宋产品 | 发布验收报告 |

## 5. 迁移词汇总表

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

## 6. 后续阶段文档建议

唐宋迁移进入实现后，建议按版本追加这些文件，避免把所有记录堆进总提示词：

```text
md/prompt/v5.0-唐宋迁移/
├── codex-v5.0-唐宋aiagent历史策略迁移总提示词.md
├── v5.0_audit_and_contract.md              # 已创建：当前二战残留审计与 v5.1 合同
├── v5.1_powers_turn_order_record.md
├── v5.2_scenario_mapeditor_record.md
├── v5.3_rules_siege_grain_record.md
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

## 7. 轻量检查入口

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

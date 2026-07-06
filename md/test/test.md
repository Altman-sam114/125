# 本地轻量检查与云端重验证规范

> 当前规则：默认云端重验证；若人工未另行限制，本机只做轻量语法、格式和配置文件检查。当前 v5.8q 起按人工明确要求，本机不运行测试、build、Swift parse、Markdown 检查或 `git diff --check`，只做只读审查、git diff/status、commit/push，验证交给 GitHub Actions。历史 Probe、Smoke、Stage Regression、Dynamic Theater Regression、Full 记录只作回归参考，不再是每轮本机默认要求。

## 0. 总原则

- 每轮实现或验收前仍要读本文件，但目的从“选择测试层级”改为“确认哪些检查允许执行、哪些检查禁止执行”。
- 默认不在本机跑任何耗费性能的测试、构建、模拟器启动或 app 启动。
- 若人工明确要求“都去云端测试”，本机连轻量检查也不跑；只能阅读文件、审查 diff、提交并推送，由云端 workflow 给出验证结果。
- Swift / Xcode / 业务逻辑相关改动完成后，默认由 Agent B commit 并 push 到 `origin/main`，触发 GitHub Actions 云端重验证。
- GitHub Actions 上传未加密 CI 结果包，Agent C 下载后核对 manifest、JUnit、主构建日志、failure summary 和项目原生结果文件。
- 默认不新增或修改测试文件；可以阅读既有测试理解历史语义。
- 若某风险必须依靠重测试才能确认，本机只记录“本机未跑重测试；等待或参考云端结果包”，不要擅自扩大本机验证范围。
- 不得用“已验证”代替具体命令和结果；不得伪造测试、构建或模拟器结果。
- 当前默认云端 workflow：`.github/workflows/ci-results.yml`，触发条件为 `push` 到 `main` 或手动 `workflow_dispatch`。
- Agent C 下载缓存默认放在 `/private/tmp/wwiihexv0-c-review-<run_id>/`，人工确认前不自动删除。

## 1. 本机禁止主动执行

除非人工在当前任务中明确授权，否则 Agent 不得主动执行以下操作：

- `xcodebuild test`
- `xcodebuild build`
- `xcodebuild build-for-testing`
- `xcrun simctl ...`
- Probe / Smoke / Stage Regression / Dynamic Theater Regression / Full
- XCTest、UI test、性能测试、快照测试
- 启动 iOS Simulator
- 启动 app 做人工烟测
- 全项目 Swift 编译、全量 lint、全量格式化
- 会长时间占用 CPU、内存、磁盘或 DerivedData 的命令

如果旧文档、历史 prompt 或 README 仍要求跑这些命令，以本文件和 `AGENTS.md` 的当前规则为准。

## 2. 默认允许的本地轻量检查

### 2.1 Markdown / 文本

检查改动文档是否存在尾随空白：

```sh
rg -n "[[:blank:]]+$" AGENTS.md README.md update_log.md md/test/test.md md/flow/flow.md md/flow/flowchart.md md/prompt/README.md
```

检查当前规范中是否仍残留旧默认测试口径：

```sh
rg -n "默认先跑|默认 Probe|Probe -> Smoke|Stage Regression -> Full|代码改动按 .*Probe" AGENTS.md md/flow/flow.md
```

检查 GitHub Actions workflow YAML 能解析：

```sh
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'
```

### 2.2 Xcode project / plist

仅当修改了 `WWIIHexV0.xcodeproj/project.pbxproj` 时运行：

```sh
plutil -lint WWIIHexV0.xcodeproj/project.pbxproj
```

仅当修改了 scheme 或 XML 文件时运行：

```sh
xmllint --noout WWIIHexV0.xcodeproj/xcshareddata/xcschemes/WWIIHexV0.xcscheme
xmllint --noout WWIIHexV0.xcodeproj/xcshareddata/xcschemes/WWIIHexV0Probes.xcscheme
```

### 2.3 JSON

仅当修改了 JSON 数据时运行对应文件的解析检查，优先只查改动文件：

```sh
jq empty WWIIHexV0/Data/ardennes_v0_scenario.json
jq empty WWIIHexV0/Data/ardennes_v02_regions.json
jq empty WWIIHexV0/Data/general_agents.json
jq empty WWIIHexV0/Data/generals.json
jq empty WWIIHexV0/Data/terrain_rules.json
jq empty WWIIHexV0/Data/unit_templates.json
```

### 2.4 Swift 单文件语法

默认不做全项目编译。若只改了少量纯 Swift 文件，并且单文件语法检查不会触发项目构建，可以只针对改动文件做轻量 parse；如果命令需要 SDK、SwiftUI/SpriteKit 依赖或变慢，立即停止并记录未检查。

示例：

```sh
swiftc -parse path/to/ChangedFile.swift
```

## 3. 云端重验证与结果包

### 3.1 默认触发方式

Agent B 完成本地轻量检查后在 `main` 上提交并推送：

```sh
git fetch origin
git switch main
git pull --ff-only origin main
git status --short
git add 相关文件
git commit -m "chore: 简要说明本轮制度或功能改动"
git push origin main
```

推送会触发 `WWIIHexV0 CI Results` workflow。该 workflow 默认执行：

- `git diff --check`
- `plutil -lint WWIIHexV0.xcodeproj/project.pbxproj`
- `xmllint --noout` 检查共享 scheme XML
- `xcodebuild build`，使用 `WWIIHexV0.xcodeproj` / `WWIIHexV0` / `Debug` / `generic/platform=iOS` / `CODE_SIGNING_ALLOWED=NO`

云端 `xcodebuild` 使用 `.derivedData-ci`，不同于本机历史 DerivedData 路径；该目录只存在于 GitHub runner。

### 3.2 未加密结果包内容

workflow 必须上传未加密 artifact。最低内容：

- `ci-results/ci-artifact-manifest.json`
- `ci-results/ci-failure-summary.md`
- `ci-results/junit.xml`
- `ci-results/static-checks.log`
- `ci-results/xcodebuild.log`
- `ci-results/WWIIHexV0.xcresult`，如果 Xcode 成功生成 result bundle
- `ci-results/artifact-name.txt`

`ci-artifact-manifest.json` 至少记录：

- `branch`
- `commitSha`
- `shortSha`
- `runId`
- `runAttempt`
- `workflowName`
- `projectName`
- `scheme`
- `destination`
- `resultBundlePath`
- `junitPath`
- `buildLogPath`
- `failureSummaryPath`
- `staticChecksOutcome`
- `buildOutcome`
- `testOutcome`

### 3.3 Agent C 下载和核对

Agent C 必须先确认 GitHub CLI 可访问仓库 Actions。私有仓库或权限受限时先执行：

```sh
gh auth login
```

下载缓存位置：

```sh
/private/tmp/wwiihexv0-c-review-<run_id>/
```

推荐核对命令：

```sh
git fetch origin
git rev-parse origin/main
gh run list --workflow "WWIIHexV0 CI Results" --branch main --limit 5
gh run download <run_id> --dir /private/tmp/wwiihexv0-c-review-<run_id>
jq empty /private/tmp/wwiihexv0-c-review-<run_id>/*/ci-artifact-manifest.json
```

Agent C 必须核对 manifest 的 `branch=main`、`commitSha`、`runId`、`runAttempt` 与 `origin/main` 最新 commit 和对应 Actions run 完全一致，并阅读 `junit.xml`、`xcodebuild.log`、`ci-failure-summary.md`。不能只看 Agent B 文字汇报，不能用旧 artifact 冒充本轮结果。

### 3.4 云端失败处理

云端失败时，Agent C 输出退回清单；Agent B 在 `main` 上追加修复 commit，再 push 触发新 run。默认不回滚远端 `main`，也不创建 PR 或候选分支。

如果云端环境缺依赖，必须说明哪个检查没跑、缺什么依赖、是否影响验收、需要人工提供什么。

## 4. 多分支 / 并发后的整合检查

多分支或多子 Agent 并发完成后，主 Agent 必须做轻量整合检查。即使不跑测试，也不能跳过冲突审查。

必查项：

- 同一文件是否被多个分支或子 Agent 修改。
- 同一 public API、类型名、枚举 case、JSON key 是否出现分叉。
- `WWIIHexV0.xcodeproj/project.pbxproj` 是否存在重复文件引用、缺失文件引用或 UUID 冲突。
- `Data/*.json` 与 `ScenarioDefinition` / `RegionDataSet` 是否同时变化但文档未同步。
- `Command` / `ZoneDirective` / `WarCommandExecutor` / `RuleEngine` 管线是否仍保持统一入口。
- `hexToTheater`、`hexToFrontZone`、`regionToTheater` 的权威边界是否被不同分支写成不同口径。
- README、`md/flow/*`、阶段 prompt、`update_log.md` 是否描述同一版本状态。

建议命令：

```sh
rg -n "struct |enum |class |protocol |case |func " WWIIHexV0 MapEditor
rg -n "hexToTheater|hexToFrontZone|regionToTheater|ZoneDirective|WarCommandExecutor|RuleEngine" WWIIHexV0 md README.md AGENTS.md
```

这些命令只用于定位冲突线索，不等于功能测试。

## 5. 历史测试基线

以下记录只用于理解历史状态，不作为当前任务的默认执行要求：

- v0.37 Probe：18 tests, 0 failures。
- v0.37 CommandSystemTests：15 tests, 0 failures。
- v0.37 Stage Regression：69 tests, 0 failures。
- v0.37 Full Regression：226 tests, 0 failures。

当前交付中若没有人工授权，统一写明：

```text
本机未跑 Xcode / XCTest / 模拟器 / 性能测试；按当前规范仅做轻量检查，重验证交给 GitHub Actions。
```

## 6. 决策表

| 场景 | 默认允许做什么 | 禁止默认做什么 |
|---|---|---|
| 文档改动 | 尾随空白、旧口径残留、YAML 解析、必要的 Markdown 人工阅读检查 | 本机 Xcode / XCTest |
| JSON 改动 | `jq empty` 查改动文件 | 本机启动游戏加载全场景 |
| project / scheme 改动 | 本机 `plutil` / `xmllint`；云端 main push 后跑 Xcode build | 本机 build-for-testing |
| 少量 Swift 改动 | 必要时单文件 `swiftc -parse`；云端 main push 后跑 Xcode build | 本机全项目 build / test |
| 大任务并发 | 文件/API/schema/文档冲突检查；云端 artifact 复核 | 以文字汇报代替结果包 |
| 版本分支候选 | 当前默认不走候选分支；人工授权时记录分支差异和风险 | 未检查冲突就合并 |

## 7. 交付写法

最终回复必须区分“本地轻量检查”“云端 workflow”和“未跑本机重测试”：

- 已跑：写具体命令和结果。
- 云端：写 commit SHA、run id、run attempt、artifact 名称和结果；Agent C 还要说明 manifest/JUnit/log 核对结果。
- 未跑：明确说明禁止或未授权的本机重测试类型。
- 风险：说明哪些功能正确性仍未通过运行时测试确认。

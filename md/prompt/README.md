# Prompt 阶段文档规则

本文记录 `md/prompt/` 下阶段提示词的写法和云端协作要求。历史 prompt 保留为上下文，不代表当前默认流程；若旧 prompt 与 `AGENTS.md`、`md/test/test.md` 冲突，以当前入口文档为准。

## 角色召唤

- `agenta`、`a:` 或 `A:` 开头：召唤 Agent A。最终回复第一行写 `我是 Agent A。`
- `agentb`、`b:` 或 `B:` 开头：召唤 Agent B。最终回复第一行写 `我是 Agent B。`
- `agentc`、`c:` 或 `C:` 开头：召唤 Agent C。最终回复第一行写 `我是 Agent C。`
- 没有这些前缀时，按普通 Codex 任务处理；若任务需要 A/B/C 边界，应提醒用户指定角色，或说明本轮按普通任务执行。

## Agent A 提示词必须包含

Agent A 写给 Agent B 的阶段提示词必须明确：

- 本轮目标、非目标、禁止项和业务边界。
- 当前架构依据：至少引用 `AGENTS.md`、`update_log.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/test/test.md` 和相关源码。
- 需要改动的模块、关键文件和可能冲突点。
- 本轮固定在 `main` 上实现、提交并 push 到 `origin/main`。
- Agent B 本地只跑 `md/test/test.md` 允许的轻量检查。
- GitHub Actions 云端重验证要求：workflow 名称、预期 run、未加密 artifact、manifest/JUnit/log/failure summary。
- Agent C 验收要求：下载 `/private/tmp/wwiihexv0-c-review-<run_id>/` 缓存，核对 `branch`、`commitSha`、`runId`、`runAttempt`、JUnit、主构建日志和失败摘要。
- 文档更新要求：按需同步 `README.md`、`AGENTS.md`、`md/flow/*`、`md/test/test.md`、`md/prompt/README.md`、`update_log.md`。
- 验收标准、遗留风险和未跑本机重测试的说明口径。

## main 直推阶段约定

当前默认协作制度不使用 `smalldata_test`、`develop`、`codeb/...`、候选分支或 PR 合并流。Agent B 的默认路径是：

```text
同步 origin/main
  -> git switch main
  -> git pull --ff-only origin main
  -> 小步实现
  -> 本地轻量检查
  -> commit
  -> git push origin main
  -> GitHub Actions 生成未加密结果包
```

Agent C 的默认路径是：

```text
确认 origin/main 最新 commit
  -> gh auth login
  -> 定位对应 Actions run
  -> 下载 artifact 到 /private/tmp/wwiihexv0-c-review-<run_id>/
  -> 核对 manifest / JUnit / build log / failure summary
  -> 通过则记录验收；失败则退回 Agent B 追加修复 commit
```

## 禁止照搬项目特例

本项目只迁移云端协作制度和 CI 结果包骨架。不要把 AITRANS 的漫画探针、GGUF、模型 Release、`test/1.png`、`smalldata_test` 或其他项目专属产物硬复制到 WWIIHexV0。

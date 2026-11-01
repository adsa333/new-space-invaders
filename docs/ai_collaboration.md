# AI 协作日志（AI Collaboration Log）

| 项目 | 内容 |
| --- | --- |
| 版本 | v0.1（模板） |
| 更新日期 | 2026-11-01 |

> 比赛评分含"大模型协作与技能包"。**从第一天开始记录**，纠错轨迹比成功记录更有价值。

## 记录格式

```
### 2026-11-01 / 角色 / 工具与模型
- 提问：（真实提示词，原样粘贴）
- 回答要点：（摘要）
- 采纳 / 否决 / 纠错：（模型哪里错了、怎么发现的、最终怎么改）
- 产出物：（文件路径）
```

## 日志

### 2026-11-01 / A / Codex
- 提问：帮我按照这个模板新建一个新的空仓库在 D 盘，文件夹叫 new-space-invaders，并同步到 GitHub 上
- 回答要点：按 `docs/repo_conventions.md` 冻结的目录结构生成骨架（docs/src/sim/constraints/build/scripts/board/data/metrics/skill/report/web-game），
  附 `.gitignore`、`.gitattributes`、MIT LICENSE、`create_project.tcl` 模板与各文档模板，初始化 git 并推送到远端。
- 采纳 / 否决 / 纠错：采纳目录骨架；文档内容全部为待填模板，避免把上一版工程的结论直接当成本工程结论。
- 产出物：仓库根目录 + `docs/`
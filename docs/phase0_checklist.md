# 第零阶段交付清单（Phase 0 Checklist）

| 项目 | 内容 |
| --- | --- |
| 版本 | v0.1（模板） |
| 更新日期 | 2026-11-01 |

## 1. 标准冻结

- [ ] 手势定义定稿（`docs/gesture_spec.md` v1.0）
- [ ] 时钟 / 复位 / 接口定稿（`docs/interface_spec.md` v1.0）
- [ ] 引脚约束初版通过（LED 闪烁验证）
- [ ] 目录结构与提交规范确认（`docs/repo_conventions.md`）

## 2. 环境

- [ ] Vivado 2026.1 安装并跑通示例工程
- [ ] xsim 仿真跑通（无需额外 license）
- [ ] VS Code + 插件安装
- [ ] Python 3.10+ 与 `requirements.txt` 安装完成
- [ ] 队友各自 clone 后能重建工程

## 3. 仓库

- [ ] 仓库建好、README 可执行
- [ ] `.gitignore` 生效（`git status` 无生成物）
- [ ] `scripts/create_project.tcl` 一键建工程
- [ ] AI 协作日志开始记录（`docs/ai_collaboration.md`）

## 4. 分工

| 角色 | 负责 | 交付物 |
| --- | --- | --- |
| A | 平台与集成 | 工程骨架、约束、构建脚本 |
| B | 视觉与手势 | 肤色分割、方向判定、仿真 |
| C | 游戏与显示 | 游戏核心、渲染、上板验证 |

## 5. 变更记录

| 版本 | 日期 | 变更内容 | 作者 |
| --- | --- | --- | --- |
| v0.1 | 2026-11-01 | 建立模板 | - |
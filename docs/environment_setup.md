# 环境搭建（Environment Setup）

| 项目 | 内容 |
| --- | --- |
| 版本 | v0.1（模板） |
| 更新日期 | 2026-11-01 |

## 1. 必装软件

| 软件 | 版本 | 用途 | 检查命令 |
| --- | --- | --- | --- |
| Vivado | 2026.1 | 综合 / 实现 / 仿真 / 烧写 | `vivado -version` |
| VS Code | 最新 | 编辑 + Markdown 预览 | `code -v` |
| Git | 最新 | 版本管理 | `git --version` |
| Python | 3.10+ | 图像算法验证、脚本 | `python --version` |
| Python 包 | 见 `requirements.txt` | OpenCV / NumPy / MediaPipe 等 | `pip list` |

> Vivado 安装路径统一为 `D:\fpga\2026.1`，`scripts/check_env.ps1` 按此路径检查。

## 2. VS Code 推荐插件

| 插件 | 用途 |
| --- | --- |
| Markdown Preview Enhanced | Markdown 预览、导出 |
| Verilog-HDL/SystemVerilog | 语法高亮、lint |
| Tcl | Tcl 语法高亮 |
| GitLens | Git 历史 |
| Chinese (Simplified) | 中文界面 |

## 3. 关键坑

1. **PowerShell 5.1 读中文脚本乱码**：`.ps1` 必须存成 UTF-8 with BOM，`.gitattributes` 里已固定 `eol=crlf`。
2. **Vivado 路径不要含空格/中文**，否则 Tcl `glob` 可能失败。
3. **工程路径用 `$PPRDIR`**，不要写死绝对路径，否则队友 clone 后打不开。

## 4. 自检

```powershell
.\scripts\check_env.ps1
```

输出全部 `OK` 才算环境就绪。

## 5. 变更记录

| 版本 | 日期 | 变更内容 | 作者 |
| --- | --- | --- | --- |
| v0.1 | 2026-11-01 | 建立模板 | - |
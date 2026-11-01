# new-space-invaders

> 空仓库骨架 —— 按 [docs/repo_conventions.md](docs/repo_conventions.md) 冻结的目录结构建立，
> 代码与文档内容待逐步填充。

| 项目 | 内容 |
| --- | --- |
| 阶段 | 第零阶段（骨架已建，内容待填） |
| 器件 | Artix-7 **XC7A100T-FGG484-2**（野火升腾 Pro） |
| 输入 | OV7725 摄像头（DVP 8bit / SCCB）+ 2 个按键 |
| 输出 | HDMI 640x480@60（SiI9134） |
| 工具链 | Vivado 2026.1（`D:\fpga\2026.1`） |
| 系统时钟 | 50 MHz（`sys_clk = W19`），`sys_rst_n = N15` |
| 许可 | MIT |

## 目录结构

```
new-space-invaders/
├─ README.md                 项目总览与复现入口
├─ LICENSE                   MIT
├─ docs/                     设计文档（接口规范、手势定义、协作日志等）
├─ src/
│   ├─ rtl/                  手写 Verilog / SystemVerilog
│   ├─ hls/                  Vitis HLS 源码
│   ├─ ps/                   PS 侧代码（本项目为纯 PL，一般留空）
│   └─ ip/                   IP 生成脚本或 .xci
├─ sim/                      Testbench 与测试向量
├─ constraints/              XDC 约束
├─ build/                    Vivado 工程与构建脚本（生成物不入库）
├─ scripts/                  自动化脚本（建工程、构建、环境自检）
├─ board/                    上板材料（接线图、引脚说明、比特流指纹）
├─ data/                     小型测试数据（大文件走 LFS 或网盘）
├─ metrics/                  指标与证据（metrics.csv、日志、截图）
├─ skill/                    可复用 Skill 与提示词模板
├─ report/                   设计报告、PPT、演示视频
└─ web-game/                 浏览器原型（算法验证 / 演示对比）
```

## 快速开始

```powershell
git clone https://github.com/adsa333/new-space-invaders.git
cd new-space-invaders
```

1. 环境自检：`.\scripts\check_env.ps1`
2. 重建 Vivado 工程：`vivado -mode batch -source scripts/create_project.tcl`
3. 打开 `build/new_space_invaders/new_space_invaders.xpr` 继续开发

## 文档索引

| 文档 | 内容 |
| --- | --- |
| [docs/interface_spec.md](docs/interface_spec.md) | 时钟 / 复位 / 接口 / 坐标（唯一权威） |
| [docs/gesture_spec.md](docs/gesture_spec.md) | 手势定义（唯一权威） |
| [docs/architecture.md](docs/architecture.md) | 系统架构与数据流 |
| [docs/hardware_setup.md](docs/hardware_setup.md) | 板卡、接线、供电 |
| [docs/environment_setup.md](docs/environment_setup.md) | 软件安装与验证 |
| [docs/phase0_checklist.md](docs/phase0_checklist.md) | 第零阶段交付清单 |
| [docs/test_plan.md](docs/test_plan.md) | 测试计划与用例 |
| [docs/repo_conventions.md](docs/repo_conventions.md) | 仓库使用规范（冻结） |
| [docs/ai_collaboration.md](docs/ai_collaboration.md) | 大模型协作日志 |

## 三条硬规矩

1. 目录与文件名只用**英文小写字母、数字、下划线、连字符**，中文只出现在文件内容里。
2. 工程**只由 Tcl 脚本重建**，不手工点 GUI 建工程；生成物（`.runs/`、`.bit`、`.dcp`）不入库。
3. 接口或手势定义的冻结项要改，先改文档、升版本号，再改 RTL。

## 许可

MIT，见 [LICENSE](LICENSE)。
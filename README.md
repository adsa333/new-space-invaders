# FPGA 双模式手势控制的《太空侵略者》

一块 XC7A100T 里同时驻留两套视觉前端——**全硬件 Lucas-Kanade 光流**与**肤色质心跟踪**，
外加一个完整的《太空侵略者》游戏内核。挥手即是摇杆，按一个键就能在两种"手感"之间切换。

| 项目 | 内容 |
|---|---|
| 目标平台 | 野火升腾 Pro，XC7A100T-FGG484-2 |
| 外设 | OV7725 摄像头（640×480@60fps，RGB565）+ HDMI 显示器（SiI9134） |
| 工具链 | Vivado 2026.1 |
| 顶层 | `top_cam_dual` |
| 代码规模 | 23 个 RTL 文件 / 3,573 行（SystemVerilog + Verilog-2001 板级驱动） |
| 实现结果 | LUT 17802（28.08%）、FF 7251（5.72%）、BRAM 51.5（38.15%）、DSP 12 |
| 时序 | WNS **+0.520 ns**、WHS +0.114 ns，16860 端点 0 违例 |
| 功耗 | 0.278 W（动态 0.178 + 静态 0.100），结温约 26 ℃，无需散热片 |
| 交互 | 手势左右移动 + key0 切模式 + key2 开始/暂停 + key3 重开 |

---

## 目录

- [1. 两种模式](#1-两种模式)
- [2. 目录结构](#2-目录结构)
- [3. 快速开始](#3-快速开始)
- [4. 设计要点](#4-设计要点)
- [5. 已知限制](#5-已知限制)
- [6. 复现提示](#6-复现提示)
- [文件索引](#文件索引)
- [许可证](#许可证)

## 文件索引

| 路径 | 内容 |
|---|---|
| `src/rtl/top_cam_dual.sv` | 顶层：时钟与复位、双前端例化、跨域同步、画中画合成 |
| `src/rtl/game_core.sv` | 游戏内核：状态机、55 只外星人、4 座掩体、UFO、计分与生命 |
| `src/rtl/lk_flow.sv`、`flow_fsm.sv` | 光流：16×16 块梯度累加与正规方程求解；漏桶积分与 2/3 投票出方向 |
| `src/rtl/div_pipe.sv` | 54 位定点除法器（QF=16，70 拍流水），供克莱姆法则求解用 |
| `src/rtl/gray_framebuf.sv`、`flow_linebuf.sv`、`flow_tag_ram.sv` | 光流用的灰度帧缓冲、行缓存与块标签 |
| `src/rtl/centroid_calc.sv`、`dir_judge_acc.sv` | 质心：面积/一阶矩统计；泄漏积分器判方向（慢速可用） |
| `src/rtl/rgb2gray.sv`、`rgb2ycrcb.sv`、`bin_frame_buf.sv` | 两套前端的像素预处理与二值图缓存 |
| `src/rtl/sprite_render.sv`、`vga_timing.sv` | 扫描线实时渲染；640×480@60 Hz 视频时序 |
| `src/rtl/debounce.sv` | 按键消抖（250000 拍 ≈ 5 ms） |
| `src/board_cam/` | OV7725 采集与 SCCB 配置（69 条寄存器，RGB565） |
| `src/board_hdmi/` | SiI9134 配置与 I2C 主机 |
| `sim/tb_dir_judge_acc.sv` | 方向判决 8 项检查，含 ±3 px 抖动零误触发 |
| `sim/tb_game_core.sv` | 游戏内核 14 项断言（`TICK_DIV` 快进到 60 Hz） |
| `sim/run_sim.bat`、`sim/sim_log.txt` | 仿真回归脚本与 22/22 通过的结果记录 |
| `build/build.tcl`、`build/rerun_impl.tcl` | 一键构建（建工程→IP→综合→实现→bit→5 份报告）；只重跑实现 |
| `build/report/10_util.rpt` 等 6 份 | 资源、分层资源、时序、DRC、方法论、功耗实测报告 |
| `board/top_cam_dual.xdc` | 54 个引脚约束（含两路时钟与跨域 false_path） |
| `board/top_cam_dual.bit` | 已验证比特流，可直接烧录 |
| `board/program.tcl`、`board/README.md` | 命令行烧录脚本与板级说明 |
| `data/README.md` | 仿真黄金参考、实现实测指标、版本对比 |
| `report/report.md`、`report/ai_collaboration.md` | 设计报告；大模型协作记录（含纠错轨迹） |
| `skill/README.md` | 可复用经验包 S1~S10 |

## 1. 两种模式

| 模式 | 原理 | 分辨率 | 灵敏度 | 特点 |
|---|---|---|---|---|
| **光流**（默认） | 分块 Lucas-Kanade，16×16 块解正规方程 | 320×240 灰度，20×15=300 块/帧 | 0.125 px/帧（≈3.75 px/s） | 快，看的是"动"，静态手势无效 |
| **质心** | YCbCr 肤色分割 + 背景差分 + 质心位移 | 640×480 全分辨率 | 泄漏积分器，≈60 px/s 起 | 慢也能动，画中画显示手的白色轮廓 |

`key0` 任意时刻切换（整局复位回待机）。指示灯：`led_left` 亮=光流，`led_right` 亮=质心。

### 质心模式的慢速判定

早期版本要单帧位移 > 9 px 才认为"在移动"，30 fps 下等于 270 px/s，慢挥手完全不动。
现改为**泄漏积分器**：每帧 `acc = acc - (acc >> 3) + dx`，`|acc| ≥ 16` 才触发并扣掉额度。

| 手速 | 每帧位移 | 表现 |
|---|---|---|
| 很快 | > 9 px | 立即连续移动（原行为） |
| 中速 | 4~9 px | 积累 2~4 帧后连续移动 |
| 慢速 | 2~4 px | 脉冲式爬行（走一步停一步） |
| 几乎不动 | < 2 px | 不动（±3 px 抖动的稳态积分约 3.5，距门限 16 有 4.6σ 余量） |

---

## 2. 目录结构

```
src/rtl/        SystemVerilog 设计（23 个中的 16 个：游戏、光流、质心、顶层）
src/board_cam/  OV7725 驱动（Verilog-2001：ov7725_top/cfg/data + cam_i2c_ctrl）
src/board_hdmi/ HDMI 芯片配置（hdmi_cfg/hdmi_i2c + i2c_ctrl）
sim/            testbench 与回归脚本（run_sim.bat，结果 sim_log.txt）
build/          build.tcl 一键构建 + report/ 综合实现报告
board/          引脚约束、烧录脚本、已验证比特流
data/           仿真黄金参考与实测指标汇总
skill/          可复用经验（技能包）
report/         设计报告 + 大模型协作记录
```

## 3. 快速开始

```bash
# 1) 构建（约 12 分钟，产出 build/report/*.rpt 与 bit）
vivado -mode batch -source build/build.tcl

# 2) 仿真回归（约 20 秒，产出 sim/sim_log.txt）
sim\run_sim.bat

# 3) 烧录（板子插好 USB、上电）
vivado -mode batch -source board/program.tcl
```

`build/build.tcl` 会自动建工程、生成 `hdmi_pll`（MMCM 50→25 MHz）、综合、实现、
写比特流，并导出资源/时序/DRC/方法论/功耗五份报告。只想重跑实现（改约束后验证时序）用
`build/rerun_impl.tcl`。

## 4. 设计要点

- **三个时钟域**：`cam1_pclk` 24 MHz（摄像头，XCLK 24 MHz 不分频）、`sys_clk` 50 MHz
  （游戏逻辑，60 Hz tick = TICK_DIV 833333）、`clk_25m` 25 MHz（像素渲染与 HDMI）。
  game_core 状态用 toggle 信箱整包跨域（54 位玩家子弹 + 1152 位掩体一次搬完），
  方向指令用两级同步器，模式位反向也走两级同步器。
- **光流**：灰度帧缓冲 → 16×16 块梯度累加 → 正规方程 `[A B;B C][u;v]=[-D;-E]` →
  克莱姆法则解（`det=AC-B²`，`DET_MIN=1e6` 过滤孔径问题）→ 除法器 70 拍流水 →
  漏桶积分（`TH_BUCKET=3`，上限 8）→ 投票（2/3 多数）出方向脉冲。
- **质心**：RGB→YCbCr，`Cr−Cb ≥ 14` 且 `Cb∈[92,128]`、`Cr∈[135,180]` 判肤色；
  背景差分 `|Y−bg|>16` 去掉静止家具；二值图求质心和面积，面积门槛滤掉噪点。
- **显示**：`sprite_render` 按扫描线实时合成（无帧缓冲），外星人 11×5=55 只、
  4 座可破坏掩体、UFO、掩体按位图存储；画中画 160×120 显示光流矢量场或手的轮廓。

## 5. 已知限制

- 光流模式对光照突变敏感（无自动曝光），摄像头固定曝光后需重新标定；
- 质心模式依赖肤色与背景对比，深色衣物/同色背景会失效；
- 掩体位图用 `case` 返回固定基地址来规避大位宽变量下标导致的综合卡死；
- 未实现音频输出。

## 6. 复现提示

- 引脚见 `board/top_cam_dual.xdc`（54 个 IOB）；
- `cam1_pclk` 的 `CLOCK_DEDICATED_ROUTE FALSE` 是必需的（24 MHz 走普通布线足够）；
- `sys_clk → cam1_pclk` 需要显式 `set_false_path`，否则该路径按单周期分析会报 −2.932 ns；
- 仿真时 `xvlog` 必须带 `-sv`，否则 `signed` 等关键字会报 `VRFC 10-4982`。

---

## 许可证

初版为单模式光流版（2026-10-30 提交），当前为双模式合并版。设计报告见
[`report/report.md`](report/report.md)，指标明细见 [`data/README.md`](data/README.md)。

本项目采用 [MIT 许可证](LICENSE)。
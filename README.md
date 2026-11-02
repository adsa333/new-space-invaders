# FPGA 双模式手势控制的《太空侵略者》

> 2026 全国大学生嵌入式芯片与系统设计竞赛 · FPGA 创新设计赛道（AMD）· 自主选题赛道 · 初级组

对着摄像头**挥一挥手**就能左右移动激光炮台——不是按键、不是手机 App，而是 FPGA 内部
用纯硬件算出来的运动方向。更特别的是：**一块 XC7A100T 里同时驻留着两套视觉前端**，
一套是 Lucas-Kanade 光流（300 个图像块并行解算运动矢量），一套是肤色质心
（640×480 全分辨率二值化 + 背景差分 + 轮廓提取）。两套算法共用一路摄像头数据、
同一套跨时钟域结构、同一个游戏内核，**一个比特流、按键随时切换**。

| | |
|---|---|
| 器件 | 野火升腾Pro **XC7A100T-FGG484-2** |
| 输入 | OV7725 摄像头（DVP 8bit / SCCB 配置）+ 3 个按键 |
| 输出 | HDMI 640×480@60（24bit RGB）+ 右上角 160×120 画中画 |
| 工具链 | **Vivado 2026.1** |
| 规模 | 23 个源文件 / 3,573 行（SystemVerilog + Verilog-2001 板级驱动） |
| 时钟域 | `cam1_pclk` 24 MHz（摄像头）/ `sys_clk` 50 MHz（游戏）/ `clk_25m` 25 MHz（显示） |
| 实测 | LUT **17,802（28.1%）**、FF 7,251、BRAM **51.5（38.2%）**、DSP 12、WNS **+0.520 ns**、功耗 **0.278 W** |

## 两种手势模式

| | 光流模式（默认） | 肤色质心模式 |
|---|---|---|
| 算法 | Lucas-Kanade，20×15=300 块并行，Q16 定点，自研 70 拍流水除法器 | Cb/Cr 肤色判据 + 背景差分 + 轮廓提取，640×480 全分辨率 |
| 判据 | 逐块投票 → 帧方向判定 → 漏桶积分（±8） | 帧间质心位移 → 泄漏积分器（`acc ← acc − acc/8 + dx`，门限 16） |
| 手感 | 极灵敏，0.125 px/帧即可响应（≈3.75 px/s） | 稳健，慢速也能爬动（≈60 px/s 起），静止抖动不误触发 |
| 画中画 | 矢量场（红=向左 / 绿=向右 / 深灰=静止） | 手势轮廓（白）+ 红色十字准星 |
| 指示 | `led_left` 亮 | `led_right` 亮 |

质心模式的慢速判定是这一版新增的：原先只看单帧 |dx| > 9 px（30 fps 下等于 270 px/s），
手慢慢移动永远进不了门；现在改成带泄漏的累积器，慢漂移会一点点攒到门限，而零均值的
静止抖动攒不起来。速度档位：> 9 px/帧立即连续 → 4~9 短积累后连续 → 2~4 脉冲式慢爬 → < 2 静止。

## 操作方式

```
key0 (V17)   任意时刻切换模式 —— 当前局作废、回到待机画面，key2 开新局
key2 (AA18)  开始 / 暂停 / 继续
key3 (AB18)  同模式重开
```

切换时整局复位是**故意的**：两套前端的坐标尺度与手感不同，带着残局切换容易出现
诡异状态，干净重来最稳。

## 作品特性

1. **双前端共存**：两套视觉方案在同一个比特流里运行，只在 `cam1_pclk` 域的方向出口处
   二选一；相对光流单版只多 **+1,537 LUT（+2.4 个百分点）、+3 BRAM**
2. **纯硬件光流**：`lk_flow` 对 300 个图像块并行解算 (u,v)，Q16 定点，克莱姆法则解正规方程，
   自研 70 拍流水除法器（无 IP、无 DSP 除法）
3. **鲁棒判决**：`flow_fsm` 三级决策（逐块投票 → 帧方向判定 → 漏桶积分），单帧误判被滤除，
   静止自动回中立
4. **慢速可用**：质心模式新增泄漏积分器 `dir_judge_acc`，慢挥手也能爬动，静止零误触发
5. **可解释的调试**：右上角画中画把算法"看得见"——光流看矢量场，质心看轮廓与质心
6. **完整街机规则**：55 只外星人（11×5）、4 座可逐位破坏的掩体、UFO、波次递进、胜负结算
7. **工程化跨域**：3 个时钟域，2FF 同步器 + toggle 信箱整包快照，
   跨域例外路径**双向** `set_false_path`
8. **时序有余量**：0 违例端点（16,860 个端点），WNS +0.520 ns / WHS +0.114 ns

## 目录结构

```
├── README.md                 本文件：项目简介 + 复现步骤
├── src/rtl/*.sv              16 个 SystemVerilog：游戏 / 光流 / 质心 / 渲染 / 顶层
├── src/board_cam/*.v         OV7725 驱动（SCCB 配置 + DVP 采集）
├── src/board_hdmi/*.v        HDMI 发送芯片 I2C 配置
├── sim/                      testbench 与回归脚本（run_sim.bat、sim_log.txt）
├── build/                    build.tcl 一键构建 + report/ 六份实测报告
├── board/                    引脚约束、烧录脚本、已验证比特流
├── data/                     仿真黄金参考与实测指标汇总
├── skill/                    技能包 S1~S10（全部来自真实踩坑）
└── report/                   设计报告 + 大模型协作记录
```

## 快速开始

### 构建（一条命令，约 12 分钟）

```bash
vivado -mode batch -source build/build.tcl
# 产出 → build/dual/dual.runs/impl_1/top_cam_dual.bit
#        build/report/{10_util,11_util_hier,20_timing,30_drc,40_methodology,50_power}.rpt
```

`PROJ` 环境变量可换工程目录名（默认 `dual`）。只改约束、想重跑实现用 `build/rerun_impl.tcl`。

### 上板

```bash
vivado -mode batch -source board/program.tcl
```

摄像头朝向操作者，距离 30~50 cm、镜头略向下，光照充足、背景单色少纹理。
key2 开局 → 挥手左右移动炮台 → key0 切模式 → key3 重开。

### 仿真

```bash
xvlog -sv src/rtl/dir_judge_acc.sv sim/tb_dir_judge_acc.sv
xelab -debug typical tb_dir_judge_acc -s sim_dja
xsim sim_dja -R
# 实测输出：CHECK1~8 全 PASS，==== TB RESULT: 0 ERRORS ====
```

游戏内核回归：`sim/tb_game_core.sv`（`TICK_DIV` 参数加速，14 条断言全过）。
两条一起跑用 `sim\run_sim.bat`，结果写在 `sim/sim_log.txt`（22/22 通过）。

## 文档索引

| 文档 | 内容 |
|---|---|
| [report/report.md](report/report.md) | 设计报告正文 |
| [report/ai_collaboration.md](report/ai_collaboration.md) | 大模型协作记录（13 条，含纠错轨迹） |
| [data/README.md](data/README.md) | 仿真黄金参考、实现实测指标、版本对比 |
| [board/README.md](board/README.md) | 板级说明：引脚、烧录、上板验证 |
| [skill/README.md](skill/README.md) | 技能包 S1~S10 |
| [build/report/00_metrics.txt](build/report/00_metrics.txt) | 本次构建的指标摘要 |

## 已知限制

- **质心模式的肤色阈值是按自动曝光标定的**，而 `src/board_cam/ov7725_cfg.v` 是光流版调的
  固定曝光。上板后若质心模式偏色或漏检，改 `src/rtl/top_cam_dual.sv` 顶部的
  `CB_LO/CB_HI/CR_LO/CR_HI/WARM_MIN` 五个 `localparam` 即可，不用动判定结构
- 合并版 WNS（+0.520 ns）比光流单版（+3.428 ns）低，原因是 `dir_judge_acc` 在 24 MHz 域里
  加了 14 位符号累加/比较；改 `game_core` 前建议重查时序
- 光流模式对光照突变敏感（无自动曝光）；质心模式依赖肤色与背景对比，
  深色衣物 / 同色背景会失效
- 掩体位图用 `case` 返回固定基地址来规避大位宽变量下标导致的综合卡死；未实现音频输出
- 单模式工程（光流单版、按键版）不在本仓库，见主仓库 `fpga_space_invaders`

## 许可

MIT，见 [LICENSE](LICENSE)。
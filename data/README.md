# 测试数据与参考结果

## 1. 仿真黄金参考（本仓库实测，2026-11-02）

| 项目 | 结果 |
|---|---|
| 工具 | Vivado Simulator 2026.1（`sim\run_sim.bat`） |
| 用例 1 | `tb_dir_judge_acc` — 质心模式慢速判定，**8/8 PASS，0 ERROR** |
| 用例 2 | `tb_game_core` — 游戏内核，**14/14 断言 PASS**（TICK_DIV=10 加速） |
| 原始日志 | [`../sim/sim_log.txt`](../sim/sim_log.txt) |

`tb_dir_judge_acc` 覆盖的 8 项：

```
CHECK1 规律抖动 ±2 x80 帧      -> 不动
CHECK2 随机抖动 ±3 x300 帧     -> 不动
CHECK3 慢速 -3px/帧 x60        -> 出脉冲（触发 16 帧，最长连续 4）
CHECK4 中速 -5px/帧            -> 连续移动
CHECK5 快速 -15px/帧           -> 立即触发
CHECK6 快速反向                -> 立刻换向
CHECK7 无手（valid=0）         -> 回 IDLE
CHECK8 慢速 +3px/帧 x60        -> 右移脉冲（触发 32 帧）
```

`tb_game_core` 覆盖的 14 条：复位后 IDLE / 生命 6 / 55 只外星人 / 掩体完整 / stage=1 /
开始进 PLAY / win=0 / 自动射击 / 左右移动 / 打中得分 / 敌机开火 / UFO 由 LFSR 生成 /
被击中掉命。

## 2. 综合与实现实测（Vivado 2026.1 真实运行）

| 指标 | 值 |
|---|---|
| 器件 / 顶层 | `xc7a100tfgg484-2` / `top_cam_dual` |
| LUT / FF | **17,802（28.08%）** / **7,251（5.72%）** |
| BRAM / DSP | **51.5（38.15%）** / **12（5.00%）** |
| 时序 | WNS **+0.520 ns**、WHS **+0.114 ns**（16,860 端点，0 失败） |
| 功耗 | **0.278 W**（动态 0.178 + 静态 0.100），结温 25.7 ℃ |
| 比特流 | 3,825,992 B |

时钟：`cam1_pclk` 41.667 ns（24 MHz）/ `sys_clk` 20.000 ns（50 MHz）/
`clk_out1_hdmi_pll` 40.000 ns（25 MHz）。

### 双前端共存的代价

| 版本 | LUT | FF | BRAM | DSP | WNS |
|---|---|---|---|---|---|
| 光流单版 | 16,265 | 6,800 | 48.5 | 12 | +3.428 |
| 质心单版 | 16,774 | — | 3 | 0 | — |
| **双模式合并版** | **17,802** | **7,251** | **51.5** | **12** | **+0.520** |

两套前端共用游戏内核与显示通路，合并只多花 **1,537 LUT（+9.4%）**、
**3 BRAM**，DSP 无增加；代价是最差裕量从 +3.428 ns 降到 +0.520 ns
（质心累加器在 24 MHz 像素域），仍为 0 违例。

### 分层资源（`build/report/11_util_hier.rpt`）

| 模块 | LUT | FF | 说明 |
|---|---|---|---|
| `u_game`（game_core） | 11,054 | 1,788 | 游戏状态机、敌机阵列、掩体、碰撞 |
| `u_flow`（lk_flow） | 2,597 | 3,228 | 光流核心，占 BRAM 48、DSP 12 |
| `u_vga`（vga_timing + sprite_render 内联） | 2,920 | — | 扫描线实时合成 |
| `u_cent`（centroid_calc） | 376 | 318 | 质心与面积 |
| `u_cam`（ov7725_top） | 350 | 80 | 摄像头时序与 SCCB |
| `u_div`（div_pipe） | 368 | 219 | 70 拍流水除法 |
| `u_ycc`（rgb2ycrcb） | 161 | — | 颜色空间转换 |

## 3. 板级 vs 仿真比对

| 项目 | 仿真/实现 | 板级实测 | 结论 |
|---|---|---|---|
| 游戏可玩性 | 14/14 断言 | 待填（照片/视频） | — |
| 光流方向正确率 | 静态激励通过 | 待填 | — |
| 质心抖动抑制 | ±3 px 零误触发 | 待填 | — |
| 模式切换 | — | 待填 | — |

板级素材（接线照片、两种模式录像）尚未入库，见 [`../board/README.md`](../board/README.md)。

## 4. 文件说明

| 文件 | 来源 | 用途 |
|---|---|---|
| `sim/sim_log.txt` | xsim 批处理 | 证明功能正确（8+14 项） |
| `build/report/10_util.rpt` | Vivado | 资源占用原始证据 |
| `build/report/11_util_hier.rpt` | Vivado | 分层资源 |
| `build/report/20_timing.rpt` | Vivado | 时序与时钟表 |
| `build/report/30_drc.rpt` | Vivado | DRC |
| `build/report/40_methodology.rpt` | Vivado | 方法论检查 |
| `build/report/50_power.rpt` | Vivado | 功耗估算 |
| `board/top_cam_dual.bit` | Vivado | 已验证比特流（可直接烧） |
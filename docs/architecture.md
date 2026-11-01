# 系统架构（Architecture）

| 项目 | 内容 |
| --- | --- |
| 版本 | v0.1（模板） |
| 更新日期 | 2026-11-01 |

## 1. 总体框图

```
        OV7725                ┌──────────────────────────┐
   ┌──────────────┐  DVP      │        FPGA (PL)         │
   │  cam_capture │──────────>│  gesture_pipeline        │
   └──────────────┘  pclk     │        │                 │
                             │        v                 │
   按键 key0/key1 ──────────>│  gesture_cmd (level/edge)│
                             │        │                 │
                             │        v                 │
                             │  game_core  ──>  render   │
                             └────────┬─────────────────┘
                                      v
                              HDMI (SiI9134) 640x480@60
```

（用 draw.io 画正式图后替换本段，图源放 `docs/diagrams/`。）

## 2. 模块划分

| 模块 | 时钟域 | 职责 | 负责人 |
| --- | --- | --- | --- |
| `cam_capture` | `cam_pclk` | DVP 采集、行缓存 | 待定 |
| `skin_segment` | `cam_pclk` | 肤色分割 + 质心统计 | 待定 |
| `gesture_fsm` | `sys_clk` | 方向判定、滞回、命令输出 | 待定 |
| `game_core` | `sys_clk` | 游戏规则、碰撞、计分 | 待定 |
| `sprite_render` | `clk_pix` | 像素级渲染 | 待定 |
| `hdmi_timing` | `clk_pix` | 640x480@60 时序 | 待定 |

## 3. 时钟域与 CDC

| 源 | 目标 | 方法 | 约束 |
| --- | --- | --- | --- |
| `cam_pclk` | `sys_clk` | 双触发器同步 + 数据稳定期采样 | `set_false_path` |
| `sys_clk` | `clk_pix` | 双口 RAM 信箱快照 | `set_max_delay -datapath_only` |

## 4. 风险清单

| 编号 | 风险 | 影响 | 缓解措施 | 状态 |
| --- | --- | --- | --- | --- |
| R1 | 肤色在不同光照下漂移 | 识别失效 | 每次上电采样 + 合理性检查 | 待验证 |
| R2 | `cam_pclk` 非专用时钟引脚 | 时序隐患 | 降频、约束说明、必要时改引脚 | 待验证 |
| R3 | 只有 JTAG 烧写 | 掉电丢失 | 交付前写 QSPI Flash | 未开始 |

## 5. 变更记录

| 版本 | 日期 | 变更内容 | 作者 |
| --- | --- | --- | --- |
| v0.1 | 2026-11-01 | 建立模板 | - |
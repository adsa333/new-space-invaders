# metrics —— 指标与证据

本目录按提交模板分为四块：指标表、日志、证据、脚本。

## 1. `metrics.csv`（指标总表）

列定义：`date,stage,metric,value,unit,note`

| 字段 | 含义 |
|---|---|
| `date` | 数据产生的日期（YYYY-MM-DD） |
| `stage` | 指标所属阶段：`impl`（实现后）/ `power`（功耗）/ `sim`（仿真）/ `vision`（算法）/ `timing`（时钟） |
| `metric` | 指标名，小写下划线，如 `lut`、`wns`、`total_power` |
| `value` | 数值；成对结果写成 `8/8` 这样的字符串 |
| `unit` | 单位：`count`、`%`、`ns`、`W`、`MHz`、`fps`、`px/frame`、`px/s`、`degC` |
| `note` | 口径说明（数据来自哪份报告、拆分明细等） |

**数据来源**：`stage=impl/power` 的行全部抄自 `build/report/` 下的六份报告
（`10_util.rpt`、`11_util_hier.rpt`、`20_timing.rpt`、`50_power.rpt`、`00_metrics.txt`），
`stage=sim` 的行来自 `metrics/logs/sim_log.txt`，`stage=vision/timing` 的行来自 RTL 参数与 XDC。

## 2. `logs/`（原始日志）

| 文件 | 内容 |
|---|---|
| `sim_log.txt` | `sim/run_sim.bat` 的完整输出：`tb_dir_judge_acc` 8 项检查 + `tb_game_core` 14 条断言 |
| `build.log` | 一次完整构建的 Vivado 日志（`scripts/build.tcl`） |

## 3. `evidence/`（板级证据）

> **当前为空 —— 这是提交前必须补齐的一项。**

| 待补素材 | 拍摄/导出要求 | 对应指标 |
|---|---|---|
| 整机接线照 | 板子 + 摄像头 + 显示器 + 电源同帧 | 硬件连接真实性 |
| 上电运行照 | HDMI 出画面的全景 | 可运行 |
| 光流模式录像 15~20 s | 挥手 → 炮台左右移 → 画中画矢量场变色 → `led_left` 亮 | 灵敏度 0.125 px/帧 |
| 质心模式录像 15~20 s | 白色轮廓 + 红十字跟随 → 慢速挥手炮台仍移动 | 最小速度 ≈60 px/s |
| key0 切换录像 10 s | 切换瞬间 LED 换向、画中画换色 | 双前端共存 |
| 标定截图 | 按住 key1 时标定框由黄转绿的一帧 | 自适应标定 |
| （可选）示波器波形 | `cam1_pclk` 24 MHz、`hdmi_out_clk` 25 MHz | 时钟域 |

## 4. `scripts/`

指标由 `scripts/build.tcl` 在构建末尾自动汇总到 `build/report/00_metrics.txt`；
`metrics/scripts/` 预留给"从报告生成本表"的脚本，目前不需要——`metrics.csv` 为手工誊写，
每一行都能在 `build/report/` 里找到出处，便于评审核对。
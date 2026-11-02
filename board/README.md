# 上板工程与实测

## 1. 硬件连接

| 部件 | 接口 | 说明 |
|---|---|---|
| 开发板 | 野火升腾 Pro（XC7A100T-FGG484-2） | 板载 50 MHz 晶振 |
| 摄像头 | OV7725，接 2×7 排针 | 板载 24 MHz XCLK 直接进摄像头，RGB565 并口 8 位 |
| 显示器 | HDMI，经 SiI9134 编码 | 800×525@25 MHz，有效区 640×480@60 Hz |
| JTAG | Micro USB | Digilent 下载器，`localhost:3121` |

摄像头布置要求：镜头朝下、距手 30~50 cm；背景尽量单色少纹理；光源固定，
关闭自动曝光（否则肤色阈值需重新标定）。

## 2. 引脚约束

`top_cam_dual.xdc` 共约束 **54 个 IOB**：

| 组 | 数量 | 备注 |
|---|---|---|
| 时钟与复位 | 2 | `sys_clk` W19（50 MHz）、`sys_rst_n` N15 |
| 摄像头并口 | 15 | `cam1_pclk` AA21、`cam1_href` T21、`cam1_vsync` T18、`cam1_data[7:0]`、`sccb1_scl/sda`（复用为 SCCB，R14/P14）、`cam_rst_n` P16、`cam_pwdn` R17 |
| 按键 | 3 | `key0` V17（切模式）、`key2` AA18（开始/暂停）、`key3` AB18（重开），低有效 |
| HDMI 并口 | 29 | `hdmi_out_clk` K18、`hsync` K17、`vsync` J17、`de` K19、`rgb[23:0]`、`rst_n` J16 |
| DDC | 2 | `ddc_scl` E19、`ddc_sda` D19（上电读 EDID 配 SiI9134） |
| LED | 3 | `led_stop` M21（恒 0，预留）、`led_left` L21（亮=光流）、`led_right` K21（亮=质心） |

两处容易踩的坑：

1. `cam1_pclk` 走的是普通布线，需要 `set_property CLOCK_DEDICATED_ROUTE FALSE`；
2. `sys_clk → cam1_pclk` 必须显式 `set_false_path`，否则工具按单周期分析会报 −2.932 ns。

## 3. 烧录

```bash
# 仓库内已带已验证比特流
vivado -mode batch -source board/program.tcl

# 若自行构建过，脚本会优先烧 build/dual/.../top_cam_dual.bit
set PROJ=dual && vivado -mode batch -source board/program.tcl
```

成功标志：`End of startup status: HIGH`。
若报 "找不到 JTAG 目标"，检查板子是否上电、USB 是否插好、`hw_server` 是否在 3121 端口。

## 4. 操作

| 按键 | 功能 |
|---|---|
| `key0` | 切换光流 / 质心模式（任意时刻，整局复位回待机） |
| `key2` | 开始 / 暂停 |
| `key3` | 重开一局 |

显示内容：顶部 HUD（分数 / 波次 / 生命）、11×5 外星人阵列、4 座可破坏掩体、
玩家飞船与子弹、敌方弹幕、随机 UFO；右上角画中画 160×120 实时显示视觉前端的中间结果
（光流=彩色矢量场，质心=手的白色轮廓与红色质心十字）。

## 5. 实测记录

| 项目 | 状态 | 证据 |
|---|---|---|
| 比特流烧录 | ✅ 已实测（2026-11-01 12:53，`End of startup status: HIGH`） | 见 `data/README.md` |
| 光流模式挥手控制 | ⬜ 待补照片/录像 | — |
| 质心模式轮廓显示 | ⬜ 待补照片/录像 | — |
| `key0` 模式切换 | ⬜ 待补照片/录像 | — |
| 长时间运行稳定性 | ⬜ 待补 | — |

> 板级照片与录像尚未入库，是本仓库目前唯一缺失的一类材料。
# AI 协作日志（AI Collaboration Log）

> 比赛评分项「大模型协作与技能包」占 15 分。本文件**从第一天开始记录**，且必须包含
> **失败与纠错轨迹**，不能只写成功案例。禁止事后补写、禁止伪造。

**记录格式**

```
### YYYY-MM-DD | 角色 | 工具与模型
- 目标：
- 提问（原样粘贴）：
- 回答要点：
- 采纳 / 否决 / 纠错：
- 产出物：
```

---

### 2026-10-11 | A（平台与集成） | Codex（GPT-5 系列，桌面版）

**目标**：完成第零阶段四项交付物——手势定义、时钟与接口标准、软件环境安装、仓库规范。

**提问（原样粘贴）**

```
第零阶段-本周周日：
定义四种用到的手势，确认全过程用的时钟频率、什么接口等关键标准。
安装vs code、vivado仿真、python图像处理库等其他的所需软件，约定仓库使用规范。
```

**过程**

1. 扫描工作区：`D:\fpga`（含比赛指南 PDF、LaTeX 计划书）、`D:\fpga\fpga_space_invaders`（git 仓库，远端 `Chen-Yinong/fpga_space_invaders`）。
2. 读取 `fpga_space_invaders_plan.tex`，提取角色划分（A 平台/集成、B 视觉/HLS、C 游戏/显示/验证）、WP0–WP6 工作包、架构链路与风险清单。
3. 探测本机环境：
   - `git --version` -> 2.56.0.windows.2（`D:\fpga\Git\cmd\git.exe`）
   - `python --version` -> **无输出且退出码 1**；`py -0p` -> Python 3.13.5
   - `node --version` -> v24.19.0
   - `code --version` -> 命令不存在；注册表查询 -> 未安装
   - `D:\fpga\2026.1\Vivado\bin` -> Vivado/Vitis 2026.1 已安装但不在 PATH
4. 安装软件：`winget install Microsoft.VisualStudioCode --scope user`；`py -m pip install -r requirements.txt` 等价包；`py -m pip install cocotb`。
5. 产出文档 `docs/gesture_spec.md`、`docs/interface_spec.md`、`docs/environment_setup.md`、`docs/repo_conventions.md`、`docs/phase0_checklist.md`，以及 `scripts/check_env.ps1`、`requirements.txt`。

**采纳**

- 以「传统视觉特征 + 小型决策器」而非 CNN 作为手势方案（与计划书一致，7 Series 资源可承受）。
- 手势方案确定为：移动用**空间位置 + 迟滞**，射击用**开合度下降沿**，开始用**往复挥手计数**；三者特征正交，可同时操作。
- 独热命令编码 `cmd[3:0]` + 单比特 `cmd_valid` 跨时钟域，避免多比特跨域毛刺。
- 采用 `scripts/check_env.ps1` 作为环境唯一验收入口（可重复、可交接）。

**纠错轨迹（重要）**

| # | AI 的错误 / 缺陷 | 发现方式 | 修正 |
| --- | --- | --- | --- |
| 1 | 首版 `check_env.ps1` 写成 **UTF-8 without BOM** | 执行脚本报 `Unexpected token 'PASS'`、`Missing closing '}'`，中文全部乱码 | 改为 **UTF-8 with BOM**，并在 `environment_setup.md` 第 3 节把「.ps1 必须带 BOM」列为硬性注意事项 |
| 2 | 脚本用 `code --version` 取版本，返回空字符串 | 自检输出 `VS Code PASS  | ...`（版本列为空） | 改用 `(Get-Item Code.exe).VersionInfo.ProductVersion`，得到 1.141.0 |
| 3 | 脚本读取 `Vivado\data\version` 作版本号，文件不存在 | 输出 `[版本 (未知版本)]` | 该路径实际文件是二进制 `version.dat`，改为从安装目录名 `2026.1` 推导版本 |
| 4 | 最初假设 `python` 命令可用 | `python --version` 无输出、退出码 1 | 查明是 **Microsoft Store 占位程序**；项目统一改用 `py -3` 或虚拟环境 python，并在文档中列为「关键坑」 |
| 5 | `environment_setup.md` 第 2.6 节误写入一行无关的 `winget install --id Bleachbit.BleachBit` | 自查文档时发现 | 删除，替换为正确的 iverilog 安装方式（choco / 官方安装包） |

> 说明：第 1 条是最典型的一类问题——AI 生成的脚本在本机「看起来没问题」，但被执行环境
> 的编码假设打败。这类问题只有**真的跑一遍**才能发现，因此本项目规定：任何脚本交付前必须实际执行。

**产出物**

| 路径 | 内容 |
| --- | --- |
| `docs/gesture_spec.md` | 四种手势定义（唯一权威），v1.0 冻结 |
| `docs/interface_spec.md` | 时钟/复位/总线/分辨率/坐标/延迟预算/端口契约，v1.0 冻结 |
| `docs/environment_setup.md` | 工具清单、安装步骤、常见坑、自检流程 |
| `docs/repo_conventions.md` | 目录/命名/分支/提交/PR/数据/AI 记录规范 |
| `docs/phase0_checklist.md` | 第零阶段交付清单与遗留问题 |
| `scripts/check_env.ps1` | 环境自检脚本（UTF-8 with BOM） |
| `requirements.txt` | Python 依赖声明 |

**待验证（不得当作已结论）**

- 手势阈值（张开 480 / 握拳 300 / 面积 2000–120000）为**基于经验的首版默认值**，
  必须由 B 用真实采集数据标定后才能写进最终报告。
- 「挥手计数」作为开始手势在现场光照下是否稳定，需要实测；备选方案为「中区停留 2 s」。
- MMCM 能否生成 25.175 MHz 需在 A 的真实板卡上验证。

---


---

### 2026-10-11（续） | A（平台与集成） | Codex（GPT-5 系列，桌面版）

**目标**：关闭第零阶段遗留的「板卡/器件型号未冻结」问题。

**提问（原样粘贴）**

```
artix-7
```

**过程**

1. 检索 `D:\fpga` 与仓库，未发现团队已有的板卡线索（无 xc7*/basys/nexys/arty 相关工程文件）。
2. 将器件系列冻结为 **Artix-7**：首选 **XC7A100T-1CSG324C**（Nexys A7 / Arty A7-100T），备选 **XC7A35T**（Basys 3）。
3. 更新 `docs/interface_spec.md` 至 **v1.1**：补充「无 PS 架构调整」对照表——摄像头初始化改由 PL I2C 主机、日志改由 PL UART、去掉 DDR 全帧缓冲默认改为行缓冲 + 双缓冲。
4. 同步更新 `check_env.ps1`（目标器件 PASS）、`phase0_checklist.md`（R1 关闭）、`architecture.md`（RK1 降级为已缓解）、`README.md`（器件表述）。

**采纳**

- 选 Artix-7 后**架构随之收紧**：所有原本交给 PS 的辅助功能（SCCB 配置、UART 日志、性能统计）全部下沉到 PL，更贴合「展示 FPGA 核心价值」的评分导向。

**纠错 / 权衡**

- 风险点：XC7A35T（Basys 3）若作为实际板卡，BRAM 偏紧，640×480 视频流水线 + 双缓冲可能吃紧。
  应对：已在该表注明「若用 35T，第 2 周先做资源预评估」，并把视觉处理分辨率下调到 320×240 作为默认缓冲策略。
- 尚未敲定具体开发板型号（Nexys A7 / Arty A7-100T / Basys 3），这决定 XDC 引脚与是否有板载 VGA，
  已保留为第 1 周唯一待办，不影响器件系列开工。

**产出物**

| 路径 | 内容 |
| --- | --- |
| `docs/interface_spec.md` | 升 v1.1，冻结 Artix-7 器件与架构调整 |
| `scripts/check_env.ps1` | 目标器件改为 PASS |
| `docs/phase0_checklist.md` | R1 关闭 |
| `docs/architecture.md` | RK1 状态更新 |
| `README.md` | 器件表述更新为 Artix-7 |

---


---

### 2026-10-15 ~ 2026-10-17 | C（游戏本体）+ A（板级集成） | Codex（GPT-5 系列，桌面版）

**目标**：把游戏本体做完整并上真板；接入 OV7725 摄像头手势；解决"战机一直向右"。

**里程碑**

1. 游戏本体 v2 上板可玩：自动连射（多子弹）、敌机子弹、生命/无敌、波次、HUD。
2. 板卡确认：**野火「升腾 Pro」XC7A100T-FGG484-2**，50MHz，HDMI（SiI9134），**OV7725** 摄像头。
3. 摄像头链路打通：OV7725(0x21) → DVP 采集 → RGB565→YCbCr → 肤色 → 质心速度 → 左/右/停 → 游戏。
4. 按团队方案加入：**按键触发肤色标定**（key1）+ **摄像头小窗预览**（右上角，肤色标绿，黄框为采样区）。

**关键问题与纠错（保留）**

| # | 现象 | 根因 | 修复 |
| --- | --- | --- | --- |
| 1 | 不按键战机一直左移 | 板载按键**低有效**，代码按高有效 | 顶层改为 `~key[n]` |
| 2 | 自动连射却不发射 | 点射脉冲 1ms < tick 周期 1.67ms，脉冲落在两次 tick 之间 | 脉冲加宽到 3ms |
| 3 | 综合后时序崩（WNS −15.2ns） | 6 子弹 × 50 敌机碰撞组合逻辑 60 级 | 列/行坐标预寄存 + 碰撞结果流水 + 视频输出流水 → WNS +8.9ns |
| 4 | 摄像头全屏红（cfg_done=0） | 摄像头是 **OV7725(0x21)**，误用 OV5640(0x3C) 配置，I2C 无 ACK 卡死 | 换用 `ov7725_top/ov7725_cfg` |
| 5 | 战机一直向右 | `dxs=xsum−xsum_prev` 声明为无符号，左移的负数变成约 40 亿 | 改为 `logic signed [33:0]` 有符号比较 |
| 6 | 采样后大部分画面变绿 | 采样 ROI 240×240 太大、min/max 范围过宽 | ROI 缩到 120×120，阈值改为「中点 ±12」 |
| 7 | 布线失败 IO Clock Placer | `cam1_pclk` 到 BUFG 走非专用路径 | `CLOCK_DEDICATED_ROUTE FALSE` + 显式 `create_clock` |
| 8 | CDC 路径时序违例 | cam1_pclk ↔ sys_clk ↔ clk_25m 多处跨域 | 补 `set_false_path` CDC 约束 |
| 9 | 综合报 `i2c_ctrl` 参数不存在 | HDMI 与摄像头两个 `i2c_ctrl` 模块重名 | 摄像头版改名 `cam_i2c_ctrl` |

**产出物**

- `src/rtl/`：`game_core`(v2)、`debounce`、`vga_timing`、`sprite_render`(多子弹+HUD)、`top_button_game`、`top_hdmi_game`、`top_cam_game`、`top_cam_test`、`cam_preview`、`cam_frame_buf`、`skin_calib`、`rgb2ycrcb`、`vision_gesture`
- `src/rtl/board/`：HDMI I2C（`i2c_ctrl/hdmi_cfg/hdmi_i2c`）；`board/cam/`：OV7725/OV5640 配置与采集
- `constraints/top_cam_game.xdc`：摄像头 + HDMI + 按键 + CDC 约束
- `scripts/`：`create_project` / `build_bitstream` / `build_game` / `build_camtest` / `program_fpga` / `program_camtest`
- `sim/`：`tb_game_core`(11 项)、`tb_gesture_dir_fsm`、`tb_render`、`tb_dyn_render`、一键运行脚本
- `docs/game_tuning.md`：游戏本体参数确认表

**验证数据**

- 仿真：`tb_game_core` 11/11 PASS；`tb_gesture_dir_fsm` 7/7 PASS；渲染 9 帧正常。
- 时序：`top_cam_game` WNS **+8.705ns**（全约束满足）；`top_cam_test` WNS +25.887ns。
- 上板：游戏可玩、HDMI 出图、摄像头出图、肤色识别正常。

**待验证 / 风险**

- 标定后的手势方向与灵敏度仍需现场实测（`K_PIX=6`、`MIN_PIX=2000`）。
- 摄像头 pclk 走非专用 IO→BUFG 路径（已放宽约束，24MHz 可接受，但属时序隐患）。
- 尚未写 Flash（当前 JTAG 烧写，掉电丢失）。
- `docs/interface_spec.md` 仍写 VGA/100MHz，需更新为 HDMI/50MHz/OV7725。

---


---

### 2026-10-17（续） | C（游戏本体）+ A（板级集成） | Codex（GPT-5 系列，桌面版）

**目标**：落地团队方案——**先采样肤色、再开始游戏、旁边显示摄像头小窗**。

**需求确认（团队）**
- 开机时不允许有默认肤色数据；必须先用按键采样才能开始游戏（每个人肤色不同）；
- 采样用板载按键；摄像头画面在游戏画面旁边开小窗；
- 只需要 1 个开始/暂停按键。

**实现**
1. `skin_calib.sv`：上电阈值置空（不匹配任何像素），`key1` 触发采样，采样完成后写入阈值。
2. 采样参数迭代：ROI 240×240 → 120×120 → **160×160**；采样帧数 30 → **45（约 1.5s）**；阈值由 min/max±8 → **范围中点 ±12**。
3. **合理性检查**：采样中点必须落在 `Cb∈[60,150]`、`Cr∈[110,200]` 内，否则判为“不像肤色”，**拒绝本次采样**（框保持红色），避免把背景误标成皮肤。
4. **全屏标定预览**：按 `key1` 期间整屏显示摄像头（320×240 帧缓存 2× 放大）+ 大黄框；采完自动回到游戏画面。
5. 游戏态：右上角 160×120 小窗显示摄像头（肤色标绿），框颜色表示状态：**红=未标定 / 黄=采样中 / 绿=完成**。
6. 未完成采样时 `skin` 强制为 0，且 `key0` 开始按键被门控（不能开始）。

**本轮发现的问题**

| # | 现象 | 根因 | 处理 |
| --- | --- | --- | --- |
| 10 | 按住 key1 没反应 / 手一直是绿的 | 上电用了默认肤色阈值，采样没有可见反馈 | 上电阈值置空；框颜色（红/黄/绿）反馈 |
| 11 | 采样后“环境变绿、手不绿” | 采样框太小、手没盖满，采到的是背景 | 框放大到 160×160；采样 1.5s；加合理性检查 |
| 12 | 采样体验差 | 小窗里的框太小、难对准 | 改为**全屏标定预览 + 大框**，采完自动切回游戏 |

**验证**
- RTL 全量 `xvlog` 编译通过；Vivado 综合/实现/比特流成功；`top_cam_game` WNS **+8.7ns**（全约束满足）。
- 上板：摄像头出图、肤色识别、全屏标定流程均已烧写验证（标定阈值仍需现场微调）。

**待办**
- 若全屏标定仍难对准：下一步改为“自动选取画面中最像肤色的区域”。
- 写 Flash，实现上电自动运行。
- 更新 `docs/interface_spec.md`（VGA→HDMI、50MHz、OV7725）。

---

### 2026-10-17（续） | C（游戏本体）+ A（板级集成） | Codex（GPT-5 系列，桌面版）

**目标**：复核远端仓库目录重构，并把 Vivado 工程更新到当前源码版本。

**执行与结论**
- 已重新 fetch `origin/main`，当前远端仍为 `9359f76 do nothing`，没有比本地更新的提交。
- 新结构把 Vivado 工程与说明文档分开，顶层更清爽；但 `d32030c simplify the directory` 同时删除了 `src/rtl`、`sim`、`constraints`、`data` 与 `web-game`，新机器直接 clone 后无法构建。
- 已恢复构建必需目录到工程目录下，并把 `.xpr` 中写死的 `C:/Users/Lenovo/...` 路径全部改为 `$PPRDIR/...` 相对路径。
- `fpga_space_invaders.xpr` 当前包含 25 个 RTL 文件，综合顶层为 `top_cam_game`；新增 `sim_1` 文件集，加入 5 个 testbench，仿真顶层为 `tb_game_core`。
- `create_project.tcl` 同步补上 `sim_1`，以后重建工程不会漏掉仿真文件。
- 全量 `xvlog` 编译时发现 `top_cam_game.sv` 中 `hand_pix` 在声明前使用（仿真会报隐式声明错误）；已把声明前移，30 个 RTL/Testbench 文件全部编译通过。
- 最新比特流已重新综合/实现/生成：`top_cam_game.bit`，3,825,992 bytes，WNS **+8.747 ns**，全约束满足，0 routing error。

**遗留问题**
- `说明/` 为中文目录名，与 `repo_conventions.md` 的英文路径规则冲突；`script2/` 与 `scripts/` 功能重复。
- 根 `README.md` 目前是整理说明，不是可供队友直接复现的入口文档。
- 旧 `web-game/` 被本次重构整体移除；若仍需浏览器演示，应从历史提交恢复。

---

> **补记**：以下两条于 11-01 补记，记录 10-18 ~ 10-20 的事。
> 依据提交记录（`git log 4d6aa70..593f5bf`）、实现报告与当时的对话原话整理；
> 无原文留存的部分只写可核对的事实，不编造对话。

### 2026-10-18 ~ 2026-10-19 | 队友（C/B）+ A（复核） | Codex

**目标**：把三种手势方案（按键、肤色二值化 + 质心、Lucas-Kanade 光流）各自做成可独立综合上板的工程，供后续选型比较。

**说明**：无对话原文留存，本条据提交记录（`git log 4d6aa70..593f5bf`）与读码重建，故不列提问。

**过程**

1. 队友分三笔提交推入顶层目录 `is-it-possible-to-ai-it-perfect/`，合计 +127 文件、两万余行：`8db35a6`（10-17 21:19，small correction to readme）、`7102bd1`（10-18 23:10，it is possible to ai it perfect，62 文件 / +9682 行）、`593f5bf`（10-19 14:13，small refine）。
2. 五个可独立打开的 Vivado 工程：`button_game_perfectversion`、`cam_game`、`cam_game_optiflowverison`、`hand_bin_display`、`hand_optiflowversion_display`。
3. 游戏本体补齐：11×5 = 55 只外星人、6 个子弹槽（`ESLOTS=6`）、4 座可破坏掩体（24×12 位图，`bunker_bits` 1152 位）、UFO（50/100/150/300 抽奖）、阶段推进与胜利判定、`LIVES_INIT=6`。
4. 手势判定由"除法求平均位移"改为交叉相乘，省掉除法器：`|xsum·cnt_prev − xsum_prev·cnt| > K_PIX·cnt·cnt_prev`，且要求 `cnt` 与 `cnt_prev` 均 ≥ `MIN_PIX`；同时修掉两处旧问题（手进出画面时凭空发一帧方向命令、开合形变被误判为左右移动）。
5. 光流链路扩到 333 行（新增 `div_pipe`、`flow_tag_ram`、`gray_framebuf`、`flow_fsm`、`rgb2gray`）。
6. 复核时记录三处不一致（未改）：`board/i2c_ctrl.v` 与 `board/cam/i2c_ctrl.v` 同名而模块名不同（`i2c_ctrl` / `cam_i2c_ctrl`）；`run_all_xsim.bat`、`run_sim.bat` 写死 `C:\Xilinx\2026.1\...`、`C:\intelFPGA_lite\17.1\...`；`LIVES_INIT` 三处不同步（`cam_game/src/rtl/game_core.sv:12` 为 10，另两工程为 6，`README.md` 写 6）。

**产出物**：`is-it-possible-to-ai-it-perfect/` 下五个工程；新增 `tb_vision_gesture.sv`（未加入 `sim_1` 文件集）。

---

### 2026-10-19 ~ 2026-10-20 | B（视觉）+ A（集成） | DeepSeek Harness

**目标**：把肤色手势从"能出图但没法用"改到可上板可玩——轮廓化显示、慢速可识别、静止背景不再误识别。

**提问（原样粘贴，按时间顺序）**

```
按住key1不能采样，他只会变成大屏幕一瞬间，并不能进行采样，这是为什么
我觉得还是采用square-demo那样，先采样，然后进行游戏，不用把整个手变绿，把手的轮廓描述出来就行
没有轮廓。手没有识别出来。衣服上面倒是识别出来不少
红的，手在框里是绿的。我松手之后框还是红的。而且手的轮廓没有那么明显。手势识别能力没有square-demo那么强，环境还是有一点轮廓
桌板又开始变绿了，手的轮廓不是完整的，手内部会一直闪烁
手内部空洞闪烁还是在闪，手轮廓也是断续的
```

**人工决策（AI 只给选项，不替用户定）**

| 决策点 | 选项 | 结论 |
| --- | --- | --- |
| 采样与显示方式 | 全屏填充 / **ROI 均值采样 + 轮廓不填充** | **按 `square_demo.py` 的做法**：每帧先算 ROI 的 Cb/Cr 均值，再对均值序列取 min/max（demo 为 ±12，本工程放宽到 ±24）；显示只描轮廓不填充 |
| 去噪手段 | 最大连通域 / **背景差分** | **背景差分**（理由见"否决"） |
| 颜色判据松紧 | 收紧 / **放宽** | **放宽**（颜色只做粗筛，静止物交给背景差分） |

**过程**

1. 读 `scripts/square_demo.py`，对照出三处此前没做的差异：① 采 20 帧，但**每帧先算 ROI 的 Cb/Cr 均值**，再对 20 个均值取 min/max±12，不是对全部像素取；② 有按键可切默认肤色；③ 用 `drawContours` 描白边 + 红十字标质心，**不填充**。
2. 重写 `skin_calib.sv`：ROI 固定、逐帧算均值、滚动取 min/max、按住期间实时刷新；上电默认 Cb 77~127 / Cr 133~173，`calib_done` 恒 1，`calib_busy` 由"正在采样"改为"手还按着"。均值除法由 `>>14` 换成重复减法（`rem >= npix_reg` 逐拍减，最多 255 拍），以支持 ROI 80×80。
3. `cam_frame_buf.sv` 改为描轮廓：`is_edge = (skin ^ skin_left) | (skin ^ skin_up)`，再水平、垂直各膨胀一个抽点周期（约 3 px）。
4. 判据加 `Cr − Cb >= 30`（实测手 Cb=110 / Cr=158，背景 Cb=127 / Cr=125）；再加背景差分：`Y=(77R+150G+29B)>>8`、`fg=|Y−bg|>16`，前 40 帧无条件学背景，之后仅在 `!skin && |Y−bg|<16` 时 `bg += (Y−bg)>>6`，前景 >60% 触发重学 4 帧，标定期间冻结。
5. 上板反馈迭代：框色分状态（黄=采样中 / 绿=可用 / 红=没采到 / 橙=散布太宽 / 品红=不够暖），配合 `calib_stat[1:0]` 诊断码定位卡点。
6. 新建 `sim/tb_skin_contour.sv`（合成一帧手 + 背景噪点），含手背高光用例 `RGB(255,243,228)`（Cb≈119 / Cr≈135，Cr−Cb=16）。
7. 10-20 中午合并队友三笔提交：`26638e0`（本地改动）→ `99ff66b`（merge，无冲突）→ `0434b9f`（xsim 脚本改路径自动探测）；并复跑队友两工程确认可烧：`cam_game` 16774 LUT (26.46%) / BRAM 3 / DSP 0，`cam_game_optiflowverison` 16265 LUT (25.65%) / BRAM 48.5 / DSP 12 / WNS +3.428。

**纠错轨迹（重要）**

| # | 现象 | 根因 | 处理 |
| --- | --- | --- | --- |
| 1 | 编译报 `ERROR: [VRFC 10-4982] syntax error near 'edge'` | `edge` 是 SystemVerilog 保留字，不能作标识符 | 信号改名 `is_edge` |
| 2 | 仿真里"没有轮廓"，干净背景也全黑，怎么调阈值都没用 | 腐蚀用了**已腐蚀的上一行**做行缓存输入，缓存初值 0 → 逐行级联全为 0 | 拆成三组行缓存：raw 供下一行腐蚀、cln 存腐蚀结果供边界、e 存加粗边界供垂直加粗 |
| 3 | 掩膜整行错位，图像像被撕了一条 | `rcnt` 有 +1 偏移，`sy` 可达 240，超出 120 有效行范围 | 加越界保护 `wr_ok = samp1 && (sy1 < DH)` |
| 4 | 采样框一直是红的，阈值从未生效 | 判据要求采样点数**正好**等于 16384，少几个点整帧被丢弃，一直用上电默认值 | 改按实际 ROI 像素数计算，并加 `calib_stat[1:0]` 诊断码与框色反馈 |
| 5 | 墙不再变绿，桌板开始变绿 | 木头与手 Cb/Cr 几乎相同（Cr−Cb≈47），单看颜色无法区分 | 上 `Cr−Cb>=30` 彩度判据 + 背景差分，静止桌面由 `fg` 判为背景 |
| 6 | 综合报 `ERROR: [Synth 8-3391] Unable to infer a block/distributed RAM for 'bg_mem_reg'` | "读旧值 + 写新值"被拆在两个 `always_ff`，工具认不出同一块 RAM | 读写合入同一个 `always_ff` |
| 7 | 编译报 `ERROR: [VRFC 10-3818] variable 'bg_r' is driven by invalid combination of procedural drivers` | `bg_r` 被两处过程块赋值 | 只留一处驱动，输出由读取路径直出 |
| 8 | 手背高光处被挖洞，手内部持续闪烁 | MARGIN 仅 8 偏窄，`warm_ok>=30`、`sat_ok>=16` 过严，受光面彩度掉出窗口 | MARGIN→24、warm_ok≥14、sat_ok≥8、默认窗口 Cb[86,134]×Cr[134,186]、ROI 缩到 80×80，并补高光 testbench 用例 |
| 9 | 队友的 `run_all_xsim.bat` 在本机跑不起来，且编译错误被吞掉 | 脚本写死 `C:\Xilinx\2026.1\Vivado\bin`，并用 `>nul 2>nul` 重定向 | 改为三级自动探测：`VIVADO_BIN` 环境变量 → `D:\fpga\2026.1` → `C:\Xilinx\2026.1` → PATH |

**采纳**

- 采样与显示按 `square_demo` 的做法（ROI 均值 + 轮廓），理由是它验证过的采样口径比"对全部像素取极值"抗噪得多；
- 颜色判据只承担粗筛，静止物交给背景差分，避免为"木头与手同色"去死磕阈值。

**否决**

- 最大连通域：桌板面积约为手的 10 倍，按面积必选错；两遍扫描额外 33~66 ms，超出 `interface_spec.md` 的 ≤33 ms 预算；union-find 随机访问破坏流水线且问题难复现。

**产出物**：`skin_calib.sv`、`cam_frame_buf.sv`、`sim/tb_skin_contour.sv`、`说明/docs/camera_calibration_log.md`；合并提交 `99ff66b`、脚本修复 `0434b9f`。

---

### 2026-10-25 | A（平台与集成） | DeepSeek Harness（qwen3.8-flash / glm-5.3 多模型）

**目标**：给光流版游戏核心建立"能自己跑起来"的验证环境，并能判断核心逻辑是否正确。

**提问（原样粘贴）**

```
教我怎么创建工程然后在vivado里面跑（附 game_core.sv 路径）
```

**过程**

1. 读 `game_core.sv` 后指出：`TICK_DIV=833333`（50 MHz→60 Hz）下每拍要等 80 万时钟沿，
   仿真必须用**参数覆盖**加速，否则跑不动；先做行为仿真再谈上板。
2. 产出 `tb_game_core.sv`（`TICK_DIV=8`，含战况打印与关键信号监视），本机无 Vivado 时
   改用 ModelSim 10.5b 批处理验证。
3. 定位 4 个真实故障（见下表），最终编译 0 error、仿真 82 µs 跑完全流程
   （得分 70→200、掉命 6→5、UFO 出现、暂停/恢复均触发）。

**纠错轨迹（重要）**

| # | 现象 | 根因 | 处理 |
| --- | --- | --- | --- |
| 1 | `vlog` 报 `sqlite3_open ... unable to open database file`，路径乱码 | 工作目录在中文用户名下，ModelSim 为 ANSI 构建 | 换到纯英文目录 `C:\msim_game` |
| 2 | 极简模块也报 `Error loading design` + `FileWatch(fileName)` | `TEMP/TMP` 指向中文目录 | 把 `TEMP/TMP` 覆盖为英文子目录后正常 |
| 3 | `vsim-3694`：`(.*)` 找不到 `clk_sys` 端口 | TB 里时钟命名 `clk`，与 DUT 端口 `clk_sys` 不匹配（该错误只在加载期报，编译期不报） | TB 信号改名为 `clk_sys` |
| 4 | 仿真跑不完 | `TICK_DIV` 未覆盖 | 例化时 `#(.TICK_DIV(8))`，逻辑不变仅提速 |

**产出物**：`sim/tb_game_core.sv`（初版）、ModelSim 仿真日志。

---

### 2026-10-29 | A/B/C（提交材料整理） | DeepSeek Harness（glm-5.3 / deepseek-v4.1-flash）

**目标**：按官方《选题指南（AMD）》3.3 要求，把仓库整理成可提交结构，并补齐
综合与实现报告、技能包、设计报告、架构图。

**提问（原样粘贴，按时间顺序）**

```
我们现在交作品还缺什么东西还需要怎么弄
你就直接写drawio的代码然后我打开drawio就能看的那种
我的仓库在d盘啊D:\fpga\fpga_space_invaders
11yue4hao截止
ai协作的那个你是不是还没写
```

**人工决策（AI 只给选项，不替用户定）**

| 决策点 | 选项 | 结论 |
| --- | --- | --- |
| 提交哪个版本 | 肤色版 / **光流版** / 两个都交 | **光流版**（`cam_game_optiflowverison`），肤色版保留为对照 |
| 仓库结构 | 保持 `说明/` / **根目录建官方结构** / 重构 | **根目录建官方结构**，材料复制同步，原工作区不动 |

**过程**

1. 解析 28 页指南 PDF，确认所属赛道（3.3 自主选题·初级组）与提交清单；
2. 在仓库根目录建立 `src/ sim/ build/ board/ data/ skill/ report/ docs/`，
   源码从 `cam_game_optiflowverison/src/rtl` 复制（20 个文件），约束与 bit 从该工程取；
3. 写 `build/build.tcl`（含 `hdmi_pll` IP 自动生成）并在真工程上跑一次完整构建，
   产出 bitstream 3.65 MB 与 11 份报告；
4. 跑仓库 testbench：**14/14 断言全 PASS**，日志存 `sim/sim_log.txt`；
5. 产出 5 张 drawio 图（架构/数据流/时钟域/主FSM/手势FSM）、`skill/README.md`（8 条）、
   `report/report.md`、`docs/*.md`，并重写根 `README.md`。

**纠错轨迹（重要）**

| # | AI 的错误 / 缺陷 | 发现方式 | 修正 |
| --- | --- | --- | --- |
| 1 | 一直在 C 盘副本 `C:\FPGA\space_invaders_fpga` 上作业 | 用户指出"我的仓库在d盘" | 全部材料迁到 `D:\fpga\fpga_space_invaders` 根结构 |
| 2 | 依据"逐行注释版"副本写文档，与仓库真源码版本不一致 | 对比 `game_core.sv` 行数（377 vs 571） | 以仓库 `cam_game_optiflowverison/src/rtl` 为准重建 |
| 3 | 注释版 XDC 行尾 `#` 注释导致 53 个引脚约束全部失效（DRC NSTD-1/UCIO-1，bitgen 失败） | bitstream 阶段报错 | 清理行尾注释并做**前后计数校验**（116 条命令/53 引脚零丢失） |
| 4 | 生成 XDC 清理脚本时按整行注释处理，误把命令并进注释行 | 输出行数与命令数对不上 | 改为"非注释行截断首个 `#`"+ 计数断言，先恢复备份再重做 |
| 5 | Vivado 批处理在布线后报告阶段卡死（子进程占用 15 GB、CPU 空转 20 min） | 日志停在 `Bitgen Completed` 不动 | 终止进程，改用已生成的 `*_routed.dcp` 单独导出报告 |
| 6 | 用 `Set-Content -Encoding UTF8` 写 Tcl 带 BOM，Vivado 报 `invalid command name "锘縮et"` | 报告脚本第一行就失败 | 改用 `UTF8Encoding($false)` 无 BOM 写入 |
| 7 | 根 `.gitignore` 含 `/build/ /sim/ /scripts/`，会把新提交目录整个排除 | `git check-ignore` 逐个验证 | 重写为只忽略构建产物，14 个必备文件全部可提交 |
| 8 | `说明/docs/architecture.md` 是第零阶段规划稿（肤色版/AXI-Stream），与提交版不符 | 与 RTL 模块清单对照 | 在文首加版本声明，指向 `docs/architecture.md` 为准 |

**采纳 / 否决**

- 采纳：官方目录结构、"一条命令出 bit + 报告"、技能包按"真实踩坑"写（禁写教科书条目）；
- 否决：同时提交两个版本（工作量翻倍，且指南推荐只选其一）；
- 保留意见：`hold` 余量仅 +0.090 ns，报告中如实列为风险而非隐去。

**产出物**：根目录提交结构（`src/ sim/ build/ board/ data/ skill/ report/ docs/`）、
`build/build.tcl`、`build/report/`（11 份）、`sim/sim_log.txt`（14 PASS）、
`skill/README.md`（8 条）、`report/report.md`、`docs/diagrams/*.drawio`。

**待办**：板级照片/视频（10 项，清单见 `board/README.md`）、确认官网提交入口与截止时刻、
`git commit/push`。

---

### 2026-10-30 | A（平台与集成） | DeepSeek Harness（glm-5.3）

**目标**：把已完成的提交材料推送到远端仓库 `origin/main`。

**提问（原样粘贴）**

```
我怎么push
你能帮我push上去吗
```

**过程**

1. 先自检推送前提：`user.name/email`、`credential.helper=manager`、`git ls-remote` 连通性、
   待提交文件数（86 项 / 5.26 MB）、大文件（`.dcp` 已被 `*.runs/` 忽略）；
2. 用户首次 push 报 `Recv failure: Connection was reset`，逐层定位到代理链路；
3. 最终用「git 走 HTTP 代理 + GCM 用已缓存凭据」推成功：
   `593f5bf..4045234  main -> main`；
4. 推送后用 `git ls-tree -r origin/main` 逐项核对 13 个关键提交物，确认全部到位。

**纠错轨迹（重要）**

| # | 现象 | 根因 | 处理 |
| --- | --- | --- | --- |
| 1 | `Recv failure: Connection was reset` | Clash Verge 在跑（7897），但 **Windows 系统代理关闭**（`ProxyEnable=0`），git 走直连被重置 | 给 git 单独配代理 |
| 2 | 配 HTTP 代理后 `schannel: failed to receive handshake` | 该时刻经 7897 到 github 的 CONNECT 不稳定（百度/Google 正常） | 换 `socks5h://`，`ls-remote` 通 |
| 3 | `ServicePointManager 不支持具有 socks5h 方案的代理` | **GCM 是 .NET 程序，只支持 HTTP 代理**，不支持 socks5 | git 与 GCM 分别配置：git 传输可用 socks5h，GCM 需 HTTP 代理 |
| 4 | `User cancelled dialog` / `could not read Username` | 我一度把 `credential.https://github.com.provider` 改成 `generic`，GCM 认证流程失效 | 撤销该配置，恢复默认 provider |
| 5 | 误判"必须交互登录" | 用 `git credential fill` 验证后发现**凭据其实已缓存**（OAuth token，93 字符） | 直接复用缓存凭据，无需弹窗 |

**采纳 / 否决**

- 采纳：以 `git credential fill` 验证凭据可用性，再决定是否需要人工登录（避免让用户白等弹窗）；
- 否决：把 PAT 明文写进 remote URL（会留在 `.git/config`，最终用缓存凭据解决，不必暴露令牌）。

**产出物**：远端 `main` 更新到 `4045234`（86 文件）；全局 git 代理配置；本条目。

---

### 2026-10-31 ~ 2026-11-01 | A/B（双模式集成） | DeepSeek Harness

**目标**：把光流版与肤色版合成为一个交付工程，现场用一个按键切换，不动已冻结的时序。

**提问（原样粘贴）**

```
不用改帧率什么的了，风险有点高而且我们时序什么的已经冻结了，就只把两个版本合并一下吧
```

**人工决策（AI 只给选项，不替用户定）**

| 决策点 | 选项 | 结论 |
| --- | --- | --- |
| 是否提显示时钟换帧率 | 升频 / **不提** | **不提**：时序刚收敛，重开风险 |
| 合并方式 | 二选一打包 / **双前端并存 + 按键切换** | **双前端并存**，共享 `game_core` 与显示通路 |
| 跨域方式 | 逐信号 2FF / **toggle 信箱整包快照** | 状态走信箱整包（多比特不撕裂），方向与模式各用 2FF |

**过程**

1. 先算资源：光流 16265 LUT / 48.5 BRAM / 12 DSP + 质心 16774 LUT / 3 BRAM / 0 DSP，最坏完全不共享为 33039 LUT（52.1%）、51.5 BRAM（38.1%），100T 可容纳。
2. 新建 `is-it-possible-to-ai-it-perfect/cam_dual/`：`rtl/top_cam_dual.sv`、`rtl/dual_extra.xdc`、`build_dual.tcl`、`rerun_impl.tcl`、`program_dual.tcl`、`README.md`、`.gitignore`；其余模块复用光流版源码，不复制第二份。
3. 三时钟域：`cam1_pclk` 24 MHz（采集与两路视觉）、`sys_clk` 50 MHz（`game_core`、`debounce`）、`clk_25m` 25 MHz（渲染与 HDMI）；`rst_n = sys_rst_n & locked`；游戏状态经 `refresh_cnt` 计数 4095 翻转 toggle 整包锁存。
4. 首版 WNS +0.987747 / WHS +0.108447，11:55 烧录 `End of startup status: HIGH`。
5. 上板发现 key0 中局无效：`mode_chg` 被门控在 IDLE，而 `game_core` 无回 IDLE 路径（`src/game_core.sv:382-384` 的 key3 重开直进 `S_PLAY`、`:407-432` 的 key2 仅在 IDLE/OVER→PLAY 与 PLAY↔PAUSE 间走）；改为 `wire mode_chg = k0_rise`，任意时刻可切。
6. 提交 `2a5279e`（11 文件 / +3397 行），与队友交接文档合并为 `536a884`。

**纠错轨迹（重要）**

| # | 现象 | 根因 | 处理 |
| --- | --- | --- | --- |
| 1 | GUI 点 reset_run 后工程像被掏空，报 `Failed to delete one or more files in run directory`，此后无法综合 | GUI 清理动作与批处理残留产物冲突 | 重建 `cam_dual2`，README 注明"以后开 cam_dual2.xpr" |
| 2 | 新建工程 part 为 `xa7a100tfgg484-2I` | 汽车级 XA + 工业温度，与板上器件不符 | 改回 `xc7a100tfgg484-2`，与队友工程一致 |
| 3 | 改 part 后为 `xc7a15tfgg484-2` | 100 误输为 15；15T 的 LUT 约为 100T 的 1/6，16774 LUT 放不下 | 改回 100T，并用 `get_property part [current_project]` 复核 |
| 4 | 实现后弹 "Methodology Violations / Critical violations detected" | 35 条 `TIMING-17` 全部位于厂商 `i2c_ctrl.v`：以 LUT 输出作时钟，触发器不在时钟树 | 核对 `route_design completed successfully`、`All user specified timing constraints are met`；队友同批代码同样告警 70 条仍可运行 → 判定无害，报告中如实记录 |
| 5 | 工程内 8 个源文件为队友目录的**引用**路径 | 新建工程时用 Add Files 而非 Copy | 改动会污染队友工作副本，改为复制进 `cam_dual/rtl` |

**采纳 / 否决**

- 采纳：脚本用 `DUAL_PROJ` 环境变量 + `file join` 定位工程，避免写死单机路径；
- 否决：把比特流提交进 `is-it-possible-to-ai-it-perfect/`（`.gitignore:27` 的 `*.bit`，探索工程不提交 bit），交付 bit 放根 `board/`。

**产出物**：`cam_dual/` 工程与 README、`top_cam_dual.bit`；提交 `2a5279e`、`536a884`。

---

### 2026-11-01 | B（交互手感） | DeepSeek Harness

**目标**：解决质心模式"手移动慢飞机就不动"的手感问题。

**提问（原样粘贴）**

```
关于这个肤色识别的版本，我发现如果手移动的太慢，飞机不会移动，是不是移速阈值太低了
按照b方案改一下
```

**人工决策（AI 只给选项，不替用户定）**

| 决策点 | 选项 | 结论 |
| --- | --- | --- |
| 慢速判定 | A 降 `TH_FAST` 9→6 / **B 泄漏积分器** | **B**（`dir_judge_acc`），A 留作备选 |

**过程**

1. 定位问题不是阈值低而是入口门槛高：`dir_judge.sv` 只看单帧 `|dx|>TH_FAST(9)`，`centroid_calc` 输出 0..639 全分辨率坐标，30 fps 下 9 px/帧 ≈ 270 px/s（约 20 cm/s）；人手慢挪 5~10 cm/s 只有 2~4 px/帧，永不触发。对照光流版 `U_MIN=8192`（0.125 px/帧），灵敏度相差约 72 倍。
2. 新增 `cam_dual/rtl/dir_judge_acc.sv`：`acc <= acc - (acc>>>ACC_SH) + dx`（`ACC_SH=3`，每拍泄 1/8），`|acc| >= TH_ACC(16)` 触发一次并扣额度；参数 `TH_FAST=9`、`TH_SLOW=4`、`HOLD_MAX=3`；端口与 `dir_judge` 一致，顶层只改例化名。
3. 新建 `cam_dual/sim/tb_dir_judge_acc.sv` 八项检查（规律抖动、随机抖动、慢速、中速、快速、反向、`valid=0`、对称方向），xsim **8/8 PASS、0 error**（慢速 60 帧触发 16 帧、最长连续 4 帧）。
4. `build_dual.tcl` 的源文件收集改为 `glob rtl/*.sv`，后续新增文件不再改脚本。
5. 重编 WNS +0.575620 / WHS +0.079104、0 违例，LUT 17802（28.08%）/ BRAM 51.5 / DSP 12，烧录确认可玩，提交 `e2e3016`。

**纠错轨迹（重要）**

| # | 现象 | 根因 | 处理 |
| --- | --- | --- | --- |
| 1 | testbench 报 16 个失败，全是"抖动也触发了" | `$random % 5` 在 Verilog 中为**有符号**取模，实际范围 −4..+4 而非 ±2，测试条件写松了 | 改为 `({$random} % 7) - 3` |
| 2 | 修好 TB 后仍偶发误触发 | `TH_ACC` 初值 12，±3~4 px 抖动可攒到门限 | `TH_ACC` 提到 16（±3 px 抖动下 `acc` 稳态 σ≈3.5，余量 4.6σ） |
| 3 | CHECK5"快速反向"不过 | 前面只给 2 帧静止就要求换向，而 `HOLD_MAX=3` 需 4 帧以上才退出 `S_LEFT` | 测试改为先给 6 帧静止 |

**产出物**：`dir_judge_acc.sv`、`sim/tb_dir_judge_acc.sv`、README 增补 §2.1；提交 `e2e3016`。

---

### 2026-11-01 | A/B/C（材料与文档） | DeepSeek Harness

**目标**：把实现结果写成可核查的性能指标与报告 2.2 硬件系统介绍，做到每个数字都能回查报告文件。

**提问（原样粘贴，按时间顺序）**

```
关于比赛中的性能指标，我们这个项目应该怎么写，最好用表格
性能指标在两百字以内
性能指标建议使用表格
导出成word
2.2硬件系统介绍 / 硬件整体介绍；机械设计介绍（如果有的话…）；电路各模块介绍（从总体到局部…）
尽量简单一点啊
```

**过程**

1. 补 `cam_dual/metrics_report.tcl`：打开 `cam_dual2` 后跑 `report_power` 与 `report_utilization -hierarchical`，产出 `50_power.rpt`、`11_util_hier.rpt`。
2. 写 `说明/docs/competition_metrics.md`：四版资源对比、分层资源、时序与折算频率、功耗、延迟预算、testbench 覆盖、与 PC 方案量级对比（标注估算）。
3. 用 python-docx 排 `说明/docs/比赛性能指标表.docx`（3 张表），并渲染成图逐页校验（表格 fixed 布局、表头跨页重复、行不拆页）。
4. 用 PIL 画 5 张框图（`说明/scripts/hw_figs.py`）：系统总体、三时钟域、输入链路、输出链路、交互与复位。
5. 生成 `说明/docs/报告_2.2_硬件系统介绍.docx`：详细版 12 页 / 10 表 → 按"尽量简单"改为 6 页（2 表 + 54 引脚附表）；引脚表由脚本解析 `board/top_cam_game.xdc` 与 `rtl/dual_extra.xdc` 的 `PACKAGE_PIN` 生成。
6. 口径纠错：`cam1_pclk` 的 41.667 ns 与 OV7725 实际 PCLK 一致（板载 XCLK 24 MHz、`0x11 CLKRC=0x00` 不分频），此前"约束偏松 4%"的说法作废，指标文档与 Word 口径小节一并改正。

**纠错轨迹（重要）**

| # | 现象 | 根因 | 处理 |
| --- | --- | --- | --- |
| 1 | 框图脚本提示成功，但图片未更新 | `hw_figs.py` 的 `OUT` 为相对路径，在 `说明/scripts` 下运行被写到 `说明/scripts/说明/docs/figs/` | 规定从仓库根目录运行，并删除误写目录 |
| 2 | Word 引脚表 54 行全为"—" | `load_pins()` 正则 `[^\}\]]+` 遇到 `{cam1_data[0]}` 中的 `]` 提前截断 | 改为 `(?:\{([^}]+)\}\|([^\]\s]+))` 双分支，复核 54 引脚全部正确 |
| 3 | 生成文档出现整页空白 | `add_page_break()` 在已满页后再插一页 | 改用段落的 `page_break_before` 属性 |
| 4 | 表格末行被顶到下一页，表题与表格被拆开，标题孤留页底 | 未设"与下段同页" | 字号 9→8.5，表题与标题加 `keep_with_next`，列宽按内容重排 |
| 5 | 指标文档写"`cam1_pclk` 约束偏松 4%" | 按常见值假定 OV7725 PCLK 为 25 MHz；实际 XCLK 24 MHz 且不分频，41.667 ns 本即正确 | 改正 `competition_metrics.md` 与 Word 口径小节 |

**采纳**

- 数字必须能回查报告文件；功耗标注为 Vivado 估算模型，延迟标注为推算，未实测的一律声明。

**产出物**：`说明/docs/competition_metrics.md`、`说明/docs/比赛性能指标表.docx`、`说明/docs/报告_2.2_硬件系统介绍.docx`、`说明/scripts/`（`hw_figs.py`、`make_metrics_docx.py`、`make_hw_section_simple.py`）、`cam_dual/metrics_report.tcl`。

---

## 变更记录

| 版本 | 日期 | 变更内容 | 作者 |
| --- | --- | --- | --- |
| v1.0 | 2026-10-11 | 建立日志，记录第零阶段 AI 协作全过程与 5 条纠错轨迹 | A |
| v1.1 | 2026-10-11 | 追加器件冻结（Artix-7）决策记录与架构调整说明 | A |
| v1.2 | 2026-10-17 | 游戏 v2 上板、OV7725 摄像头手势、肤色标定与小窗预览；记录 9 条关键纠错 | C/A |
| v1.3 | 2026-10-17 | 肤色标定方案落地：上电无默认肤色、key1 全屏采样、160×160 ROI、中点±12、合理性检查、小窗预览 | C/A |
| v1.4 | 2026-10-17 | 复核目录重构、恢复构建源、相对化 xpr 路径、加入 sim_1，并记录最新构建验证 | C/A |
| v1.5 | 2026-10-17 | 修复 top_cam_game 中 hand_pix 声明顺序，完成全量 xvlog 与重新构建验证 | C/A |
| v1.6 | 2026-10-25 | 为光流版建立可仿真验证环境（TICK_DIV 参数覆盖），记录中文路径/隐式端口连线等 4 条纠错 | A |
| v1.7 | 2026-10-29 | 官方 3.3 提交结构落地、真实构建（WNS +3.428ns）、14 断言全过、技能包 8 条、5 张架构图；记录 8 条纠错 | A/B/C |
| v1.8 | 2026-10-30 | 提交材料推送远端（`4045234`，86 文件）；记录代理/GCM 认证 5 条纠错 | A |
| v1.9 | 2026-10-19（11-01 补记） | 补记队友推上来的五个工程（据提交记录与读码重建，无对话原文） | B |
| v2.0 | 2026-10-20（11-01 补记） | 肤色链路返工：均值标定、轮廓化、`Cr−Cb` 判据、背景差分；与队友三个提交合并；xsim 脚本改路径自动探测；记录 9 条纠错 | B/A |
| v2.1 | 2026-11-01 | 双模式合并版 `cam_dual`（一键切换）；慢速判定改用泄漏积分器 `dir_judge_acc`；性能指标与报告 2.2 文档化；记录 13 条纠错 | A/B/C |

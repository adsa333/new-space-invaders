# =============================================================================
#  build/build.tcl —— 双模式合并版（光流 LK + 肤色质心，key0 切换）
#  器件: xc7a100tfgg484-2    顶层: top_cam_dual
#
#  用法（仓库根目录）:
#      vivado -mode batch -source build/build.tcl
#      （环境变量 PROJ 可换工程目录名，默认 dual）
#
#  产出:
#      build/report/*.rpt                       资源 / 时序 / DRC / 方法论 / 功耗
#      build/report/00_metrics.txt              关键指标汇总
#      build/dual/dual.runs/impl_1/top_cam_dual.bit
# =============================================================================

set PART xc7a100tfgg484-2
set TOP  top_cam_dual
set PROJ dual
if {[info exists ::env(PROJ)]} { set PROJ $::env(PROJ) }

set SCRIPT   [file normalize [info script]]
set ROOT     [file normalize [file join [file dirname $SCRIPT] ..]]
set SRCDIR   [file join $ROOT src rtl]
set CAMDIR   [file join $ROOT src board_cam]
set HDMIDIR  [file join $ROOT src board_hdmi]
set CONSDIR  [file join $ROOT board]
set BUILDDIR [file join $ROOT build]
set PROJDIR  [file join $BUILDDIR $PROJ]
set RPT      [file join $BUILDDIR report]
file mkdir $RPT

puts "== ROOT: $ROOT"
puts "== PART: $PART   TOP: $TOP   PROJ: $PROJ"

# ---- 1. 建工程 + 收源文件 ----
create_project -force $PROJ $PROJDIR -part $PART

set srcs [glob -nocomplain -directory $SRCDIR  -types f *.sv]
lappend srcs {*}[glob -nocomplain -directory $CAMDIR  -types f *.v]
lappend srcs {*}[glob -nocomplain -directory $HDMIDIR -types f *.v]
if {[llength $srcs] == 0} { error "没有找到源文件" }
add_files -fileset sources_1 $srcs
set_property top $TOP [current_fileset]
puts "== sources: [llength $srcs] files"

set xdc [file join $CONSDIR top_cam_dual.xdc]
if {![file exists $xdc]} { error "找不到约束文件: $xdc" }
add_files -fileset constrs_1 $xdc

# ---- 2. 时钟 IP: hdmi_pll (MMCM 50MHz -> 25MHz) ----
if {[get_ips -quiet hdmi_pll] eq ""} {
    create_ip -name clk_wiz -vendor xilinx.com -library ip -module_name hdmi_pll
    set_property -dict [list \
        CONFIG.PRIM_IN_FREQ {50.000} \
        CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {25.000} \
        CONFIG.USE_LOCKED {true} \
        CONFIG.USE_RESET {true} \
        CONFIG.RESET_TYPE {ACTIVE_HIGH} \
        CONFIG.PRIMITIVE {MMCM} \
    ] [get_ips hdmi_pll]
    generate_target all [get_ips hdmi_pll]
}

# ---- 3. 综合 ----
puts "== launch synth_1"
launch_runs synth_1 -jobs 8
wait_on_run synth_1
set st [get_property STATUS [get_runs synth_1]]
puts "== synth_1 status: $st"
if {[string first "synth_design Complete" $st] < 0} {
    set f [file join $PROJDIR ${PROJ}.runs synth_1 runme.log]
    if {[file exists $f]} { puts [exec tail -n 40 $f] }
    error "synth_1 未完成: $st"
}

# ---- 4. 实现 + bitstream ----
puts "== launch impl_1"
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1
set st [get_property STATUS [get_runs impl_1]]
puts "== impl_1 status: $st"
if {[string index [string tolower $st] 0] ne "w" && [string first "write_bitstream Complete" $st] < 0} {
    set f [file join $PROJDIR ${PROJ}.runs impl_1 runme.log]
    if {[file exists $f]} { puts [exec tail -n 40 $f] }
    error "impl_1 未完成: $st"
}

open_run impl_1
set wns [get_property STATS.WNS [current_run]]
set whs [get_property STATS.WHS [current_run]]
puts "== WNS: $wns   WHS: $whs"

# ---- 5. 报告 ----
report_utilization   -file [file join $RPT 10_util.rpt]
report_timing_summary -file [file join $RPT 20_timing.rpt] -warn_on_violation
report_drc           -file [file join $RPT 30_drc.rpt]
report_methodology   -file [file join $RPT 40_methodology.rpt]
catch { report_power -file [file join $RPT 50_power.rpt] }

# ---- 6. 关键指标汇总 ----
set fp [open [file join $RPT 00_metrics.txt] w]
puts $fp "# top_cam_dual @ xc7a100tfgg484-2  ([clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S}])"
puts $fp "PART=$PART"
puts $fp "WNS=$wns"
puts $fp "WHS=$whs"
foreach rpt {10_util.rpt 20_timing.rpt 50_power.rpt} {
    puts $fp "report=$rpt"
}
close $fp

set bit [glob -nocomplain [file join $PROJDIR ${PROJ}.runs impl_1 *.bit]]
puts "==== BIT: $bit"
puts "==== DONE ===="
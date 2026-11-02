# =============================================================================
#  scripts/rerun_impl.tcl —— 只重跑实现（改约束后验证时序，不重新综合）
#  用法: vivado -mode batch -source scripts/rerun_impl.tcl
#  前提: 已跑过 scripts/build.tcl（工程目录 build/$PROJ 存在）
# =============================================================================

set PROJ dual
if {[info exists ::env(PROJ)]} { set PROJ $::env(PROJ) }

set SCRIPT   [file normalize [info script]]
set ROOT     [file normalize [file join [file dirname $SCRIPT] ..]]
set PROJDIR  [file join $ROOT build $PROJ]
set RPT      [file join $ROOT build report]
set XPR      [file join $PROJDIR ${PROJ}.xpr]

if {![file exists $XPR]} { error "工程不存在: $XPR（先跑 scripts/build.tcl）" }
open_project $XPR

reset_run impl_1
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1
set st [get_property STATUS [get_runs impl_1]]
puts "== impl_1 status: $st"

open_run impl_1
puts "== WNS: [get_property STATS.WNS [current_run]]   WHS: [get_property STATS.WHS [current_run]]"
report_utilization     -file [file join $RPT 10_util.rpt]
report_timing_summary  -file [file join $RPT 20_timing.rpt] -warn_on_violation
report_drc             -file [file join $RPT 30_drc.rpt]
report_methodology     -file [file join $RPT 40_methodology.rpt]
catch { report_power   -file [file join $RPT 50_power.rpt] }
puts "==== DONE ===="
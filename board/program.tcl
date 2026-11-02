# =============================================================================
#  board/program.tcl —— 把比特流烧进 FPGA
#  用法（仓库根目录）:
#      vivado -mode batch -source board/program.tcl
#      （环境变量 PROJ 可指定 build/ 下的工程目录名，默认 dual）
#
#  优先级：build/$PROJ/.../top_cam_dual.bit（自行构建的最新版）
#          → board/top_cam_dual.bit（仓库自带的已验证版）
# =============================================================================

set PROJ dual
if {[info exists ::env(PROJ)]} { set PROJ $::env(PROJ) }

set SCRIPT [file normalize [info script]]
set ROOT   [file normalize [file join [file dirname $SCRIPT] ..]]

set cands [list \
    [file join $ROOT build $PROJ ${PROJ}.runs impl_1 top_cam_dual.bit] \
    [file join $ROOT board top_cam_dual.bit] \
]

set BIT ""
foreach c $cands {
    if {[file exists $c]} { set BIT $c ; break }
}
if {$BIT eq ""} { error "找不到比特流，试过：$cands" }
puts "== BIT: $BIT  ([file size $BIT] bytes)"

open_hw_manager
connect_hw_server -url localhost:3121
set targs [get_hw_targets -quiet]
if {[llength $targs] == 0} {
    error "找不到 JTAG 目标：检查板子是否上电、USB 线是否插好、hw_server 是否在 3121 端口"
}
current_hw_target [lindex $targs 0]
open_hw_target

set devs [get_hw_devices -quiet -filter {NAME =~ *xc7a100t*}]
if {[llength $devs] == 0} { set devs [get_hw_devices -quiet] }
if {[llength $devs] == 0} { error "没有检测到器件" }
set dev [lindex $devs 0]
puts "== DEVICE: $dev"

set_property PROGRAM.FILE $BIT $dev
program_hw_devices $dev
puts "==== PROGRAM DONE ===="
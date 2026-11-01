# create_project.tcl - 重建可移植 Vivado 工程（相对路径，clone 即可用）
# 用法（在仓库根目录执行）：
#   vivado -mode batch -source scripts/create_project.tcl
# 可选参数：
#   set TOP_MODULE  综合顶层模块名
#   set CREATE_PLL  是否生成 hdmi_pll（1=生成，0=跳过）

set TOP_MODULE  top
set CREATE_PLL  0
set PART        xc7a100tfgg484-2

set root    [pwd]
set prj_name new_space_invaders
set prj_dir  [file join $root build $prj_name]
set rtl_dir  [file join $root src rtl]
set sim_dir  [file join $root sim]
set xdc_dir  [file join $root constraints]

create_project -force $prj_name $prj_dir -part $PART

# ---- RTL ----
set rtl_files [concat \
    [glob -nocomplain [file join $rtl_dir *.sv]] \
    [glob -nocomplain [file join $rtl_dir *.v]] \
    [glob -nocomplain [file join $rtl_dir * *.sv]] \
    [glob -nocomplain [file join $rtl_dir * *.v]]]
if {[llength $rtl_files] > 0} {
    add_files -fileset sources_1 $rtl_files
} else {
    puts "WARN: src/rtl 下没有源文件，工程为空"
}
if {[llength [get_files -quiet -fileset sources_1]] > 0} {
    if {[llength [get_ports -quiet]] >= 0} { }
    catch { set_property top $TOP_MODULE [current_fileset] }
}

# ---- 约束 ----
set xdc_files [glob -nocomplain [file join $xdc_dir *.xdc]]
if {[llength $xdc_files] > 0} {
    add_files -fileset constrs_1 $xdc_files
}

# ---- 仿真（不参与综合）----
set sim_files [glob -nocomplain [file join $sim_dir *.sv]]
set sim_files [concat $sim_files [glob -nocomplain [file join $sim_dir *.v]]]
if {[llength $sim_files] > 0} {
    add_files -fileset sim_1 $sim_files
    catch { set_property top [file rootname [lindex [file tail $sim_files] 0]] [get_filesets sim_1] }
}

# ---- HDMI 像素时钟 PLL（50 MHz -> 25 MHz）----
if {$CREATE_PLL == 1 && [get_ips -quiet hdmi_pll] eq ""} {
    create_ip -name clk_wiz -vendor xilinx.com -library ip -module_name hdmi_pll
    set_property -dict [list \
        CONFIG.PRIM_IN_FREQ                {50.000} \
        CONFIG.CLKOUT1_REQUESTED_OUT_FREQ  {25.000} \
        CONFIG.USE_LOCKED                  {true}  \
        CONFIG.USE_RESET                   {true}  \
        CONFIG.RESET_TYPE                  {ACTIVE_HIGH} \
        CONFIG.PRIMITIVE                   {MMCM}  \
    ] [get_ips hdmi_pll]
    generate_target all [get_ips hdmi_pll]
}

update_compile_order -fileset sources_1
puts "==== PROJECT READY: [file join $prj_dir ${prj_name}.xpr] ===="
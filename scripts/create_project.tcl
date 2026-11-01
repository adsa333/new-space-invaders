# create_project.tcl - rebuild a portable Vivado project (relative paths only)
# Usage (run from repo root):
#   vivado -mode batch -source scripts/create_project.tcl
# Optional overrides before sourcing:
#   set TOP_MODULE  <synth top>    (default: top)
#   set CREATE_PLL  1              (generate hdmi_pll: 50 MHz -> 25 MHz)
# NOTE: keep puts() strings ASCII-only; Vivado reads .tcl as ANSI on zh-CN Windows.

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
    catch { set_property top $TOP_MODULE [current_fileset] }
} else {
    puts "WARN: no RTL under src/rtl, project is empty"
}

# ---- Constraints ----
set xdc_files [glob -nocomplain [file join $xdc_dir *.xdc]]
if {[llength $xdc_files] > 0} {
    add_files -fileset constrs_1 $xdc_files
}

# ---- Simulation sources (not synthesised) ----
set sim_files [concat \
    [glob -nocomplain [file join $sim_dir *.sv]] \
    [glob -nocomplain [file join $sim_dir *.v]]]
if {[llength $sim_files] > 0} {
    add_files -fileset sim_1 $sim_files
    set tb_top [file rootname [file tail [lindex $sim_files 0]]]
    catch { set_property top $tb_top [get_filesets sim_1] }
}

# ---- HDMI pixel clock PLL (50 MHz -> 25 MHz) ----
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

catch { update_compile_order -fileset sources_1 }
puts "==== PROJECT READY: [file join $prj_dir ${prj_name}.xpr] ===="
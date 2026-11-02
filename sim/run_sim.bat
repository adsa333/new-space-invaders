@echo off
REM ===========================================================================
REM  sim/run_sim.bat -- regression for the merged dual-mode design
REM    tb_dir_judge_acc : slow-motion judge for centroid mode (8 checks)
REM    tb_game_core     : game core (14 assertions, TICK_DIV=10)
REM  Requires xvlog / xelab / xsim in PATH (Vivado bin directory)
REM  Result is written to metrics/logs/sim_log.txt
REM ===========================================================================
setlocal enabledelayedexpansion
cd /d "%~dp0"

if exist _work rmdir /s /q _work
mkdir _work
cd _work

REM _work is sim/_work, so the repo root is two levels up
set SRC=
for %%f in (..\..\src\rtl\*.sv) do set SRC=!SRC! "%%f"
for %%f in (..\..\src\rtl\*.v) do set SRC=!SRC! "%%f"
set SRC=!SRC! "..\tb_dir_judge_acc.sv" "..\tb_game_core.sv"

echo [1/4] compile RTL
call xvlog -sv -nolog !SRC! > compile.log 2>&1
if errorlevel 1 (
    echo COMPILE FAILED
    type compile.log
    exit /b 1
)

echo [2/4] elaborate tb_dir_judge_acc
call xelab -debug typical tb_dir_judge_acc -s sim_dja > elab_dja.log 2>&1
if errorlevel 1 (
    echo ELAB FAILED: tb_dir_judge_acc
    type elab_dja.log
    exit /b 1
)

echo [3/4] elaborate tb_game_core
call xelab -debug typical tb_game_core -s sim_game > elab_game.log 2>&1
if errorlevel 1 (
    echo ELAB FAILED: tb_game_core
    type elab_game.log
    exit /b 1
)

if not exist ..\..\metrics\logs mkdir ..\..\metrics\logs
echo [4/4] run
> ..\..\metrics\logs\sim_log.txt echo ==== tb_dir_judge_acc (8 checks) ====
call xsim sim_dja -R >> ..\..\metrics\logs\sim_log.txt 2>&1
>> ..\..\metrics\logs\sim_log.txt echo.
>> ..\..\metrics\logs\sim_log.txt echo ==== tb_game_core (14 assertions) ====
call xsim sim_game -R >> ..\..\metrics\logs\sim_log.txt 2>&1

type ..\..\metrics\logs\sim_log.txt
cd ..
rmdir /s /q _work
echo.
echo ==== DONE: metrics/logs/sim_log.txt ====
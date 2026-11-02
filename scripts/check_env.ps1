# check_env.ps1 - 环境自检（在仓库根目录执行）
# 注意：本文件必须保存为 UTF-8 with BOM，否则 Windows PowerShell 5.1 会乱码。

$ErrorActionPreference = 'Continue'
$fail = 0

function Test-Tool($name, $cmd, $args) {
    try {
        $out = & $cmd @args 2>&1 | Select-Object -First 1
        Write-Host ("[OK]   {0}: {1}" -f $name, $out)
    } catch {
        Write-Host ("[FAIL] {0}: 未找到 {1}" -f $name, $cmd) -ForegroundColor Red
        $script:fail++
    }
}

Write-Host "==== 环境自检 ===="

try { $v = (Get-Command git -ErrorAction Stop).Source; Write-Host "[OK]   git: $v" } catch { Write-Host "[FAIL] git 未安装" -ForegroundColor Red; $fail++ }
try { $p = (Get-Command python -ErrorAction Stop).Source; $pv = python --version 2>&1; Write-Host "[OK]   python: $pv ($p)" } catch { Write-Host "[FAIL] python 未安装" -ForegroundColor Red; $fail++ }

$vivadoBat = 'D:\fpga\2026.1\Vivado\bin\vivado.bat'
if (Test-Path $vivadoBat) { Write-Host "[OK]   vivado: $vivadoBat" }
else { Write-Host "[WARN] vivado 不在默认路径 $vivadoBat" -ForegroundColor Yellow }

if (Test-Path (Join-Path (Get-Location) 'README.md')) { Write-Host "[OK]   在仓库根目录" }
else { Write-Host "[WARN] 当前目录不像仓库根目录" -ForegroundColor Yellow }

Write-Host "==== 结束 ===="
if ($fail -eq 0) { Write-Host "全部通过" -ForegroundColor Green; exit 0 }
else { Write-Host "$fail 项失败" -ForegroundColor Red; exit 1 }
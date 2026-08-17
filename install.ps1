#!/usr/bin/env pwsh
param([switch]$Uninstall)

$ErrorActionPreference = "Stop"
$LocalBin = Join-Path $HOME ".local\bin"
$UvBin = Join-Path $LocalBin "uv.exe"

$Version = "0.1.0"
$Wheel = "aish-$Version-py3-none-any.whl"
$WheelUrl = "https://github.com/Devkid-Til/aish-releases/releases/download/v$Version/$Wheel"

function Say($m) { Write-Host $m }
function Ok($m) { Write-Host "  [OK] $m" -ForegroundColor Green }
function Warn($m) { Write-Host "  [!] $m" -ForegroundColor Yellow }
function Die($m) { Write-Host "[X] $m" -ForegroundColor Red; exit 1 }

if ($Uninstall) {
    Say "卸载 aish…"
    if (Test-Path $UvBin) {
        & $UvBin tool uninstall aish 2>$null
        if ($LASTEXITCODE -eq 0) { Ok "已移除 aish 命令" } else { Warn "aish 未通过 uv 安装" }
    }
    Remove-Item (Join-Path $LocalBin "aish.exe") -Force -ErrorAction SilentlyContinue
    Say "已尽量移除。配置目录 ~\.config\aish 需手动清理。"
    exit 0
}

Say "==> 安装 aish（免管理员，装到用户目录）"

if (-not (Get-Command uv -ErrorAction SilentlyContinue) -and -not (Test-Path $UvBin)) {
    Say "  安装 uv（Python 环境管理器，免管理员）…"
    New-Item -ItemType Directory -Force -Path $LocalBin | Out-Null
    $env:INSTALLER_NO_MODIFY_PATH = "1"
    irm https://astral.sh/uv/install.ps1 | iex
    Ok "uv 已装到 $LocalBin"
}

$Uv = (Get-Command uv -ErrorAction SilentlyContinue).Source
if (-not $Uv -and (Test-Path $UvBin)) { $Uv = $UvBin }
if (-not $Uv) { Die "uv 安装失败" }
Ok "uv 就绪"

Say "  下载 aish $Version wheel…"
New-Item -ItemType Directory -Force -Path $LocalBin | Out-Null
$TmpWheel = Join-Path $env:TEMP $Wheel
Invoke-WebRequest -Uri $WheelUrl -OutFile $TmpWheel
if (-not (Test-Path $TmpWheel)) { Die "下载 wheel 失败（$WheelUrl）" }
& $Uv tool install --force --python '>=3.9' $TmpWheel
if ($LASTEXITCODE -ne 0) { Die "aish 安装失败（uv tool install）。" }
Remove-Item $TmpWheel -Force -ErrorAction SilentlyContinue

if (-not (Test-Path (Join-Path $LocalBin "aish.exe"))) {
    $src = (Get-Command aish -ErrorAction SilentlyContinue).Source
    if ($src) {
        New-Item -ItemType SymbolicLink -Path (Join-Path $LocalBin "aish.exe") -Target $src -ErrorAction SilentlyContinue | Out-Null
    }
}

$aish = (Get-Command aish -ErrorAction SilentlyContinue).Source
if (-not $aish) { $aish = Join-Path $LocalBin "aish.exe" }
if (-not (Test-Path $aish)) { Die "aish 命令未就位" }
Ok "aish 命令已就位：$aish"

Say "  验证…"
& $aish route ls *> $null
if ($LASTEXITCODE -eq 0) { Ok "路由自检通过" } else { Warn "路由自检异常（可能缺 LLM 配置，属正常）" }

if (($env:Path -split ';') -notcontains $LocalBin) {
    Warn "$LocalBin 不在 PATH。请把下面这行加进 PowerShell profile（$PROFILE）：
     `$env:Path = `"$LocalBin;`$env:Path`""
}

Say ""
Ok "安装完成。运行 aish 进入交互终端。"
Say "  首次运行会引导配置 AI 后端（也可 `$env:DEEPSEEK_API_KEY='sk-…'`）。"

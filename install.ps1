#!/usr/bin/env pwsh
# aish 一键安装脚本（Windows / PowerShell 版）：从依赖到可用的 aish，全程免管理员。
#
# 用法：
#   irm https://raw.githubusercontent.com/Devkid-Til/aish-releases/main/install.ps1 | iex
#   .\install.ps1 -Uninstall
#
# 设计（与 install.sh 同构）：用 uv（单静态二进制，免管理员装到 ~\.local\bin）统一管
# Python 解释器 + 依赖 + 虚拟环境 + pipx 式命令安装。Windows 与 POSIX 同一条路径。
param([switch]$Uninstall)

$ErrorActionPreference = "Stop"
$LocalBin = Join-Path $HOME ".local\bin"
$UvBin = Join-Path $LocalBin "uv.exe"

# ---- 发行版本与 wheel 下载地址 ----
$Version = "0.1.0"
$Wheel = "aish-$Version-py3-none-any.whl"
$WheelUrl = "https://github.com/Devkid-Til/aish-releases/releases/download/v$Version/$Wheel"

function Say($m) { Write-Host $m }
function Ok($m) { Write-Host "  [OK] $m" -ForegroundColor Green }
function Warn($m) { Write-Host "  [!] $m" -ForegroundColor Yellow }
function Die($m) { Write-Host "[X] $m" -ForegroundColor Red; exit 1 }

# ---- 卸载 ----
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

# ---- 第 1 步：确保 uv 可用（没有就免管理员装到 ~\.local\bin）----
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

# ---- 第 2 步：下载发行 wheel 并用 uv 装为全局命令 ----
Say "  下载 aish $Version wheel…"
New-Item -ItemType Directory -Force -Path $LocalBin | Out-Null
$TmpWheel = Join-Path $env:TEMP $Wheel
Invoke-WebRequest -Uri $WheelUrl -OutFile $TmpWheel
if (-not (Test-Path $TmpWheel)) { Die "下载 wheel 失败（$WheelUrl）" }
# uv tool install 为 aish 建独立环境、把 `aish` 暴露到 ~\.local\bin，自带依赖解析。
# --python 让 uv 在系统 Python 太老/不全时自动下载合适的（免管理员）。
& $Uv tool install --force --python '>=3.9' $TmpWheel
if ($LASTEXITCODE -ne 0) { Die "aish 安装失败（uv tool install）。" }
Remove-Item $TmpWheel -Force -ErrorAction SilentlyContinue

# uv 默认把工具放进 ~\.local\bin；个别环境落到别处，兜底软链。
if (-not (Test-Path (Join-Path $LocalBin "aish.exe"))) {
    $src = (Get-Command aish -ErrorAction SilentlyContinue).Source
    if ($src) {
        New-Item -ItemType SymbolicLink -Path (Join-Path $LocalBin "aish.exe") -Target $src -ErrorAction SilentlyContinue | Out-Null
    }
}

# ---- 第 3 步：验证安装 ----
$aish = (Get-Command aish -ErrorAction SilentlyContinue).Source
if (-not $aish) { $aish = Join-Path $LocalBin "aish.exe" }
if (-not (Test-Path $aish)) { Die "aish 命令未就位" }
Ok "aish 命令已就位：$aish"

Say "  验证…"
& $aish route ls *> $null
if ($LASTEXITCODE -eq 0) { Ok "路由自检通过" } else { Warn "路由自检异常（可能缺 LLM 配置，属正常）" }

# ---- 收尾：PATH 提示 ----
if (($env:Path -split ';') -notcontains $LocalBin) {
    Warn "$LocalBin 不在 PATH。请把下面这行加进 PowerShell profile（$PROFILE）：
     `$env:Path = `"$LocalBin;`$env:Path`""
}

Say ""
Ok "安装完成。运行 aish 进入交互终端。"
Say "  首次运行会引导配置 AI 后端（也可 `$env:DEEPSEEK_API_KEY='sk-…'`）。"

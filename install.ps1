#!/usr/bin/env pwsh
# aish 一键安装脚本（Windows / PowerShell 版）：从依赖到可用的 aish，全程免管理员。
#
# 用法：
#   .\install.ps1                     # 从当前仓库安装
#   .\install.ps1 -Uninstall
#   irm https://raw.githubusercontent.com/Devkid-Til/aish/main/install.ps1 | iex
#
# 设计（与 install.sh 同构）：用 uv（单静态二进制，免管理员装到 ~\.local\bin）统一管
# Python 解释器 + 依赖 + 虚拟环境 + pipx 式命令安装。Windows 与 POSIX 同一条路径。
param([switch]$Uninstall)

$ErrorActionPreference = "Stop"
$LocalBin = Join-Path $HOME ".local\bin"
$UvBin = Join-Path $LocalBin "uv.exe"

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

# ---- 第 2 步：用 uv 装 aish 为全局命令（自动建隔离 venv + 装依赖 + 选合适 Python）----
Say "  安装 aish 及其依赖…"
New-Item -ItemType Directory -Force -Path $LocalBin | Out-Null
# 安装来源：从本地仓库（脚本文件所在目录）或远程 git（irm|iex 时无本地仓库）。
$RepoDir = if ($MyInvocation.MyCommand.Path) {
    Split-Path -Parent $MyInvocation.MyCommand.Path
} else { $null }
$InstallSource = if ($RepoDir -and (Test-Path (Join-Path $RepoDir "pyproject.toml"))) {
    $RepoDir
} else {
    "git+https://github.com/Devkid-Til/aish.git"
}
# --python 让 uv 在系统 Python 太老/不全时自动下载合适的（免管理员）。
& $Uv tool install --force --python '>=3.9' $InstallSource
if ($LASTEXITCODE -ne 0) { Die "aish 安装失败（uv tool install）。" }

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

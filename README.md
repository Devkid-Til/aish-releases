# aish-releases

aish 的发行分发仓库，提供各平台的一键安装脚本与发行产物。

## 一键安装

### Windows（PowerShell 7+）

```powershell
irm https://raw.githubusercontent.com/Devkid-Til/aish-releases/main/install.ps1 | iex
```

### macOS / Ubuntu（POSIX）

```bash
curl -fsSL https://raw.githubusercontent.com/Devkid-Til/aish-releases/main/install.sh | bash
```

## 发行产物

- `install.sh` — POSIX 一键安装脚本
- `install.ps1` — Windows 一键安装脚本
- `aish-<version>-py3-none-any.whl` — 通用 wheel

## 版本

各版本发行物见 [Releases](https://github.com/Devkid-Til/aish-releases/releases)。

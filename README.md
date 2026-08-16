# aish-releases

[aish](https://github.com/Devkid-Til/aish) 的发行分发仓库：提供各平台的一键安装脚本与发行产物。

> 源码在私有仓库 `Devkid-Til/aish`；本仓库公开，只放发行产物，便于直接下载安装。

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

- `aish-<version>-py3-none-any.whl` — 纯 Python wheel，三平台通用
- `install.sh` — POSIX 一键安装脚本（macOS / Ubuntu / 国产 OS）
- `install.ps1` — Windows PowerShell 一键安装脚本

详见 [Releases](https://github.com/Devkid-Til/aish-releases/releases)。

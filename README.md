# aish — AI Shell

命令与自然语言无缝切换的终端助手：命令直接执行，自然语言交给 AI。

## 特性

- **命令直通**：敲命令直接执行，`cd` / 别名 / 历史 / 环境变量像真 shell 一样生效，输出带颜色。
- **自然语言**：用大白话说需求，AI 翻译成命令执行，或直接回答。
- **认得你的环境**：加载你的 shell 配置（`.zshrc` / `.bashrc`），`ll`、`gs` 这类你自己的别名直接可用。
- **失败诊断**：命令失败后输入 `?`，AI 基于真实输出分析原因并给出修复。
- **智能安装引导**：敲了没装的命令，自动给出安装命令，装完立即可用，不用重启。
- **风险分级**：只读命令直接执行；写入命令需确认；危险命令（`rm -rf`、`dd`…）要输 `yes`。
- **会话记忆**：记得这个会话里做过的事，可用「刚才那条」「这个文件」指代追问。
- **多后端**：保存多个 AI 后端配置，一条命令秒切。

## 安装

### macOS / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/Devkid-Til/aish-releases/main/install.sh | bash
```

### Windows（PowerShell 7+）

```powershell
irm https://raw.githubusercontent.com/Devkid-Til/aish-releases/main/install.ps1 | iex
```

### 手动装 wheel

从 [Releases](https://github.com/Devkid-Til/aish-releases/releases) 下载 `aish-<版本>-py3-none-any.whl`，然后：

```bash
uv tool install aish-0.1.0-py3-none-any.whl
```

安装后命令在 `~/.local/bin/aish`。卸载：`bash install.sh --uninstall` / `.\install.ps1 -Uninstall`。

要求 Python ≥ 3.9；Windows 额外要求 PowerShell 7+ 与 Windows 10 1809+。

## 快速上手

```bash
# 1. 配置 AI 后端（首次运行会引导，也可先设环境变量）
export DEEPSEEK_API_KEY="sk-你的key"     # 推荐 DeepSeek：中文好、便宜

# 2. 进入
aish
```

进去之后，就像用普通 shell，但随时能用自然语言：

```
❯ ls -la                    # 命令：直接执行
❯ 看看哪个文件最大            # 自然语言：交给 AI
❯ tar 命令怎么用             # 问用法：AI 直接答
❯ ffmpeg                    # 没装：安装引导
❯ ?                         # 上一条失败了？AI 分析原因
```

## 使用方式

### 命令 vs 自然语言

aish 自动区分输入：是命令就执行，是自然语言就交给 AI。不用加任何前缀。

### 失败诊断

命令跑失败了，单独输入 `?`（全角 `？` 也行），AI 会基于真实的错误输出分析原因，并给出修复命令。

### 未安装命令

敲了没装的命令，aish 会识别出来、给你安装命令，装完自动生效。包名和命令名不一样时（比如装 `miniconda` 得到的是 `conda`），会告诉你真实的命令名。

### 风险确认

- **只读**（`ls`、`cat`、`ps`、`git status`…）：直接执行，不打扰。
- **写入**（`cp`、`mv`、`git commit`…）：提示确认。
- **危险**（`rm -rf`、`dd`、`mkfs`…）：红色警告，要输 `yes` 才执行。

### 会话记忆

aish 记得这个会话里的「问 → 答 → 执行 → 结果」，可以追问「刚才那条再跑一次」「把上面那个文件删了」。`/clear` 清空当前记忆。

## 元命令

交互模式或 `aish /xxx` 下都可用：

| 命令 | 作用 |
|------|------|
| `/config` | 交互式重选 AI 后端 |
| `/config list` | 列出已保存的后端 |
| `/config use <名>` | 切换到指定后端 |
| `/config add` | 交互式新增后端 |
| `/config del <名>` | 删除一个后端 |
| `/config model [模型]` | 查看或修改当前模型 |
| `/status` | 查看状态：后端、记忆、本次用量 |
| `/clear` | 清空当前会话记忆 |
| `/o`（或 `/output`） | 分页回看最近一次命令的完整输出（`q` 退出） |
| `/copy` | 复制最近一次 AI 回答到剪贴板 |
| `/copy out` | 复制最近一次命令输出到剪贴板 |
| `/history` | 查看命令历史（含跨会话） |
| `/history <词>` | 按关键词过滤历史 |
| `/remember <事实>` | 记一条跨会话偏好（如「我习惯用 python3」） |
| `/facts` | 查看持久事实 |
| `/facts clear` | 清空持久事实 |
| `/help` | 显示帮助 |
| `exit` / `quit` / `Ctrl+D` | 退出 |

未识别的 `/xxx` 会提示，不会误当成命令；真实的绝对路径（`/bin/ls`）照常执行。

## 配置

### 环境变量

设了下面这些 Key，首次启动会自动探测到对应后端：

| 环境变量 | 后端 |
|----------|------|
| `DEEPSEEK_API_KEY` | DeepSeek |
| `ANTHROPIC_API_KEY`（+ 可选 `ANTHROPIC_BASE_URL`） | Anthropic 及兼容端点 |
| `OPENAI_API_KEY`（+ 可选 `OPENAI_BASE_URL`） | OpenAI 及兼容服务 |
| `MOONSHOT_API_KEY` | Moonshot Kimi |
| `DASHSCOPE_API_KEY` | 通义千问 DashScope |
| `OPENROUTER_API_KEY` | OpenRouter |

此外会自动探测本地的 Ollama（`localhost:11434`）、LM Studio（`localhost:1234`），并复用你 Claude Code 里配过的 key。

aish 自身的控制变量：

| 环境变量 | 作用 |
|----------|------|
| `AISH_MODEL` | 覆盖默认模型名 |
| `AISH_CONFIG_DIR` | 覆盖配置目录（默认 `~/.config/aish`） |
| `AISH_NO_USER_RC` | 设为 `1` 时不加载你的 shell 配置（排查用） |
| `AISH_NO_PERSISTENT_SHELL` | 设为 `1` 时每条命令独立执行（排查用） |

### settings.json

可调参数在 `~/.config/aish/settings.json`（首次运行自动生成，带默认值）：

| 键 | 默认 | 作用 |
|----|------|------|
| `max_look_rounds` | 5 | AI 单轮自动只读探查的最大轮数 |
| `max_total_actions` | 10 | AI 单轮自主动作总数上限 |
| `auto_diagnose` | `true` | 命令失败且有输出时，自动触发 AI 诊断 |
| `persist_history` | `true` | 命令历史落盘（跨会话记住 ↑） |
| `mem_max_turns` | 20 | 会话记忆保留的最近轮数 |
| `mem_max_total_chars` | 16000 | 会话记忆总字符上限 |
| `mem_max_output_chars` | 8000 | 单条输出保留上限（超出存本地） |
| `mem_full_turns` | 4 | 最近几轮给完整内容，更早的压成摘要 |
| `max_facts` | 50 | 持久事实条数上限 |
| `max_fact_len` | 200 | 单条事实长度上限 |
| `keep_session_logs` | 20 | 交互会话日志保留份数 |
| `keep_history_files` | 30 | 对话历史归档保留份数 |
| `readonly_whitelist` | `[...]` | AI 可自主执行的只读命令白名单（空数组 = 禁用） |

## 命令行用法

```bash
aish                      # 进入交互模式
aish 查看磁盘占用           # 单条：自然语言
aish ls -la               # 单条：命令
aish route <文本>          # 只显示路由结果（command / natural），不执行
aish translate <文本>      # 只翻译成命令，不执行
aish --config             # 重新配置后端
```

## 兼容性

| 平台 | shell | 状态 |
|------|-------|------|
| macOS（Intel / Apple Silicon） | zsh | ✅ 实测 |
| Ubuntu / Debian | bash / zsh | ✅ 实测 |
| CentOS / RHEL / Rocky / Alma | bash / zsh | ✅ 实测 |
| Arch / openSUSE / Alpine | bash / zsh | ✅ 支持 |
| Windows 10/11 | PowerShell 7+ | ✅ 实测 |

## License

MIT © herrshi

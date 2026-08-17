#!/usr/bin/env bash
set -euo pipefail

VERSION="0.2.0"
WHEEL="aish-${VERSION}-py3-none-any.whl"
WHEEL_URL="https://github.com/Devkid-Til/aish-releases/releases/download/v${VERSION}/${WHEEL}"

say()  { printf '%s\n' "$*"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$*"; }
die()  { printf '\033[31m✗ %s\033[0m\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

LOCAL_BIN="$HOME/.local/bin"
UV_BIN="$LOCAL_BIN/uv"

if [[ "${1:-}" == "--uninstall" ]]; then
  say "卸载 aish…"
  if [[ -x "$UV_BIN" ]]; then
    "$UV_BIN" tool uninstall aish 2>/dev/null && ok "已移除 aish 命令" || warn "aish 未通过 uv 安装"
  fi
  rm -f "$LOCAL_BIN/aish" 2>/dev/null || true
  say "已尽量移除。配置目录 ~/.config/aish 需手动清理。"
  exit 0
fi

say "==> 安装 aish ${VERSION}（免 sudo，装到用户目录）"

if ! have uv && [[ ! -x "$UV_BIN" ]]; then
  say "  安装 uv（Python 环境管理器，免 sudo）…"
  have curl || die "需要 curl 来安装 uv，请先安装 curl。"
  mkdir -p "$LOCAL_BIN"
  curl -LsSf https://astral.sh/uv/install.sh | env INSTALLER_NO_MODIFY_PATH=1 sh >/dev/null
  ok "uv 已装到 $LOCAL_BIN"
fi
UV="$(command -v uv || echo "$UV_BIN")"
[[ -x "$UV" ]] || die "uv 安装失败"
ok "uv 就绪：$("$UV" --version 2>/dev/null | head -1)"

say "  下载 aish ${VERSION} wheel…"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
curl -fsSL "$WHEEL_URL" -o "$TMP_DIR/$WHEEL" || die "下载 wheel 失败（${WHEEL_URL}）"
if "$UV" tool install --force --python '>=3.9' "$TMP_DIR/$WHEEL" 2>&1 | tail -5; then
  :
else
  die "aish 安装失败（uv tool install）。"
fi

if [[ ! -e "$LOCAL_BIN/aish" ]]; then
  src="$(command -v aish || true)"
  [[ -n "$src" ]] && ln -sf "$src" "$LOCAL_BIN/aish" 2>/dev/null || true
fi
AISH="$(command -v aish || echo "$LOCAL_BIN/aish")"
[[ -x "$AISH" ]] || die "aish 命令未就位"
ok "aish 命令已就位：$AISH"

say "  验证…"
"$AISH" route ls >/dev/null 2>&1 && ok "路由自检通过" || warn "路由自检异常（可能缺 LLM 配置，属正常）"

case ":$PATH:" in
  *":$LOCAL_BIN:"*) : ;;
  *) warn "$LOCAL_BIN 不在 PATH。请把下面这行加进 ~/.zshrc 或 ~/.bashrc：
     export PATH=\"$LOCAL_BIN:\$PATH\"" ;;
esac

say ""
ok "安装完成。运行 aish 进入交互终端。"
say "  首次运行会引导配置 AI 后端（也可 export DEEPSEEK_API_KEY=…）。"

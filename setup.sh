#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

# dotfiles の適用は mise bootstrap に委譲している（設定は mise.toml / mise.wsl.toml を参照）
if command -v mise >/dev/null 2>&1; then
  MISE=mise
elif [ -x "$HOME/.local/bin/mise" ]; then
  MISE="$HOME/.local/bin/mise"
else
  echo "mise が見つかりません。先にインストールしてください:" >&2
  echo "  curl https://mise.run | sh" >&2
  echo "  （macOS なら brew install mise でも可）" >&2
  exit 1
fi

"$MISE" trust

# WSL では settings.wsl.json を使うため環境を切り替える
if grep -qi microsoft /proc/version 2>/dev/null; then
  exec "$MISE" bootstrap -E wsl
else
  exec "$MISE" bootstrap
fi

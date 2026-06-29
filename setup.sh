#!/bin/bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

mkdir -p "$CLAUDE_DIR"

link() {
  local src="$1" dst="$2"
  if [ -L "$dst" ]; then
    rm "$dst"
  elif [ -e "$dst" ]; then
    echo "SKIP: $dst は既存ファイル（symlink ではない）。必要なら手動でバックアップしてください。" >&2
    return
  fi
  ln -sf "$src" "$dst"
  echo "  $dst -> $src"
}

echo "=== Claude Code ==="
link "$DOTFILES_DIR/claude/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
link "$DOTFILES_DIR/claude/settings.json" "$CLAUDE_DIR/settings.json"
link "$DOTFILES_DIR/claude/main-branch-allowed-repos.txt" "$CLAUDE_DIR/main-branch-allowed-repos.txt"
link "$DOTFILES_DIR/claude/hooks" "$CLAUDE_DIR/hooks"

echo "=== Karabiner-Elements ==="
mkdir -p "$HOME/.config/karabiner"
link "$DOTFILES_DIR/.config/karabiner/karabiner.json" "$HOME/.config/karabiner/karabiner.json"

echo "完了"

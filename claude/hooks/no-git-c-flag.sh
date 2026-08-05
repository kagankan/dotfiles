#!/bin/bash
# git -C を使おうとした場合にブロックする
# プロジェクトディレクトリにいるのでそのまま git コマンドを実行すべき

CMD=$(cat | jq -r '.tool_input.command // empty' 2>/dev/null)

if echo "$CMD" | grep -qE '(^|[;&|] *)git -C '; then
  echo "ERROR: -C は使わないでください。プロジェクトディレクトリにいるのでそのまま git コマンドを実行してください。" >&2
  exit 2
fi

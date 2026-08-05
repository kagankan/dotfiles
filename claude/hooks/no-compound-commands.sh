#!/usr/bin/env bash
# 複合コマンド（&&, ||, ;）を検出して deny し、分割実行を促す
set -euo pipefail

CMD=$(cat | jq -r '.tool_input.command // empty' 2>/dev/null)

if echo "$CMD" | grep -qE '&&|\|\||;'; then
  cat <<'EOF'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"複合コマンド(&&, ||, ;)を使わないでください。各コマンドを個別に実行してください。"}}
EOF
fi

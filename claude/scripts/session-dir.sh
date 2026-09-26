#!/usr/bin/env bash
set -euo pipefail

# セッションディレクトリの作成・検索を行うスクリプト
# 使い方:
#   session-dir.sh <概要>
#     CLAUDE_CODE_SESSION_ID 環境変数を使用する（Claude Code が自動セット）。
#     既存ディレクトリがあればそのパスを返し、なければ新規作成して返す。
#
#   session-dir.sh <session_id> <概要>
#     後方互換: 明示的に session_id を渡す場合。

if [[ $# -ge 2 ]]; then
  SESSION_ID="$1"
  SUMMARY="$2"
else
  SESSION_ID="${CLAUDE_CODE_SESSION_ID:?環境変数 CLAUDE_CODE_SESSION_ID が必要です}"
  SUMMARY="${1:?引数1: 概要（日本語）が必要です}"
fi

BASE_DIR=".ai-output/sessions"

existing=$(find "$BASE_DIR" -maxdepth 1 -name "*${SESSION_ID}*" -type d 2>/dev/null | head -1)

if [[ -n "$existing" ]]; then
  echo "$existing"
else
  dir_name="$(date +%Y-%m-%d)-${SESSION_ID}-${SUMMARY}"
  new_dir="${BASE_DIR}/${dir_name}"
  mkdir -p "${new_dir}"
  echo "$new_dir"
fi

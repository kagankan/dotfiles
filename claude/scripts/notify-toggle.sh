#!/bin/bash
# 音声通知の有効・無効を切り替える
# 使い方: notify-toggle.sh [on|off]（引数なしで toggle）

FLAG="$HOME/.claude/notify-disabled"

case "${1:-}" in
  on)  rm -f "$FLAG" ;;
  off) touch "$FLAG" ;;
  "")
    if [ -f "$FLAG" ]; then
      rm -f "$FLAG"
    else
      touch "$FLAG"
    fi
    ;;
  *)
    echo "不明な引数: $1（on / off / 引数なし で指定）" >&2
    exit 1
    ;;
esac

if [ -f "$FLAG" ]; then
  echo "音声通知を無効にしました"
else
  echo "音声通知を有効にしました"
fi

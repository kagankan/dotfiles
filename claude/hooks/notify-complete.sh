#!/bin/bash
[ -f "$HOME/.claude/notify-disabled" ] && exit 0
source "$(dirname "$0")/project-name.sh"
say -v Kyoko "${PROJECT_NAME}、完了"

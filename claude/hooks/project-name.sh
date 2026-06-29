#!/bin/bash
PROJECT_NAME=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")")

# マシンごとに読み替えたいリポジトリ名があれば case を追加する
# case "$PROJECT_NAME" in
#   my-repo) PROJECT_NAME="マイリポ" ;;
# esac

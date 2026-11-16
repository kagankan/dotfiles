#!/bin/bash
# git commit 時に保護ブランチへの直接コミットをブロックする
# ただし許可リストに載っているリポジトリは除外する

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

if ! echo "$CMD" | grep -q 'git commit'; then
  exit 0
fi

# hook のプロセスはセッションを起動したディレクトリで動くことがあり、worktree で作業していても
# 元のチェックアウトのブランチを見てしまう。コマンドが実行されるディレクトリ（入力の cwd）へ移ってから調べる。
# 移れなかった場合は、これまでどおり hook のプロセスのディレクトリで調べる
HOOK_CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
if [ -n "$HOOK_CWD" ] && [ -d "$HOOK_CWD" ]; then
  cd "$HOOK_CWD" 2>/dev/null || true
fi

REMOTE=$(git remote get-url origin 2>/dev/null)

# Wiki リポジトリは許可
if echo "$REMOTE" | grep -q '.wiki.git$'; then
  exit 0
fi

# 許可リストに載っているリポジトリは許可
# remote URL（git@host:owner/repo.git / https://host/owner/repo.git など）を owner/repo に正規化して完全一致で比べる。
# 部分一致だと、許可したいリポジトリ名を含む別のリポジトリ（dotfiles に対する kishi-dotfiles 等）まで許可されるため
# gh repo view --json nameWithOwner でも取れるが、コミットのたびに API を呼んで遅くなり、
# オフラインや認証切れで失敗し、fork では origin ではなく upstream を返しうるため使わない
REPO=$(echo "$REMOTE" | sed -E 's#/+$##; s#\.git$##; s#^.*[:/]([^/:]+/[^/:]+)$#\1#')
ALLOWLIST="$HOME/.claude/main-branch-allowed-repos.txt"
if [ -n "$REPO" ] && [ -f "$ALLOWLIST" ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      '#'*|'') continue ;;
    esac
    if [ "$REPO" = "$line" ]; then
      exit 0
    fi
  done < "$ALLOWLIST"
fi

# 保護ブランチのチェック
BRANCH=$(git branch --show-current 2>/dev/null)
case " main master develop " in
  *" $BRANCH "*)
    echo "ERROR: 現在 '$BRANCH' ブランチ（保護ブランチ）にいます。直接コミットできません。git switch -c <適切なブランチ名> で新しいブランチを作成してからコミットしてください。" >&2
    exit 2
    ;;
esac

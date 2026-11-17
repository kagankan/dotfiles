# プロンプトカスタマイズ
export CLICOLOR=1

function left-prompt {
  name_t='179m%}'      # user name text clolr
  name_b='000m%}'    # user name background color
  path_t='255m%}'     # path text clolr
  path_b='031m%}'   # path background color
  arrow='087m%}'   # arrow color
  text_color='%{\e[38;5;'    # set text color
  back_color='%{\e[30;48;5;' # set background color
  reset='%{\e[0m%}'   # reset
  sharp="\uE0B0"      # triangle

  # https://dev.macha795.com/zsh-prompt-customize/
  user="${back_color}${name_b}${text_color}${name_t}"
  dir="${back_color}${path_b}${text_color}${path_t}"
  echo "${dir}%~${reset}${text_color}${path_b}${sharp}${reset}\n${text_color}${arrow}> ${reset}"
}

PROMPT=`left-prompt`

# Claude Code の音声通知（hooks/notify-*.sh）の有効・無効を切り替える
# 使い方: notify-claude [on|off]（引数なしで toggle）
alias notify-claude="$HOME/.claude/scripts/notify-toggle.sh"

# ブランチを fzf で選び、そのブランチの worktree を VS Code で開く
# 使い方: wt [ブランチ名]（引数なしで fzf から選ぶ）
# - worktree があればそのディレクトリを開く
# - なければ <メインのチェックアウト>/.claude/worktrees/ に作り、依存のインストールは裏で流す
# 依存のインストールコマンドはリポジトリごとに git config で上書きできる（認証付きのレジストリを使う場合等）:
#   git config wt.install 'envchain npm pnpm install --frozen-lockfile'
function wt {
  local main
  main=$(_wt_main) || return

  local branch=${1-}
  if [[ -z $branch ]]; then
    local line
    line=$(_wt_branches "$main" | fzf --prompt='branch> ' --delimiter=$'\t' --tabstop=4) || return
    branch=${line%%$'\t'*}
  fi

  local dir
  dir=$(git -C "$main" worktree list --porcelain |
    awk -v b="branch refs/heads/$branch" '/^worktree /{p=substr($0,10)} $0==b{print p; exit}')
  if [[ -z $dir ]]; then
    dir="$main/.claude/worktrees/${branch//\//+}"
    _wt_create "$main" "$branch" "$dir" || return
  fi
  code "$dir"
}

# マージ済み、またはリモートで削除済みのブランチの worktree を fzf で選んで削除する（Tab で複数選択）
# - ブランチは消さない
# - 未コミットの変更がある worktree は git worktree remove が拒否するので消えない
# - 「コミットなし」は作ったばかりで作業前の worktree も含むので、使用中でないか確かめてから選ぶ
function wt-prune {
  local main
  main=$(_wt_main) || return

  local base
  base=$(git -C "$main" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null) || base=origin/HEAD
  git -C "$main" fetch --prune --quiet origin

  local here
  here=$(git rev-parse --show-toplevel 2>/dev/null)

  local selected
  selected=$(
    # 1 つ目の入力: base にマージ済みのブランチ、2 つ目: ブランチ・upstream・追跡状態・worktree のパス
    awk -F'\t' -v main="$main" -v here="$here" '
      NR == FNR { merged[$0] = 1; next }
      $4 == "" || $4 == main || $4 == here { next }
      $3 == "[gone]" { print $1 "\tリモート削除済み\t" $4; next }
      ($1 in merged) && $2 != "" { print $1 "\tマージ済み\t" $4; next }
      ($1 in merged) { print $1 "\tコミットなし\t" $4 }
    ' \
      <(git -C "$main" branch --merged "$base" --format='%(refname:short)') \
      <(git -C "$main" for-each-ref --format='%(refname:short)%09%(upstream)%09%(upstream:track)%09%(worktreepath)' refs/heads) |
      sort -t$'\t' -k2,2 -k1,1 |
      fzf --multi --prompt='削除する worktree> ' --header='Tab で複数選択、Enter で削除' \
        --delimiter=$'\t' --tabstop=4
  ) || return

  local line
  for line in ${(f)selected}; do
    git -C "$main" worktree remove "${line##*$'\t'}" && echo "削除しました: ${line%%$'\t'*}"
  done
}

# 1 件目の worktree がメインのチェックアウト
function _wt_main {
  local main
  main=$(git worktree list --porcelain 2>/dev/null | awk 'NR==1{print substr($0,10); exit}')
  if [[ -z $main ]]; then
    echo 'git リポジトリの中で実行してください' >&2
    return 1
  fi
  echo "$main"
}

# 「ブランチ名<TAB>worktree のパス」を列挙する。ローカルとリモートで同名のブランチは 1 行にまとめる
function _wt_branches {
  git -C "$1" for-each-ref --format='%(refname:lstrip=2)%09%(worktreepath)' refs/heads refs/remotes/origin |
    sed -E 's#^origin/##' | grep -v $'^HEAD\t' |
    awk -F'\t' '!($1 in s) || $2 != "" {s[$1]=$2} END {for (k in s) print k "\t" s[k]}' |
    sort
}

function _wt_create {
  local main=$1 branch=$2 dir=$3
  if git -C "$main" show-ref --verify --quiet "refs/heads/$branch"; then
    git -C "$main" worktree add "$dir" "$branch" || return
  else
    # ローカルにないブランチは origin の最新を取ってから追跡ブランチを作る
    git -C "$main" fetch --quiet origin "$branch" || return
    git -C "$main" worktree add --track -b "$branch" "$dir" "origin/$branch" || return
  fi

  # .worktreeinclude に書かれた gitignore 対象のファイル（証明書等）をメインからコピーする
  # （Claude Code が worktree を作るときと同じ規約）
  if [[ -f $main/.worktreeinclude ]]; then
    local file
    git -C "$main" ls-files --others --ignored --exclude-from="$main/.worktreeinclude" |
      while IFS= read -r file; do
        mkdir -p "$dir/${file:h}"
        cp -p "$main/$file" "$dir/$file"
      done
  fi

  local install
  install=$(git -C "$main" config --get wt.install)
  if [[ -z $install && -f $dir/pnpm-lock.yaml ]]; then
    install='pnpm install --frozen-lockfile'
  fi
  if [[ -n $install ]]; then
    local log="${${TMPDIR:-/tmp}%/}/wt-install-${dir:t}.log"
    echo "依存をバックグラウンドでインストールしています（ログ: $log）"
    # コードを読むだけなら install を待つ必要はないので、終わったら通知する
    (
      cd "$dir" || exit
      if eval "$install" >"$log" 2>&1; then
        result='完了'
      else
        result="失敗（ログ: $log）"
      fi
      if command -v osascript >/dev/null 2>&1; then
        osascript -e "display notification \"$result\" with title \"wt: ${dir:t} の依存インストール\""
      fi
    ) &!
  fi
}

# mise（インストール済みの場合のみ有効化）
if [ -x "$HOME/.local/bin/mise" ]; then
  eval "$("$HOME/.local/bin/mise" activate zsh)"
elif command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

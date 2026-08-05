# dotfiles
設定ファイル置き場

## ディレクトリ構成の規約

配布物はツール名のディレクトリでフラットに置く（`claude/` `git/` `karabiner/` `zsh/` `wsl/`）。配置先の対応は `mise.toml` の `[dotfiles]` が定義する。

- **ルート直下で先頭 dot 付きの名前（`.gitignore`、`.claude/` 等）は「このリポジトリ自体に効く設定」だけに使う。** 配布物のディレクトリには dot を付けない。このルールはルート直下の名前にのみ適用する
- ディレクトリ内のファイル名は、配置先との対応が分かる名前にする（原則そのまま。例: `wsl/.wslconfig` → `C:\Users\<name>\.wslconfig`）。拡張子は配置先とあわせ、あえて別名にする場合は理由を README に書く（例: `zsh/zshrc-shared.zsh`）

## セットアップ

[mise](https://mise.jdx.dev/) が必要（`curl https://mise.run | sh` または `brew install mise`）。

```sh
mise trust
mise bootstrap        # WSL では mise bootstrap -E wsl
```

状態確認（宣言と実マシンの乖離チェック）:

```sh
mise bootstrap dotfiles status
```

## Claude settings のマシン固有設定

`~/.claude/settings.json` は symlink ではなく、共有ベースとマシン固有設定を jq でマージして生成する実ファイル。Claude Code のユーザーレベル設定に `settings.local.json` のような重ね合わせが効かないため、配置時にマージする。

| ファイル | 管理 | 役割 |
| --- | --- | --- |
| `claude/settings.json` | repo | 全マシン共通のベース（permissions、hooks 等） |
| `~/.claude/settings.machine.json` | マシン側（repo 外） | このマシン専用の値（`env`、`statusLine`、`enabledPlugins`、`model` 等） |
| `~/.claude/settings.json` | 生成物 | 上記 2 つを `jq -s '.[0] * .[1]'` でマージした結果 |

`settings.machine.json` を repo の外（`~/.claude/` 直下）に置くのは、repo を消して clone し直してもマシン固有設定が残るようにするため。初回は `claude/settings.machine.json` をテンプレとして copy-once する。

- 共有したい設定は `claude/settings.json` に書く。マシン固有の値は `~/.claude/settings.machine.json` に書く
- どちらを変えても `mise bootstrap`（または `mise run bootstrap`）で再マージする
- 乖離チェックは `mise run dotfiles-status`（`mise bootstrap dotfiles status` は symlink のみが対象で、生成物のこのファイルは見ない）
- jq の `*` はオブジェクトを再帰マージするが**配列は後勝ち**。`permissions.allow` 等の配列は共有側に集約し、machine 側では持たない

### hooks のマシン固有管理

- **hook の挙動差**（通知の有無・対象の切り替え等）はスクリプト側で吸収する（`project-name.sh` と同様に、copy-once したローカル設定ファイルをスクリプトが読む形）
- **hook の登録自体をマシンから外したい**場合は `~/.claude/settings.machine.json` の `hooks` で上書きする（オブジェクトのキー単位で後勝ちになる）
- 実際に「このマシンでは外したい」hook が出てきたときに初めて書く。先回りで作らない

## CLAUDE.md のマシン固有設定

`claude/CLAUDE.md`（→ `~/.claude/CLAUDE.md`）は先頭で `@CLAUDE.local.md` を読み込む。マシン固有の指示は `~/.claude/CLAUDE.local.md` に書く（`claude/CLAUDE.local.md` をテンプレとして copy-once する）。settings.json と違いマージ処理は不要で、Claude Code の import 機能に任せている。

## zshrc の扱い

`~/.zshrc` はツール（rbenv、pnpm、safe-chain 等）が自動追記するためマシン固有ファイルとして repo 管理外に置く。共通部分は `zsh/zshrc-shared.zsh` → `~/.config/zsh/shared.zsh` に symlink し、`~/.zshrc` の先頭から `source` する（この source 行は `[tasks.bootstrap]` が無ければ挿入する）。

ソース側のファイル名を配置先と同じ `shared.zsh` にせず `zshrc-shared.zsh` にしているのは、`~/.zshrc` から読み込まれる共有部分であること（かつ `~/.zshrc` そのものとして配置されるわけではないこと）を名前で示すため。

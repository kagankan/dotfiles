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

## Claude Code のアカウント切り替え（プロファイル）

Claude Code は 1 つの設定ディレクトリに 1 アカウントしか保持できないため、アカウントを使い分けるマシンでは `CLAUDE_CONFIG_DIR` を作業ディレクトリごとに切り替える。**この仕組みはマシン側のオプトイン**で、1 マシン 1 アカウントのマシンでは何も増えない（`~/.claude` だけを使う従来どおりの構成のまま）。

```
~/.claude/              # 共有テンプレ・hooks・scripts・マシン固有ファイルの置き場（全マシン共通）
~/.claude-profiles/     # プロファイルを使うマシンにだけできる
  default/              # どのアカウントにもログインしない（プロファイル未指定時の退避先）
  personal/
  work/
```

プロファイル側に置くのは、Claude Code が設定ディレクトリ直下からしか読まないもの（`CLAUDE.md`、`CLAUDE.local.md`、`skills/<名前>` の symlink と、生成した `settings.json`）だけ。hooks・scripts・マシン固有ファイルは `~/.claude` を絶対パスで参照するので、どのプロファイルで起動しても同じものが動く。

### 有効化

プロファイル一覧は `mise.toml` ではなくマシン側の `~/.config/mise/config.toml` で宣言する。repo 側に書くと全マシンに波及するため。

```toml
# ~/.config/mise/config.toml
[env]
CLAUDE_PROFILES = "default personal work"           # mise bootstrap がこの名前でディレクトリを用意する
CLAUDE_CONFIG_DIR = "~/.claude-profiles/default"    # 既定はどのアカウントも使わないプロファイル
```

```sh
mise bootstrap    # プロファイルの作成と共有設定の配布
```

作業用のプロファイルは作業ディレクトリごとの `mise.toml` で上書きする（mise の `[env]` はグローバル設定より優先され、ディレクトリを出ると戻る）。

```toml
# ~/<作業ディレクトリ>/mise.toml
[env]
CLAUDE_CONFIG_DIR = "~/.claude-profiles/work"
```

```sh
mise trust ~/<作業ディレクトリ>/mise.toml
```

- 割り当てるディレクトリ名は所属先に依存するため repo では管理しない
- mise は親ディレクトリを遡って `mise.toml` を探すので、作業ルートに 1 つ置けば配下の全リポジトリに効く
- リポジトリの `mise.toml` をツールバージョン管理に使っている場合、`CLAUDE_CONFIG_DIR` は git 管理外の `mise.local.toml` に分ける
- 各プロファイルでの初回ログインは、そのディレクトリで `claude` を起動して `/login` する
- **`~/.claude` にログイン済みのアカウントが残っていると、`CLAUDE_CONFIG_DIR` が効かない経路（mise を通さない GUI 起動等）でそのアカウントが使われる。** プロファイルを使い始めたら `~/.claude` では `/logout` しておく

## Claude settings のマシン固有設定

`~/.claude/settings.json` は symlink ではなく、共有ベースとマシン固有設定を jq でマージして生成する実ファイル。Claude Code のユーザーレベル設定に `settings.local.json` のような重ね合わせが効かないため、配置時にマージする。

| ファイル | 管理 | 役割 |
| --- | --- | --- |
| `claude/settings.json` | repo | 全マシン共通のベース（permissions、hooks 等） |
| `~/.claude/settings.machine.json` | マシン側（repo 外） | このマシン専用の値（`env`、`statusLine`、`enabledPlugins`、`model` 等） |
| `~/.claude/settings.json` | 生成物 | 上記 2 つを `jq -s '.[0] * .[1]'` でマージした結果（プロファイルを使うマシンでは各プロファイルにも同じ内容を配る） |

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

## Claude skill の追加

skill は `claude/skills/<skill 名>/SKILL.md` に置き、`mise.toml` の `[dotfiles]` で **ディレクトリ単位** に symlink する。

```toml
"~/.claude/skills/<skill 名>" = "claude/skills/<skill 名>"
```

```sh
mise bootstrap    # symlink を張る
```

- ファイル単位ではなくディレクトリ単位にするのは、`SKILL.md` 以外の補助ファイル（参照ドキュメント、スクリプト）が増えても宣言を変えずに済むため
- `~/.claude/skills` 自体は symlink にしない。Homebrew 等のツールが入れる skill（`hunk-review` 等）が同じディレクトリに同居するため

## zshrc の扱い

`~/.zshrc` はツール（rbenv、pnpm、safe-chain 等）が自動追記するためマシン固有ファイルとして repo 管理外に置く。共通部分は `zsh/zshrc-shared.zsh` → `~/.config/zsh/shared.zsh` に symlink し、`~/.zshrc` の先頭から `source` する（この source 行は `[tasks.bootstrap]` が無ければ挿入する）。

ソース側のファイル名を配置先と同じ `shared.zsh` にせず `zshrc-shared.zsh` にしているのは、`~/.zshrc` から読み込まれる共有部分であること（かつ `~/.zshrc` そのものとして配置されるわけではないこと）を名前で示すため。

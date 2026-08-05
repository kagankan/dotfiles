# dotfiles
設定ファイル置き場

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

`claude/settings.json` は mise の template モード（Tera 記法）で配置する。`~/.claude/settings.json` は symlink ではなく、変数を埋めて生成された実ファイルになる。

- マシンごとに変えたい値（`model`、`theme`、`tui` 等）はテンプレート内で `{{ vars.* }}` として参照する
  - デフォルト値は `mise.toml` の `[vars]` に書く（新マシンは何も設定しなくても動く状態を保つ）
  - マシン固有の上書きは `mise.local.toml`（git 管理外）の `[vars]` に書く
- `~/.claude/settings.json` を直接編集した場合、repo には自動反映されない。`mise bootstrap dotfiles status` がドリフトとして検知するので、共有すべき変更はテンプレートへ、マシン固有の変更は `mise.local.toml` の vars へ取り込んでから `apply` し直す
- テンプレート内に literal な `{{` や `{%` を書かない（Tera 記法として解釈され壊れる）。生成後の JSON は `[tasks.bootstrap]` の `jq empty` で妥当性チェックされる

### hooks のマシン固有管理

- **hook の挙動差**（通知の有無・対象の切り替え等）はスクリプト側で吸収する（`project-name.sh` と同様に、copy-once したローカル設定ファイルをスクリプトが読む形）
- **hook の登録自体をマシンから外したい**場合のみ、`[vars]` にフラグを追加してテンプレート内で `{% if %}` 分岐する。フラグはデフォルト値を持たせ「未設定なら全部入り」にする
- フラグや分岐は、実際に「このマシンでは外したい」hook が出てきたときに初めて追加する。先回りで作らない

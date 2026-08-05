# CLAUDE.md

## リポジトリ概要

個人の dotfiles。macOS と WSL で使う設定ファイルを管理している。
`mise bootstrap` で `~/.claude/` や `~/.config/` 配下に symlink を張って適用する。
適用対象は `mise.toml` の `[dotfiles]` で宣言し、WSL 向けの差分は `mise.wsl.toml` で上書きする。

## ディレクトリ構成

配布物はツール名のディレクトリでフラットに置く。配置先は `mise.toml` の `[dotfiles]` が定義する。

- `claude/` — Claude Code のユーザーレベル設定（`~/.claude/` に配布する共有テンプレ）
  - `claude/settings.json` — macOS 用（template モードで変数を埋めて配置）
  - `claude/settings.wsl.json` — WSL 用
  - `claude/hooks/` — 通知音スクリプト等
  - `claude/CLAUDE.md` — 全プロジェクト共通の指示書（symlink 先: `~/.claude/CLAUDE.md`）
- `git/` — グローバル gitignore（→ `~/.config/git/ignore`）
- `karabiner/` — Karabiner-Elements の設定、外部キーボード向けリマップ（→ `~/.config/karabiner/`）
- `zsh/` — シェル設定（→ `~/.zshrc`）
- `wsl/` — WSL のグローバル設定（Windows 側に置くファイルのため手動で配置）
- `mise.toml` — dotfiles の適用定義（`[dotfiles]` と `[tasks.bootstrap]`）
- `mise.wsl.toml` — WSL 用の上書き設定（`mise bootstrap -E wsl` でマージされる）

## 規約

- コメント・説明は日本語で書く（コード中のコメント、スクリプトの echo、description フィールド等すべて）
- dot 付きのファイル・ディレクトリ（`.gitignore`、`.claude/` 等）は「このリポジトリ自体に効く設定」のみに使う。配布物はツール名のディレクトリに dot 無しのファイル名で置く（例: `zsh/zshrc`）
- `claude/` 配下のファイルは共有テンプレとして機能するため、スクリプトが参照するファイル（許可リスト等）も空テンプレの状態で含める
- マシン固有の設定ファイル（`main-branch-allowed-repos.txt`、`hooks/project-name.sh`）は symlink にせず、`mise.toml` の `[tasks.bootstrap]` で「存在しない場合のみテンプレからコピー」する（マシン側の編集を上書きしないため）

## 注意事項

- main ブランチへの直接コミットが許可されている（`~/.claude/main-branch-allowed-repos.txt` で除外済み）
- `claude/` 内のファイルはこのリポジトリのプロジェクト設定ではなく、symlink 経由で `~/.claude/` に配置する共有テンプレ

## Karabiner 設定の編集

- `device_if` 条件で外部キーボード接続時のみ適用するルールを書いている
- デバイスの `vendor_id` / `product_id` は Karabiner-EventViewer で確認できる
- 既存のデバイス ID:
  - `vendor_id: 7247, product_id: 99` — 外部キーボード 1
  - `vendor_id: 9354, product_id: 33639` — 外部キーボード 2
- `simple_modifications`（Ctrl↔Cmd スワップ）が先に評価され、その結果に対して `complex_modifications` が適用される

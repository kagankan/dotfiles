# CLAUDE.md

## リポジトリ概要

個人の dotfiles。macOS と WSL で使う設定ファイルを管理している。
`setup.sh` で `~/.claude/` や `~/.config/` 配下に symlink を張って適用する。

## ディレクトリ構成

- `.config/karabiner/` — Karabiner-Elements の設定（外部キーボード向けリマップ）
- `claude/` — Claude Code のユーザーレベル設定（`~/.claude/` に symlink して使う）
  - `claude/settings.json` — macOS 用
  - `claude/settings.wsl.json` — WSL 用
  - `claude/hooks/` — 通知音スクリプト等
  - `claude/CLAUDE.md` — 全プロジェクト共通の指示書（symlink 先: `~/.claude/CLAUDE.md`）
- `.wslconfig` — WSL のグローバル設定
- `.zshrc` — シェル設定

## 規約

- コメント・説明は日本語で書く（コード中のコメント、スクリプトの echo、description フィールド等すべて）
- `claude/` 配下のファイルは共有テンプレとして機能するため、スクリプトが参照するファイル（許可リスト等）も空テンプレの状態で含める

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

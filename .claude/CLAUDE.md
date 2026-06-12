# CLAUDE.md (user-level)

## コマンド実行のルール

- `pnpm test` / `pnpm lint` 等の長時間コマンドを実行するときは、出力を必ずファイルに保存する
- 出力先はリポジトリ直下の `.ai-output/` ディレクトリを使う (`/tmp/` は permission の都合で避ける)
  - `.ai-output/` はグローバル gitignore に登録済み
  - ディレクトリがなければ `mkdir -p .ai-output` で作る
- ファイル名は `$(date +%Y-%m-%d-%H-%M)-<内容>.log` の形式 (例: `2026-04-29-02-15-test.log`)
- 結果の確認は保存したファイルを `grep` / `sed` で処理する。同じコマンドを再実行しない
- 例:
  - 実行: `pnpm test --run path/to/file 2>&1 | tee .ai-output/$(date +%Y-%m-%d-%H-%M)-test.log`
  - 確認: `grep -E 'Test Files|Tests |✗|FAIL' .ai-output/2026-04-29-02-15-test.log`
  - 別観点で見直したいときは grep パターンを変えるだけで再実行不要

## Pull Request のルール

- PR は必ず **Draft** 状態で作成する。Open に切り替えるのは人間が行う
  - `gh pr create` を使う場合は `--draft` フラグを必ず付ける
  - 既存 PR を作り直す場合も Draft で作成する
- PR description は、リポジトリに `.github/pull_request_template.md` がある場合は**そのテンプレートのセクション構成をそのまま使って**記入する
  - `## Summary` / `## Test plan` 等の独自構成に書き換えない
  - テンプレートのコメント (`<!-- ... -->`) は埋めるかコメントごと差し替える
  - 既存のチェックリスト項目は AI 側で完了確認したものだけ `[x]`、人間が後でやる項目 (セルフレビュー、AI レビュー、ラベル付与、Slack 連絡等) は `[ ]` のまま残す
  - テンプレートが無いリポジトリのみ Summary / Test plan で書く

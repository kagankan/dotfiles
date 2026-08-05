# dotfiles
設定ファイル置き場

## セットアップ

[mise](https://mise.jdx.dev/) が必要（`curl https://mise.run | sh`）。

```sh
./setup.sh  # 内部で mise bootstrap を実行（WSL では自動で -E wsl が付く）
```

状態確認は `mise bootstrap dotfiles status`。

# settings.json のマージ処理。第 1 引数を共有ベースとし、以降のレイヤー
# （WSL 差分、マシン固有）を順に重ねる。jq -s -f で使う。
#
# permissions の allow/deny/ask はレイヤーをまたいで結合する。`*` に任せると
# 配列は後勝ちになり、レイヤー側が deny を 1 つ足すだけで共有側の deny 全体が
# 消えてしまうため。
def merge($base; $layer):
  ($base * $layer)
  | .permissions.allow = (($base.permissions.allow // []) + ($layer.permissions.allow // []) | unique)
  | .permissions.deny = (($base.permissions.deny // []) + ($layer.permissions.deny // []) | unique)
  | .permissions.ask = (($base.permissions.ask // []) + ($layer.permissions.ask // []) | unique);

reduce .[1:][] as $layer (.[0]; merge(.; $layer))

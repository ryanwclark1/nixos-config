{
  pkgs
}:

pkgs.writeShellScriptBin "cliphist-copy" ''
  sleep 0.1 && cliphist list | rofi -dmenu -theme $HOME/.config/rofi/style/cliphist | cliphist delete
''
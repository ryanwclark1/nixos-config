{
  pkgs
}:

pkgs.writeShellScriptBin "cliphist-copy" ''
  sleep 0.1 && ${pkgs.cliphist}/bin/cliphist list | ${pkgs.rofi}/bin/rofi -dmenu -theme $HOME/.config/rofi/style/cliphist | ${pkgs.cliphist}/bin/cliphist delete
''
{
  pkgs
}:

pkgs.writeShellScriptBin "applauncher-fullscreen" ''
  dir="$HOME/.config/rofi/style"
  theme='launcher-full'

  rofi_cmd() {
    rofi -show drun \
      -theme "$dir/$theme.rasi"
  }

  rofi_cmd
''
{
  pkgs
}:

pkgs.writeShellScriptBin "yt" ''
  notify-send "Opening video" "$(wl-paste)"
  mpv "$(wl-paste)"
''

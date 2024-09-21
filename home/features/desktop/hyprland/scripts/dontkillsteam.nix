
#TO DO: UPDATE
{
  pkgs
}:

pkgs.writeShellScriptBin "dontkillsteam" ''
  if [[ $(hyprctl activewindow -j | jq -r ".class") == "Steam" ]]; then
      ${pkgs.ydotool}/bin/ydotool windowunmap $(ydotool getactivewindow)
  else
      hyprctl dispatch killactive ""
  fi
''
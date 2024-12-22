{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.file.".config/eww/scripts/workspaces.sh" = {
    text = ''
      #!/bin/sh
      
      workspaces() {
      ./scripts/workspaces.lua
      }
      workspaces
      tail -f /tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/hyprland.log | grep --line-buffered "Changed to workspace" | while read -r; do
      workspaces
      done
    '';
    executable = true;
  };
}
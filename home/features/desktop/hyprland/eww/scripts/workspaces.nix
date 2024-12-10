{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.file.".config/eww/scripts/workspaces.sh" = {
    text = ''
    '';
    executable = true;
  };
}
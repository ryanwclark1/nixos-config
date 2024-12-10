{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.file.".config/eww/scripts/workspace.sh" = {
    text = ''
    '';
    executable = true;
  };
}
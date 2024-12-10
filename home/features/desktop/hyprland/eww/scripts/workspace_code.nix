{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.file.".config/eww/scripts/workspace_code.sh" = {
    text = ''
    '';
    executable = true;
  };
}
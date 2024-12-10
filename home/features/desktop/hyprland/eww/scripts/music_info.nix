{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.file.".config/eww/scripts/music_info.sh" = {
    text = ''
    '';
    executable = true;
  };
}
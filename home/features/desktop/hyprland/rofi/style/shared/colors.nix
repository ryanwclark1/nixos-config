{
  config,
  lib,
  pkgs,
  ...
}:

with config.lib.stylix.colors.withHashtag;
with config.stylix.fonts;

{
  home.file.".config/rofi/style/shared/colors.rasi" = {
    text = ''
      * {
        background:     #1E1D2FFF;
        background-alt: #282839FF;
        foreground:     #D9E0EEFF;
        selected:       #7AA2F7FF;
        active:         #ABE9B3FF;
        urgent:         #F28FADFF;
      }
    '';
    executable = false;
  };
}

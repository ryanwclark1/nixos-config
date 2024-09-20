{
  config,
  lib,
  pkgs,
  ...
}:

with config.lib.stylix.colors.withHashtag;
with config.stylix.fonts;

{
  home.file.".config/rofi/style/shared/border.rasi" = {
    text = ''
      * { border-width: 3px; }
    '';
    executable = false;
  };
}

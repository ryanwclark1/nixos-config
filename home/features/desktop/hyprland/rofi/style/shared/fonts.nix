{
  config,
  lib,
  pkgs,
  ...
}:

with config.lib.stylix.colors.withHashtag;
with config.stylix.fonts;

{
  home.file.".config/rofi/style/shared/fonts.rasi" = {
    text = ''
      * {
          font: "JetBrains Mono Nerd Font 12";
      }
    '';
    executable = false;
  };
}

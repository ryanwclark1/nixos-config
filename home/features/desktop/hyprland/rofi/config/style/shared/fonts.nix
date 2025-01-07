{
  config,
  ...
}:

{
  home.file.".config/rofi/style/shared/fonts.rasi" = {
    text = ''
      * {
          font: "${config.stylix.fonts.monospace.name} 12";
      }
    '';
    executable = false;
  };
}

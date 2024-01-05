{
  pkgs,
  lib,
  config,
  ...
}:
with lib; {
  options.graphical.enable = mkEnableOption "graphical settings";

  config = mkIf config.graphical.enable {
    home.packages = with pkgs; [
      inkscape
      # krita
      # libresprite
      # aseprite
      gimp
      pastel
      imagemagick
      imv
      viu
      # vhs
      # ffmpeg_5-full
      # rx
    ];
  };
}
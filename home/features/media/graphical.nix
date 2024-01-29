{
  pkgs,
  lib,
  config,
  ...
}:

{
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
    exif
    # vhs
    # ffmpeg_5-full
    # rx
  ];

}
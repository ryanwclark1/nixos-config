{
  pkgs,
  lib,
  config,
  ...
}:

{
  home.packages = with pkgs; [
    vlc
    handbrake
    blender
    freetube
    ffmpeg
    ffmpegthumbs
    kdenlive
  ];
}
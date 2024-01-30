{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    blender
    freetube
    ffmpeg
    ffmpegthumbs
    handbrake
    kdenlive
    vlc
  ];
}
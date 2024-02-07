{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    # blender
    blender-hip
    freetube
    ffmpeg
    ffmpegthumbs
    handbrake
    kdenlive
    vlc
  ];
}
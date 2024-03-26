{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    blender-hip # Includes blender and thembnailer
    freetube
    ffmpeg
    ffmpegthumbs
    # handbrake
    kdenlive
    vlc
  ];
}

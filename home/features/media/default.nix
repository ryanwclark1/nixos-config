{
  pkgs,
  ...
}:

{
  imports = [
    ./aria.nix
    ./gstreamer.nix
    ./freetube.nix
    ./mpv.nix
    ./obs.nix
    ./yt-dlp.nix
  ];

  home.packages = with pkgs; [
    mkvtoolnix # Matroska tools
    # blender-hip # Includes blender and thumbnailer
    # darktable # RAW photo editor
    # digikam # Photo management
    # drawio # Diagram editor
    # eog # Gnome Image viewer
    ffmpeg # Multimedia framework
    # gimp # Image editor
    graphviz # Graph visualization
    # handbrake # Video transcoder
    imagemagick # Image manipulation
    # inkscape # Vector graphics editor
    # kdenlive # Video editor
    # krita # Digital painting
    # termusic
    vlc # Media player
  ];
}



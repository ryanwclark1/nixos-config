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
    ./ncmp.nix
    # ./obs.nix
    ./playerctl.nix
    ./yt-dlp.nix
  ];

  home.packages = with pkgs; [
    # blender-hip # Includes blender and thumbnailer
    # darktable # RAW photo editor
    # digikam # Photo management
    # drawio # Diagram editor
    eog # Gnome Image viewer
    ffmpeg # Multimedia framework
    # gimp # Image editor
    graphviz # Graph visualization
    # handbrake # Video transcoder
    imagemagick # Image manipulation
    # inkscape # Vector graphics editor
    # kdenlive # Video editor
    # krita # Digital painting
    spotify
    termusic
    vlc # Media player
    tartube-yt-dlp

  ];
}



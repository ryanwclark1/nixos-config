{
  pkgs,
  ...
}:

{
  imports = [
    ./darktable.nix
    ./graphical.nix
    ./gstreamer.nix
    ./mediautils.nix
    ./music.nix
    ./obs.nix
    ./video.nix
    ./yt-dlp.nix
  ];

   home.packages = with pkgs; [
    f3d
  ];
}
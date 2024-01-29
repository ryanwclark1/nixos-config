{
  pkgs,
  lib,
  config,
  ...
}:
{

  imports = [
    ./darktable.nix
    ./graphical.nix
    ./mediautils.nix
    ./music.nix
    ./obs.nix
    ./video.nix
    ./yt-dlp.nix
  ];



}
{
  pkgs,
  lib,
  config,
  ...
}:
with lib; {

  imports = [
    ./darktable.nix
    ./graphical.nix
    ./mediautils.nix
    ./music.nix
    ./obs.nix
    ./video.nix
    ./yt-dlp.nix

  ];

  options.media.enable = mkEnableOption "media packages";
  config = mkIf config.media.enable {
    darktable.enable = true;
    graphical.enable = true;
    mediautils.enable = true;
    music.enable = true;
    obs.enable = true;
    video.enable = true;
    yt-dlp.enable = true;

  };
}
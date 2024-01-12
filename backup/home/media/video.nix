{
  pkgs,
  lib,
  config,
  ...
}:
with lib; {
  options.video.enable = mkEnableOption "video settings";

  config = mkIf config.video.enable {
    home.packages = with pkgs; [
      vlc
      handbrake
      blender
      freetube
      ffmpeg
      ffmpegthumbs
      kdenlive
    ];
  };
}
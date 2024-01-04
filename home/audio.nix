{
  pkgs,
  lib,
  config,
  ...
}:
with lib; {
  options.audio.enable = mkEnableOption "audio settings";

  config = mkIf config.audio.enable {
    home.packages = with pkgs; [
      pavucontrol
      playerctl
      pulsemixer
    ];
  };
}
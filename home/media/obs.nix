{
  lib,
  config,
  pkgs,
  ...
}:
with lib; {
  options.obs.enable = mkEnableOption "obs settings";

  config = mkIf config.obs.enable {
    programs.obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [
        wlrobs
        obs-pipewire-audio-capture
      ];
    };
  };
}

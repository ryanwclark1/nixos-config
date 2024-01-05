{
  pkgs,
  config,
  lib,
  ...
}:
# media - control and enjoy audio/video
with lib; {
  options.mediautils.enable = mkEnableOption "media utilities settings";

  config = mkIf config.mediautils.enable {

    home.packages = with pkgs; [
      # audio control
      pavucontrol
      playerctl
      pulsemixer
      # images
      imv
    ];

    programs = {
      mpv = {
        enable = true;
        defaultProfiles = ["gpu-hq"];
        scripts = [pkgs.mpvScripts.mpris];
      };

      obs-studio.enable = true;
    };

    services = {
      playerctld.enable = true;
    };
  };
}

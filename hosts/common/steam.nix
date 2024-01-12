{
  pkgs,
  lib,
  config,
  ...
}:

with lib; {
  options.steam.enable = mkEnableOption "steam settings";

  config = mkIf config.steam.enable {

    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      package = pkgs.steam;
    };

  };
}

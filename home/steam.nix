{
  pkgs,
  lib,
  config,
  ...
}:

with lib; {
  options.steam.enable = mkEnableOption "steam settings";

  config = mkIf config.steam.enable {
    # programs.steam = {
    #   enable = true;
    #   remotePlay.openFirewall = true;
    # };

    home.packages = with pkgs; [
      steam
      steam-run
      lunar-client
      lutris
      vulkan-loader
      vulkan-tools
      # wineWowPackages.stagingFull
    ];

  };
}

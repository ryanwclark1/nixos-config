{
  pkgs,
  ...
}:

{
  programs = {
    gamemode = {
      enable = true;
    };
    steam = {
      enable = true;
      package = pkgs.steam;
      remotePlay.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
      protontricks = {
        enable = true;
        package = pkgs.protontricks;
      };
    };
  };
}

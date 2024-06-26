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
      remotePlay.openFirewall = true;
      package = pkgs.steam;
    };
  };
}

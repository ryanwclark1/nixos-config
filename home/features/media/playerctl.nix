{
  pkgs,
  ...
}:

{
  services.playerctld = {
    enable = true;
    package = pkgs.playerctl;
  };
}

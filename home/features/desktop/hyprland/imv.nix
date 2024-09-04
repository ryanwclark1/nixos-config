{
  pkgs,
  ...
}:

{
  programs.imv = {
    enable = true;
    package = pkgs.imv;
  };
}
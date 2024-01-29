{
  pkgs,
  lib,
  config,
  ...
}:

{
  programs.zoxide = {
    enable = true;
  };
}

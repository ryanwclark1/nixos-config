{
  pkgs,
  lib,
  config,
  ...
}:
with lib; {
  programs.lazygit = {
    enable = true;
  };
}

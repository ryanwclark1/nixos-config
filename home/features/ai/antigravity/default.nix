{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.packages = [
    pkgs.antigravity.fhs
    pkgs.antigravity-cli
    pkgs.antigravity-ide.fhs
  ];
}

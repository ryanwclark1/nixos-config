{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.packages = [
    pkgs.antigravity
    pkgs.antigravity-cli
    pkgs.antigravity-ide
  ];
}

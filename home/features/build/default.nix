{
  pkgs,
  lib,
  config,
  ...
}:
with lib; {
  home.packages = with pkgs; [
    cmake
    gnumake
    pkg-config
  ];
}
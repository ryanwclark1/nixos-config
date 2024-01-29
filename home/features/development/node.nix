# TODO: add user variable
{
  pkgs,
  lib,
  config,
  ...
}:
with lib; {
  home.packages = with pkgs; [
    nodejs
    nodePackages.npm
    nodePackages.pnpm
    yarn
  ];
  home.sessionPath = ["/home/administrator/.node/bin"];

}
# TODO: add user variable
{
  pkgs,
  lib,
  config,
  ...
}:
with lib; {
  options.node.enable = mkEnableOption "node settings";

  config = mkIf config.node.enable {
    home.packages = with pkgs; [
      nodejs
      nodePackages.npm
      nodePackages.pnpm
      yarn
    ];
    home.sessionPath = ["/home/administrator/.node/bin"];
  };
}
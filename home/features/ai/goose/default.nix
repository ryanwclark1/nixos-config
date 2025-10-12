{
  config,
  pkgs,
  lib,
  ...
}:

let
  gooseHome = "${config.home.homeDirectory}/goose";
  settingsPath = "${gooseHome}/goose.json";
in
{
  home.packages = with pkgs; [
    goose-cli
  ];

  # home.file."${gooseHome}/goose.json" = {
  #   force = true;
  #   source = ./goose.json;
  # };
}

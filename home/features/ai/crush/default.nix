{
  config,
  pkgs,
  lib,
  ...
}:

let
  crushHome = "${config.home.homeDirectory}/crush";
  settingsPath = "${crushHome}/crush.json";
in
{
  home.packages = with pkgs; [
    crush
  ];

  home.file."${crushHome}/crush.json" = {
    force = true;
    source = ./crush.json;
  };
}

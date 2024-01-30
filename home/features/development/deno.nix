{
  pkgs,
  lib,
  ...
}:

with lib; {
  home.packages = with pkgs; [deno];
  home.sessionPath = ["$HOME/.deno/bin"];
}
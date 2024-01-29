# TODO: add user variable
{
  pkgs,
  lib,
  config,
  ...
}:

with lib; {
  home.packages = with pkgs; [deno];
  home.sessionPath = ["/home/administrator/.deno/bin"];
}
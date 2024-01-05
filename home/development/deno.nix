# TODO: add user variable
{
  pkgs,
  lib,
  config,
  ...
}:
with lib; {
  options.deno.enable = mkEnableOption "deno settings";
  
  config = mkIf config.deno.enable {
    home.packages = with pkgs; [deno];
    home.sessionPath = ["/home/administrator/.deno/bin"];
  };
}
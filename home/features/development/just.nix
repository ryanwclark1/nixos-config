# just is a handy way to save and run project-specific commands.
# Similar to make
{
  pkgs,
  lib,
  config,
  ...
}:
with lib; {
  home.packages = with pkgs; [just];
}
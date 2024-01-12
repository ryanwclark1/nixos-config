# just is a handy way to save and run project-specific commands.
# Similar to make
{
  pkgs,
  lib,
  config,
  ...
}:
with lib; {
  options.just.enable = mkEnableOption "just settings";
  config = mkIf config.just.enable {
    home.packages = with pkgs; [just];
  };
}
# An interactive cheatsheet tool for the command-line
{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.thefuck = {
    enable = true;
    package = pkgs.thefuck;
    enableBashIntegration = lib.mkIf config.programs.bash.enable true;
    enableZshIntegration = lib.mkIf config.programs.zsh.enable true;
    enableFishIntegration = lib.mkIf config.programs.fish.enable true;
    enableNushellIntegration = lib.mkIf config.programs.nushell.enable true;
    enableInstantMode = true;
  };
}
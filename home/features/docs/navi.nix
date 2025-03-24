# An interactive cheatsheet tool for the command-line
{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.navi = {
    enable = true;
    package = pkgs.navi;
    enableBashIntegration = lib.mkIf config.programs.bash.enable false;
    enableFishIntegration = lib.mkIf config.programs.fish.enable false;
    enableZshIntegration = lib.mkIf config.programs.zsh.enable false;
    settings = {
      finder = {
        command = "fzf";
      };
      client = {
        tealdeer = true;
      };
      shell = {
        command = "bash";
      };
    };
  };
}

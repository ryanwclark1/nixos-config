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
    # conflicts with Control G -> GH
    enableBashIntegration = lib.mkIf config.programs.bash.enable false;
    enableFishIntegration = lib.mkIf config.programs.fish.enable false;
    enableZshIntegration = lib.mkIf config.programs.zsh.enable false;
    settings = {
      finder = {
        command = "fzf";
      #   # overrides: --tac # equivalent to the --fzf-overrides option
      #   # overrides_var: --tac # equivalent to the --fzf-overrides-var option
      };
      # cheats = {
      #   paths = [];
      # };
      # search:
      #   tags: git,!checkout # equivalent to the --tag-rules option
      client = {
        tealdeer = true;
      };
      shell = {
        command = "bash";
        finder_command = "bash";
      };
    };
  };
}
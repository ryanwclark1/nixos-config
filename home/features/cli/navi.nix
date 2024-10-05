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
    enableBashIntegration = lib.mkIf config.programs.bash.enable true;
    enableFishIntegration = lib.mkIf config.programs.fish.enable true;
    enableZshIntegration = lib.mkIf config.programs.zsh.enable true;
    settings = {
      style = {
        tag = {
          color = "cyan";
          width_percentage = 26;
          min_width = 20;
        };
        comment = {
          color = "blue";
          width_percentage = 42;
          min_width = 45;
        };
        snippet = {
          color = "white";
        };
      };
      finder = {
        command = "fzf";
        # overrides: --tac # equivalent to the --fzf-overrides option
        # overrides_var: --tac # equivalent to the --fzf-overrides-var option
      };
      cheats = {
        paths = [];
      };
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
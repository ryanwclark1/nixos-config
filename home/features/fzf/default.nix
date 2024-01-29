# TODO add config for fzf
# A command-line fuzzy finder
{
  pkgs,
  lib,
  config,
  ...
}:

{
  programs.fzf = {
    enable = true;
    changeDirWidgetCommand = "fd --type d";
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
  };

  home.packages = with pkgs; [
    skim
  ];
}

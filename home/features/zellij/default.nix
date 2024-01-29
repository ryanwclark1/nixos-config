# Similar to TMUX
{
  lib,
  pkgs,
  config,
  ...
}:

with lib; {
  programs.zellij = {
    enable = true;
    package = pkgs.zellij;
    # https://zellij.dev/documentation
    # settings = {};
    # enableZshIntegration = true;
    # enableFishIntegration = true;
    # enableBashIntegration = true;
  };
}
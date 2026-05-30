# zoxide is a smarter cd command, inspired by z and autojump.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.zoxide = {
    enable = true;
    enableBashIntegration = lib.mkIf config.programs.bash.enable true;
    enableFishIntegration = lib.mkIf config.programs.fish.enable true;
    enableZshIntegration = lib.mkIf config.programs.zsh.enable true;
    enableNushellIntegration = lib.mkIf config.programs.nushell.enable true;
  };
}

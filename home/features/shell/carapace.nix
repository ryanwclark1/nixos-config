# Enhanced shell configuration with additional Home Manager options
{ config, lib, pkgs, ... }:

{
  # Carapace - Multi-shell completion framework
  programs.carapace = {
    enable = true;
    enableBashIntegration = lib.mkIf config.programs.bash.enable true;
    enableZshIntegration = lib.mkIf config.programs.zsh.enable true;
    enableFishIntegration = lib.mkIf config.programs.fish.enable true;
  };
}

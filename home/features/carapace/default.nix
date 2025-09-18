# Enhanced shell configuration with additional Home Manager options
{ config, lib, pkgs, ... }:

{
  # Carapace - Multi-shell completion framework
  programs.carapace = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
  };
}

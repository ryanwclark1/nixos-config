{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Copy Hyprland configuration files for system-level Hyprland
  # This module provides configs without enabling home-manager's Hyprland
  
  # Note: imports removed to avoid dependency on home-manager hyprland module

  home.file = {
    # Main Hyprland config directories
    ".config/hypr/conf" = {
      source = ../hyprland/hypr/conf;
      recursive = true;
    };

    ".config/hypr/effects" = {
      source = ../hyprland/hypr/effects;
      recursive = true;
    };

    ".config/hypr/shaders" = {
      source = ../hyprland/hypr/shaders;
      recursive = true;
    };

    ".config/hypr/scripts" = {
      source = ../hyprland/scripts;
      recursive = true;
      executable = true;
    };

    # Main Hyprland config file
    ".config/hypr/hyprland.conf" = {
      text = ''
        # Hyprland Configuration for System-Level Installation
        # This config is used with system-level Hyprland + UWSM
        
        # Source all configuration files
        source = ~/.config/hypr/conf/animation.conf
        source = ~/.config/hypr/conf/autostart.conf
        source = ~/.config/hypr/conf/cursor.conf
        source = ~/.config/hypr/conf/custom.conf
        source = ~/.config/hypr/conf/decoration.conf
        source = ~/.config/hypr/conf/environment.conf
        source = ~/.config/hypr/conf/keybinding.conf
        source = ~/.config/hypr/conf/keyboard.conf
        source = ~/.config/hypr/conf/layout.conf
        source = ~/.config/hypr/conf/misc.conf
        source = ~/.config/hypr/conf/monitor.conf
        source = ~/.config/hypr/conf/plugin-hyprexpo.conf
        source = ~/.config/hypr/conf/window.conf
        source = ~/.config/hypr/conf/windowrule.conf
        source = ~/.config/hypr/conf/workspace.conf

        # Source color scheme
        source = ~/.config/hypr/conf/colors-hyprland.conf
        
        # Host-specific configuration
        source = ~/.config/hypr/conf/host-specific.conf
      '';
    };
  };

  # Add some basic packages that work well with Hyprland
  home.packages = with pkgs; [
    # Essential Hyprland tools
    wl-clipboard
    grim
    slurp
    
    # Additional tools
    wlr-randr
  ];
}
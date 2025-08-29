{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Copy Hyprland configuration files for system-level Hyprland
  # This consolidates both hyprland-configs and hyprland-minimal functionality
  
  home.file = {
    # Main Hyprland config directories
    ".config/hypr/conf" = {
      source = ../conf;
      recursive = true;
    };

    ".config/hypr/effects" = {
      source = ../effects;
      recursive = true;
    };

    ".config/hypr/shaders" = {
      source = ../shaders;
      recursive = true;
    };

    ".config/hypr/scripts" = {
      source = ../scripts;
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

}
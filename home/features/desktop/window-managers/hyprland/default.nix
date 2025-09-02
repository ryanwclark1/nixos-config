{
  config,
  pkgs,
  ...
}:
# Scripts reorganized 2025-08-20

{
  imports = [
    # ./config # Consolidated configuration
    ./colors.nix
    ./hypridle # Idle management
    ./hyprlock # Screen locking
    ./hyprpolkitagent # Authentication agent
    ./scripts/utilities.nix # Hyprland utility scripts
    ./scripts/keybindings-menu.nix # Interactive keybinding reference
    ./wal # Wallpaper automation (if hyprland-specific)
  ];


  home.packages = with pkgs; [
    # Hyprland-specific tools
    hyprpicker # Color picker for Hyprland
    grimblast # Enhanced screenshot tool (hyprland wrapper around grim)
    hdrop # Dropdown terminal for Hyprland
  ];

  home.file = {
    # Main Hyprland config directories
    ".config/hypr/conf" = {
      source = ./conf;
      recursive = true;
    };

    ".config/hypr/effects" = {
      source = ./effects;
      recursive = true;
    };

    ".config/hypr/shaders" = {
      source = ./shaders;
      recursive = true;
    };

    ".config/hypr/scripts" = {
      source = ./scripts;
      recursive = true;
      executable = true;
    };

    # Main Hyprland config file
    ".config/hypr/hyprland.conf" = {
      text = ''
        # Hyprland Configuration for System-Level Installation
        # This config is used with system-level Hyprland + UWSM

        # Source global variables first (required for all other configs)
        source = ~/.config/hypr/conf/variables.conf

        # Source all configuration files
        source = ~/.config/hypr/conf/animation.conf
        source = ~/.config/hypr/conf/autostart.conf
        source = ~/.config/hypr/conf/core.conf
        source = ~/.config/hypr/conf/decoration.conf
        source = ~/.config/hypr/conf/environment.conf
        source = ~/.config/hypr/conf/keybinding.conf
        source = ~/.config/hypr/conf/plugin.conf
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

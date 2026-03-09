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
    ./hyprsunset
    ./wal # Wallpaper automation (if hyprland-specific)
  ];

  home.packages = with pkgs; [
    # Hyprland-specific tools
    hyprpicker # Color picker for Hyprland
    grimblast # Enhanced screenshot tool (hyprland wrapper around grim)
    hdrop # Dropdown terminal for Hyprland
    hyprland-qtutils # Qt utilities for Hyprland

    # Hyprland utility scripts - maintained as external files

    # Terminal current working directory utility - maintained as external file: ./scripts/hypr/terminal-cwd.sh
    (writeShellScriptBin "terminal-cwd" (
      ''
        PATH="${pkgs.hyprland}/bin:${pkgs.procps}/bin:${pkgs.gawk}/bin:${pkgs.coreutils}/bin:${pkgs.jq}/bin:$PATH"

      ''
      + builtins.readFile (./scripts + "/hypr/terminal-cwd.sh")
    ))

    # Terminal here utility - maintained as external file: ./scripts/hypr/terminal-here.sh
    (writeShellScriptBin "terminal-here" (
      ''
        PATH="${pkgs.kitty}/bin:$PATH"

      ''
      + builtins.readFile (./scripts + "/hypr/terminal-here.sh")
    ))

    # Close all windows utility - maintained as external file: ./scripts/hypr/close-all-windows.sh
    (writeShellScriptBin "close-all-windows" (
      ''
        PATH="${pkgs.hyprland}/bin:${pkgs.jq}/bin:${pkgs.libnotify}/bin:$PATH"

      ''
      + builtins.readFile (./scripts + "/hypr/close-all-windows.sh")
    ))

    # Window information utility - maintained as external file: ./scripts/hypr/window-info.sh
    (writeShellScriptBin "window-info" (
      ''
        PATH="${pkgs.hyprland}/bin:${pkgs.jq}/bin:$PATH"

      ''
      + builtins.readFile (./scripts + "/hypr/window-info.sh")
    ))

    # Workspace switcher utility - maintained as external file: ./scripts/hypr/workspace-switch.sh
    (writeShellScriptBin "workspace-switch" (
      ''
        PATH="${pkgs.hyprland}/bin:$PATH"

      ''
      + builtins.readFile (./scripts + "/hypr/workspace-switch.sh")
    ))

    # Hyprland keybindings menu - maintained as external file: ./scripts/hypr/keybindings-menu.sh
    (writeShellScriptBin "keybindings-menu" (''
      PATH="${pkgs.hyprland}/bin:${pkgs.jq}/bin:${pkgs.libxkbcommon}/bin:${pkgs.walker}/bin:${pkgs.gawk}/bin:${pkgs.gnused}/bin:${pkgs.coreutils}/bin:$PATH"
    '' + builtins.readFile ./scripts/hypr/keybindings-menu.sh))

    # Toggle workspace gaps - maintained as external file: ./scripts/hypr/workspace-toggle-gaps.sh
    (writeShellScriptBin "workspace-toggle-gaps" (''
      PATH="${pkgs.hyprland}/bin:${pkgs.jq}/bin:${pkgs.libnotify}/bin:$PATH"
    '' + builtins.readFile ./scripts/hypr/workspace-toggle-gaps.sh))

    # Toggle nightlight - maintained as external file: ./scripts/hypr/toggle-nightlight.sh
    (writeShellScriptBin "toggle-nightlight" (''
      PATH="${pkgs.hyprland}/bin:${pkgs.procps}/bin:${pkgs.gnugrep}/bin:${pkgs.libnotify}/bin:${pkgs.coreutils}/bin:$PATH"
    '' + builtins.readFile ./scripts/hypr/toggle-nightlight.sh))

    # Toggle idle daemon - maintained as external file: ./scripts/hypr/toggle-idle.sh
    (writeShellScriptBin "toggle-idle" (''
      PATH="${pkgs.procps}/bin:${pkgs.libnotify}/bin:$PATH"
    '' + builtins.readFile ./scripts/hypr/toggle-idle.sh))

    # Toggle window transparency - maintained as external file: ./scripts/hypr/toggle-transparency.sh
    (writeShellScriptBin "toggle-transparency" (''
      PATH="${pkgs.hyprland}/bin:${pkgs.jq}/bin:${pkgs.libnotify}/bin:$PATH"
    '' + builtins.readFile ./scripts/hypr/toggle-transparency.sh))

    # Pop window (float + pin) - maintained as external file: ./scripts/hypr/window-pop.sh
    (writeShellScriptBin "window-pop" (''
      PATH="${pkgs.hyprland}/bin:${pkgs.jq}/bin:${pkgs.libnotify}/bin:$PATH"
    '' + builtins.readFile ./scripts/hypr/window-pop.sh))
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

    ".config/desktop/window-managers/hyprland/scripts" = {
      source = ./scripts;
      recursive = true;
      executable = true;
    };

    # Main Hyprland config file
    ".config/hypr/hyprland.conf" = {
      force = true;
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
        source = ~/.config/hypr/conf/monitor.conf
        source = ~/.config/hypr/conf/plugin.conf
        source = ~/.config/hypr/conf/window.conf
        source = ~/.config/hypr/conf/windowrule.conf
        source = ~/.config/hypr/conf/workspace.conf

        # Source color scheme
        source = ~/.config/hypr/conf/colors-hyprland.conf

        # Host-specific configuration (optional - generated by host-specific modules)
        # This file is created by host-specific.nix modules (e.g., woody.nix, frametop.nix)
        # Hyprland will skip this source if the file doesn't exist
        source = ~/.config/hypr/conf/host-specific.conf
      '';
    };
  };
}

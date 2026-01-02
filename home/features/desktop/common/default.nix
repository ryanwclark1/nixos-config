{
  pkgs,
  ...
}:

{
  imports = [
    ./theming
    ./services
    # ./wallpapers.nix
    ./xdg
    ./wayland
  ];

  # Core desktop dependencies - other packages moved to appropriate feature directories
  home.packages = with pkgs; [
    cairo # Graphics library (required by desktop components)
    libsoup_3 # HTTP library (required by desktop components)
    webkitgtk_6_0 # Web rendering engine (required by desktop components)

    # Audio utility scripts
    (writeShellScriptBin "audio-switch" (builtins.readFile ./scripts/system/audio-switch.sh))
    (writeShellScriptBin "audio-volume-up" (builtins.readFile ./scripts/system/audio-volume-up.sh))
    (writeShellScriptBin "audio-volume-down" (builtins.readFile ./scripts/system/audio-volume-down.sh))
    (writeShellScriptBin "audio-volume-mute" (builtins.readFile ./scripts/system/audio-volume-mute.sh))

    # MCP utility scripts
    (writeShellScriptBin "mcp-cli" (builtins.readFile ./scripts/system/mcp-cli-launcher.sh))
    (writeShellScriptBin "mcp-process-config" (builtins.readFile ./scripts/system/mcp-process-config.sh))
    (writeShellScriptBin "qwen-env" (builtins.readFile ./scripts/system/qwen-env-manager.sh))
    (writeShellScriptBin "update-gemini-cli" (builtins.readFile ./scripts/system/update-gemini-cli.sh))
    (writeShellScriptBin "gemini-cli-version" (builtins.readFile ./scripts/system/gemini-cli-version.sh))

    # System info notification scripts
    (writeShellScriptBin "show-battery" (''
      PATH="${pkgs.coreutils}/bin:${pkgs.libnotify}/bin:$PATH"
    '' + builtins.readFile ./scripts/system/show-battery.sh))

    (writeShellScriptBin "show-time" (''
      PATH="${pkgs.coreutils}/bin:${pkgs.libnotify}/bin:$PATH"
    '' + builtins.readFile ./scripts/system/show-time.sh))

    # Wayland utility scripts (Hyprland-compatible)
    (writeShellScriptBin "keybindings-menu" (''
      PATH="${pkgs.hyprland}/bin:${pkgs.jq}/bin:${pkgs.libxkbcommon}/bin:${pkgs.walker}/bin:${pkgs.gawk}/bin:${pkgs.gnused}/bin:${pkgs.coreutils}/bin:$PATH"
    '' + builtins.readFile ./scripts/wayland/keybindings-menu.sh))

    (writeShellScriptBin "workspace-toggle-gaps" (''
      PATH="${pkgs.hyprland}/bin:${pkgs.jq}/bin:${pkgs.libnotify}/bin:$PATH"
    '' + builtins.readFile ./scripts/wayland/workspace-toggle-gaps.sh))

    (writeShellScriptBin "toggle-nightlight" (''
      PATH="${pkgs.hyprland}/bin:${pkgs.procps}/bin:${pkgs.gnugrep}/bin:${pkgs.libnotify}/bin:${pkgs.coreutils}/bin:$PATH"
    '' + builtins.readFile ./scripts/wayland/toggle-nightlight.sh))

    (writeShellScriptBin "toggle-idle" (''
      PATH="${pkgs.procps}/bin:${pkgs.libnotify}/bin:$PATH"
    '' + builtins.readFile ./scripts/wayland/toggle-idle.sh))

    (writeShellScriptBin "toggle-transparency" (''
      PATH="${pkgs.hyprland}/bin:${pkgs.jq}/bin:${pkgs.libnotify}/bin:$PATH"
    '' + builtins.readFile ./scripts/wayland/toggle-transparency.sh))

    (writeShellScriptBin "window-pop" (''
      PATH="${pkgs.hyprland}/bin:${pkgs.jq}/bin:${pkgs.libnotify}/bin:$PATH"
    '' + builtins.readFile ./scripts/wayland/window-pop.sh))
  ];

  # Desktop common scripts - available to all desktop environments/window managers
  home.file = {
    # System-level scripts (independent of window manager/DE)
    ".local/bin/scripts/system" = {
      force = true;
      source = ./scripts/system;
      recursive = true;
      executable = true;
    };

    # Wayland-specific scripts (for all Wayland compositors)
    ".local/bin/scripts/wayland" = {
      force = true;
      source = ./scripts/wayland;
      recursive = true;
      executable = true;
    };
  };
}

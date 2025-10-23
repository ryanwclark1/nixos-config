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

    # TODO: Relocate
    # Rofi scripts (common across window managers)
    ".local/bin/scripts/rofi" = {
      force = true;
      source = ./scripts/rofi;
      recursive = true;
      executable = true;
    };
  };
}

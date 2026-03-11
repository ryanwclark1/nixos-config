{
  pkgs,
  lib,
  ...
}:

{
  # Truly universal Wayland tools that work with any compositor/DE
  home.packages = with pkgs; [
    # Universal clipboard utilities
    wl-clipboard
    wl-clip-persist # Keep Wayland clipboard even after programs close

    # Universal screenshot and recording tools
    grim # Screenshot utility for Wayland
    slurp # Screen region selector for Wayland
    wf-recorder # Screen recording for Wayland
    wl-screenrec # Modern Wayland screen recorder

    # Universal audio tools
    pwvucontrol # PipeWire volume control

    # Universal Wayland utilities
    waypipe # Network proxy for Wayland clients
    wayland-utils # Wayland debugging and info utilities

    # Terminal utilities - support multiple Wayland compositors (Hyprland, Sway, etc.)
    # Terminal current working directory utility - maintained as external file: ./terminal-cwd.sh
    (writeShellScriptBin "terminal-cwd" (
      ''
        PATH="${pkgs.hyprland}/bin:${pkgs.sway}/bin:${pkgs.procps}/bin:${pkgs.gawk}/bin:${pkgs.coreutils}/bin:${pkgs.jq}/bin:$PATH"
      ''
      + builtins.readFile (./. + "/terminal-cwd.sh")
    ))

    # Terminal here utility - maintained as external file: ./terminal-here.sh
    (writeShellScriptBin "terminal-here" (
      ''
        PATH="${pkgs.kitty}/bin:${pkgs.libnotify}/bin:$PATH"
      ''
      + builtins.readFile (./. + "/terminal-here.sh")
    ))
  ];

  # Wayland compositor scripts (shared across all Wayland compositors)
  # NOTE: Scripts have been co-located to ../scripts/system/ for better organization
  # Legacy wayland/scripts directory maintained for backward compatibility
  home.file = {
    # Wayland utility scripts directory (legacy - scripts now in system/)
    ".local/bin/scripts/wayland" = {
      force = true;
      source = ./.;
      recursive = true;
      executable = true;
    };

    # Screen recording scripts (deployed directly to ~/.local/bin for easy access)
    ".local/bin/screenrecord" = {
      force = true;
      source = ./screenrecord.sh;
      executable = true;
    };

    ".local/bin/screenrecord-stop" = {
      force = true;
      source = ./screenrecord-stop.sh;
      executable = true;
    };

    ".local/bin/screenrecord-toggle" = {
      force = true;
      source = ./screenrecord-toggle.sh;
      executable = true;
    };
  };

  # Ensure Videos directory exists for screen recordings
  home.activation.createVideosDir = ''
    mkdir -p "$HOME/Videos"
  '';
}

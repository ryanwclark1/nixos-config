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
    ./scripts/wayland
    ./scripts/hyprland
  ];

  # Core desktop dependencies - other packages moved to appropriate feature directories
  home.packages = with pkgs; [
    cairo # Graphics library (required by desktop components)
    libsoup_3 # HTTP library (required by desktop components)
    webkitgtk_6_0 # Web rendering engine (required by desktop components)

    # Universal file and system utilities (work on X11 and Wayland)
    handlr-regex # File association handler
    libnotify # Notification library
    mission-center # System monitor
    networkmanagerapplet # Network management GUI
    tesseract # OCR tool for screenshots
    xdg-desktop-portal-gtk # File picker support
    yad # Dialog tool

    # ── Volume / Audio ──────────────────────────────────────
    (writeShellScriptBin "os-volume" (
      ''
        PATH="${pkgs.wireplumber}/bin:${pkgs.libnotify}/bin:${pkgs.rofi}/bin:${pkgs.coreutils}/bin:${pkgs.gawk}/bin:${pkgs.gnugrep}/bin:$PATH"
      ''
      + builtins.readFile ./scripts/system/os-volume.sh
    ))
    (writeShellScriptBin "os-audio-switch" (
      ''
        PATH="${pkgs.wireplumber}/bin:${pkgs.libnotify}/bin:$PATH"
      ''
      + builtins.readFile ./scripts/system/os-audio-switch.sh
    ))
    (writeShellScriptBin "os-audio-volume-up" (
      ''
        PATH="${pkgs.wireplumber}/bin:${pkgs.libnotify}/bin:$PATH"
      ''
      + builtins.readFile ./scripts/system/os-audio-volume-up.sh
    ))
    (writeShellScriptBin "os-audio-volume-down" (
      ''
        PATH="${pkgs.wireplumber}/bin:${pkgs.libnotify}/bin:$PATH"
      ''
      + builtins.readFile ./scripts/system/os-audio-volume-down.sh
    ))
    (writeShellScriptBin "os-audio-volume-mute" (
      ''
        PATH="${pkgs.wireplumber}/bin:${pkgs.libnotify}/bin:$PATH"
      ''
      + builtins.readFile ./scripts/system/os-audio-volume-mute.sh
    ))

    # ── Brightness ──────────────────────────────────────────
    (writeShellScriptBin "os-brightness" (
      ''
        PATH="${pkgs.brightnessctl}/bin:${pkgs.rofi}/bin:${pkgs.libnotify}/bin:${pkgs.gawk}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:$PATH"
      ''
      + builtins.readFile ./scripts/system/os-brightness.sh
    ))

    # ── Battery ─────────────────────────────────────────────
    (writeShellScriptBin "os-battery-show" (
      ''
        PATH="${pkgs.coreutils}/bin:${pkgs.libnotify}/bin:$PATH"
      ''
      + builtins.readFile ./scripts/system/os-battery-show.sh
    ))
    (writeShellScriptBin "os-battery-remaining" (
      ''
        PATH="${pkgs.coreutils}/bin:${pkgs.upower}/bin:${pkgs.gawk}/bin:${pkgs.gnugrep}/bin:$PATH"
      ''
      + builtins.readFile ./scripts/system/os-battery-remaining.sh
    ))
    (writeShellScriptBin "os-battery-device" (
      ''
        PATH="${pkgs.coreutils}/bin:${pkgs.upower}/bin:${pkgs.gnugrep}/bin:$PATH"
      ''
      + builtins.readFile ./scripts/system/os-battery-device.sh
    ))
    (writeShellScriptBin "os-battery-state" (
      ''
        PATH="${pkgs.coreutils}/bin:${pkgs.upower}/bin:${pkgs.gawk}/bin:${pkgs.gnugrep}/bin:$PATH"
      ''
      + builtins.readFile ./scripts/system/os-battery-state.sh
    ))
    (writeShellScriptBin "os-battery-monitor" (
      ''
        PATH="${pkgs.coreutils}/bin:${pkgs.upower}/bin:${pkgs.libnotify}/bin:${pkgs.gawk}/bin:${pkgs.gnugrep}/bin:$PATH"
      ''
      + builtins.readFile ./scripts/system/os-battery-monitor.sh
    ))

    # ── Time ────────────────────────────────────────────────
    (writeShellScriptBin "os-time-show" (
      ''
        PATH="${pkgs.coreutils}/bin:${pkgs.libnotify}/bin:$PATH"
      ''
      + builtins.readFile ./scripts/system/os-time-show.sh
    ))

    # ── Screen recording indicator ──────────────────────────
    (writeShellScriptBin "os-screenrecording-indicator" (
      ''
        PATH="${pkgs.procps}/bin:${pkgs.coreutils}/bin:$PATH"
      ''
      + builtins.readFile ./scripts/system/os-screenrecording-indicator.sh
    ))

    # ── Launch scripts ──────────────────────────────────────
    (writeShellScriptBin "os-launch-or-focus" (
      ''
        PATH="${pkgs.hyprland}/bin:${pkgs.jq}/bin:${pkgs.coreutils}/bin:$PATH"
      ''
      + builtins.readFile ./scripts/system/os-launch-or-focus.sh
    ))
    (writeShellScriptBin "os-launch-or-focus-tui" (
      builtins.readFile ./scripts/system/os-launch-or-focus-tui.sh
    ))
    (writeShellScriptBin "os-launch-or-focus-webapp" (
      builtins.readFile ./scripts/system/os-launch-or-focus-webapp.sh
    ))
    (writeShellScriptBin "os-launch-tui" (builtins.readFile ./scripts/system/os-launch-tui.sh))
    (writeShellScriptBin "os-launch-browser" (
      ''
        PATH="${pkgs.coreutils}/bin:${pkgs.gnused}/bin:${pkgs.gnugrep}/bin:$PATH"
      ''
      + builtins.readFile ./scripts/system/os-launch-browser.sh
    ))
    (writeShellScriptBin "os-launch-webapp" (
      ''
        PATH="${pkgs.coreutils}/bin:${pkgs.gnused}/bin:$PATH"
      ''
      + builtins.readFile ./scripts/system/os-launch-webapp.sh
    ))
    (writeShellScriptBin "os-launch-walker" (
      ''
        PATH="${pkgs.procps}/bin:${pkgs.walker}/bin:$PATH"
      ''
      + builtins.readFile ./scripts/system/os-launch-walker.sh
    ))
    (writeShellScriptBin "os-launch-wifi" (
      ''
        PATH="${pkgs.util-linux}/bin:$PATH"
      ''
      + builtins.readFile ./scripts/system/os-launch-wifi.sh
    ))
    (writeShellScriptBin "os-launch-bluetooth" (
      ''
        PATH="${pkgs.util-linux}/bin:$PATH"
      ''
      + builtins.readFile ./scripts/system/os-launch-bluetooth.sh
    ))
    (writeShellScriptBin "os-launch-about" (builtins.readFile ./scripts/system/os-launch-about.sh))
    (writeShellScriptBin "os-launch-editor" (builtins.readFile ./scripts/system/os-launch-editor.sh))
    (writeShellScriptBin "os-launch-screensaver" (
      ''
        PATH="${pkgs.hyprland}/bin:${pkgs.jq}/bin:${pkgs.procps}/bin:${pkgs.libnotify}/bin:${pkgs.coreutils}/bin:$PATH"
      ''
      + builtins.readFile ./scripts/system/os-launch-screensaver.sh
    ))
    (writeShellScriptBin "os-launch-floating-terminal-with-presentation" (
      builtins.readFile ./scripts/system/os-launch-floating-terminal-with-presentation.sh
    ))

    # ── Toggle scripts ──────────────────────────────────────
    (writeShellScriptBin "os-toggle-nightlight" (
      ''
        PATH="${pkgs.hyprland}/bin:${pkgs.procps}/bin:${pkgs.gnugrep}/bin:${pkgs.libnotify}/bin:${pkgs.coreutils}/bin:$PATH"
      ''
      + builtins.readFile ./scripts/system/os-toggle-nightlight.sh
    ))
    (writeShellScriptBin "os-toggle-idle" (
      ''
        PATH="${pkgs.procps}/bin:${pkgs.libnotify}/bin:$PATH"
      ''
      + builtins.readFile ./scripts/system/os-toggle-idle.sh
    ))
    (writeShellScriptBin "os-toggle-waybar" (
      ''
        PATH="${pkgs.procps}/bin:$PATH"
      ''
      + builtins.readFile ./scripts/system/os-toggle-waybar.sh
    ))
    (writeShellScriptBin "os-toggle-screensaver" (
      ''
        PATH="${pkgs.coreutils}/bin:${pkgs.libnotify}/bin:$PATH"
      ''
      + builtins.readFile ./scripts/system/os-toggle-screensaver.sh
    ))

    # ── Restart scripts ─────────────────────────────────────
    (writeShellScriptBin "os-restart-app" (
      ''
        PATH="${pkgs.procps}/bin:$PATH"
      ''
      + builtins.readFile ./scripts/system/os-restart-app.sh
    ))
    (writeShellScriptBin "os-restart-walker" (builtins.readFile ./scripts/system/os-restart-walker.sh))
    (writeShellScriptBin "os-restart-terminal" (
      ''
        PATH="${pkgs.procps}/bin:${pkgs.coreutils}/bin:$PATH"
      ''
      + builtins.readFile ./scripts/system/os-restart-terminal.sh
    ))
    (writeShellScriptBin "os-restart-bluetooth" (
      ''
        PATH="${pkgs.util-linux}/bin:$PATH"
      ''
      + builtins.readFile ./scripts/system/os-restart-bluetooth.sh
    ))
    (writeShellScriptBin "os-restart-wifi" (
      ''
        PATH="${pkgs.util-linux}/bin:$PATH"
      ''
      + builtins.readFile ./scripts/system/os-restart-wifi.sh
    ))
    (writeShellScriptBin "os-restart-pipewire" (
      builtins.readFile ./scripts/system/os-restart-pipewire.sh
    ))

    # ── Power / Lock ────────────────────────────────────────
    (writeShellScriptBin "os-power" (
      ''
        PATH="${pkgs.procps}/bin:${pkgs.libnotify}/bin:${pkgs.coreutils}/bin:${pkgs.hyprland}/bin:$PATH"
      ''
      + builtins.readFile ./scripts/system/os-power.sh
    ))
    (writeShellScriptBin "os-lock-screen" (
      ''
        PATH="${pkgs.hyprland}/bin:${pkgs.procps}/bin:$PATH"
      ''
      + builtins.readFile ./scripts/system/os-lock-screen.sh
    ))

    # ── Command scripts ─────────────────────────────────────
    (writeShellScriptBin "os-cmd-present" (builtins.readFile ./scripts/system/os-cmd-present.sh))
    (writeShellScriptBin "os-cmd-missing" (builtins.readFile ./scripts/system/os-cmd-missing.sh))
    (writeShellScriptBin "os-cmd-reboot" (builtins.readFile ./scripts/system/os-cmd-reboot.sh))
    (writeShellScriptBin "os-cmd-shutdown" (builtins.readFile ./scripts/system/os-cmd-shutdown.sh))
    (writeShellScriptBin "os-cmd-screenshot" (
      ''
        PATH="${pkgs.coreutils}/bin:${pkgs.libnotify}/bin:$PATH"
      ''
      + builtins.readFile ./scripts/system/os-cmd-screenshot.sh
    ))
    (writeShellScriptBin "os-cmd-screenrecord" (
      ''
        PATH="${pkgs.procps}/bin:${pkgs.coreutils}/bin:${pkgs.hyprland}/bin:${pkgs.jq}/bin:${pkgs.libnotify}/bin:${pkgs.gawk}/bin:$PATH"
      ''
      + builtins.readFile ./scripts/system/os-cmd-screenrecord.sh
    ))
    (writeShellScriptBin "os-cmd-screensaver" (
      ''
        PATH="${pkgs.hyprland}/bin:${pkgs.jq}/bin:${pkgs.procps}/bin:${pkgs.coreutils}/bin:$PATH"
      ''
      + builtins.readFile ./scripts/system/os-cmd-screensaver.sh
    ))
    (writeShellScriptBin "os-cmd-share" (
      ''
        PATH="${pkgs.wl-clipboard}/bin:${pkgs.coreutils}/bin:${pkgs.findutils}/bin:${pkgs.fzf}/bin:$PATH"
      ''
      + builtins.readFile ./scripts/system/os-cmd-share.sh
    ))
    (writeShellScriptBin "os-cmd-terminal-cwd" (
      ''
        PATH="${pkgs.hyprland}/bin:${pkgs.procps}/bin:${pkgs.gawk}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:$PATH"
      ''
      + builtins.readFile ./scripts/system/os-cmd-terminal-cwd.sh
    ))

    # ── Utility scripts ─────────────────────────────────────
    (writeShellScriptBin "os-font-list" (
      ''
        PATH="${pkgs.fontconfig}/bin:${pkgs.gnugrep}/bin:${pkgs.coreutils}/bin:$PATH"
      ''
      + builtins.readFile ./scripts/system/os-font-list.sh
    ))
    (writeShellScriptBin "os-hook" (builtins.readFile ./scripts/system/os-hook.sh))
    (writeShellScriptBin "os-update-checker" (
      ''
        PATH="${pkgs.nixos-rebuild}/bin:${pkgs.nix}/bin:${pkgs.nvd}/bin:${pkgs.gawk}/bin:${pkgs.gnugrep}/bin:${pkgs.coreutils}/bin:$PATH"
      ''
      + builtins.readFile ./scripts/system/os-update-checker.sh
    ))
    (writeShellScriptBin "nm-applet-ctl" (
      ''
        PATH="${pkgs.networkmanagerapplet}/bin:${pkgs.procps}/bin:${pkgs.libnotify}/bin:$PATH"
      ''
      + builtins.readFile ./scripts/system/nm-applet.sh
    ))
    (writeShellScriptBin "os-clipboard-manager" (builtins.readFile ./scripts/system/os-clipboard-manager.sh))
    (writeShellScriptBin "os-channel-set" (builtins.readFile ./scripts/system/os-channel-set.sh))
  ];

  # Library scripts only (sourced by bins, not executed directly)
  home.file = {
    ".local/bin/scripts/system/os-battery-lib.sh".source = ./scripts/system/os-battery-lib.sh;
    ".local/bin/scripts/system/os-battery-icons.sh".source = ./scripts/system/os-battery-icons.sh;
    ".local/bin/scripts/system/os-rofi-helpers.sh".source = ./scripts/system/os-rofi-helpers.sh;
    ".local/bin/scripts/system/os-desktop-detection.sh".source =
      ./scripts/system/os-desktop-detection.sh;
    ".local/bin/scripts/system/os-app-launcher.sh".source = ./scripts/system/os-app-launcher.sh;
    ".local/bin/scripts/system/os-system-tools.sh".source = ./scripts/system/os-system-tools.sh;
    ".local/bin/scripts/system/os-url-handler.sh".source = ./scripts/system/os-url-handler.sh;
    ".local/bin/scripts/system/os-web-search.sh".source = ./scripts/system/os-web-search.sh;
    ".local/bin/scripts/system/os-vscode-workspaces.sh".source =
      ./scripts/system/os-vscode-workspaces.sh;
    ".local/bin/scripts/system/os-mpd-control.sh".source = ./scripts/system/os-mpd-control.sh;
    ".local/bin/scripts/system/os-power-manager.sh".source = ./scripts/system/os-power-manager.sh;
    ".local/bin/scripts/system/os-notify-lib.sh".source = ./scripts/system/os-notify-lib.sh;
  };
}

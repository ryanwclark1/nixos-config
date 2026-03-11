{
  config,
  lib,
  pkgs,
  ...
}:

let
  appsScript = pkgs.writeShellScriptBin "qs-apps" ''
    PATH="${pkgs.jq}/bin:${pkgs.coreutils}/bin:${pkgs.findutils}/bin:${pkgs.gnugrep}/bin:$PATH"
    ${builtins.readFile ./scripts/apps.sh}
  '';

  qsRofiScript = pkgs.writeShellScriptBin "qs-rofi" ''
    PATH="${pkgs.quickshell}/bin:${pkgs.jq}/bin:${pkgs.coreutils}/bin:$PATH"
    ${builtins.readFile ./scripts/qs-rofi.sh}
  '';

  runScript = pkgs.writeShellScriptBin "qs-run" ''
    PATH="${pkgs.jq}/bin:${pkgs.coreutils}/bin:${pkgs.findutils}/bin:$PATH"
    ${builtins.readFile ./scripts/run.sh}
  '';

  emojiScript = pkgs.writeShellScriptBin "qs-emoji" ''
    PATH="${pkgs.coreutils}/bin:$PATH"
    ${builtins.readFile ./scripts/emojis.sh}
  '';

  clipScript = pkgs.writeShellScriptBin "qs-clip" ''
    PATH="${pkgs.cliphist}/bin:${pkgs.jq}/bin:${pkgs.coreutils}/bin:$PATH"
    ${builtins.readFile ./scripts/cliphist.sh}
  '';

  wallpaperScript = pkgs.writeShellScriptBin "qs-wallpapers" ''
    PATH="${pkgs.jq}/bin:${pkgs.coreutils}/bin:${pkgs.findutils}/bin:$PATH"
    ${builtins.readFile ./scripts/wallpapers.sh}
  '';

  keybindsScript = pkgs.writeShellScriptBin "qs-keybinds" ''
    PATH="${pkgs.jq}/bin:${pkgs.gnugrep}/bin:${pkgs.coreutils}/bin:$PATH"
    ${builtins.readFile ./scripts/keybinds.sh}
  '';

  aiScript = pkgs.writeShellScriptBin "qs-ai" ''
    PATH="${pkgs.curl}/bin:${pkgs.jq}/bin:$PATH"
    ${builtins.readFile ./scripts/ai-prompt.sh}
  '';

  bookmarksScript = pkgs.writeShellScriptBin "qs-bookmarks" ''
    PATH="${pkgs.sqlite}/bin:${pkgs.jq}/bin:${pkgs.coreutils}/bin:${pkgs.findutils}/bin:$PATH"
    ${builtins.readFile ./scripts/bookmarks.sh}
  '';

  updatorScript = pkgs.writeShellScriptBin "qs-updator" ''
    PATH="${pkgs.jq}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.perl}/bin:$PATH"
    ${builtins.readFile ./scripts/updator.sh}
  '';

  cavaScript = pkgs.writeShellScriptBin "qs-cava" ''
    PATH="${pkgs.cava}/bin:${pkgs.gnused}/bin:${pkgs.coreutils}/bin:$PATH"
    ${builtins.readFile ./scripts/cava.sh}
  '';

  inhibitorScript = pkgs.writeScriptBin "qs-inhibitor" ''
    #!${pkgs.python3.withPackages (ps: [ ps.pywayland ])}/bin/python
    ${builtins.readFile ./scripts/inhibitor.py}
  '';

  networkScript = pkgs.writeShellScriptBin "qs-network" ''
    PATH="${pkgs.networkmanager}/bin:${pkgs.jq}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:$PATH"
    ${builtins.readFile ./scripts/network.sh}
  '';

  iconResolverScript = pkgs.writeShellScriptBin "qs-icon-resolver" ''
    PATH="${pkgs.jq}/bin:${pkgs.coreutils}/bin:${pkgs.findutils}/bin:${pkgs.gnugrep}/bin:${pkgs.gawk}/bin:$PATH"
    ${builtins.readFile ./scripts/icon-resolver.sh}
  '';

  in
  {
  options.features.quickshell = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable the Quickshell panel.";
    };
  };

  config = lib.mkIf config.features.quickshell.enable {
    home.packages = with pkgs; [
      # Quickshell core and Qt dependencies
      quickshell
      qt6.qtdeclarative # qmlls (QML language server)
      qt6.qtsvg
      qt6.qtimageformats
      qt6.qtmultimedia
      qt6.qt5compat

      # Quickshell utility scripts
      appsScript
      qsRofiScript
      runScript
      emojiScript
      clipScript
      wallpaperScript
      keybindsScript
      aiScript
      bookmarksScript
      updatorScript
      cavaScript
      inhibitorScript
      networkScript
      iconResolverScript
    ];

    home.activation.disableLegacyNotificationDaemons = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      if command -v systemctl >/dev/null 2>&1; then
        # Explicitly stop, disable and MASK these to prevent restarts
        for svc in swaync.service mako.service dunst.service; do
          systemctl --user stop "$svc" >/dev/null 2>&1 || true
          systemctl --user disable "$svc" >/dev/null 2>&1 || true
          systemctl --user mask "$svc" >/dev/null 2>&1 || true
          systemctl --user reset-failed "$svc" >/dev/null 2>&1 || true
        done

        # Kill any stray processes
        pkill -x swaync >/dev/null 2>&1 || true
        pkill -x mako >/dev/null 2>&1 || true
        pkill -x dunst >/dev/null 2>&1 || true

        # Clean up any other services claiming the notifications name
        while IFS= read -r unit; do
          [ -n "$unit" ] || continue
          systemctl --user stop "$unit" >/dev/null 2>&1 || true
          systemctl --user mask "$unit" >/dev/null 2>&1 || true
        done <<EOF
$(systemctl --user list-units --full --all --plain --no-legend 'dbus-*.service' 2>/dev/null | awk '/org\.freedesktop\.Notifications/ { print $1 }')
EOF
      fi

      if command -v busctl >/dev/null 2>&1; then
        busctl --user call org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus ReloadConfig >/dev/null 2>&1 || true
      fi
    '';

    home.activation.prepareQuickshellRestart = lib.hm.dag.entryBefore [ "reloadSystemd" ] ''
      if command -v systemctl >/dev/null 2>&1; then
        systemctl --user stop quickshell.service >/dev/null 2>&1 || true
      fi

      if command -v busctl >/dev/null 2>&1; then
        for _ in $(seq 1 50); do
          owner_line="$(busctl --user --list 2>/dev/null | awk '/org\.freedesktop\.Notifications/ { print $3; exit }')"
          if [ -z "$owner_line" ] || [ "$owner_line" = "-" ]; then
            break
          fi
          sleep 0.1
        done
      fi
    '';

    home.file.".config/quickshell" = {
      source = ./config;
      recursive = true;
    };

    home.file.".local/share/applications/org.quickshell.desktop".text = ''
      [Desktop Entry]
      Name=Quickshell
      Comment=Quickshell panel
      Exec=${pkgs.quickshell}/bin/quickshell
      Type=Application
      NoDisplay=true
      Categories=System;
    '';

    home.file.".local/share/dbus-1/services/org.freedesktop.Notifications.service".text = ''
      [D-BUS Service]
      Name=org.freedesktop.Notifications
      SystemdService=quickshell.service
    '';

    systemd.user.services.quickshell = {
      Unit = {
        Description = "Quickshell (QML shell)";
        After = [ "graphical-session.target" ];
        Wants = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${pkgs.quickshell}/bin/quickshell";
        Environment = [
          "PATH=%h/.nix-profile/bin:/etc/profiles/per-user/%u/bin:/run/current-system/sw/bin:${pkgs.quickshell}/bin:${pkgs.pipewire}/bin:${pkgs.networkmanager}/bin:${pkgs.tailscale}/bin:${pkgs.hyprland}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.bash}/bin"
        ];
        Restart = "on-failure";
        RestartSec = 2;
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}

{
  config,
  lib,
  pkgs,
  ...
}:

let
  repoRoot = builtins.toString ../../../../../../..;
  healthRules = pkgs.writeText "qs-health-rules.json" (builtins.readFile ./scripts/health-rules.json);

  qsRofiScript = pkgs.writeShellScriptBin "qs-rofi" ''
    PATH="${pkgs.quickshell}/bin:${pkgs.jq}/bin:${pkgs.coreutils}/bin:$PATH"
    ${builtins.readFile ./scripts/qs-rofi.sh}
  '';

  runScript = pkgs.writeShellScriptBin "qs-run" ''
    PATH="${pkgs.jq}/bin:${pkgs.coreutils}/bin:${pkgs.findutils}/bin:$PATH"
    ${builtins.readFile ./scripts/run.sh}
  '';

  wallpaperScript = pkgs.writeShellScriptBin "qs-wallpapers" ''
    PATH="${pkgs.jq}/bin:${pkgs.coreutils}/bin:${pkgs.findutils}/bin:$PATH"
    ${builtins.readFile ./scripts/wallpapers.sh}
  '';

  keybindsScript = pkgs.writeShellScriptBin "qs-keybinds" ''
    PATH="${pkgs.jq}/bin:${pkgs.gnugrep}/bin:${pkgs.coreutils}/bin:${pkgs.python3}/bin:$PATH"
    export PARSER_SCRIPT="${./scripts/parse-niri-binds.py}"
    ${builtins.readFile ./scripts/keybinds.sh}
  '';

  aiScript = pkgs.writeShellScriptBin "qs-ai" ''
    PATH="${pkgs.curl}/bin:${pkgs.jq}/bin:$PATH"
    ${builtins.readFile ./scripts/ai-prompt.sh}
  '';

  aiStreamScript = pkgs.writeShellScriptBin "qs-ai-stream" ''
    PATH="${pkgs.curl}/bin:${pkgs.jq}/bin:${pkgs.coreutils}/bin:${pkgs.gnused}/bin:$PATH"
    ${builtins.readFile ./scripts/ai-stream.sh}
  '';

  bangSyncScript = pkgs.writeShellScriptBin "qs-bang-sync" ''
    PATH="${pkgs.curl}/bin:${pkgs.jq}/bin:${pkgs.coreutils}/bin:$PATH"
    ${builtins.readFile ./scripts/bang-sync.sh}
  '';

  bangSearchScript = pkgs.writeShellScriptBin "qs-bang-search" ''
    PATH="${pkgs.jq}/bin:${pkgs.coreutils}/bin:$PATH"
    ${builtins.readFile ./scripts/bang-search.sh}
  '';

  bookmarksScript = pkgs.writeShellScriptBin "qs-bookmarks" ''
    PATH="${pkgs.sqlite}/bin:${pkgs.jq}/bin:${pkgs.coreutils}/bin:${pkgs.findutils}/bin:$PATH"
    ${builtins.readFile ./scripts/bookmarks.sh}
  '';

  updatorScript = pkgs.writeShellScriptBin "qs-updator" ''
    PATH="${pkgs.jq}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.perl}/bin:$PATH"
    ${builtins.readFile ./scripts/updator.sh}
  '';

  sleepMonitorScript = pkgs.writeShellScriptBin "qs-sleep-monitor" ''
    PATH="${pkgs.dbus}/bin:${pkgs.gawk}/bin:${pkgs.coreutils}/bin:$PATH"
    ${builtins.readFile ./scripts/sleep-monitor.sh}
  '';

  screenshotScript = pkgs.writeShellScriptBin "qs-screenshot" ''
    PATH="${pkgs.grim}/bin:${pkgs.slurp}/bin:${pkgs.wl-clipboard}/bin:${pkgs.coreutils}/bin:${pkgs.jq}/bin:${pkgs.hyprpicker}/bin:${pkgs.hyprland}/bin:$PATH"
    ${builtins.readFile ./scripts/screenshot.sh}
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

  compositorGuardScript = pkgs.writeShellScriptBin "qs-compositor-guard-check" ''
    PATH="${pkgs.ripgrep}/bin:${pkgs.bash}/bin:${pkgs.coreutils}/bin:$PATH"
    ${builtins.readFile ./scripts/check-compositor-guards.sh}
  '';

  compositorSmokeScript = pkgs.writeShellScriptBin "qs-compositor-smoke-check" ''
    PATH="${pkgs.ripgrep}/bin:${pkgs.bash}/bin:${pkgs.coreutils}/bin:${pkgs.jq}/bin:${pkgs.gnused}/bin:${pkgs.hyprland}/bin:${pkgs.niri}/bin:$PATH"
    ${builtins.readFile ./scripts/compositor-smoke.sh}
  '';

  compositorFixtureScript = pkgs.writeShellScriptBin "qs-compositor-fixture-check" ''
    PATH="${pkgs.jq}/bin:${pkgs.bash}/bin:${pkgs.coreutils}/bin:$PATH"
    ${builtins.readFile ./scripts/check-compositor-fixtures.sh}
  '';

  compositorVerifyScript = pkgs.writeShellScriptBin "qs-compositor-verify" ''
    PATH="${pkgs.ripgrep}/bin:${pkgs.bash}/bin:${pkgs.coreutils}/bin:${pkgs.jq}/bin:${pkgs.gnused}/bin:${pkgs.hyprland}/bin:${pkgs.niri}/bin:$PATH"
    ${builtins.readFile ./scripts/compositor-verify.sh}
  '';

  healthSafeFixScript = pkgs.writeShellScriptBin "qs-health-safe-fix" ''
    export QS_REPO_ROOT=${lib.escapeShellArg repoRoot}
    PATH="${pkgs.ripgrep}/bin:${pkgs.perl}/bin:${pkgs.coreutils}/bin:${pkgs.bash}/bin:$PATH"
    ${builtins.readFile ./scripts/health-safe-fix.sh}
  '';

  healthCheckScript = pkgs.writeShellScriptBin "qs-health-check" ''
    export QS_REPO_ROOT="''${QS_REPO_ROOT:-${lib.escapeShellArg repoRoot}}"
    export QS_HEALTH_RULES_FILE=${lib.escapeShellArg healthRules}
    export QS_COMPOSITOR_GUARD_SCRIPT="${compositorGuardScript}/bin/qs-compositor-guard-check"
    export QS_COMPOSITOR_FIXTURE_SCRIPT="${compositorFixtureScript}/bin/qs-compositor-fixture-check"
    export QS_COMPOSITOR_VERIFY_SCRIPT="${compositorVerifyScript}/bin/qs-compositor-verify"
    export QS_COMPOSITOR_SMOKE_SCRIPT="${compositorSmokeScript}/bin/qs-compositor-smoke-check"
    export QS_HEALTH_SAFE_FIX_SCRIPT="${healthSafeFixScript}/bin/qs-health-safe-fix"
    export QS_CONFIG_DIR="${config.home.homeDirectory}/.config/quickshell"
    export QS_FIXTURES_DIR="${config.home.homeDirectory}/.config/quickshell/fixtures"
    PATH="${pkgs.quickshell}/bin:${pkgs.jq}/bin:${pkgs.ripgrep}/bin:${pkgs.git}/bin:${pkgs.perl}/bin:${pkgs.findutils}/bin:${pkgs.coreutils}/bin:${pkgs.procps}/bin:${pkgs.systemd}/bin:${pkgs.bash}/bin:$PATH"
    ${builtins.readFile ./scripts/health-check.sh}
  '';

  quickshellLaunchScript = pkgs.writeShellScriptBin "quickshell-launch" ''
    set -euo pipefail

    runtime_dir="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    wayland_display="''${WAYLAND_DISPLAY:-}"

    have_wayland_socket() {
      local socket_name="$1"
      [[ -n "''${socket_name}" && -S "''${runtime_dir}/''${socket_name}" ]]
    }

    if ! have_wayland_socket "''${wayland_display}"; then
      wayland_display=""
      for _ in $(seq 1 150); do
        for candidate in "''${runtime_dir}"/wayland-*; do
          [[ -S "''${candidate}" ]] || continue
          wayland_display="$(basename "''${candidate}")"
          break 2
        done
        sleep 0.2
      done
    fi

    if ! have_wayland_socket "''${wayland_display}"; then
      printf 'quickshell-launch: no Wayland socket found in %s\n' "''${runtime_dir}" >&2
      exit 1
    fi

    export WAYLAND_DISPLAY="''${wayland_display}"
    export QT_QPA_PLATFORM=wayland

    exec ${pkgs.quickshell}/bin/quickshell -p "${config.home.homeDirectory}/.config/quickshell/shell.qml"
  '';

  pluginDoctorScript = pkgs.writeShellScriptBin "qs-plugin-doctor" ''
    export QS_REPO_ROOT=${lib.escapeShellArg repoRoot}
    PATH="${pkgs.quickshell}/bin:${pkgs.jq}/bin:${pkgs.ripgrep}/bin:${pkgs.findutils}/bin:${pkgs.coreutils}/bin:${pkgs.bash}/bin:$PATH"
    ${builtins.readFile ./scripts/plugin-doctor.sh}
  '';

  surfaceResponsiveScript = pkgs.writeShellScriptBin "qs-surface-responsive-check" ''
    PATH="${pkgs.quickshell}/bin:${pkgs.findutils}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.gawk}/bin:${pkgs.procps}/bin:${pkgs.bash}/bin:$PATH"
    ${builtins.readFile ./scripts/check-surface-responsive.sh}
  '';

  surfacePreviewScript = pkgs.writeShellScriptBin "qs-surface-preview" ''
    PATH="${pkgs.quickshell}/bin:${pkgs.findutils}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.gawk}/bin:${pkgs.procps}/bin:${pkgs.bash}/bin:$PATH"
    ${builtins.readFile ./scripts/preview-surface-responsive.sh}
  '';

  multibarSmokeScript = pkgs.writeShellScriptBin "qs-multibar-smoke-check" ''
    PATH="${pkgs.quickshell}/bin:${pkgs.findutils}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.gawk}/bin:${pkgs.procps}/bin:${pkgs.bash}/bin:$PATH"
    ${builtins.readFile ./scripts/check-multibar-smoke.sh}
  '';

  panelConfigContractsScript = pkgs.writeShellScriptBin "qs-panel-config-contracts" ''
    PATH="${pkgs.quickshell}/bin:${pkgs.jq}/bin:${pkgs.findutils}/bin:${pkgs.coreutils}/bin:${pkgs.gnused}/bin:${pkgs.gnugrep}/bin:${pkgs.gawk}/bin:${pkgs.procps}/bin:${pkgs.bash}/bin:$PATH"
    ${builtins.readFile ./scripts/check-panel-config-contracts.sh}
  '';

  panelRuntimeScript = pkgs.writeShellScriptBin "qs-panel-runtime-verify" ''
    PATH="${pkgs.quickshell}/bin:${pkgs.jq}/bin:${pkgs.findutils}/bin:${pkgs.coreutils}/bin:${pkgs.gnused}/bin:${pkgs.gnugrep}/bin:${pkgs.gawk}/bin:${pkgs.procps}/bin:${pkgs.bash}/bin:$PATH"
    ${builtins.readFile ./scripts/check-panel-runtime.sh}
  '';

  panelPreviewScript = pkgs.writeShellScriptBin "qs-panel-preview" ''
    PATH="${pkgs.quickshell}/bin:${pkgs.findutils}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.gawk}/bin:${pkgs.procps}/bin:${pkgs.bash}/bin:$PATH"
    ${builtins.readFile ./scripts/preview-panel-qa.sh}
  '';

  settingsCaptureScript = pkgs.writeShellScriptBin "qs-settings-capture" ''
    PATH="${pkgs.quickshell}/bin:${pkgs.hyprland}/bin:${pkgs.grim}/bin:${pkgs.imagemagick}/bin:${pkgs.jq}/bin:${pkgs.findutils}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.gawk}/bin:${pkgs.procps}/bin:${pkgs.git}/bin:${pkgs.bash}/bin:$PATH"
    ${builtins.readFile ./scripts/capture-settings-viewport.sh}
  '';

  settingsMatrixCaptureScript = pkgs.writeShellScriptBin "qs-settings-capture-matrix" ''
    PATH="${pkgs.quickshell}/bin:${pkgs.hyprland}/bin:${pkgs.grim}/bin:${pkgs.imagemagick}/bin:${pkgs.jq}/bin:${pkgs.findutils}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.gawk}/bin:${pkgs.procps}/bin:${pkgs.git}/bin:${pkgs.bash}/bin:$PATH"
    ${builtins.readFile ./scripts/capture-settings-matrix.sh}
  '';

  surfaceCaptureScript = pkgs.writeShellScriptBin "qs-surface-capture" ''
    PATH="${pkgs.quickshell}/bin:${pkgs.hyprland}/bin:${pkgs.grim}/bin:${pkgs.imagemagick}/bin:${pkgs.jq}/bin:${pkgs.findutils}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.gawk}/bin:${pkgs.procps}/bin:${pkgs.bash}/bin:$PATH"
    ${builtins.readFile ./scripts/capture-surface-viewport.sh}
  '';

  surfaceMatrixCaptureScript = pkgs.writeShellScriptBin "qs-surface-capture-matrix" ''
    PATH="${pkgs.quickshell}/bin:${pkgs.hyprland}/bin:${pkgs.grim}/bin:${pkgs.imagemagick}/bin:${pkgs.jq}/bin:${pkgs.findutils}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.gawk}/bin:${pkgs.procps}/bin:${pkgs.bash}/bin:$PATH"
    ${builtins.readFile ./scripts/capture-surface-matrix.sh}
  '';

  launcherCaptureScript = pkgs.writeShellScriptBin "qs-launcher-capture" ''
    PATH="${pkgs.quickshell}/bin:${pkgs.hyprland}/bin:${pkgs.grim}/bin:${pkgs.imagemagick}/bin:${pkgs.jq}/bin:${pkgs.findutils}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.gawk}/bin:${pkgs.procps}/bin:${pkgs.nodejs}/bin:${pkgs.bash}/bin:$PATH"
    ${builtins.readFile ./scripts/capture-launcher-viewport.sh}
  '';

  launcherMatrixCaptureScript = pkgs.writeShellScriptBin "qs-launcher-capture-matrix" ''
    PATH="${pkgs.quickshell}/bin:${pkgs.hyprland}/bin:${pkgs.grim}/bin:${pkgs.imagemagick}/bin:${pkgs.jq}/bin:${pkgs.findutils}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.gawk}/bin:${pkgs.procps}/bin:${pkgs.nodejs}/bin:${pkgs.bash}/bin:$PATH"
    ${builtins.readFile ./scripts/capture-launcher-matrix.sh}
  '';

  panelMatrixCaptureScript = pkgs.writeShellScriptBin "qs-panel-capture-matrix" ''
    PATH="${pkgs.quickshell}/bin:${pkgs.hyprland}/bin:${pkgs.grim}/bin:${pkgs.imagemagick}/bin:${pkgs.jq}/bin:${pkgs.findutils}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.gawk}/bin:${pkgs.procps}/bin:${pkgs.git}/bin:${pkgs.bash}/bin:$PATH"
    ${builtins.readFile ./scripts/capture-panel-matrix.sh}
  '';

  # Build-time theme manifest: converts 177 base24 YAML themes into a single JSON file
  themeManifest = pkgs.runCommand "quickshell-theme-manifest" {
    nativeBuildInputs = [ pkgs.yq-go pkgs.jq ];
  } ''
    mkdir -p $out
    bash ${./scripts/generate-theme-manifest.sh} \
      ${../../../../../tmux/plugins/tmux-forceline/themes/yaml} \
      $out/themes.json
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
      python3 # Needed for various scripts (Niri binds parser, etc.)
      ydotool # On-screen keyboard input injection

      # Quickshell utility scripts
      qsRofiScript
      runScript
      wallpaperScript
      keybindsScript
      aiScript
      aiStreamScript
      bookmarksScript
      bangSyncScript
      bangSearchScript
      updatorScript
      sleepMonitorScript
      screenshotScript
      inhibitorScript
      networkScript
      iconResolverScript
      compositorGuardScript
      compositorSmokeScript
      compositorFixtureScript
      compositorVerifyScript
      healthSafeFixScript
      healthCheckScript
      pluginDoctorScript
      surfaceResponsiveScript
      surfacePreviewScript
      multibarSmokeScript
      panelConfigContractsScript
      panelRuntimeScript
      panelPreviewScript
      settingsCaptureScript
      settingsMatrixCaptureScript
      surfaceCaptureScript
      surfaceMatrixCaptureScript
      panelMatrixCaptureScript
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
      force = true;
      source = ./src;
      recursive = true;
    };

    home.file.".config/quickshell/fixtures" = {
      source = ./fixtures;
      recursive = true;
    };

    home.file.".config/quickshell/themes.json".source = "${themeManifest}/themes.json";

    home.file.".local/bin/qs-screenshot" = {
      force = true;
      executable = true;
      text = ''
        #!/usr/bin/env bash
        exec bash ${./scripts/screenshot.sh} "$@"
      '';
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
        ConditionEnvironment = "WAYLAND_DISPLAY";
        StartLimitBurst = 5;
        StartLimitIntervalSec = 30;
      };

      Service = {
        ExecStartPre = "${pkgs.writeShellScript "quickshell-wait-notifications-name" ''
          set -eu

          if ! command -v busctl >/dev/null 2>&1; then
            exit 0
          fi

          for _ in $(seq 1 50); do
            owner_pid="$(busctl --user --list 2>/dev/null | awk '/org\.freedesktop\.Notifications/ { print $2; exit }')"
            if [ -z "$owner_pid" ] || [ "$owner_pid" = "-" ]; then
              exit 0
            fi
            sleep 0.1
          done

          exit 0
        ''}";
        ExecStart = "${quickshellLaunchScript}/bin/quickshell-launch";
        Environment = [
          "PATH=%h/.local/bin:%h/.nix-profile/bin:/etc/profiles/per-user/%u/bin:/run/current-system/sw/bin:${pkgs.quickshell}/bin:${pkgs.pipewire}/bin:${pkgs.networkmanager}/bin:${pkgs.tailscale}/bin:${pkgs.coreutils}/bin:${pkgs.findutils}/bin:${pkgs.gnugrep}/bin:${pkgs.bash}/bin:${pkgs.procps}/bin:${pkgs.wl-clipboard}/bin:${pkgs.power-profiles-daemon}/bin:${pkgs.ddcutil}/bin:${pkgs.grim}/bin:${pkgs.slurp}/bin:${pkgs.dbus}/bin:${pkgs.python3}/bin"
          "QS_NIRI_PARSER=${./scripts/parse-niri-binds.py}"
          "QT_QPA_PLATFORMTHEME=adwaita"
          "QT_STYLE_OVERRIDE=adwaita-dark"
        ];


        Restart = "on-failure";
        RestartSec = 2;
      };

      Install = { };
    };

    systemd.user.services.quickshell-health = {
      Unit = {
        Description = "Quickshell health monitor";
        After = [ "quickshell.service" ];
        Wants = [ "quickshell.service" ];
      };

      Service = {
        Type = "oneshot";
        ExecStart = "${healthCheckScript}/bin/qs-health-check --apply-safe-fixes";
        SuccessExitStatus = [ 20 ];
        StandardOutput = "journal";
        StandardError = "journal";
      };
    };

    systemd.user.timers.quickshell-health = {
      Unit = {
        Description = "Quickshell health monitor timer";
        Requires = [ "quickshell-health.service" ];
      };

      Timer = {
        OnBootSec = "2min";
        OnUnitActiveSec = "15min";
        RandomizedDelaySec = "45sec";
        Persistent = true;
      };

      Install = {
        WantedBy = [ "timers.target" ];
      };
    };
  };
}

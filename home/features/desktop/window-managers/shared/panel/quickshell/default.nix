{
  config,
  lib,
  pkgs,
  ...
}:

let
  hyprlandStateScript = pkgs.writeShellScript "quickshell-hyprland-state" ''
    PATH="${pkgs.hyprland}/bin:${pkgs.jq}/bin:${pkgs.coreutils}/bin:$PATH"
    ${builtins.readFile ./scripts/hyprland-state.sh}
  '';

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
    home.packages = [
      appsScript
      qsRofiScript
      runScript
      emojiScript
      clipScript
      wallpaperScript
      keybindsScript
    ];
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

    systemd.user.services.quickshell = {
      Unit = {
        Description = "Quickshell (QML shell)";
        After = [ "graphical-session.target" ];
        Wants = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${pkgs.quickshell}/bin/quickshell";
        Restart = "on-failure";
        RestartSec = 2;
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    systemd.user.services.quickshell-hyprland-state = {
      Unit = {
        Description = "Quickshell Hyprland state snapshot";
        After = [ "graphical-session.target" ];
        Wants = [ "graphical-session.target" ];
      };

      Service = {
        Type = "oneshot";
        ExecStart = hyprlandStateScript;
      };
    };

    systemd.user.timers.quickshell-hyprland-state = {
      Unit = {
        Description = "Quickshell Hyprland state snapshot timer";
      };

      Timer = {
        OnBootSec = "1s";
        OnUnitActiveSec = "1s";
      };

      Install = {
        WantedBy = [ "timers.target" ];
      };
    };
  };
}

{
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./global/home.nix

    ./features/kitty
    ./features/ssh

    ./features/desktop/common
    ./features/desktop/window-managers/shared/clipboard
    ./features/desktop/window-managers/shared/panel/quickshell
    ./features/desktop/window-managers/niri
  ];

  features.quickshell.enable = true;

  xdg.autostart.enable = lib.mkForce false;

  home.file.".zshrc".text = ''
    # Niri VM test profile
  '';
  home.file.".zprofile".text = ''
    current_tty="$(tty 2>/dev/null || true)"

    if [[ -z "''${SSH_TTY:-}" && -z "''${SSH_CONNECTION:-}" && -z "''${WAYLAND_DISPLAY:-}" && -z "''${DISPLAY:-}" ]]; then
      case "''${current_tty}" in
        /dev/tty1|/dev/ttyS0)
          if ! systemctl --user is-active --quiet niri.service; then
            exec uwsm start niri-uwsm.desktop
          fi
          ;;
      esac
    fi
  '';
  home.file.".config/autostart/nm-applet.desktop".text = ''
    [Desktop Entry]
    Hidden=true
  '';
  home.file.".config/autostart/blueman.desktop".text = ''
    [Desktop Entry]
    Hidden=true
  '';
  home.file.".config/autostart/geoclue-demo-agent.desktop".text = ''
    [Desktop Entry]
    Hidden=true
  '';

  programs.niri.settings.spawn-at-startup = lib.mkForce [
    {
      command = [
        "sh"
        "-lc"
        "env_vars='WAYLAND_DISPLAY XDG_CURRENT_DESKTOP DESKTOP_SESSION XDG_SESSION_TYPE NIRI_SOCKET'; if [ -n \"\${DISPLAY:-}\" ]; then env_vars=\"DISPLAY \${env_vars}\"; fi; dbus-update-activation-environment --systemd \${env_vars} || true; systemctl --user import-environment \${env_vars} || true"
      ];
    }
    {
      command = [
        "sh"
        "-c"
        "systemctl --user reset-failed quickshell.service niri-vm-kitty.service >/dev/null 2>&1 || true"
      ];
    }
    {
      command = [
        "systemctl"
        "--user"
        "start"
        "--no-block"
        "quickshell.service"
        "niri-vm-kitty.service"
      ];
    }
  ];

  systemd.user.services.niri-vm-kitty = {
    Unit = {
      Description = "Kitty terminal for the Niri VM session";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
      ConditionEnvironment = "WAYLAND_DISPLAY";
      StartLimitBurst = 10;
      StartLimitIntervalSec = 60;
    };

    Service = {
      ExecStart = "${pkgs.kitty}/bin/kitty";
      Restart = "on-failure";
      RestartSec = 2;
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  home.packages = with pkgs; [
    cava
    imagemagick
    rsync
  ];
}

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
    if [[ -z "''${SSH_TTY:-}" && -z "''${SSH_CONNECTION:-}" && -z "''${WAYLAND_DISPLAY:-}" && -z "''${DISPLAY:-}" && "''${XDG_VTNR:-}" == "1" ]]; then
      exec uwsm start niri-uwsm.desktop
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
        "systemctl --user reset-failed quickshell.service >/dev/null 2>&1 || true"
      ];
    }
    {
      command = [
        "systemctl"
        "--user"
        "start"
        "--no-block"
        "quickshell.service"
      ];
    }
    {
      command = [ "kitty" ];
    }
  ];

  home.packages = with pkgs; [
    cava
    imagemagick
    rsync
  ];
}

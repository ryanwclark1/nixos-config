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
    if [[ -z "''${SSH_TTY:-}" && -z "''${WAYLAND_DISPLAY:-}" && -z "''${DISPLAY:-}" ]]; then
      exec niri-session
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
        "dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP DESKTOP_SESSION XDG_SESSION_TYPE NIRI_SOCKET || true; systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP DESKTOP_SESSION XDG_SESSION_TYPE NIRI_SOCKET || true"
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

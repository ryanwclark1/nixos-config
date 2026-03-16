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
    ./features/desktop/window-managers/hyprland
  ];

  features.quickshell.enable = true;

  xdg.autostart.enable = lib.mkForce false;

  home.file.".zshrc".text = ''
    # Hyprland VM test profile
  '';
  home.file.".zprofile".text = ''
    if [[ -z "''${SSH_TTY:-}" && -z "''${WAYLAND_DISPLAY:-}" && -z "''${DISPLAY:-}" && "''${XDG_VTNR:-}" == "1" ]]; then
      exec uwsm start hyprland-uwsm.desktop
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
  home.file.".config/niri/config.kdl".text = ''
    // Minimal placeholder so Hyprland VM runs do not warn when optional Niri
    // helpers probe for the config file.
  '';
  home.file.".config/hypr/conf/host-specific.conf" = {
    force = true;
    text = ''
      # Hyprland VM-specific monitor and environment overrides.
      $IS_LAPTOP = false
      $IS_HIDPI = false
      $IS_NVIDIA = false
      $IS_AMD = false

      source = ~/.config/hypr/conf/layouts/default.conf
      source = ~/.config/hypr/conf/environments/kvm.conf

      monitor = , preferred, auto, 1
    '';
  };

  home.packages = with pkgs; [
    cava
    imagemagick
    rsync
  ];
}

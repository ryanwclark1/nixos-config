{
  pkgs,
  ...
}:
{
  imports = [
    ./hyprland-vnc.nix
    ./gammastep.nix
    # ./mako.nix
    ./qutebrowser.nix
    ./swayidle.nix
    ./swaylock.nix
    ./waybar.nix
    ./wofi.nix
    ./zathura.nix
  ];

  xdg.mimeApps.enable = true;
  home.packages = with pkgs; [
    grim
    gtk3 # For gtk-launch
    mimeo
    pulseaudio
    slurp
    waypipe
    wf-recorder
    wl-clipboard
    wl-mirror
    xdg-utils
    ydotool
  ];

  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = 1;
    QT_QPA_PLATFORM = "wayland";
    LIBSEAT_BACKEND = "logind";
  };

  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-wlr ];
}

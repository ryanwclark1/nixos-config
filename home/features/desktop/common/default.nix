{
  pkgs,
  ...
}:

{
  imports = [
    ./gtk.nix
    ./noti.nix
    ./qt.nix
    # ./trayscale.nix
    ./wallpapers.nix
    ./xdg.nix
  ];

  # Comment out screenshot, clipboard and recording tools
  home.packages = with pkgs; [
    cairo
    d-spy # Dbus debugger
    file-roller # Archive manager
    fragments # Torrent client
    gpu-viewer # GPU info
    libsoup_3
    mimeo # Open files with the right program
    # spice-vdagent # Spice agent
    virt-viewer # View virtual machines
    ventoy-full #balena type tool
    waypipe # Network proxy for Wayland clients (applications)
    webkitgtk_6_0 # Web rendering engine
    wl-clipboard # Wayland clipboard
    ydotool # Command-line tool for automation which emulates input devices
    wayland-utils # Wayland utilities
  ];
}

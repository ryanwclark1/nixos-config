{
  pkgs,
  ...
}:

{
  imports = [
    ./qt.nix
    ./xdg.nix
  ];


  home.packages = with pkgs; [
    d-spy # Dbus debugger
    ventoy-full #balena type tool
    libnotify
    wl-clipboard
    grim
    mimeo
    slurp # Screenshot tool, select area
    mediainfo
    bluez-tools # bt-adapter
    czkawka # Duplicate file finder
    gpu-viewer
    waypipe # Network proxy for Wayland clients (applications)
    wf-recorder # Utility program for screen recording of wlroots-based compositors
    wl-mirror # Simple Wayland output mirror client
    ydotool # Command-line tool for emulating input devices
  ];

}

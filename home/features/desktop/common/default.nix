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
    libnotify # Notification library
    wl-clipboard # Wayland clipboard
    grim # Screenshot tool,
    mimeo # Open files with the right program
    slurp # Screenshot tool, select area
    mediainfo # Media info
    bluez-tools # bt-adapter
    czkawka # Duplicate file finder
    gpu-viewer # GPU info
    waypipe # Network proxy for Wayland clients (applications)
    wf-recorder # Utility program for screen recording of wlroots-based compositors
    wl-mirror # Simple Wayland output mirror client
    ydotool # Command-line tool for automation which emulates input devices
    file-roller # Archive manager
  ];

}

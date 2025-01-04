{
  pkgs,
  ...
}:

{
  imports = [
    ../scripts
    ./gtk.nix
    ./noti.nix
    ./qt.nix
    ./trayscale.nix
    ./xdg.nix
  ];

  # Comment out screenshot, clipboard and recording tools
  home.packages = with pkgs; [
    bluez-tools # bt-adapter
    czkawka # Duplicate file finder
    d-spy # Dbus debugger
    dbeaver-bin # Universal Database Tool
    devpod-desktop # Codespaces but open-source, client-only and unopinionated: Works with any IDE
    file-roller # Archive manager
    fragments # Torrent client
    gpu-viewer # GPU info
    # grim # Screenshot tool,
    insomnia # API Client for REST, GraphQL, GRPC and OpenAPI design tool for developers.
    libnotify # Notification library
    libsoup_3
    mediainfo # Media info
    mimeo # Open files with the right program
    postman # API Development Environment
    # slurp # Screenshot tool, select area
    spice-vdagent # Spice agent
    sqlitebrowser # Visual tool to create, design, and edit database files compatible with SQLite
    ventoy-full #balena type tool
    waypipe # Network proxy for Wayland clients (applications)
    webkitgtk_6_0 # Web rendering engine
    # wf-recorder # Utility program for screen recording of wlroots-based compositors
    # wl-clipboard # Wayland clipboard
    ydotool # Command-line tool for automation which emulates input devices
  ];
}

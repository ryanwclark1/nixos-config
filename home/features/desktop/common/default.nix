{
  pkgs,
  ...
}:

{
  imports = [
    ./gtk.nix
    ./noti.nix
    ./qt.nix
    ./trayscale.nix
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
    webkitgtk_6_0 # Web rendering engine
    libsoup
    fragments # Torrent client
    seabird # Kubernetes native desktop app that simplifies working with Kubernetes.
    insomnia # API Client for REST, GraphQL, GRPC and OpenAPI design tool for developers.
    devpod-desktop # Codespaces but open-source, client-only and unopinionated: Works with any IDE
    tilt # Local Kubernetes development Local to manage your developer instance when your team deploys to Kubernetes in production.
    postman # API Development Environment
    dbeaver-bin # Universal Database Tool
    sqlitebrowser # Visual tool to create, design, and edit database files compatible with SQLite
    kubeshark # Kubernetes packet capture tool
    weave-gitops # GitOps for Kubernetes
    spice-vdagent # Spice agent
  ];
}

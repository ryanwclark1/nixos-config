{
  pkgs,
  ...
}:

{
  imports = [
    ./gh.nix
    ./jq.nix
    ./nixtools.nix
    ./noti.nix
    ./respects.nix
  ];
  home.packages = with pkgs; [
    # Cross-platform CLI utilities
    duf # Disk Usage/Free Utility - cross-platform
    dust # More intuitive version of du in rust - cross-platform
    figlet # Print large characters - cross-platform
    fx # Terminal JSON viewer - cross-platform
    gum # shell scripts - cross-platform
    mprocs # multiple commands in parallel - cross-platform
    ncdu # TUI disk usage - cross-platform
    so  # Stackoverflow search - cross-platform
    tokei # code statistics - cross-platform
    vhs # A tool for generating terminal GIFs with code - cross-platform
    viu # Terminal image viewer with native support for iTerm and Kitty - cross-platform
    vultr-cli # vultr cli - cross-platform
    yq-go # jq for yaml, command-line YAML processor - cross-platform
  ] ++ (if pkgs.stdenv.hostPlatform.isLinux then [
    # Linux-specific CLI utilities
    distrobox # Nice escape hatch, integrates docker images with my environment
    scrot # A command-line screen capture utility - X11/Wayland specific
    killall # A command-line tool to kill processes by name - Linux implementation
    mimeo # Open files with the right program - Linux XDG desktop integration
    plocate # Fast file search with low resource usage - Linux filesystem specific
    ydotool # Input automation tool - Linux Wayland/X11 specific
  ] else []);
}

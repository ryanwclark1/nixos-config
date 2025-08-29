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
    aichat # Use GPT-4(V), Gemini, LocalAI, Ollama and other LLMs in the terminal.
    duf # Disk Usage/Free Utility
    dust # More intuitive version of du in rust
    figlet # Print large characters (moved from desktop)
    fx # Terminal JSON viewer
    gum # shell scripts
    mimeo # Open files with the right program
    mprocs # multiple commands in parallel
    ncdu # TUI disk usage
    plocate # Fast file search with low resource usage
    so  # Stackoverflow search
    tokei # code statistics
    vhs # A tool for generating terminal GIFs with code
    viu # Terminal image viewer with native support for iTerm and Kitty
    vultr-cli # vultr cli
    ydotool # Input automation tool
    yq-go #jq for yaml, command-line YAML processor https://github.com/mikefarah/yq
  ] ++ (if pkgs.stdenv.hostPlatform.system == "x86_64-linux" then [
    distrobox # Nice escape hatch, integrates docker images with my environment
    scrot # A command-line screen capture utility
    killall # A command-line tool to kill processes by name
  ] else []);
}

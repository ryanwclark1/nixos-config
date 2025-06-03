{
  pkgs,
  ...
}:

{
  imports = [
    ./gh.nix
    ./jq.nix
    ./nixtools.nix
    ./respects.nix
  ];
  home.packages = with pkgs; [
    so  # Stackoverflow search
    tokei # code statistics
    dysk # DF with flair
    duf # Disk Usage/Free Utility
    ncdu # TUI disk usage
    gum # shell scripts
    viu # Terminal image viewer with native support for iTerm and Kitty
    yq-go #jq for yaml, command-line YAML processor https://github.com/mikefarah/yq
    fx # Terminal JSON viewer
    aichat # Use GPT-4(V), Gemini, LocalAI, Ollama and other LLMs in the terminal.
    mprocs # multiple commands in parallel
    vultr-cli # vultr cli
    vhs # A tool for generating terminal GIFs with code
  ] ++ (if pkgs.stdenv.hostPlatform.system == "x86_64-linux" then [
    distrobox # Nice escape hatch, integrates docker images with my environment
    scrot # A command-line screen capture utility
    killall # A command-line tool to kill processes by name
  ] else []);
}

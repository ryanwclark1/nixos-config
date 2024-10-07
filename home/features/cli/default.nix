{
  pkgs,
  ...
}:

{
  imports = [
    ./bat.nix
    ./btop.nix
    ./gh.nix
    ./jq.nix
    ./mprocs.nix
    ./navi.nix
    ./neomutt.nix
    ./network.nix
    ./nixtools.nix
    ./noti.nix
    ./tealdeer.nix
    ./thefuck.nix
    ./zk.nix
  ];
  home.packages = with pkgs; [
    distrobox # Nice escape hatch, integrates docker images with my environment
    httpie # Better curl
    scrot # A command-line screen capture utility
    killall # A command-line tool to kill processes by name
    duf # Disk Usage/Free Utility
    jdupes # Find duplicate files
    ncdu # TUI disk usage
    lazydocker # A simple terminal UI for both docker and docker-compose
    gum # shell scripts
    viu # Terminal image viewer with native support for iTerm and Kitty
    yq-go #jq for yaml, command-line YAML processor https://github.com/mikefarah/yq
    fx # Terminal JSON viewer
    aichat # Use GPT-4(V), Gemini, LocalAI, Ollama and other LLMs in the terminal.
  ];
}

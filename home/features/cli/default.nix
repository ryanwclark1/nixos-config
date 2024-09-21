{
  pkgs,
  ...
}:

{
  imports = [
    ./aichat.nix
    ./bat.nix
    ./btop.nix
    ./exiftool.nix
    ./fx.nix
    ./gh.nix
    ./gum.nix
    ./jq.nix
    ./mprocs.nix
    ./navi.nix
    ./neomutt.nix
    ./network.nix
    ./nixtools.nix
    ./noti.nix
    ./viu.nix
    ./yq.nix
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
  ];
}

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
    ./filesystem_utils.nix
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
    hyperfine #cli benchmarking tool
    scrot # A command-line screen capture utility
  ];
}

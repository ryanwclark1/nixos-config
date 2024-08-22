{
  pkgs,
  ...
}:

{
  imports = [
    ./aichat.nix
    ./bat.nix
    ./btop.nix
    ./diffsitter.nix
    ./exiftool.nix
    ./filesystem_utils.nix
    ./fx.nix
    ./gh.nix
    ./gum.nix
    ./jq.nix
    ./mprocs.nix
    ./neomutt.nix
    ./network.nix
    ./nixtools.nix
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

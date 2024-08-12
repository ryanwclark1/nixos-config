{
  pkgs,
  ...
}:

{
  imports = [
    ./atuin.nix
    ./aichat.nix
    ./bat.nix
    ./btop.nix
    ./diffsitter.nix
    ./direnv.nix
    ./exiftool.nix
    ./filesystem_utils.nix
    ./fx.nix
    ./gh.nix
    ./gpg.nix
    ./gum.nix
    ./jq.nix
    ./neomutt.nix
    ./network.nix
    ./nixtools.nix
    # ./ssh.nix
    ./system.nix
    ./viu.nix
    ./yq.nix
    ./zk.nix
  ];
  home.packages = with pkgs; [
    distrobox # Nice escape hatch, integrates docker images with my environment
    httpie # Better curl
    # hurl # httpie/curl alternative
    hyperfine #cli benchmarking tool
    scrot # A command-line screen capture utility
  ];
}

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
    ./direnv.nix
    ./exiftool.nix
    ./filesystem_utils.nix
    ./gh.nix
    ./gpg.nix
    ./jq.nix
    ./neomutt.nix
    ./network.nix
    ./nixtools.nix
    # ./ssh.nix
    ./viu.nix
  ];
  home.packages = with pkgs; [
    diffsitter # Better diff
    distrobox # Nice escape hatch, integrates docker images with my environment
    fx # Terminal JSON viewer
    gum # shell scripts
    httpie # Better curl
    # hurl # httpie/curl alternative
    hyperfine #cli benchmarking tool
    mprocs # multiple commands in parallel
    pciutils # lspci
    scrot # A command-line screen capture utility
    trashy # cli rm with trash support
    usbutils # lsusb
    yq-go #jq for yaml https://github.com/mikefarah/yq
    zk # note taking
  ];
}

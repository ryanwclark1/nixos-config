{
  pkgs,
  ...
}:

{
  imports = [
    # ./atuin.nix
    ./bat.nix
    ./direnv.nix
    ./exiftool.nix
    ./filesearch.nix
    ./filesystem_utils.nix
    ./gh.nix
    ./gpg.nix
    ./jq.nix
    ./network.nix
    ./nixtools.nix
    # ./ssh.nix
    ./viu.nix
  ];
  home.packages = with pkgs; [
    aha # required by kde plasma info center firmware security info
    bottom # System viewer
    clinfo # opencl info required by kde plasma info center
    comma # Install and run programs by sticking a , before them
    diffsitter # Better diff
    distrobox # Nice escape hatch, integrates docker images with my environment
    fastfetch # System info
    fx # Terminal JSON viewer
    gum # shell scripts
    httpie # Better curl
    hurl # httpie/curl alternative
    hyperfine #cli benchmarking tool
    mprocs # multiple commands in parallel
    pciutils # lspci
    trashy #cli rm with trash support
    usbutils # lsusb
    vulkan-tools # vulkaninfo, required by kde plasma info center
    wayland-utils # wayland-info required by kde plasma info center
    wget
    yq-go #jq for yaml https://github.com/mikefarah/yq
    zk # note taking
  ];
}

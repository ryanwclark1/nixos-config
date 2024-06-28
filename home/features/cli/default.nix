{
  pkgs,
  ...
}:

{
  imports = [
    # ./atuin.nix
    ./aichat.nix
    ./bat.nix
    ./btop.nix
    ./direnv.nix
    ./exiftool.nix
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
    clinfo # opencl info required by kde plasma info center
    diffsitter # Better diff
    distrobox # Nice escape hatch, integrates docker images with my environment
    fx # Terminal JSON viewer
    gum # shell scripts
    httpie # Better curl
    hurl # httpie/curl alternative
    hyperfine #cli benchmarking tool
    mprocs # multiple commands in parallel
    pciutils # lspci
    scrot # A command-line screen capture utility
    trashy # cli rm with trash support
    usbutils # lsusb
    vulkan-tools # vulkaninfo, required by kde plasma info center
    wayland-utils # wayland-info required by kde plasma info center
    wget
    yq-go #jq for yaml https://github.com/mikefarah/yq
    zk # note taking
  ];
}

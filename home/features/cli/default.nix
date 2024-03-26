{
  pkgs,
  ...
}:

{
  imports = [
    # ./atuin.nix
    ./bat.nix
    ./direnv.nix
    ./filesearch.nix
    ./filesystem_utils.nix
    ./gh.nix
    ./gpg.nix
    ./jq.nix
    ./network.nix
    ./nixtools.nix
    # ./ssh.nix
  ];
  home.packages = with pkgs; [
    mprocs # multiple commands in parallel
    gum # shell scripts
    hyperfine #cli benchmarking tool
    neofetch # System info
    pciutils # lspci
    usbutils # lsusb
    comma # Install and run programs by sticking a , before them
    distrobox # Nice escape hatch, integrates docker images with my environment
    bottom # System viewer
    diffsitter # Better diff
    timer # To help with my ADHD paralysis
    ltex-ls # Spell checking LSP
    zk # note taking
    trashy #cli rm with trash support
    wget
    hurl # httpie/curl alternative
    httpie # Better curl
    fx # Terminal JSON viewer
    yq-go #jq for yaml https://github.com/mikefarah/yq
    vulkan-tools # vulkaninfo, required by kde plasma info center
    wayland-utils # wayland-info required by kde plasma info center
    clinfo # opencl info required by kde plasma info center
    aha # required by kde plasma info center firmware security info
  ];
}

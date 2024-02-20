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
    ./git.nix
    ./gpg.nix
    ./jq.nix
    ./lf.nix
    ./network.nix
    ./nix-index.nix
    ./nixtools.nix
    ./pfetch.nix
    ./screen.nix
    # ./shellcolor.nix
    # ./ssh.nix
    # ./xpo.nix
    # ./xplr.nix
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
    # trekscii # Cute startrek cli printer
    timer # To help with my ADHD paralysis
    ltex-ls # Spell checking LSP
    # tly # Tally counter
    d2 #diagram
    zk # note taking
    trashy #cli rm with trash support
    hurl # httpie/curl alternative
    httpie # Better curl
    fx # Terminal JSON viewer
    yq-go #jq for yaml https://github.com/mikefarah/yq
  ];
}

{ pkgs
, ...
}:

{
  imports = [
    ./atuin.nix
    ./bash.nix
    ./bat.nix
    ./direnv.nix
    ./doc.nix
    ./filesearch.nix
    ./filesystem_utils.nix
    ./fish.nix
    ./gh.nix
    ./git.nix
    ./gpg.nix
    ./jq.nix
    ./lf.nix
    ./network.nix
    ./nix-index.nix
    ./nixtools.nix
    ./pfetch.nix
    ./pistol.nix
    ./ranger.nix
    ./screen.nix
    # ./shellcolor.nix
    ./skim.nix
    # ./ssh.nix
    # ./xpo.nix
    ./zsh.nix
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
    mc # Midnight commander
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

{ pkgs, ... }: {
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
    ./nix-index.nix
    ./pfetch.nix
    ./ranger.nix
    ./screen.nix
    # ./shellcolor.nix
    ./skim.nix
    # ./ssh.nix
    ./starship.nix
    # ./xpo.nix
    ./zsh.nix
  ];
  home.packages = with pkgs; [
    comma # Install and run programs by sticking a , before them
    distrobox # Nice escape hatch, integrates docker images with my environment

    bc # Calculator
    bottom # System viewer
    ncdu # TUI disk usage
    httpie # Better curl
    diffsitter # Better diff
    # trekscii # Cute startrek cli printer
    timer # To help with my ADHD paralysis

    nil # Nix LSP
    nixfmt # Nix formatter
    nvd # Differ
    nix-output-monitor
    nh # Nice wrapper for NixOS and HM

    ltex-ls # Spell checking LSP

    # tly # Tally counter
  ];
}

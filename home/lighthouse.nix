{
  lib,
  ...
}:

{
  imports = [
    ./global
    ./features/atuin
    ./features/bat
    ./features/btop
    ./features/cli
    ./features/compression
    ./features/docs
    ./features/eza
    ./features/fastfetch
    ./features/fd
    ./features/fonts
    ./features/fzf
    ./features/git
    ./features/kubernetes
    ./features/lazygit
    ./features/networking-utils
    ./features/nixvim
    ./features/ripgrep
    ./features/shell
    ./features/starship
    ./features/sys-stats
    ./features/tmux
    ./features/yazi
    ./features/zoxide
    ./features/development/build.nix
    ./features/development/go.nix
    ./features/development/python.nix
    ./features/development/js.nix
  ];

  # Whether to enable settings that make Home Manager work better on GNU/Linux distributions other than NixOS.
  targets.genericLinux.enable = true;

  home.username = lib.mkForce "ryanc";
  # Disable impermanence
  # home.persistence = lib.mkForce {};
}

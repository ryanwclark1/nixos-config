{
  lib,
  ...
}:

{
  imports = [
    ./global

    ./features/atuin
    ./features/bat
    ./features/cli
    ./features/compression
    ./features/eza
    ./features/fastfetch
    ./features/fd
    ./features/fzf
    ./features/git
    # ./features/kubernetes
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

  # home.username = lib.mkForce "administrator";
  # Disable impermanence
  # home.persistence = lib.mkForce {};


}

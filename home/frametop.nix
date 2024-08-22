{
  lib,
  ...
}:

{
  imports = [
    ./global
    ./features/desktop/hyprland
    ./features/desktop/plasma
    ./features/desktop/common

    ./features/alacritty
    ./features/ansible
    ./features/atuin
    ./features/cli
    ./features/compression
    ./features/development
    ./features/eza
    ./features/fastfetch
    ./features/fzf
    ./features/games
    ./features/git
    # ./features/helix
    ./features/kitty
    ./features/kubernetes
    ./features/lazygit
    ./features/lf
    ./features/media
    ./features/networking-utils
    ./features/nvim
    ./features/osint
    ./features/pistol
    ./features/productivity
    ./features/qutebrowser
    ./features/remmina
    ./features/ripgrep
    ./features/shell
    ./features/starship
    ./features/sys-stats
    # ./features/tmux
    ./features/vhs
    ./features/vscode
    ./features/yazi
    ./features/zed
    ./features/zellij
    ./features/zoxide
  ];

  # Disable impermanence
  # home.persistence = lib.mkForce {};
}

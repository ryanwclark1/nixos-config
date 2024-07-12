{
  lib,
  ...
}:

{
  imports = [
    ./global
    # ./features/desktop/hyprland
    ./features/desktop/plasma
    ./features/desktop/common

    ./features/alacritty
    ./features/ansible
    ./features/cli
    ./features/compression
    ./features/development
    ./features/eza
    ./features/fastfetch
    ./features/fzf
    ./features/games
    ./features/git
    ./features/insomnia
    ./features/kitty
    ./features/kubernetes
    ./features/lazygit
    ./features/lf
    ./features/media
    ./features/networking-utils
    ./features/nvim
    ./features/pistol
    ./features/productivity
    ./features/qutebrowser
    ./features/ripgrep
    ./features/shell
    ./features/starship
    ./features/sys-stats
    ./features/tmux
    ./features/vscode
    ./features/wezterm
    ./features/zed
    ./features/zellij
    ./features/zoxide

    # ./features/helix
  ];

    # Disable impermanence
  # home.persistence = lib.mkForce { };
}

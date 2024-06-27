{
  lib,
  ...
}:

{
  imports = [
    ./global
    # ./features/desktop/hyprland2
    ./features/desktop/gnome
    ./features/desktop/common

    ./features/alacritty
    ./features/cli
    ./features/compression
    ./features/development
    ./features/eza
    ./features/filesearch
    ./features/fzf
    ./features/games
    ./features/git
    ./features/gpu
    # ./features/helix
    ./features/insomnia
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
    ./features/shell
    ./features/starship
    ./features/sys-stats
    ./features/vhs
    ./features/vscode
    ./features/wezterm
    ./features/zellij
    ./features/zoxide
  ];

    # Disable impermanence
  # home.persistence = lib.mkForce { };
}

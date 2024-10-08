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
    ./features/discord
    ./features/fragments
    ./features/development
    ./features/eza
    ./features/fastfetch
    ./features/fd
    ./features/firefox
    ./features/fzf
    ./features/games
    ./features/git
    # ./features/helix
    # ./features/kdeconnect
    ./features/kitty
    ./features/kubernetes
    ./features/lazygit
    ./features/media
    ./features/networking-utils
    ./features/nixvim
    # ./features/pistol
    ./features/productivity
    ./features/qutebrowser
    # ./features/remmina
    ./features/ripgrep
    ./features/slack
    ./features/shell
    ./features/starship
    ./features/sys-stats
    ./features/tmux
    ./features/virtviewer
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

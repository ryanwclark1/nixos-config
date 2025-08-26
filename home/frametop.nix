{
  ...
}:

{
  imports = [
    ./global

    ./features/ai
    ./features/ansible
    ./features/atuin
    ./features/audio
    ./features/bat
    ./features/bluetooth
    ./features/btop
    ./features/cava
    ./features/chrome
    ./features/cli
    ./features/compression
    ./features/cursor
    ./features/development
    ./features/docker
    ./features/docs
    ./features/eza
    ./features/fastfetch
    ./features/fd
    ./features/firefox
    ./features/fonts
    ./features/fzf
    ./features/games
    ./features/ghostty
    ./features/git
    ./features/imv
    ./features/kitty
    ./features/kubernetes
    ./features/lazygit
    ./features/media
    ./features/networking-utils

    ./features/neovim
    ./features/productivity
    # ./features/qutebrowser
    ./features/remmina
    ./features/ripgrep
    ./features/shell
    ./features/starship
    ./features/sys-stats
    ./features/tmux
    ./features/vscode
    ./features/wireless
    ./features/yazi
    ./features/zellij
    ./features/zen
    ./features/zoxide

    ./features/desktop/hyprland
    ./features/desktop/hyprland/host-specific/frametop.nix
    # ./features/desktop/gnome
    ./features/desktop/common
  ];

  # Disable impermanence
  # home.persistence = lib.mkForce {};
}

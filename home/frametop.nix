{
  ...
}:

{
  imports = [
    ./global

    ./features/accounts
    ./features/alacritty
    ./features/ansible
    ./features/atuin
    ./features/bat
    ./features/btop
    ./features/cli
    ./features/compression
    ./features/cursor
    ./features/discord
    ./features/development
    ./features/eza
    ./features/fastfetch
    ./features/fd
    ./features/firefox
    ./features/fonts
    ./features/fzf
    ./features/games
    ./features/git
    ./features/ghostty
    ./features/imv
    ./features/kitty
    ./features/kubernetes
    ./features/lazygit
    ./features/media
    ./features/networking-utils
    ./features/nixvim
    ./features/productivity
    ./features/qutebrowser
    ./features/remmina
    ./features/ripgrep
    ./features/slack
    ./features/shell
    ./features/starship
    ./features/sys-stats
    ./features/tmux
    ./features/virtualisation
    ./features/vscode
    ./features/wireless
    ./features/yazi
    ./features/zed
    ./features/zen
    ./features/zellij
    ./features/zoxide

    ./features/desktop/hyprland
    ./features/desktop/gnome
    ./features/desktop/common
  ];

  # Disable impermanence
  # home.persistence = lib.mkForce {};
}

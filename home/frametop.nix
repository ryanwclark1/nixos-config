{
  ...
}:

{
  imports = [
    ./global

    ./features/alacritty
    ./features/ansible
    ./features/atuin
    ./features/audio
    ./features/bat
    ./features/btop
    ./features/cava
    ./features/chrome
    ./features/cli
    ./features/compression
    ./features/cursor
    ./features/development
    ./features/discord
    ./features/docs
    ./features/dotfiles
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
    ./features/nixvim
    ./features/productivity
    ./features/qutebrowser
    ./features/remmina
    ./features/ripgrep
    ./features/shell
    ./features/slack
    ./features/starship
    ./features/sys-stats
    ./features/tmux
    ./features/vscode
    ./features/windsurf
    ./features/wireless
    ./features/yazi
    ./features/zellij
    ./features/zen
    ./features/zoxide

    ./features/desktop/hyprland
    ./features/desktop/gnome
    ./features/desktop/common
  ];

  # Disable impermanence
  # home.persistence = lib.mkForce {};
}

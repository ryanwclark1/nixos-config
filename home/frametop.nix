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
    ./features/gui-tools
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
    ./features/webapps
    ./features/wireless
    ./features/yazi
    ./features/zellij
    # ./features/zen
    ./features/zoxide

    # Desktop environment configuration
    ./features/desktop/common # Core desktop components
    ./features/desktop/window-managers # Window managers and shared WM tools
    ./features/desktop/window-managers/hyprland/host-specific/frametop.nix
    ./features/desktop/window-managers/niri/host-specific/frametop.nix
  ];

  # Disable impermanence
  # home.persistence = lib.mkForce {};
}

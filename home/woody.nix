{
  pkgs,
  ...
}:

{
  imports = [
    ./global

    ./features/alacritty
    ./features/ansible
    ./features/atuin
    ./features/bat
    ./features/btop
    ./features/cli
    ./features/chrome
    ./features/compression
    ./features/cursor
    ./features/dotfiles
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
    ./features/kodi
    ./features/kubernetes
    ./features/lazygit
    ./features/media
    ./features/navi
    ./features/networking-utils
    ./features/nixvim
    ./features/productivity
    ./features/qutebrowser
    ./features/ripgrep
    ./features/remmina
    ./features/slack
    ./features/shell
    ./features/starship
    ./features/sys-stats
    ./features/tealdeer
    ./features/tmux
    ./features/virtualisation
    ./features/vscode
    ./features/yazi
    ./features/zed
    ./features/zen
    ./features/zellij
    ./features/zoxide

    ./features/desktop/hyprland
    # ./features/desktop/gnome
    ./features/desktop/common
  ];

  home.packages = with pkgs; [
    amdgpu_top
  ];

  # Disable impermanence
  # home.persistence = lib.mkForce {};
}

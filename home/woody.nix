{
  pkgs,
  ...
}:

{
  imports = [
    ./global
    ./features/desktop/hyprland
    ./features/desktop/gnome
    ./features/desktop/common
    ./features/accounts
    ./features/alacritty
    ./features/ansible
    ./features/atuin
    ./features/bat
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
    ./features/kodi
    ./features/kubernetes
    ./features/lazygit
    ./features/media
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
    ./features/tmux
    ./features/virtualisation
    ./features/vscode
    ./features/yazi
    ./features/zed
    ./features/zellij
    ./features/zoxide
  ];

  home.packages = with pkgs; [
    amdgpu_top
    # f1multiviewer
  ];

  # programs.f1multiviewer = {
  #   enable = true;
  # };

  # Disable impermanence
  # home.persistence = lib.mkForce {};
}

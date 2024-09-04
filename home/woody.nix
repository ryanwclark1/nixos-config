{
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./global
    ./features/desktop/hyprland
    ./features/desktop/gnome
    ./features/desktop/common

    ./features/alacritty
    ./features/atuin
    ./features/cli
    ./features/compression
    ./features/development
    ./features/eza
    ./features/fastfetch
    ./features/fd
    ./features/fzf
    ./features/games
    ./features/git
    # ./features/gpu
    ./features/kitty
    ./features/kubernetes
    ./features/lazygit
    ./features/media
    ./features/networking-utils
    ./features/nvim
    ./features/osint
    ./features/pistol
    ./features/productivity
    ./features/qutebrowser
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

    # ./features/helix
  ];

  home.packages = with pkgs; [
    amdgpu_top
  ];

  # Disable impermanence
  # home.persistence = lib.mkForce {};
}

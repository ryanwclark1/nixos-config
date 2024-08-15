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
    ./features/cli
    ./features/compression
    ./features/development
    ./features/eza
    ./features/fastfetch
    ./features/fzf
    ./features/games
    ./features/git
    # ./features/gpu
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
    ./features/ripgrep
    ./features/shell
    ./features/starship
    ./features/sys-stats
    ./features/tmux
    ./features/vhs
    ./features/vscode
    ./features/wezterm
    ./features/zellij
    ./features/zoxide

    # ./features/helix
  ];

  home.packages = with pkgs; [
    amdgpu_top
  ];

  # Disable impermanence
  home.persistence = lib.mkForce { };
}

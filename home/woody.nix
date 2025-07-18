{
  pkgs,
  ...
}:

{
  imports = [
    ./global

    ./features/ai
    # ./features/alacritty    # Removed: using ghostty as primary terminal
    ./features/ansible
    ./features/atuin
    ./features/audio
    ./features/bat
    # ./features/bluetooth
    ./features/btop
    ./features/cava
    ./features/chrome
    ./features/cli
    ./features/compression
    ./features/cursor
    ./features/development
    ./features/docker
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
    ./features/kodi
    ./features/kubernetes
    ./features/lazygit
    ./features/media
    ./features/multiviewer
    ./features/networking-utils
    ./features/nixvim
    ./features/productivity
    # ./features/qutebrowser
    ./features/remmina
    ./features/ripgrep
    ./features/shell
    ./features/starship
    ./features/sys-stats
    ./features/tmux
    ./features/vscode
    # ./features/whispar
    ./features/wireless
    ./features/windsurf
    ./features/yazi
    ./features/zellij
    ./features/zen
    ./features/zoxide

    ./features/desktop/hyprland
    ./features/desktop/hyprland/host-specific/woody.nix
    # ./features/desktop/gnome
    ./features/desktop/common
  ];

  home.packages = with pkgs; [
    amdgpu_top
  ];

  # wallpaper = pkgs.wallpapers.aenami-lost-in-between;
  # stylix.targets.hyprland.enable = lib.mkForce true;

  # Disable impermanence
  # home.persistence = lib.mkForce {};
}

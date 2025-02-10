{
  ...
}:

{
  imports = [
    ./global

    # ./features/accounts
    ./features/alacritty
    ./features/ansible
    ./features/atuin
    ./features/bat
    ./features/btop
    ./features/cli
    ./features/chrome
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
    ./features/navi
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
    ./features/tealdeer
    ./features/tmux
    # ./features/virtualisation
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
  # stylix.targets.gnome.enable = lib.mkForce true;
  # stylix.targets.gtk.enable = lib.mkForce true;
  # stylix.targets.ghostty.enable = lib.mkForce true;
  # stylix.polarity = lib.mkForce "dark";
  # stylix.iconTheme.enable = lib.mkForce true;
  # stylix.iconTheme.package = lib.mkForce pkgs.papirus-icon-theme;
  # stylix.iconTheme.dark = lib.mkForce "Papirus-Dark";
  # stylix.iconTheme.light = lib.mkForce "Papirus";
  # stylix.targets.cava.enable = lib.mkForce true;
  # stylix.targets.cava.rainbow.enable = lib.mkForce true;
  # stylix.targets.vscode.enable = lib.mkForce true;
}

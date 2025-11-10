{
  pkgs,
  ...
}:

{
  imports = [
    ./global

    ./features/ai
    ./features/alacritty
    ./features/ansible
    ./features/atuin
    ./features/audio
    ./features/bat
    ./features/bluetooth
    ./features/btop
    ./features/cava
    ./features/chromium
    ./features/cli
    ./features/compression
    ./features/cursor
    ./features/development
    ./features/discord
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
    ./features/gui-tools
    ./features/imv
    ./features/kitty
    # ./features/kodi
    ./features/kubernetes
    ./features/lazygit
    ./features/media
    ./features/multiviewer
    ./features/neovim
    ./features/networking-utils
    ./features/not-found
    ./features/productivity
    ./features/qutebrowser
    ./features/readline
    ./features/remmina
    ./features/ripgrep
    ./features/shell
    ./features/slack
    ./features/starship
    ./features/sys-stats
    ./features/tmux
    ./features/virtualisation
    ./features/vivid
    ./features/vscode
    ./features/webapps
    ./features/wireless
    ./features/windsurf
    ./features/yazi
    ./features/zellij
    ./features/zoxide

    # Desktop environment configuration
    ./features/desktop/common # Core desktop components
    ./features/desktop/window-managers # Window managers and shared WM tools
    ./features/desktop/window-managers/hyprland/host-specific/woody.nix
    # ./features/desktop/window-managers/niri/host-specific/woody.nix
  ];

  home.packages = with pkgs; [
    amdgpu_top
  ];

  home.file.".config/wireplumber/wireplumber.conf.d/51-usb-dac-default.conf".text = ''
    monitor.alsa.rules = [
      {
        matches = [
          { node.name = "*PCM2704*Pro*" }
        ]
        actions = {
          update-props = {
            audio.priority = 1000
            priority.driver = 1000
          }
        }
      }
    ]
  '';

  # wallpaper = pkgs.wallpapers.aenami-lost-in-between;
  # stylix.targets.hyprland.enable = lib.mkForce true;

  # Disable impermanence
  # home.persistence = lib.mkForce {};
}

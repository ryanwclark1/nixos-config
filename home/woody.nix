{
  pkgs,
  ...
}:

{
  imports = [
    ./global

    ./features/ai
    ./features/aichat
    # ./features/alacritty    # Removed: using ghostty as primary terminal
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
    ./features/kodi
    ./features/kubernetes
    ./features/lazygit
    ./features/media
    ./features/multiviewer
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
    # ./features/whispar
    ./features/wireless
    ./features/windsurf
    ./features/yazi
    ./features/zellij
    # ./features/zen
    ./features/zoxide

    # Desktop environment configuration
    ./features/desktop/common # Core desktop components
    ./features/desktop/window-managers # Window managers and shared WM tools
    ./features/desktop/window-managers/hyprland/host-specific/woody.nix
    ./features/desktop/window-managers/niri/host-specific/woody.nix

    # Application launcher cleanup
  ];

  home.packages = with pkgs; [
    amdgpu_top
  ];

  # Woody-specific USB DAC configuration
  # Set USB DAC (PCM2704) as default audio output on startup
  # This ensures volume controls work with the correct device
  home.file.".config/wireplumber/main.lua.d/51-usb-dac-default.lua".text = ''
    -- Set USB DAC (PCM2704) as default audio sink with higher priority
    rule = {
      matches = {
        {
          { "node.name", "matches", "*PCM2704*Pro*" },
        },
      },
      apply_properties = {
        ["audio.priority"] = 1000,
        ["priority.driver"] = 1000,
      },
    }

    table.insert(alsa_monitor.rules, rule)
  '';

  # wallpaper = pkgs.wallpapers.aenami-lost-in-between;
  # stylix.targets.hyprland.enable = lib.mkForce true;

  # Disable impermanence
  # home.persistence = lib.mkForce {};
}

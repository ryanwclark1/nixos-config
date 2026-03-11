{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ./theme.conf.nix ];

  programs.ghostty = {
    enable = true;
    package = inputs.ghostty.packages.${pkgs.stdenv.hostPlatform.system}.default;
    installVimSyntax = true;
    installBatSyntax = true;
    # Set to true to disable Ghostty defaults and use only keybinds defined below.
    clearDefaultKeybinds = false;
    settings = {
      # Theme
      theme = "theme";

      # Font
      font-family = "JetBrainsMono Nerd Font";
      font-style = "Regular";
      font-size = 12;

      # Window
      window-theme = "ghostty";
      window-padding-x = 4;
      window-padding-y = 4;
      confirm-close-surface = false;
      resize-overlay = "never";
      gtk-toolbar-style = "flat";
      gtk-titlebar = false;

      # Cursor
      cursor-style = "block";
      cursor-style-blink = false;

      # Shell integration
      # Removed ssh-env to prevent OSC 7 host warnings with remote hostnames
      shell-integration-features = "no-cursor";

      # Background
      background-opacity = 0.7;
      background-blur = true;

      # Behavior
      copy-on-select = true;
      auto-update = "off";
      # Slow down mouse scrolling for finer control
      mouse-scroll-multiplier = 0.95;

      # Keybindings
      keybind = [
        "ctrl+shift+c=copy_to_clipboard"
        "ctrl+shift+v=paste_from_clipboard"
      ];
    };
    enableBashIntegration = lib.mkIf config.programs.bash.enable true;
    enableFishIntegration = lib.mkIf config.programs.fish.enable true;
    enableZshIntegration = lib.mkIf config.programs.zsh.enable true;
  };
}

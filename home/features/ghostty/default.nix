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
      font-family = config.theme.fonts.monospace;
      font-style = "Regular";
      font-size = 12;

      # Window
      window-theme = "ghostty";
      window-padding-x = 4;
      window-padding-y = 4;
      window-padding-balance = true;
      window-show-tab-bar = "always";
      window-new-tab-position = "end";
      confirm-close-surface = false;
      resize-overlay = "after-first";
      resize-overlay-position = "top-right";
      unfocused-split-opacity = 0.85;
      gtk-toolbar-style = "flat";
      gtk-titlebar = false;
      gtk-tabs-location = "bottom";
      gtk-single-instance = true;

      # Cursor
      cursor-style = "block";
      cursor-style-blink = false;

      # Shell integration
      # Removed ssh-env to prevent OSC 7 host warnings with remote hostnames
      shell-integration-features = "cursor,no-sudo,title,no-ssh-env,no-ssh-terminfo,path";

      # Background
      background-opacity = 0.9;
      background-blur = true;

      # Behavior
      focus-follows-mouse = true;
      copy-on-select = true;
      right-click-action = "copy-or-paste";
      clipboard-read = "allow";
      clipboard-write = "allow";
      clipboard-paste-protection = true;
      clipboard-paste-bracketed-safe = true;
      clipboard-trim-trailing-spaces = true;
      link-url = true;
      link-previews = true;
      app-notifications = "clipboard-copy,config-reload";
      auto-update = "off";
      # Slow down mouse scrolling for finer control
      mouse-scroll-multiplier = "precision:0.85,discrete:2";

      # Quick terminal
      quick-terminal-position = "top";
      quick-terminal-screen = "main";
      quick-terminal-autohide = true;
      quick-terminal-keyboard-interactivity = "exclusive";

      # Dynamic color integration with quickshell ColorExportService
      # Silently skipped if file doesn't exist yet (? prefix)
      config-file = "?~/.local/state/quickshell/ghostty-colors";

      # Keybindings
      keybind = [
        "performable:ctrl+shift+c=copy_to_clipboard:mixed"
        "ctrl+shift+v=paste_from_clipboard"
        "ctrl+shift+,=reload_config"
        "ctrl+,=open_config"
        "ctrl+shift+n=new_window"
        "ctrl+shift+t=new_tab"
        "ctrl+shift+w=close_tab:this"
        "ctrl+shift+q=close_window"
        "ctrl+shift+o=new_split:right"
        "ctrl+shift+e=new_split:down"
        "ctrl+shift+h=goto_split:left"
        "ctrl+shift+j=goto_split:down"
        "ctrl+shift+k=goto_split:up"
        "ctrl+shift+l=goto_split:right"
        "ctrl+alt+h=resize_split:left,10"
        "ctrl+alt+j=resize_split:down,10"
        "ctrl+alt+k=resize_split:up,10"
        "ctrl+alt+l=resize_split:right,10"
        "ctrl+shift+x=toggle_split_zoom"
        "ctrl+shift+p=toggle_command_palette"
        "ctrl+shift+b=toggle_background_opacity"
        "ctrl+shift+space=toggle_quick_terminal"
        "ctrl+enter=toggle_fullscreen"
        "alt+1=goto_tab:1"
        "alt+2=goto_tab:2"
        "alt+3=goto_tab:3"
        "alt+4=goto_tab:4"
        "alt+5=goto_tab:5"
        "alt+6=goto_tab:6"
        "alt+7=goto_tab:7"
        "alt+8=goto_tab:8"
        "alt+9=last_tab"
      ];
    };
    enableBashIntegration = lib.mkIf config.programs.bash.enable true;
    enableFishIntegration = lib.mkIf config.programs.fish.enable true;
    enableZshIntegration = lib.mkIf config.programs.zsh.enable true;
  };
}

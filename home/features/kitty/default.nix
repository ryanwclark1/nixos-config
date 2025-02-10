{
  config,
  lib,
  pkgs,
  ...
}:


{
  programs.bash.bashrcExtra = ''
    [ "$TERM" = "xterm-kitty" ] && alias ssh="kitty +kitten ssh"
  '';

  programs.zsh.initExtra = ''
    [ "$TERM" = "xterm-kitty" ] && alias ssh="kitty +kitten ssh"
  '';

  # home = {
  #   sessionVariables = {
  #     TERMINAL = "kitty -1";
  #   };
  # };
  programs.kitty = {
    enable = true;
    package = pkgs.kitty;
    environment = {
      "LS_COLORS" = "1";
    };
    font = {
      name = "DejaVu Sans";
      size = 12;
    };
    shellIntegration = {
      enableZshIntegration = lib.mkIf config.programs.kitty.enable true;
      enableBashIntegration = lib.mkIf config.programs.kitty.enable true;
      enableFishIntegration = lib.mkIf config.programs.kitty.enable true;
    };
    settings = {
      bold_font = "auto";
      italic_font = "auto";
      bold_italic_font = "auto";
      force_ltr = false;
      disable_ligatures = false;
      scrollback_lines = 25000;
      scrollback_indicator_opacity = 0.8;
      # scrollback_pager
      scrollback_pager_history_size = 2048;
      scrollback_fill_enlarged_window = true;
      wheel_scroll_multiplier = 5.0;
      wheel_scroll_min_lines = 1;
      touch_scroll_multiplier = 1.5;
      mouse_hide_wait = 4.0;
      open_url_with = "default";
      url_prefixes = "http,https,ftp,file";
      detect_urls = true;
      show_hyperlink_targets = true;
      underline_hyperlinks = "hover";
      copy_on_select = "clipboard";
      strip_trailing_spaces = "smart";
      select_by_word_characters = "@-./_~?&=%+#";
      pointer_shape_when_grabbed = "arrow";
      default_pointer_shape = "beam";
      pointer_shape_when_dragging = "beam";
      repaint_delay = 10;
      input_delay = 3;
      sync_to_monitor = true;
      enable_audio_bell = true;
      visual_bell_duration = 0.0;
      visual_bell_color = "none";
      window_alert_on_bell = true;
      bell_on_tab = "🔔 ";
      command_on_bell = "none";
      bell_path = "none";
      update_check_interval = 0;
      confirm_os_window_close = 0;
      # Advanced settings
      allow_remote_control = false;
      allow_hyperlinks = true;
      shell_integration = "enabled";
      allow_cloning = "ask";
      dynamic_background_opacity = true;
      notify_on_cmd_finish = "unfocused 5 notify";
      background_opacity = "0.65";
      background_blur = 1;
      # term = "xterm-256color";
      term = "xterm-kitty";
      terminfo_type = "path";
      forward_stdio = false;
      kitty_mod = "ctrl+shift";
      clear_all_shortcuts = false;
      symbol_map = let
        mappings = [
          "U+23FB-U+23FE"
          "U+2B58"
          "U+E200-U+E2A9"
          "U+E0A0-U+E0A3"
          "U+E0B0-U+E0BF"
          "U+E0C0-U+E0C8"
          "U+E0CC-U+E0CF"
          "U+E0D0-U+E0D2"
          "U+E0D4"
          "U+E700-U+E7C5"
          "U+F000-U+F2E0"
          "U+2665"
          "U+26A1"
          "U+F400-U+F4A8"
          "U+F67C"
          "U+E000-U+E00A"
          "U+F300-U+F313"
          "U+E5FA-U+E62B"
        ];
      in
        (builtins.concatStringsSep "," mappings) + " Symbols Nerd Font";

      # The basic colors";
      foreground = "#c6d0f5";
      background = "#303446";
      selection_foreground = "#303446";
      selection_background = "#f2d5cf";

      # Cursor colors
      cursor = "#f2d5cf";
      cursor_text_color = "#303446";

      # URL underline color when hovering with mouse
      url_color = "#f2d5cf";

      # Kitty window border colors
      active_border_color = "#babbf1";
      inactive_border_color = "#737994";
      bell_border_color = "#e5c890";

      # OS Window titlebar colors
      wayland_titlebar_color = "system";
      macos_titlebar_color = "system";

      # Tab bar colors";
      active_tab_foreground = "#232634";
      active_tab_background = "#ca9ee6";
      inactive_tab_foreground = "#c6d0f5";
      inactive_tab_background = "#292c3c";
      tab_bar_background = "#232634";

      # Colors for marks (marked text in the terminal)
      mark1_foreground = "#303446";
      mark1_background = "#babbf1";
      mark2_foreground = "#303446";
      mark2_background = "#ca9ee6";
      mark3_foreground = "#303446";
      mark3_background = "#85c1dc";

      # The 16 terminal colors

      # black
      color0 = "#51576d";
      color8 = "#626880";

      # red
      color1 = "#e78284";
      color9 = "#e78284";

      # green
      color2 = "#a6d189";
      color10 = "#a6d189";

      # yellow
      color3 = "#e5c890";
      color11 = "#e5c890";

      # blue
      color4 = "#8caaee";
      color12 = "#8caaee";

      # magenta
      color5 = "#f4b8e4";
      color13 = "#f4b8e4";

      # cyan
      color6 = "#81c8be";
      color14 = "#81c8be";

      # white
      color7 = "#b5bfe2";
      color15 = "#a5adce";
    };
  };
}

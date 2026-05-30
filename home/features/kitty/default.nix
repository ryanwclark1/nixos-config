{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.theme.colors)
    base00
    base01
    base02
    base03
    base04
    base05
    base06
    base07
    base08
    base09
    base0A
    base0B
    base0C
    base0D
    base0E
    base0F
    base10
    base11
    base12
    base13
    base14
    base15
    base16
    base17
    ;
  font = config.theme.fonts.monospace;
in

{
  programs.bash.bashrcExtra = ''
    [ "$TERM" = "xterm-kitty" ] && alias ssh="kitty +kitten ssh"
  '';

  programs.zsh.initContent = ''
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
      name = "${font}";
      size = 12;
    };
    shellIntegration = {
      enableBashIntegration = lib.mkIf config.programs.bash.enable true;
      enableFishIntegration = lib.mkIf config.programs.fish.enable true;
      enableZshIntegration = lib.mkIf config.programs.zsh.enable true;
    };
    settings = {
      bold_font = "auto";
      italic_font = "auto";
      bold_italic_font = "auto";
      force_ltr = false;
      disable_ligatures = false;
      scrollback_lines = 25000;
      # scrollback_indicator_opacity was removed in newer Kitty versions
      # No direct replacement - scrollbar appearance is now controlled by theme
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
      term = "xterm-kitty";
      terminfo_type = "path";
      forward_stdio = false;
      kitty_mod = "ctrl+shift";
      clear_all_shortcuts = false;
      symbol_map =
        let
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
      foreground = "#${base05}";
      background = "#${base00}";
      selection_foreground = "#${base00}";
      selection_background = "#${base06}";

      # Cursor colors
      cursor = "#${base06}";
      cursor_text_color = "#${base00}";

      # URL underline color when hovering with mouse
      url_color = "#${base06}";

      # Kitty window border colors
      active_border_color = "#${base07}";
      inactive_border_color = "#${base04}";
      bell_border_color = "#${base0A}";

      # OS Window titlebar colors
      wayland_titlebar_color = "system";
      macos_titlebar_color = "system";

      # Tab bar colors";
      active_tab_foreground = "#${base11}";
      active_tab_background = "#${base0E}";
      inactive_tab_foreground = "#${base05}";
      inactive_tab_background = "#${base01}";
      tab_bar_background = "#${base11}";

      # Colors for marks (marked text in the terminal)
      mark1_foreground = "#${base00}";
      mark1_background = "#${base07}";
      mark2_foreground = "#${base00}";
      mark2_background = "#${base0E}";
      mark3_foreground = "#${base00}";
      mark3_background = "#${base16}";

      # The 16 terminal colors

      # black
      color0 = "#${base03}";
      color8 = "#${base04}";

      # red
      color1 = "#${base08}";
      color9 = "#${base12}";

      # green
      color2 = "#${base0B}";
      color10 = "#${base14}";

      # yellow
      color3 = "#${base0A}";
      color11 = "#${base13}";

      # blue
      color4 = "#${base0D}";
      color12 = "#${base16}";

      # magenta
      color5 = "#${base0F}";
      color13 = "#${base17}";

      # cyan
      color6 = "#${base0C}";
      color14 = "#${base15}";

      # white
      color7 = "#${base05}";
      color15 = "#${base05}";
    };
  };
}

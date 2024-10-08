{
  config,
  lib,
  pkgs,
  ...
}:
let
  kitty-xterm = pkgs.writeShellScriptBin "xterm" ''
    ${config.programs.kitty.package}/bin/kitty -1 "$@"
  '';
  inherit (lib) mkIf;
in
{
  home = {
    packages = [ kitty-xterm ];
    # sessionVariables = {
    #   TERMINAL = "kitty -1";
    # };
  };
  programs.kitty = {
    enable = true;
    package = pkgs.kitty;
    settings = {
      scrollback_lines = 25000;
      scrollback_pager_history_size = 2048;
      copy_on_select = "clipboard";
      wheel_scroll_min_lines = 1;
      window_padding_width = 15;
      update_check_interval = 0;
      repaint_delay = 10;
      input_delay = 1;
      sync_to_monitor = true;
      # changing default behaviors
      confirm_os_window_close = 0;
      enable_audio_bell = false;
      dynamic_background_opacity = true;
      allow_remote_control = true;
      background_opacity = "0.70";
      background_blur = 1;

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
    shellIntegration = {
      enableZshIntegration = lib.mkIf config.programs.kitty.enable true;
      enableBashIntegration = lib.mkIf config.programs.kitty.enable true;
      enableFishIntegration = lib.mkIf config.programs.kitty.enable true;
    };
  };
}

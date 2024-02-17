{ pkgs
, config
, ...
}:
let
  font = "JetBrainsMono Nerd Font";
  inherit (config.colorscheme) palette;
  kitty-xterm = pkgs.writeShellScriptBin "xterm" ''
    ${config.programs.kitty.package}/bin/kitty -1 "$@"
  '';
in
{
  home = {
    packages = [ kitty-xterm ];
    sessionVariables = {
      TERMINAL = "kitty -1";
    };
  };

  programs.kitty = {
    enable = true;
    package = pkgs.kitty;
    font = {
      name = font;
      size = 12;
    };
    settings = {
      # shell_integration = "no-rc"; # I prefer to do it manually
      # performance
      scrollback_lines = 15000;
      # scrollback_pager_history_size = 2048;
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
      background_opacity = "0.9";

      # Default shell
      shell = "${pkgs.zsh}/bin/zsh";
      # Font settings
      # font_size = 12;
      # adjust_line_height = 12;
      font_family = config.global-fonts.main-regular;
      bold_font = config.global-fonts.main-black;
      italic_font = config.global-fonts.main-italic;
      bold_italic_font = config.global-fonts.main-black-italic;
      foreground = "#${palette.base05}";
      background = "#${palette.base00}";
      selection_background = "#${palette.base05}";
      selection_foreground = "#${palette.base00}";
      url_color = "#${palette.base04}";
      cursor = "#${palette.base05}";
      active_border_color = "#${palette.base03}";
      inactive_border_color = "#${palette.base01}";
      active_tab_background = "#${palette.base00}";
      active_tab_foreground = "#${palette.base05}";
      inactive_tab_background = "#${palette.base01}";
      inactive_tab_foreground = "#${palette.base04}";
      tab_bar_background = "#${palette.base01}";
      color0 = "#${palette.base00}";
      color1 = "#${palette.base08}";
      color2 = "#${palette.base0B}";
      color3 = "#${palette.base0A}";
      color4 = "#${palette.base0D}";
      color5 = "#${palette.base0E}";
      color6 = "#${palette.base0C}";
      color7 = "#${palette.base05}";
      color8 = "#${palette.base03}";
      color9 = "#${palette.base08}";
      color10 = "#${palette.base0B}";
      color11 = "#${palette.base0A}";
      color12 = "#${palette.base0D}";
      color13 = "#${palette.base0E}";
      color14 = "#${palette.base0C}";
      color15 = "#${palette.base07}";
      color16 = "#${palette.base09}";
      color17 = "#${palette.base0F}";
      color18 = "#${palette.base01}";
      color19 = "#${palette.base02}";
      color20 = "#${palette.base04}";
      color21 = "#${palette.base06}";
    };

  };
}

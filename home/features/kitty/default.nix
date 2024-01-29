{
  pkgs,
  config,
  ...
}:
let
  font = "JetBrainsMono Nerd Font";
  inherit (config.colorscheme) colors;
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
      background_opacity = "0.85";

      # Default shell
      shell = "${pkgs.zsh}/bin/zsh";

      # Font settings
      # font_size = 12;
      # adjust_line_height = 12;
      font_family = config.global-fonts.main-regular;
      bold_font = config.global-fonts.main-black;
      italic_font = config.global-fonts.main-italic;
      bold_italic_font = config.global-fonts.main-black-italic;
      foreground = "#${colors.base05}";
      background = "#${colors.base00}";
      selection_background = "#${colors.base05}";
      selection_foreground = "#${colors.base00}";
      url_color = "#${colors.base04}";
      cursor = "#${colors.base05}";
      active_border_color = "#${colors.base03}";
      inactive_border_color = "#${colors.base01}";
      active_tab_background = "#${colors.base00}";
      active_tab_foreground = "#${colors.base05}";
      inactive_tab_background = "#${colors.base01}";
      inactive_tab_foreground = "#${colors.base04}";
      tab_bar_background = "#${colors.base01}";
      color0 = "#${colors.base00}";
      color1 = "#${colors.base08}";
      color2 = "#${colors.base0B}";
      color3 = "#${colors.base0A}";
      color4 = "#${colors.base0D}";
      color5 = "#${colors.base0E}";
      color6 = "#${colors.base0C}";
      color7 = "#${colors.base05}";
      color8 = "#${colors.base03}";
      color9 = "#${colors.base08}";
      color10 = "#${colors.base0B}";
      color11 = "#${colors.base0A}";
      color12 = "#${colors.base0D}";
      color13 = "#${colors.base0E}";
      color14 = "#${colors.base0C}";
      color15 = "#${colors.base07}";
      color16 = "#${colors.base09}";
      color17 = "#${colors.base0F}";
      color18 = "#${colors.base01}";
      color19 = "#${colors.base02}";
      color20 = "#${colors.base04}";
      color21 = "#${colors.base06}";
    };

  };
}
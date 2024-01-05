{
  pkgs,
  lib,
  config,
  ...
}:

with lib; {
  options.kitty.enable = mkEnableOption "kitty settings";

  config = mkIf config.kitty.enable {
    programs.kitty = {
      enable = true;
      settings = {
        # performance
        scrollback_lines = 15000;
        update_check_interval = 0;
        repaint_delay = 10;
        input_delay = 1;
        sync_to_monitor = true;

        # changing default behaviors
        confirm_os_window_close = 0;
        enable_audio_bell = false;
        dynamic_background_opacity = false;
        allow_remote_control = true;

        # Default shell
        shell = "${pkgs.zsh}/bin/zsh";

        # Font settings
        font_size = 11;
        # adjust_line_height = 12;
        font_family = config.global-fonts.main-regular;
        bold_font = config.global-fonts.main-black;
        italic_font = config.global-fonts.main-italic;
        bold_italic_font = config.global-fonts.main-black-italic;
      };
      theme = "Rosé Pine"; # the default one is mocha colored, nice choice kitty!
    };
  };
}
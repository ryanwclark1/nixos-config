{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
let
  font = "JetBrainsMono Nerd Font";
in
{
  options.alacritty.enable = mkEnableOption "alacritty settings";

  config = mkIf config.alacritty.enable {
    programs.alacritty = {
      enable = true;
      settings = {
        window = {
          opacity = 0.90;
          dynamic_title = true;
          dynamic_padding = true;
          padding = {
            x = 5;
            y = 5;
          };
          title = "terminal";
        };
        scrolling = {
          history = 25000;
          multiplier = 5;
        };
        font = {
          normal.family = font;
          bold.family = font;
          italic.family = font;
          draw_bold_text_with_bright_colors = true;
          size = 10;
        };
        selection.save_to_clipboard = true;
      };
    };
  };
}
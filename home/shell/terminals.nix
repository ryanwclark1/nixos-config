{
  pkgs,
  ...
}:

let
  font = "JetBrainsMono Nerd Font";
in
{
  programs.alacritty = {
    enable = true;
    settings = {
      env.TERM = "xterm-256color";
      window = {
        opacity = 0.90;
        dynamic_title = true;
        dynamic_padding = true;
        padding = {
          x = 5;
          y = 5;
        };
      };
      scrolling.history = 10000;

      font = {
        normal.family = font;
        bold.family = font;
        italic.family = font;
        draw_bold_text_with_bright_colors = true;
        size = 10;
      };
      scrolling.multiplier = 5;
      selection.save_to_clipboard = true;
    };
  };
}

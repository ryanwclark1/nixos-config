{
  lib,
  ...
}:
with lib;
let
  font = "JetBrainsMono Nerd Font";
in
{
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        opacity = 0.85;
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
        size = 12;
      };
      selection.save_to_clipboard = true;
    };
  };
}
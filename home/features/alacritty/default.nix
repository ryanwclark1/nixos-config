{
  config,
  pkgs,
  ...
}:
let
  font = "JetBrainsMono Nerd Font";
  inherit (config.colorscheme) palette;
in
{
  home.packages = with pkgs; [
    alacritty-theme
  ];
  programs.alacritty = {
    enable = true;
    package = pkgs.alacritty;
    settings = {
      window = {
        opacity = 0.8;
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
      # import = [
      #   "${pkgs.alacritty-theme}/themes/nord.yml"
      # ];
      colors = {
        primary = {
          background = "#${palette.base00}";
          foreground = "#${palette.base05}";
        };
      };
      selection.save_to_clipboard = true;
    };
  };
}

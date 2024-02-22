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
          x = 2;
          y = 2;
        };
        decorations = "Full"; # Borders and title bar
        blur = true; # works on macOS/KDE Wayland
        title = "terminal";
      };
      scrolling = {
        history = 25000;
        multiplier = 5;
      };
      font = {
        normal = {
          family = font;
          style = "Regular";
        };
        bold = {
          family = font;
          style = "Bold";
        };
        italic = {
          family = font;
          style = "Italic";
        };
        bold_italic = {
          family = font;
          style = "Bold Italic";
        };
        size = 11.25;
      };
      # import = [
      #   "${pkgs.alacritty-theme}/themes/nord.yml"
      # ];
      colors = {
        # transparent_background_colors = true;
        primary = {
          background = "#${palette.base00}";
          foreground = "#${palette.base05}";
        };
      };
      selection = {
        save_to_clipboard = true;
      };
      mouse = {
        hide_when_typing = false;
      };
    };
  };
}

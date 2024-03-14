{
  config,
  pkgs,
  ...
}:

{
  programs.alacritty = {
    enable = true;
    package = pkgs.alacritty;
    settings = {
      window = {
        # opacity = 0.8;
        dynamic_title = true;
        dynamic_padding = true;
        padding = {
          x = 2;
          y = 2;
        };
        decorations = "Full"; # Borders and title bar
        blur = true; # works on macOS/KDE Wayland
        title = "alacritty";
      };
      scrolling = {
        history = 25000;
        multiplier = 5;
      };
      # colors = {
      #   transparent_background_colors = true;
      # };
      selection = {
        save_to_clipboard = true;
      };
      mouse = {
        hide_when_typing = false;
      };
    };
  };
}

{
  pkgs,
  ...
}:

{
  programs.alacritty = {
    enable = true;
    package = pkgs.alacritty;
    settings = {
      env = {
        TERM = "xterm-256color";
      };
      window = {
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
      colors = {
         # Default colors
        primary = {
          background = "#303446"; # base
          foreground = "#C6D0F5"; # text
          # Bright and dim foreground colors
          dim_foreground = "#C6D0F5"; # text
          bright_foreground = "#C6D0F5"; # text
        };

        # Cursor colors
        cursor = {
          text = "#303446"; # base
          cursor = "#F2D5CF"; # rosewater
        };
        vi_mode_cursor = {
          text = "#303446"; # base
          cursor = "#BABBF1"; # lavender
        };
        # Search colors
        search.matches = {
          foreground = "#303446"; # base
          background = "#A5ADCE"; # subtext0
        };
        search.focused_match = {
          foreground = "#303446"; # base
          background = "#A6D189"; # green
        };
        footer_bar = {
            foreground = "#303446"; # base
            background = "#A5ADCE"; # subtext0
        };
        # Keyboard regex hints
        hints.start = {
          foreground = "#303446"; # base
          background = "#E5C890"; # yellow
        };
        hints.end = {
          foreground = "#303446"; # base
          background = "#A5ADCE"; # subtext0
        };
        # Selection colors
        selection = {
          text = "#303446"; # base
          background = "#F2D5CF"; # rosewater
        };
        # Normal colors
        normal = {
          black = "#51576D"; # surface1
          red = "#E78284"; # red
          green = "#A6D189"; # green
          yellow = "#E5C890"; # yellow
          blue = "#8CAAEE"; # blue
          magenta = "#F4B8E4"; # pink
          cyan = "#81C8BE"; # teal
          white = "#B5BFE2"; # subtext1
        };
        # Bright colors
        bright = {
          black = "#626880"; # surface2
          red = "#E78284"; # red
          green = "#A6D189"; # green
          yellow = "#E5C890"; # yellow
          blue = "#8CAAEE"; # blue
          magenta = "#F4B8E4"; # pink
          cyan = "#81C8BE"; # teal
          white = "#A5ADCE"; # subtext0
        };
        # Dim colors
        dim = {
          black = "#51576D"; # surface1
          red = "#E78284"; # red
          green = "#A6D189"; # green
          yellow = "#E5C890"; # yellow
          blue = "#8CAAEE"; # blue
          magenta = "#F4B8E4"; # pink
          cyan = "#81C8BE"; # teal
          white = "#B5BFE2"; # subtext1
        };
        transparent_background_colors = true;
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

{
  pkgs,
  ...
}:
let
  base00 = "303446"; # base
  base01 = "292c3c"; # mantle
  base02 = "414559"; # surface0
  base03 = "51576d"; # surface1
  base04 = "626880"; # surface2
  base05 = "c6d0f5"; # text
  base06 = "f2d5cf"; # rosewater
  base07 = "babbf1"; # lavender
  base08 = "e78284"; # red
  base09 = "ef9f76"; # peach
  base0A = "e5c890"; # yellow
  base0B = "a6d189"; # green
  base0C = "81c8be"; # teal
  base0D = "8caaee"; # blue
  base0E = "ca9ee6"; # mauve
  base0F = "eebebe"; # flamingo
  base10 = "292c3c"; # mantle - darker background
  base11 = "232634"; # crust - darkest background
  base12 = "ea999c"; # maroon - bright red
  base13 = "f2d5cf"; # rosewater - bright yellow
  base14 = "a6d189"; # green - bright green
  base15 = "99d1db"; # sky - bright cyan
  base16 = "85c1dc"; # sapphire - bright blue
  base17 = "f4b8e4"; # pink - bright purple
  font = "CaskaydiaMono";
in
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
        decorations = "None";
        blur = true; # works on macOS/KDE Wayland
      };
      font = {
        normal = {
          family = "${font}";
          style = "Regular";
        };
        bold = {
          family = "${font}";
          style = "Bold";
        };
        italic = {
          family = "${font}";
          style = "Italic";
        };
        size = 9;
      };
      scrolling = {
        history = 25000;
        multiplier = 5;
      };
      colors = {
         # Default colors
        primary = {
          background = "#${base00}"; # base
          foreground = "#${base05}"; # text
          # Bright and dim foreground colors
          dim_foreground = "#${base05}"; # text
          bright_foreground = "#${base05}"; # text
        };

        # Cursor colors
        cursor = {
          text = "#${base00}"; # base
          cursor = "#${base06}"; # rosewater
        };
        vi_mode_cursor = {
          text = "#${base00}"; # base
          cursor = "#${base07}"; # lavender
        };
        # Search colors
        search.matches = {
          foreground = "#${base00}"; # base
          background = "#${base05}"; # subtext0/text
        };
        search.focused_match = {
          foreground = "#${base00}"; # base
          background = "#${base0B}"; # green
        };
        footer_bar = {
            foreground = "#${base00}"; # base
            background = "#${base05}"; # subtext0/text
        };
        # Keyboard regex hints
        hints.start = {
          foreground = "#${base00}"; # base
          background = "#${base0A}"; # yellow
        };
        hints.end = {
          foreground = "#${base00}"; # base
          background = "#${base05}"; # subtext0/text
        };
        # Selection colors
        selection = {
          text = "#${base00}"; # base
          background = "#${base06}"; # rosewater
        };
        # Normal colors
        normal = {
          black = "#${base03}"; # surface1
          red = "#${base08}"; # red
          green = "#${base0B}"; # green
          yellow = "#${base0A}"; # yellow
          blue = "#${base0D}"; # blue
          magenta = "#${base17}"; # pink
          cyan = "#${base0C}"; # teal
          white = "#${base05}"; # subtext1/text
        };
        # Bright colors
        bright = {
          black = "#${base04}"; # surface2
          red = "#${base08}"; # red
          green = "#${base0B}"; # green
          yellow = "#${base0A}"; # yellow
          blue = "#${base0D}"; # blue
          magenta = "#${base17}"; # pink
          cyan = "#${base0C}"; # teal
          white = "#${base05}"; # subtext0/text
        };
        # Dim colors
        dim = {
          black = "#${base03}"; # surface1
          red = "#${base08}"; # red
          green = "#${base0B}"; # green
          yellow = "#${base0A}"; # yellow
          blue = "#${base0D}"; # blue
          magenta = "#${base17}"; # pink
          cyan = "#${base0C}"; # teal
          white = "#${base05}"; # subtext1/text
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

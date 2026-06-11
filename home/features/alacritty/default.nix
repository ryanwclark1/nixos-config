{
  config,
  pkgs,
  ...
}:
let
  inherit (config.theme.colors)
    base00
    base01
    base02
    base03
    base04
    base05
    base06
    base07
    base08
    base09
    base0A
    base0B
    base0C
    base0D
    base0E
    base0F
    base10
    base11
    base12
    base13
    base14
    base15
    base16
    base17
    ;
  font = config.theme.fonts.monospace;

in
{
  home.file.".config/alacritty/screensaver.toml" = {
    force = true;
    source = ./screensaver.toml;
  };

  programs.alacritty = {
    enable = true;
    package = pkgs.alacritty;
    settings = {
      window = {
        dynamic_title = true;
        dynamic_padding = true;
        padding = {
          x = 4;
          y = 4;
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
        size = 12;
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
          cursor = "#${base06}";
        };
        vi_mode_cursor = {
          text = "#${base00}"; # base
          cursor = "#${base07}";
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
          background = "#${base06}";
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

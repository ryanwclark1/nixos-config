{
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
in
{
  home.file.".config/ghostty/themes/theme.conf" = {
    text = ''
      palette = 0=#${base03}
      palette = 1=#${base08}
      palette = 2=#${base0B}
      palette = 3=#${base0A}
      palette = 4=#${base0D}
      palette = 5=#${base17}
      palette = 6=#${base0C}
      palette = 7=#${base05}
      palette = 8=#${base04}
      palette = 9=#${base08}
      palette = 10=#${base0B}
      palette = 11=#${base0A}
      palette = 12=#${base0D}
      palette = 13=#${base17}
      palette = 14=#${base0C}
      palette = 15=#${base05}
      # background = #${base00}
      foreground = #${base05}
      cursor-color = #${base06}
      selection-background = #${base04}
      selection-foreground = #${base05}
    '';
  };
}
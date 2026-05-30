{
  config,
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
in
{
  xdg.configFile."ghostty/themes/theme" = {
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

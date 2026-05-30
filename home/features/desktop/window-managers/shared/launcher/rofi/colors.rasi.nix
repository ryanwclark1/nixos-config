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
  home.file.".config/rofi/style/shared/colors.rasi" = {
    text = ''
      * {
        background:       #${base00};
        background-alt:   #${base00}99; /* Opacity 60% */
        foreground:       #${base05};
        selected:         #${base0D};
        active:           #${base0B};
        urgent:           #${base08};
        border-color:     #${base0E};
      }
    '';
  };
}

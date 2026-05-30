{
  config,
  ...
}:
let
  scheme = "Catppuccin Frappe";
  author = "https://github.com/catppuccin/catppuccin";
  slug = "catppuccin-frappe";
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
    ;
in
{
  home.file.".config/hypr/conf/colors-hyprland.conf" = {
    text = ''
      $color0 = rgb(${base00})
      $color1 = rgb(${base01})
      $color2 = rgb(${base02})
      $color3 = rgb(${base03})
      $color4 = rgb(${base04})
      $color5 = rgb(${base05})
      $color6 = rgb(${base06})
      $color7 = rgb(${base07})
      $color8 = rgb(${base08})
      $color9 = rgb(${base09})
      $color10 = rgb(${base0A})
      $color11 = rgb(${base0B})
      $color12 = rgb(${base0C})
      $color13 = rgb(${base0D})
      $color14 = rgb(${base0E})
      $color15 = rgb(${base0F})
      $scheme = "${scheme}"
      $author = "${author}"
      $slug = "${slug}"
    '';
  };
}

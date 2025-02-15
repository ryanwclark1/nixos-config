{
  ...
}:
let 
  scheme = "Catppuccin Frappe";
  author = "https://github.com/catppuccin/catppuccin";
  slug = "catppuccin-frappe";
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
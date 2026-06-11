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
in
{
  programs.cava = {
    enable = true;
    package = pkgs.cava;
    settings = {
      general.framerate = 60;
      input.method = "pipewire";
      smoothing.noise_reduction = 88;
      color = {
        gradient = "1";
        gradient_color_1 = "'#${base0E}'";
        gradient_color_2 = "'#${base0D}'";
        gradient_color_3 = "'#${base0C}'";
        gradient_color_4 = "'#${base0B}'";
        gradient_color_5 = "'#${base0A}'";
        gradient_color_6 = "'#${base09}'";
        gradient_color_7 = "'#${base08}'";
        gradient_count = "7";
      };
    };
  };
}

{
  pkgs,
  ...
}:

{
  programs.cava = {
    enable = true;
    package = pkgs.cava;
    settings = {
     general.framerate = 60;
      input.method = "pipewire";
      smoothing.noise_reduction = 88;
      color = {
        background = "'#303446'";

        gradient = "1";
        gradient_color_1 = "'#ca9ee6'";
        gradient_color_2 = "'#8caaee'";
        gradient_color_3 = "'#81c8be'";
        gradient_color_4 = "'#a6d189'";
        gradient_color_5 = "'#e5c890'";
        gradient_color_6 = "'#ef9f76'";
        gradient_color_7 = "'#e78284'";
        gradient_count = "7";
      };
    };

  };
}
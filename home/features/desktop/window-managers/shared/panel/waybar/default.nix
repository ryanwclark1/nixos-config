{
  config,
  pkgs,
  ...
}:

{
  imports = [
    ./style.nix
  ];

  home.file.".config/waybar/config.jsonc" = {
    source = ./config.jsonc;
  };

  home.file.".config/waybar/style.css" = {
    source = ./style.css;
  };

  home.file.".config/waybar/color.css" = {
    source = ./color.css;
  };

  programs = {
    waybar = {
      enable = true;
      package = pkgs.waybar;
    };
  };
}

{
  config,
  pkgs,
  ...
}:

{
  # imports = [
  #   ./style.nix
  # ];

  home.file.".config/waybar/config" = {
    source = ./config;
  };

  home.file.".config/waybar/style.css" = {
    source = ./style;
  };

  programs = {
    waybar = {
      enable = true;
      package = pkgs.waybar;
    };
  };
}

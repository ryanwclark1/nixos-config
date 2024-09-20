{
  config,
  lib,
  pkgs,
  ...
}:

# TODO: Fix ssh functionality
{
  imports = [
    ./style
  ];
  home =
  {
    file.".config/rofi" = {
      source = ./config;
      recursive = true;
    };
  };
  programs = {
    rofi =
    let
      terminal = lib.getExe pkgs.alacritty;
    in {
      enable = true;
      package = pkgs.rofi-wayland;
      # configPath = "${config.home.homeDirectory}/.config/rofi/config.rasi";
      # cycle = true;
      # font = "JetBrainsMono";
      # location = "center";
      # terminal = "${terminal}";
      # xoffset = 0;
      # yoffset = 0;
      plugins = [
        pkgs.rofi-emoji-wayland
      ];
      pass = {
        enable = true;
        package = pkgs.rofi-pass-wayland;
        stores = [
          "${config.home.homeDirectory}/.local/share/keyrings"
        ];
      };
    };
  };
}
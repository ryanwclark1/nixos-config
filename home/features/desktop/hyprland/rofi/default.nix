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
  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
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
}
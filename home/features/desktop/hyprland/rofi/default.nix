{
  config,
  lib,
  pkgs,
  ...
}:

# TODO: Fix ssh functionality
{
  imports = [
    ./config
  ];
  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
    plugins = [
      pkgs.rofi-emoji-wayland
    ];
    configPath = "${config.home.homeDirectory}/.config/rofi/config2.rasi";
    pass = {
      enable = true;
      package = pkgs.rofi-pass-wayland;
      stores = [
        "${config.home.homeDirectory}/.local/share/keyrings"
      ];
    };
  };
}
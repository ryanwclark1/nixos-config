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
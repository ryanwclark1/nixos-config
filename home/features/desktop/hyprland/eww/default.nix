# TODO: Configure XDG_CONFIG_HOME for config directory
{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:


{
  imports = [
    ./scripts
    ./launch_bar.nix
  ];

  programs = {
    eww = {
      enable = true;
      package = pkgs.eww;
      enableZshIntegration = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      # configDir = "${config.home.homeDirectory}/.config/eww";
    };
  };



  # configuration
  home.file.".config/eww/eww.scss".source = ./eww.scss;
  home.file.".config/eww/eww.yuck".source = ./eww.yuck;
  home.file.".config/eww/colors.scss".source = ./colors.scss;
  home.file.".config/eww/eww_windows.yuck".source = ./eww_windows.yuck;
  home.file.".config/eww/eww_widgets.yuck".source = ./eww_widgets.yuck;
  home.file.".config/eww/eww_variables.yuck".source = ./eww_variables.yuck;
    home.file.".config/eww/variables.yuck".source = ./variables.yuck;

  # scripts
  home.file.".config/eww/actions" = {
    source = ./actions;
    recursive = true;
  };

  home.file.".config/eww/bar" = {
    source = ./bar;
    recursive = true;
  };

  home.file.".config/eww/date" = {
    source = ./date;
    recursive = true;
  };

  home.file.".config/eww/powermenu" = {
    source = ./powermenu;
    recursive = true;
  };

  # home.file.".config/eww/scripts/wifi.sh" = {
  #   source = ./scripts/wifi.sh;
  #   executable = true;
  # };

  # home.file.".config/eww/scripts/brightness.sh" = {
  #   source = ./scripts/brightness.sh;
  #   executable = true;
  # };

  # home.file.".config/eww/scripts/workspaces.sh" = {
  #   source = ./scripts/workspaces.sh;
  #   executable = true;
  # };

  # home.file.".config/eww/scripts/workspaces.lua" = {
  #   source = ./scripts/workspaces.lua;
  #   executable = true;
  # };
}

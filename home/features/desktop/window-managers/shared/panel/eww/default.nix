{
  lib,
  config,
  pkgs,
  ...
}:

{

  home.file.".config/eww/eww.scss" = {
    source = ./eww.scss;
  };

  home.file.".config/eww/eww.yuck" = {
    source = ./eww.yuck;
  };

  home.file.".config/eww/asset" = {
    source = ./asset;
    recursive = true;
  };

  home.file.".config/eww/bar" = {
    source = ./bar;
    recursive = true;
  };

  home.file.".config/eww/bin" = {
    source = ./bin;
    recursive = true;
  };

  home.file.".config/eww/dock" = {
    source = ./dock;
    recursive = true;
  };

  home.file.".config/eww/lock" = {
    source = ./lock;
    recursive = true;
  };

  home.file.".config/eww/notifications" = {
    source = ./notifications;
    recursive = true;
  };

  home.file.".config/eww/osd" = {
    source = ./osd;
    recursive = true;
  };

  home.file.".config/eww/widgets" = {
    source = ./widgets;
    recursive = true;
  };

  programs = {
    eww = {
      enable = true;
      package = pkgs.waybar;
      enableBashIntegration = lib.mkIf config.programs.bash.enable true;
      enableFishIntegration = lib.mkIf config.programs.fish.enable true;
      enableZshIntegration = lib.mkIf config.programs.zsh.enable true;
    };
  };
}

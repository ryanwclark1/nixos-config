# TODO: Configure XDG_CONFIG_HOME for config directory
{
  pkgs,
  ...
}:


{
  imports = [
    ./scripts
  ];

  home.packages = with pkgs; [
    pkgs.eww
  ];

  # # configuration
  home.file.".config/eww/eww.scss".source = ./eww.scss;
  home.file.".config/eww/eww.yuck".source = ./eww.yuck;
  home.file.".config/eww/colors.scss".source = ./colors.scss;
  home.file.".config/eww/eww_variables.yuck".source = ./eww_variables.yuck;
  home.file.".config/eww/eww_widgets.yuck".source = ./eww_widgets.yuck;
  home.file.".config/eww/eww_windows.yuck".source = ./eww_windows.yuck;
  home.file.".config/eww/variables.yuck".source = ./variables.yuck;

  home.file.".config/eww/launch_bar.sh" = {
    source = ./launch_bar.sh;
    executable = true;
  };

  # scripts
  home.file.".config/eww/actions" = {
    source = ./actions;
    recursive = true;
  };

  home.file.".config/eww/assets" = {
    source = ./assets;
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

  home.file.".config/eww/images" = {
    source = ./images;
    recursive = true;
  };

  home.file.".config/eww/powermenu" = {
    source = ./powermenu;
    recursive = true;
  };
}

  # programs = {
  #   eww = {
  #     enable = true;
  #     package = pkgs.eww-wayland;
  #     enableZshIntegration = true;
  #     enableBashIntegration = true;
  #     enableFishIntegration = true;
  #     configDir = "${config.home.homeDirectory}/.config/eww";
  #   };
  # };
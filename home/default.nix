 # users/administrator/home.nix
{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: let
  d = config.xdg.dataHome;
  c = config.xdg.configHome;
  cache = config.xdg.cacheHome;
in {
  imports = [
    ./programs
  ];

  home = {
    username = "administrator";
    homeDirectory = "/home/administrator";
    stateVersion = "23.11";
    sessionVariables = {
      # clean up ~
      LESSHISTFILE = cache + "/less/history";
      LESSKEY = c + "/less/lesskey";
      WINEPREFIX = d + "/wine";

      # set default applications
      EDITOR = "nvim";
      BROWSER = "firefox";
      TERMINAL = "alacritty";

      # enable scrolling in git diff
      DELTA_PAGER = "less -R";

      MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    };
  };

  programs.home-manager.enable = true;
}

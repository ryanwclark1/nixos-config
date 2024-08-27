{ pkgs, ... }:

{
  services = {
    hyprpaper = {
      enable = true;
      package = pkgs.hyprpaper;
    };
  };
}
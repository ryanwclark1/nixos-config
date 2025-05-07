{
  pkgs,
  ...
}:

{
  services = {
    hyprpaper = {
      enable = true;
      package = pkgs.hyprpaper;
      settings = {
        ipc = "on";
        splash = false;
        splash_offset = 2.0;
        preload = "$HOME/Pictures/wallpapers/default.png";
        wallpaper = ",$HOME/Pictures/wallpapers/default.png";
      };
    };
  };
}

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
        preload = "$HOME/.config/hypr/scripts/assets/blank.png";
        wallpaper = ",$HOME/.config/hypr/scripts/assets/blank.png";
      };
    };
  };
}
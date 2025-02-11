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
        preload = "$HOME/.config/ml4w/assets/blank.png";
        wallpaper = ",$HOME/.config/ml4w/assets/blank.png";
      };
    };
  };
}
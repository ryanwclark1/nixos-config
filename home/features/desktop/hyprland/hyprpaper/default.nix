{
  inputs,
  pkgs,
  ...
}:

{
  services = {
    hyprpaper = {
      enable = true;
      package = inputs.hyprpaper.packages.${pkgs.stdenv.hostPlatform.system}.default;
      settings = {
        ipc = "on";
        splash = false;
        splash_offset = 2.0;
        # preload = "$HOME/Pictures/wallpapers/default.png";
        # wallpaper = ",$HOME/Pictures/wallpapers/default.png";
      };
    };
  };
}

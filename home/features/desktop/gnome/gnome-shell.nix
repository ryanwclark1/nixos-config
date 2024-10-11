{
  pkgs,
  ...
}:

{
  programs.gnome-shell = {
    enable = true;
    theme = {
      name = "Plata-Noir";
      package = pkgs.plata-theme;
    };
    extensions = [
      {package = pkgs.gnomeExtensions.vitals;}
      {package = pkgs.gnomeExtensions.bing-wallpaper-changer;}
      {package = pkgs.gnomeExtensions.tray-icons-reloaded;}
      {package = pkgs.gnomeExtensions.removable-drive-menu;}
      {package = pkgs.gnomeExtensions.dash-to-panel;}
      {package = pkgs.gnomeExtensions.just-perfection;}
      {package = pkgs.gnomeExtensions.caffeine;}
      {package = pkgs.gnomeExtensions.clipboard-indicator;}
      {package = pkgs.gnomeExtensions.bluetooth-quick-connect;}
      {package = pkgs.gnomeExtensions.pop-shell;}
      {package = pkgs.gnomeExtensions.forge;}
    ];
  };
}
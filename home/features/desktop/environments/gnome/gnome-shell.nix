{
  pkgs,
  ...
}:

{
  # TODO: remove when new upstream release is available


  programs.gnome-shell = {
    enable = true;
    # theme = {
    #   name = "Colloid-Default-Dark-Catppuccin";
    #   package = pkgs.colloid-gtk-theme.override {
    #     colorVariants = [ "dark" ];
    #     # "default" = blue
    #     themeVariants = [ "default" ];
    #     sizeVariants = [ "standard" ];
    #     # "black" = mocha variant
    #     tweaks = [ "catppuccin" "rimless" ];
    #   };
    # };
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
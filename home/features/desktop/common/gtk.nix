{
  config,
  pkgs,
  ...
}:

# rec
{
  gtk = {
    cursorTheme = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 16;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
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
    gtk2 = {
      configLocation = "${config.home.homeDirectory}/.config/gtk-2.0/gtkrc";
      extraConfig = ''
        gtk-application-prefer-dark-theme = 1;
      '';
    };
    gtk3 = {
      bookmarks = [
           "file:///mnt/share"
      ];
      extraConfig = {
        gtk-application-prefer-dark-theme = 1;
        gtk-recent-files-limit = 20;
      };
    };
    gtk4 = {
      extraConfig = {
        gtk-application-prefer-dark-theme = 1;
      };
    };
  };

  # xdg.configFile = {
  #   "gtk-3.0/assets".source =
  #     "${gtk.theme.package}/share/themes/${gtk.theme.name}/gtk-3.0/assets";
  #   "gtk-3.0/gtk.css".source =
  #     "${gtk.theme.package}/share/themes/${gtk.theme.name}/gtk-3.0/gtk.css";
  #   "gtk-3.0/gtk-dark.css".source =
  #     "${gtk.theme.package}/share/themes/${gtk.theme.name}/gtk-3.0/gtk-dark.css";

  #   "gtk-4.0/assets".source =
  #     "${gtk.theme.package}/share/themes/${gtk.theme.name}/gtk-4.0/assets";
  #   "gtk-4.0/gtk.css".source =
  #     "${gtk.theme.package}/share/themes/${gtk.theme.name}/gtk-4.0/gtk.css";
  #   "gtk-4.0/gtk-dark.css".source =
  #     "${gtk.theme.package}/share/themes/${gtk.theme.name}/gtk-4.0/gtk-dark.css";
  # };

  # dconf.settings = {
  #   "org/gnome/desktop/interface" = {
  #     color-scheme = "prefer-dark";
  #   };
  # };
}
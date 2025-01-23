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
    font = {
      name = "DejaVu Sans";
      package = pkgs.dejavu_fonts;
      size = 12;
    };
    gtk2 = {
      configLocation = "${config.home.homeDirectory}/.config/gtk-2.0/gtkrc";
      extraConfig = ''
        gtk-application-prefer-dark-theme = 1
      '';
    };
    gtk3 = {
      bookmarks = [
           "file:///mnt/share"
           "file:///mnt/conf"
           "file:///mnt/sync"
           "file:///mnt/family"
           "file:///mnt/rclark"
           "file:///mnt/ryan"
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
}
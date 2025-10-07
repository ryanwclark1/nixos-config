{
  lib,
  pkgs,
  ...
}:

{
  services = {
    # needed for GNOME services outside of GNOME Desktop
    dbus.packages = with pkgs; [
      gcr
      # gnome-settings-daemon
    ];
    gnome.gnome-keyring.enable = lib.mkDefault true;
    gvfs.enable = lib.mkDefault true;
  };
}

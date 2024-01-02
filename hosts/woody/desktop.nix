# ./host/woody/desktop.nix
{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
   ./gnome
  ];

  services = {
    xserver = {
      enable = true;
      layout = "us";
      xkbVariant = "";

      desktopManager.gnome = {
        enable = true;
      };

      displayManager.gdm = {
        enable = true;
        autoSuspend = false;
      };

    };
    udev.packages = with pkgs; [
      gnome.gnome-settings-daemon
    ];
  };
}

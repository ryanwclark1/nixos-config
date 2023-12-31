# ./host/frametop/desktop.nix
{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./plasma
  ];

  # Enable the X server with the SDDM display manager: and use the modesetting driver.
  services.xserver = {
    enable = true;

    # Enable the Plasma desktop environment.
    desktopManager.plasma5 = {
      enable = true;
      # notoPackage = true;
      # kwinrc = true;
      # wayland = true;
    };

    displayManager = {
      sddm.enable = true;
      defaultSession = "plasmawayland";
      #videoDrivers = [ "modesetting" ]; # For Intel integrated graphics
    };
  };
}
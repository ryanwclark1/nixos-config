{
  config,
  lib,
  ...
}:
with lib;

{
  imports = [
    ./gnomeconfig.nix
  ];

  options.gnome.enable = mkEnableOption "gnome settings";
  config = mkIf config.gnome.enable {
    gnomeconfig.enable = true;
    # Enable the X11 windowing system.
    services.xserver.enable = true;

    # Enable the GNOME Desktop Environment.
    services.xserver.displayManager.gdm.enable = true;
    services.xserver.desktopManager.gnome.enable = true;

    # Configure keymap in X11
    services.xserver = {
      layout = "us";
      xkbVariant = "";
    };
  };
}
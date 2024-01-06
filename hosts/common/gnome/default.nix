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

    services.xserver = {
      enable = true;
      layout = "us";
      # Enable the Plasma Desktop Environment.
      displayManager = {
        gdm = {
          enable = true;
        };
      };
      desktopManager = {
        gnome.enable = true;
      };
    };
  };
}
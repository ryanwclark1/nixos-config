{
  config,
  lib,
  ...
}:
with lib;

{
  imports = [
    ./plasmaconfig.nix
    # ./bismuth.nix
  ];

  options.plasma.enable = mkEnableOption "plasma settings";
  config = mkIf config.plasma.enable {
    plasmaconfig.enable = true;
    # bismuth.enable = true;

    # Enable the X11 windowing system.
    services.xserver.enable = true;

    # Enable the Plasma Desktop Environment.
    services.xserver.displayManager.gdm.enable = true;
    services.xserver.desktopManager.plasma5.enable = true;
    services.xserver.displayManager.defaultSession = "plasmawayland";

    # Configure keymap in X11
    services.xserver = {
      layout = "us";
      xkbVariant = "";
    };
  };
}
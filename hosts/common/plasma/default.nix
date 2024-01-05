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
    services.xserver = {
      enable = true;
      layout = "us";
      desktopManager.plasma5.enable = true;
      # Enable the Plasma Desktop Environment.
      displayManager = {
        defaultSession = "plasmawayland";
        sddm = {
          enable = true;
          wayland.enable = true;
        };
      };
    };
  };
}
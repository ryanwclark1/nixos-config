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

    services.xserver = {
      enable = true;
      layout = "us";
      # Enable the Plasma Desktop Environment.
      displayManager = {
        defaultSession = "plasmawayland";
        sddm = {
          enable = true;
          wayland.enable = true;
        };
      };
      desktopManager = {
        plasma5.enable = true;
      };
    };
  };
}
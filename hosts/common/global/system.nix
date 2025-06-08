{
  lib,
  pkgs,
  ...
}:

{
  # Add system-wide performance improvements
  services = {
    # Enable systemd-oomd for better memory management
    systemd-oomd.enable = true;

    # Enable fstrim for SSD optimization
    fstrim.enable = true;
  };

  # Common hardware settings
  hardware = {
    enableAllFirmware = true;
    enableRedistributableFirmware = true;
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };
}

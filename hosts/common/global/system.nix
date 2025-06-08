{
  lib,
  pkgs,
  ...
}:

{
  # Add system-wide performance improvements
  services = {
    # Enable fstrim for SSD optimization
    fstrim.enable = true;
  };

  # Enable systemd-oomd for better memory management
  systemd.oomd = {
    enable = true;
    enableRootSlice = true;
    enableUserServices = true;
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

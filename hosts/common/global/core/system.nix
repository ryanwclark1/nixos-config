{
  lib,
  pkgs,
  ...
}:

{
  # Add system-wide performance improvements
  services = {
    # Enable fstrim for SSD optimization
    fstrim.enable = lib.mkDefault true;

    # Enable irqbalance for better CPU interrupt handling
    irqbalance.enable = lib.mkDefault true;
  };

  # Enable systemd-oomd for better memory management
  systemd.oomd = {
    enable = lib.mkDefault true;
    enableRootSlice = lib.mkDefault true;
    enableUserSlices = lib.mkDefault true;
  };

  # Common hardware settings
  hardware = {
    enableAllFirmware = lib.mkDefault true;
    enableRedistributableFirmware = lib.mkDefault true;
    graphics = {
      enable = lib.mkDefault true;
      enable32Bit = lib.mkDefault true;
    };
  };
}

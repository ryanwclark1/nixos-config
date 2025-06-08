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

    # Enable automatic system updates
    nixos-update = {
      enable = true;
      channel = "https://nixos.org/channels/nixos-unstable";
    };
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

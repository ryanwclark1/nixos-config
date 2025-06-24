{
  lib,
  pkgs,
  ...
}:

{
  # Enable performance-related services
  services = {
    # Enable fstrim for SSD optimization
    fstrim.enable = true;

    # Enable irqbalance for better CPU interrupt handling
    irqbalance.enable = true;
  };

  # Enable systemd-oomd for better memory management
  # https://github.com/NixOS/nixpkgs/issues/338175
  systemd.oomd.enable = true;

  # Logitech wireless device configuration
  # Based on NixOS Discourse: https://discourse.nixos.org/t/logi-master-mouse-3/18829
  hardware = {
    logitech = {
      wireless = {
        enable = true;
        enableGraphical = true;
      };
    };
  };

  # Common performance-related system packages
  environment.systemPackages = with pkgs; [
    # System monitoring
    btop # Modern system monitor (better than htop)
    htop
    iotop
    nethogs
    smartmontools
    lm_sensors
    s-tui
    upower
    acpi

    # Performance analysis
    sysstat
    perf-tools

    # Hardware tools
    cairo
    sbctl
    pciutils
    usbutils
    lshw
    lsof

    # Development tools
    git
    wget
  ];
}

{
  pkgs,
  ...
}:

# Core system packages that are useful on all systems
# Additional system statistics in home/features/sys-stats
{
  environment.systemPackages = with pkgs; [
    # System monitoring
    btop  # Modern system monitor
    iotop
    nethogs
    smartmontools
    lm_sensors

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

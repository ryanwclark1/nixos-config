{
  pkgs,
  ...
}:

# Core system packages that are useful on all systems
# Additional system statistics in home/features/sys-stats
{
  environment.systemPackages = with pkgs; [
    # System monitoring
    htop
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

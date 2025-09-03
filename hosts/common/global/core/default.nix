{
  pkgs,
  ...
}:

{
  imports = [
    ./boot.nix
    ./system.nix
    ./locale.nix
    ./logging.nix
    ./environment.nix
  ];

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

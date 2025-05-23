{
  pkgs,
  ...
}:

# Core system packages that are useful on all systems
# Additional system statistics in home/features/sys-stats
{
  environment.systemPackages = with pkgs; [
    cairo
    sbctl # Secure Boot key manager
    git
    wget
    lm_sensors # Tools for reading hardware sensors
    pciutils # lspci
    usbutils # lsusb
    lshw # Hardware lister
    lsof # List open files
    # base16-schemes # Base16 color schemes
    sops
    ssh-to-age
  ];
}

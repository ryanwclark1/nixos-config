# ./host/common/global/bluetooth.nix
{
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [ bluez bluetui ];

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # Blueman is a GTK+ Bluetooth Manager
  services.blueman.enable = true;
}

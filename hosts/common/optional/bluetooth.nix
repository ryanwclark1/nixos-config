# ./host/common/global/bluetooth.nix
{
  ...
}:

{
  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };
  # Blueman is a GTK+ Bluetooth Manager
  # services.blueman.enable = true;
}

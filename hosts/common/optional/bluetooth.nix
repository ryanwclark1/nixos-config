# ./host/common/global/bluetooth.nix
{
  pkgs,
  ...
}:

{
  hardware.bluetooth = {
    enable = true;
    package = pkgs.bluez;
    powerOnBoot = true;
    settings = {
      General = {
        Name = "Hello";
        ControllerMode = "dual";
        FastConnectable = "true";
        Experimental = "true";
      };
      Policy = {
        AutoEnable = "true";
      };
    };
  };

  # Blueman is a GTK+ Bluetooth Manager
  services.blueman.enable = true;
}

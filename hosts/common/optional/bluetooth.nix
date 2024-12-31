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
        ControllerMode = "dual";
        FastConnectable = "true";
        Experimental = "true";
      };
      Policy = {
        AutoEnable = "true";
      };
    };
  };

  environment.systemPackages = [
    pkgs.bluez-tools
  ];
  # Blueman is a GTK+ Bluetooth Manager
  services.blueman.enable = true;
}

# ./host/common/global/bluetooth.nix
{
  pkgs,
  ...
}:

{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    # settings = {
    #   General = {
    #     Class = "0x000100";
    #     ControllerMode = "dual";
    #     FastConnectable = "true";
    #     JustWorksRepairing = "always";
    #     Privacy = "device";
    #     # Battery info for Bluetooth devices
    #     Experimental = "true";
    #   };
    #   Policy = {
    #     AutoEnable = "true";
    #   };
    # };
  };

  # Blueman is a GTK+ Bluetooth Manager
  services.blueman.enable = true;
}

# ./host/common/global/bluetooth.nix
{
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    bluez
    bluetui
    bluez-tools
  ];

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Class = "0x200414";
      };
    };
  };

  # Enable BlueZ service
  services.blueman.enable = true;
}

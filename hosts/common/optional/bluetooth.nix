# ./host/common/global/bluetooth.nix
{
  ...
}:

{
  hardware = {
    bluetooth = {
      enable = true;
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
  };
  # Blueman is a GTK+ Bluetooth Manager
  services.blueman.enable = true;
}

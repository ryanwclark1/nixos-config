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
  services.blueman.enable = true;
}

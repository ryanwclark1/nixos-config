# ./host/common/global/bluetooth.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

{
  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };
  services.blueman.enable = true;
}

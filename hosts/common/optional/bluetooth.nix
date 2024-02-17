# ./host/common/global/bluetooth.nix
{ lib
, pkgs
, config
, ...
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

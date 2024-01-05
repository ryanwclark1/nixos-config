# ./host/common/global/bluetooth.nix
{
  lib,
  pkgs,
  config,
  ...
}:
with lib;

{
  options.bluetooth.enable = mkEnableOption "bluetooth settings";

  config = mkIf config.bluetooth.enable {

    hardware = {
      bluetooth = {
        enable = true;
        powerOnBoot = true;
      };
    };
    services.blueman.enable = true;
  };

}
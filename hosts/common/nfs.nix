# ./host/common/global/nfs.nix
{
  lib,
  pkgs,
  config,
  ...
}:
with lib;

{
  options.nfs.enable = mkEnableOption "nfs settings";

  config = mkIf config.nfs.enable {
    
    services.autofs = {
      enable = true;
      debug = true;

      autoMaster =
        let
          mapConf = pkgs.writeText "auto.mnt" ''
            share -fstype=nfs4,rw,soft,intr tank.techcasa.io:/mnt/tank/share
            users -fstype=nfs4,rw,soft,intr tank.techcasa.io:/mnt/tank/users
            morningstar -fstype=nfs4,rw,soft,intr tank.techcasa.io:/mnt/tank/morningstar
          '';
        in
        ''
          /mnt ${mapConf}
        '';
    };
  };

}
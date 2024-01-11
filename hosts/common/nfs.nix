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
          # intr param depricated in nfs4
          mapConf = pkgs.writeText "auto.mnt" ''
            share -fstype=nfs4,rw,soft tank.techcasa.io:/mnt/tank/share
            users -fstype=nfs4,rw,soft tank.techcasa.io:/mnt/tank/users
            morningstar -fstype=nfs4,rw,soft tank.techcasa.io:/mnt/tank/morningstar
            apps -fstype=nfs4,rw,soft tank.techcasa.io:/mnt/sophiatank/apps
            sync -fstype=nfs4,rw,soft tank.techcasa.io:/mnt/tank/sync
          '';
        in
        ''
          /mnt ${mapConf}
        '';
    };
  };

}
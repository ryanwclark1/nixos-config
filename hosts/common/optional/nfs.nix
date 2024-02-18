# ./host/common/global/nfs.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

{
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
}

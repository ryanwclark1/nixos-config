# ./host/common/global/optional/nfs.nix
{
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    nfs-utils
  ];

  services.autofs = {
    enable = true;

    autoMaster =
      let
        # intr param depricated in nfs4
        mapConf = pkgs.writeText "auto.mnt" ''
          share -fstype=nfs4,rw,soft 10.10.100.210:/mnt/tank/share
          scans -fstype=nfs4,rw,soft 10.10.100.210:/mnt/tank/scans
          rclark -fstype=nfs4,rw,soft 10.10.100.210:/mnt/tank/users/rclark
          ryan -fstype=nfs4,rw,soft 10.10.100.210:/mnt/tank/users/ryan
          apps -fstype=nfs4,rw,soft 10.10.100.210:/mnt/apptank/apps
          sync -fstype=nfs4,rw,soft 10.10.100.210:/mnt/tank/sync
        '';
      in
      ''
        /mnt ${mapConf}
      '';
  };
}


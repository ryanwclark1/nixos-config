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
          conf -fstype=nfs4,rw,soft 10.10.100.210:/mnt/apptank/conf
          sync -fstype=nfs4,rw,soft 10.10.100.210:/mnt/tank/sync
          family -fstype=nfs4,rw,soft 10.10.100.210:/mnt/tank/users/family
        '';
      in
      ''
        /mnt ${mapConf}
      '';
  };
}


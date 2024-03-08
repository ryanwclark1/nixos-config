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
    debug = true;

    autoMaster =
      let
        # intr param depricated in nfs4
        mapConf = pkgs.writeText "auto.mnt" ''
          share -fstype=nfs4,rw,soft 10.10.100.210:/mnt/tank/share
          users -fstype=nfs4,rw,soft 10.10.100.210:/mnt/tank/users
          rclark -fstype=nfs4,rw,soft 10.10.100.210:/mnt/tank/users/rclark
          morningstar -fstype=nfs4,rw,soft 10.10.100.210:/mnt/tank/morningstar
          # apps -fstype=nfs4,rw,soft 10.10.100.210:/mnt/sophiatank/apps
          sync -fstype=nfs4,rw,soft 10.10.100.210:/mnt/tank/sync
        '';
      in
      ''
        /mnt ${mapConf}
      '';
  };
}

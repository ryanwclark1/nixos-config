# ./host/common/global/optional/nfs.nix
{
  pkgs,
  ...
}:

{
  nixpkgs.overlays = [
    (
      final: prev: {
        autofs5 = prev.autofs5.overrideAttrs (_: pattr: {
          patches =
            pattr.patches
            ++ [
              (prev.fetchpatch {
                url = "mirror://kernel/linux/daemons/autofs/v5/patches-5.2.0/autofs-5.1.9-Fix-incompatible-function-pointer-types-in-cyrus-sasl-module.patch";
                hash = "sha256-erLlqZtVmYqUOsk3S7S50yA0VB8Gzibsv+X50+gcA58=";
              })
            ];
        });
      }
    )
  ];

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


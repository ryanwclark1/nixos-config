{
  pkgs,
  lib,
  config,
  ...
}:

with lib; {
  home.packages = with pkgs; [
    gparted
    dosfstools
    mtools
    ntfs3g
    btrfs-progs
    jmtpfs
    jdupes
  ];
}
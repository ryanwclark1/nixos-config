{
  lib,
  pkgs,
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
    ncdu # TUI disk usage
  ];
}

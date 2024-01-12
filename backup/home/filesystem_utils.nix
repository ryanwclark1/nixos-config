{
  pkgs,
  lib,
  config,
  ...
}:

with lib; {
  options.filesystem_utils.enable = mkEnableOption "filesystem utilities settings";

  config = mkIf config.filesystem_utils.enable {
    home.packages = with pkgs; [
      gparted
      dosfstools
      mtools
      ntfs3g
      btrfs-progs
      jmtpfs
      jdupes
    ];
  };
}
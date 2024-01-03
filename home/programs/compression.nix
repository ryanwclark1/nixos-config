{
  pkgs,
  lib,
  config,
  ...
}:
with lib; {
  options.compression.enable = mkEnableOption "compression settings";

  config = mkIf config.compression.enable {
    home.packages = with pkgs; [
      p7zip # needed for 7z files
      zip
      rar
      pigz
      atool
      xz
      zstd
      zpaq
    ];
  };
}
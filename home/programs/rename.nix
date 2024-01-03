{
  pkgs,
  config,
  lib,
  ...
}:
with lib; {
  options.rename.enable = mkEnableOption "renamer settings";

  config = mkIf config.rename.enable {
    home.packages = with pkgs; [
      detox # to sanitize filenames
      vimv-rs
    ];
  };
}
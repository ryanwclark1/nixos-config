{
  pkgs,
  lib,
  config,
  ...
}:
with lib; {
  options.android.enable = mkEnableOption "android settings";

  config = mkIf config.android.enable {
    home.packages = with pkgs; [
      android-file-transfer
    ];
  };
}
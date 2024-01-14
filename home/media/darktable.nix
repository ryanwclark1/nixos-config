{
  pkgs,
  lib,
  config,
  ...
}:
with lib; {
  options.darktable.enable = mkEnableOption "darktable settings";

  config = mkIf config.darktable.enable {
    home.packages = with pkgs; [
      darktable
    ];
  };
}
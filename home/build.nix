{
  pkgs,
  lib,
  config,
  ...
}:
with lib; {
  options.build.enable = mkEnableOption "build settings";

  config = mkIf config.build.enable {
    home.packages = with pkgs; [
      gnumake
    ];
  };
}
{
  pkgs,
  config,
  lib,
  ...
}:
with lib; {
  options.office.enable = mkEnableOption "office settings";

  config = mkIf config.office.enable {
    home.packages = with pkgs; [
      libreoffice-still
    ];
  };
}

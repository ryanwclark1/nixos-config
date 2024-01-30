{
  lib,
  pkgs,
  config,
  ...
}:

with lib; {
  options.office.enable = mkEnableOption "office settings";

  config = mkIf config.office.enable {
    home.packages = with pkgs; [
      libreoffice-fresh
      libreoffice-qt
    ];
  };
}

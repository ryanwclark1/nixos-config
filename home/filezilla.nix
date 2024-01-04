# A lightweight and flexible command-line JSON processor

{
  lib,
  pkgs,
  config,
  ...
}:

with lib; {
  options.filezilla.enable = mkEnableOption "filezilla settings";

  config = mkIf config.filezilla.enable {
    programs.filezilla = {
      enable = true;
    };
  };
}
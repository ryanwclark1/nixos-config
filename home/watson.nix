{
  pkgs,
  lib,
  config,
  ...
}:

with lib; {
  options.watson.enable = mkEnableOption "watson settings";

  config = mkIf config.watson.enable {
    programs.watson = {
      enable = true;
      enableZshIntegration = true;
      enableFishIntegration = true;

      # settings.options = {};
    };
  };
}

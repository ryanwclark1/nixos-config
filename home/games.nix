{
  pkgs,
  lib,
  config,
  ...
}:

with lib; {
  options.games.enable = mkEnableOption "games settings";

  config = mkIf config.games.enable {
    home.packages = with pkgs; [
      lutris
      dolphinEmu
      heroic
    ];

  };
}

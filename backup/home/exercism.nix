#Education

{
  pkgs,
  lib,
  config,
  ...
}:

with lib; {
  options.exercism.enable = mkEnableOption "exercism settings";

  config = mkIf config.exercism.enable {
    home.packages = with pkgs; [
      exercism
    ];
  };
}
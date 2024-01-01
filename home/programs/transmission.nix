{
  lib,
  pkgs,
  config,
  ...
}:
with lib; {
  options.transmission.enable = mkEnableOption "transmission settings";

  config = mkIf config.transmission.enable {
    home.packages = with pkgs; [
      transmission
    ];
  };
}


# {
#  programs.transmission = {
#    enable = true;
#    settings = {
#    };
#  };
#}
{
  lib,
  pkgs,
  config,
  ...
}:
with lib; {
  options.transmission.enable = mkEnableOption "transmission settings";

  config = mkIf config.transmission.enable {
    programs.transmission = {
      enable = true;
#    settings = {
#    };
    };
  };
}


# {

#}
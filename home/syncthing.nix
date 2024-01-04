{
  config,
  lib,
  ...
}:
with lib; {
  options.syncthing.enable = mkEnableOption "syncthing settings";

  config = mkIf config.syncthing.enable {
    services.syncthing = {
      enable = true;
    };
  };
}

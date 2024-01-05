{
  lib,
  config,
  ...
}:

with lib; {
  options.udiskie.enable = mkEnableOption "udiskie settings";

  config = mkIf config.udiskie.enable {
    services.udiskie = {
      enable = true;
      tray = "audo";
      notify = true;
      automount = true;
      # https://github.com/coldfix/udiskie/blob/master/doc/udiskie.8.txt#configuration
      # file written to $XDG_CONFIG_HOME/udiskie/config.yml
      # settings = {};
    };
  };
}
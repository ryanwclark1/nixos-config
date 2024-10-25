{
  pkgs,
  ...
}:

{
  services.trayscale = {
    enable = true;
    package = pkgs.trayscale;
    hideWindow = false;
    # settings = {
    #   general = {
    #     after_sleep_cmd = "trayscale -d"; # to avoid having to press a key twice to turn on the display.
    #     before_sleep_cmd = "loginctl lock-session"; # lock before suspend.
    #     ignore_dbus_inhibit = false;
    #     lock_cmd = "pidof trayscale || trayscale"; # avoid starting multiple trayscale instances.
    #   };

    #   listener = [
    #     {
    #       timeout = 900;
    #       on-timeout = "trayscale";
    #     }
    #     # dpms
    #     {
    #       timeout = 1200;
    #       on-timeout = "trayscale -d";
    #       on-resume = "trayscale";
    #     }
    #     # Suspend
    #     # {
    #     #   # SUSPEND TIMEOUT
    #     #   timeout = 20000;
    #     #   #SUSPEND ONTIMEOUT
    #     #   on-timeout = "systemctl suspend";
    #     # }
    #   ];
    # };
  };
}
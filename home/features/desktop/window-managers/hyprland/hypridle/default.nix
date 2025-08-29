{
  pkgs,
  ...
}:

{
  services = {
    hypridle = {
      enable = true;
      package = pkgs.hypridle;
      settings =
      {
        general = {
          lock_cmd = "pidof hyprlock || hyprlock"; # avoid starting multiple hyprlock instances.
          before_sleep_cmd = "loginctl lock-session"; # lock before suspend.
          after_sleep_cmd = "hyprctl dispatch dpms on"; # to avoid having to press a key twice to turn on the display.
          ignore_dbus_inhibit = false;
        };
        listener = [
          {
            timeout = 1000;
            on-timeout = "loginctl lock-session";
          }
          # dpms
          {
            timeout = 1800;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
          # Suspend
          # {
          #   # SUSPEND TIMEOUT
          #   timeout = 20000;
          #   #SUSPEND ONTIMEOUT
          #   on-timeout = "systemctl suspend";
          # }
        ];
      };
    };
  };
}
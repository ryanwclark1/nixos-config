{ pkgs, ... }:

{
  services = {
    hypridle = {
      enable = true;
      package = pkgs.hypridle;
      settings =
      {
        general = {
          after_sleep_cmd = "hyprctl dispatch dpms on"; # to avoid having to press a key twice to turn on the display.
          before_sleep_cmd = "loginctl lock-session"; # lock before suspend.
          ignore_dbus_inhibit = false;
          lock_cmd = "pidof hyprlock || hyprlock"; # avoid starting multiple hyprlock instances.
        };

        listener = [
          {
            timeout = 900;
            on-timeout = "hyprlock";
          }
          # dpms
          {
            timeout = 1200;
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
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
          after_sleep_cmd = "hyprctl dispatch dpms on"; # to avoid having to press a key twice to turn on the display.
          before_sleep_cmd = "loginctl lock-session"; # lock before suspend.
          ignore_dbus_inhibit = false;
          lock_cmd = "pidof hyprlock || hyprlock"; # avoid starting multiple hyprlock instances.
        };

        listener = [
          {
            timeout = 975;                            # 9 min
            on-timeout = notify-send "You are idle!"; # command to run when timeout has passed
            on-resume = notify-send "Welcome back!"; # command to run when user is back

          }
          {
            timeout = 1000;
            on-timeout = "loginctl lock-session";
          }
          # dpms
          {
            timeout = 2000;
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
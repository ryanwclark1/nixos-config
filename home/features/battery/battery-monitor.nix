{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Configuration options
  options.features.battery-monitor = {
    enable = lib.mkEnableOption "battery monitor service";
    
    threshold = lib.mkOption {
      type = lib.types.int;
      default = 10;
      description = "Battery percentage threshold for low battery warnings";
    };
    
    interval = lib.mkOption {
      type = lib.types.int;
      default = 30;
      description = "Check interval in seconds";
    };
  };

  # Module configuration
  config = {
    # Only enable if this is actually a laptop with a battery
    systemd.user.services.battery-monitor = lib.mkIf config.features.battery-monitor.enable {
    Unit = {
      Description = "Battery Monitor - Low Battery Notification Service";
      After = [ "graphical-session.target" ];
      Wants = [ "graphical-session.target" ];
    };

    Service = {
      Type = "oneshot";
      
      ExecStart = pkgs.writeShellScript "battery-monitor" ''
        PATH="${pkgs.coreutils}/bin:${pkgs.upower}/bin:${pkgs.libnotify}/bin:${pkgs.gawk}/bin:${pkgs.gnugrep}/bin:${pkgs.gnused}/bin:$PATH"
        
        # Configuration
        BATTERY_THRESHOLD=${toString config.features.battery-monitor.threshold}
        NOTIFICATION_FLAG="/run/user/$UID/battery_monitor_notified"
        
        # Function to get battery percentage
        get_battery_percentage() {
          upower -i $(upower -e | grep 'BAT') | grep -E "percentage" | grep -o '[0-9]\+%' | sed 's/%//'
        }
        
        # Function to get battery state
        get_battery_state() {
          upower -i $(upower -e | grep 'BAT') | grep -E "state" | awk '{print $2}'
        }
        
        # Function to send notification
        send_notification() {
          notify-send -u critical "󱐋 Time to recharge!" "Battery is down to $1%" -i battery-caution -t 30000
        }
        
        # Check if battery exists (laptop detection)
        if ! upower -e | grep -q 'BAT'; then
          echo "No battery detected - skipping battery monitor"
          exit 0
        fi
        
        # Get current battery status
        BATTERY_LEVEL=$(get_battery_percentage)
        BATTERY_STATE=$(get_battery_state)
        
        # Validate battery level is a number
        if ! [[ "$BATTERY_LEVEL" =~ ^[0-9]+$ ]]; then
          echo "Could not determine battery level"
          exit 1
        fi
        
        echo "Battery: $BATTERY_LEVEL% ($BATTERY_STATE)"
        
        # Check if battery is low and discharging
        if [[ "$BATTERY_STATE" == "discharging" && "$BATTERY_LEVEL" -le "$BATTERY_THRESHOLD" ]]; then
          if [[ ! -f "$NOTIFICATION_FLAG" ]]; then
            echo "Battery is low ($BATTERY_LEVEL%) and discharging - sending notification"
            send_notification "$BATTERY_LEVEL"
            touch "$NOTIFICATION_FLAG"
          else
            echo "Battery is low ($BATTERY_LEVEL%) but notification already sent"
          fi
        else
          # Clear notification flag when battery is charging or above threshold
          if [[ -f "$NOTIFICATION_FLAG" ]]; then
            echo "Battery status improved - clearing notification flag"
            rm -f "$NOTIFICATION_FLAG"
          fi
        fi
      '';
      
      # Environment for notifications
      Environment = [
        "DISPLAY=:0"
      ];
    };
  };

    # Timer to run battery check
    systemd.user.timers.battery-monitor = lib.mkIf config.features.battery-monitor.enable {
      Unit = {
        Description = "Battery Monitor Timer";
        Requires = [ "battery-monitor.service" ];
      };

      Timer = {
        OnBootSec = "1min";
        OnUnitActiveSec = "${toString config.features.battery-monitor.interval}sec";
        AccuracySec = "10sec";
      };

      Install = {
        WantedBy = [ "timers.target" ];
      };
    };

    # Ensure required packages are available when enabled
    home.packages = lib.mkIf config.features.battery-monitor.enable (with pkgs; [
      upower      # Battery status information
      libnotify   # Desktop notifications
    ]);
  };
}
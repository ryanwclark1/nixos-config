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
        # Use the shared os-battery-monitor script with configurable threshold
        # The script uses os-battery-lib.sh for robust battery detection with multiple fallback methods
        PATH="${pkgs.coreutils}/bin:${pkgs.upower}/bin:${pkgs.libnotify}/bin:${pkgs.gawk}/bin:${pkgs.gnugrep}/bin:${pkgs.gnused}/bin:${pkgs.acpi}/bin:$PATH"

        # Configuration - override default threshold
        export BATTERY_THRESHOLD=${toString config.features.battery-monitor.threshold}

        # Use the shared os-battery-monitor script if available
        if command -v os-battery-monitor >/dev/null 2>&1; then
          os-battery-monitor
        elif [[ -f "$HOME/.local/bin/scripts/system/os-battery-monitor.sh" ]]; then
          bash "$HOME/.local/bin/scripts/system/os-battery-monitor.sh"
        else
          # Fallback to inline implementation if script not found
          NOTIFICATION_FLAG="/run/user/$UID/battery_monitor_notified"

          # Source the battery library if available
          if [[ -f "$HOME/.local/bin/scripts/system/os-battery-lib.sh" ]]; then
            source "$HOME/.local/bin/scripts/system/os-battery-lib.sh"
            BATTERY_LEVEL=$(get_battery_percentage || echo "")
            BATTERY_STATE=$(get_battery_state || echo "")
          else
            # Fallback to upower
            if ! upower -e | grep -q 'BAT'; then
              echo "No battery detected - skipping battery monitor"
              exit 0
            fi
            BATTERY_LEVEL=$(upower -i $(upower -e | grep 'BAT') | grep -E "percentage" | grep -o '[0-9]\+%' | sed 's/%//')
            BATTERY_STATE=$(upower -i $(upower -e | grep 'BAT') | grep -E "state" | awk '{print $2}')
          fi

          # Validate battery level is a number
          if ! [[ "$BATTERY_LEVEL" =~ ^[0-9]+$ ]]; then
            echo "Could not determine battery level"
            exit 1
          fi

          echo "Battery: $BATTERY_LEVEL% ($BATTERY_STATE)"

          # Normalize state for comparison
          case "$BATTERY_STATE" in
            "charging") BATTERY_STATE="Charging" ;;
            "discharging") BATTERY_STATE="Discharging" ;;
            "fully-charged"|"full") BATTERY_STATE="Full" ;;
          esac

          # Check if battery is low and discharging
          if [[ "$BATTERY_STATE" == "Discharging" && "$BATTERY_LEVEL" -le "$BATTERY_THRESHOLD" ]]; then
            if [[ ! -f "$NOTIFICATION_FLAG" ]]; then
              echo "Battery is low ($BATTERY_LEVEL%) and discharging - sending notification"
              notify-send -u critical "󱐋 Time to recharge!" "Battery is down to $BATTERY_LEVEL%" -i battery-caution -t 30000
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
      acpi        # Alternative battery detection method (used by shared library)
      gawk        # AWK for parsing battery information
      gnugrep     # grep for battery detection
    ]);
  };
}

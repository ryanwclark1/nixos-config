#!/bin/bash

set -euo pipefail

# Designed to be run by systemd timer every 30 seconds and alerts if battery is low
# Uses shared battery library for robust detection with multiple fallback methods
# Threshold can be overridden via BATTERY_THRESHOLD environment variable

readonly BATTERY_THRESHOLD="${BATTERY_THRESHOLD:-10}"
readonly NOTIFICATION_FLAG="/run/user/${UID:-1000}/os_battery_notified"

# Source the shared battery library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if source "${SCRIPT_DIR}/os-battery-lib.sh" 2>/dev/null; then
    # Use shared library functions
    BATTERY_LEVEL=$(get_battery_percentage || echo "")
    BATTERY_STATE=$(get_battery_state || echo "")
else
    # Fallback to direct upower calls if library not available
    BATTERY_LEVEL=$(os-battery-remaining 2>/dev/null || echo "")
    BATTERY_DEVICE=$(upower -e 2>/dev/null | grep 'BAT' | head -1 || echo "")
    BATTERY_STATE=""

    if [[ -n "$BATTERY_DEVICE" ]]; then
        BATTERY_STATE=$(upower -i "$BATTERY_DEVICE" 2>/dev/null | grep -E "state" | awk '{print $2}' || echo "")
    fi

    # Normalize state for comparison
    case "$BATTERY_STATE" in
        "charging") BATTERY_STATE="Charging" ;;
        "discharging") BATTERY_STATE="Discharging" ;;
        "fully-charged"|"full") BATTERY_STATE="Full" ;;
    esac
fi

send_notification() {
  notify-send -u critical "󱐋 Time to recharge!" "Battery is down to ${1}%" -i battery-caution -t 30000
  os-hook battery-low "$1" 2>/dev/null || true
}

# Check if we have a battery
if ! has_battery 2>/dev/null; then
    # No battery detected (desktop system) - exit silently
    exit 0
fi

if [[ -n "$BATTERY_LEVEL" && "$BATTERY_LEVEL" =~ ^[0-9]+$ ]]; then
  # Normalize state for comparison (handle both upower and normalized formats)
  local normalized_state="$BATTERY_STATE"
  case "$BATTERY_STATE" in
      "charging") normalized_state="Charging" ;;
      "discharging") normalized_state="Discharging" ;;
      "fully-charged"|"full") normalized_state="Full" ;;
  esac

  if [[ "$normalized_state" == "Discharging" ]] && (( BATTERY_LEVEL <= BATTERY_THRESHOLD )); then
    if [[ ! -f "$NOTIFICATION_FLAG" ]]; then
      send_notification "$BATTERY_LEVEL"
      touch "$NOTIFICATION_FLAG"
    fi
  else
    rm -f "$NOTIFICATION_FLAG"
  fi
fi

#!/usr/bin/env bash

# Show current battery status as notification

# Check if battery exists
if [ ! -d /sys/class/power_supply/BAT* ] 2>/dev/null; then
  notify-send "⚡ Power Status" "No battery detected (desktop system)"
  exit 0
fi

# Get battery info
BATTERY_PATH=$(echo /sys/class/power_supply/BAT*)
CAPACITY=$(cat "$BATTERY_PATH/capacity" 2>/dev/null || echo "Unknown")
STATUS=$(cat "$BATTERY_PATH/status" 2>/dev/null || echo "Unknown")

# Choose icon based on status and capacity
if [ "$STATUS" = "Charging" ]; then
  ICON="🔌"
  STATUS_TEXT="Charging"
elif [ "$STATUS" = "Full" ]; then
  ICON="✅"
  STATUS_TEXT="Fully Charged"
elif [ "$STATUS" = "Discharging" ]; then
  if [ "$CAPACITY" -gt 80 ]; then
    ICON="🔋"
  elif [ "$CAPACITY" -gt 50 ]; then
    ICON="🔋"
  elif [ "$CAPACITY" -gt 20 ]; then
    ICON="🪫"
  else
    ICON="⚠️"
  fi
  STATUS_TEXT="Discharging"
else
  ICON="🔋"
  STATUS_TEXT="$STATUS"
fi

# Calculate remaining time estimate (if discharging)
if [ "$STATUS" = "Discharging" ] && [ -f "$BATTERY_PATH/power_now" ] && [ -f "$BATTERY_PATH/energy_now" ]; then
  POWER_NOW=$(cat "$BATTERY_PATH/power_now")
  ENERGY_NOW=$(cat "$BATTERY_PATH/energy_now")

  if [ "$POWER_NOW" -gt 0 ]; then
    HOURS_LEFT=$((ENERGY_NOW / POWER_NOW))
    MINUTES_LEFT=$(((ENERGY_NOW * 60 / POWER_NOW) % 60))
    TIME_INFO="\nEstimated: ${HOURS_LEFT}h ${MINUTES_LEFT}m remaining"
  else
    TIME_INFO=""
  fi
else
  TIME_INFO=""
fi

# Send notification
notify-send "$ICON Battery Status" "Level: ${CAPACITY}%\nStatus: ${STATUS_TEXT}${TIME_INFO}"

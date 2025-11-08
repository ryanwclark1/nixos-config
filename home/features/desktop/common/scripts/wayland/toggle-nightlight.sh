#!/usr/bin/env bash

# Toggle hyprsunset nightlight mode on/off

# Default temperature values
ON_TEMP=4000
OFF_TEMP=6000

# Ensure hyprsunset is running
if ! pgrep -x hyprsunset > /dev/null; then
  setsid uwsm app -- hyprsunset &
  sleep 1 # Give it time to register
fi

# Query the current temperature
CURRENT_TEMP=$(hyprctl hyprsunset temperature 2>/dev/null | grep -oE '[0-9]+')

if [[ "$CURRENT_TEMP" == "$OFF_TEMP" ]]; then
  hyprctl hyprsunset temperature $ON_TEMP
  notify-send "🌙 Nightlight" "Screen temperature: ${ON_TEMP}K (warm)"
else
  hyprctl hyprsunset temperature $OFF_TEMP
  notify-send "☀️ Daylight" "Screen temperature: ${OFF_TEMP}K (cool)"
fi

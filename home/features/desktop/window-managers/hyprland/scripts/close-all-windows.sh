#!/usr/bin/env bash

# Close all windows in Hyprland

# Get all window addresses
windows=$(hyprctl clients -j | jq -r '.[].address')

if [[ -z "$windows" ]]; then
  notify-send "Close All Windows" "No windows to close" -t 1000
  exit 0
fi

window_count=$(echo "$windows" | wc -l)

# Close each window
echo "$windows" | while read -r address; do
  [[ -n "$address" ]] && hyprctl dispatch closewindow address:"$address"
done

notify-send "Close All Windows" "Closed $window_count windows" -t 2000
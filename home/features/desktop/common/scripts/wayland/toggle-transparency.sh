#!/usr/bin/env bash

# Toggle window transparency/opacity for the active window

ADDRESS=$(hyprctl activewindow -j | jq -r '.address')

if [ -z "$ADDRESS" ] || [ "$ADDRESS" = "null" ]; then
  notify-send "No Active Window" "No window to toggle transparency"
  exit 1
fi

hyprctl dispatch setprop "address:$ADDRESS" opaque toggle

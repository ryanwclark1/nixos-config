#!/usr/bin/env bash

# Pop window out - make it floating and pinned (always on top across workspaces)

ADDRESS=$(hyprctl activewindow -j | jq -r '.address')

if [ -z "$ADDRESS" ] || [ "$ADDRESS" = "null" ]; then
  notify-send "No Active Window" "No window to pop out"
  exit 1
fi

# Make window floating if it isn't already
IS_FLOATING=$(hyprctl activewindow -j | jq -r '.floating')
if [ "$IS_FLOATING" = "false" ]; then
  hyprctl dispatch togglefloating
fi

# Pin the window
hyprctl dispatch pin
notify-send "Window Pinned" "Window will stay visible across all workspaces"

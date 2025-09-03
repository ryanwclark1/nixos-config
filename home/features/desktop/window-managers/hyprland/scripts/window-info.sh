#!/usr/bin/env bash

# Get window information for current active window

window_info=$(hyprctl activewindow -j 2>/dev/null)

if [[ -n "$window_info" && "$window_info" != "null" ]]; then
  echo "Active Window Information:"
  echo "========================="
  echo "Title: $(echo "$window_info" | jq -r '.title // "Unknown"')"
  echo "Class: $(echo "$window_info" | jq -r '.class // "Unknown"')" 
  echo "PID: $(echo "$window_info" | jq -r '.pid // "Unknown"')"
  echo "Workspace: $(echo "$window_info" | jq -r '.workspace.name // "Unknown"')"
  echo "Position: $(echo "$window_info" | jq -r '.at[0]'),$(echo "$window_info" | jq -r '.at[1]')"
  echo "Size: $(echo "$window_info" | jq -r '.size[0]')x$(echo "$window_info" | jq -r '.size[1]')"
  echo "Floating: $(echo "$window_info" | jq -r '.floating // false')"
  echo "Fullscreen: $(echo "$window_info" | jq -r '.fullscreen // false')"
else
  echo "No active window found"
fi
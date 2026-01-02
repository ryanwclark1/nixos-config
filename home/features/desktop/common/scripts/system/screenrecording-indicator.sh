#!/usr/bin/env bash

# Screen recording indicator for Waybar
# Returns JSON output indicating if screen recording is active

if pgrep -f "^gpu-screen-recorder" >/dev/null; then
  echo '{"text": "󰻂", "tooltip": "Stop recording", "class": "active"}'
else
  echo '{"text": ""}'
fi


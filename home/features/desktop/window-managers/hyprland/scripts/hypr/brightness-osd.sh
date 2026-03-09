#!/usr/bin/env bash

# Brightness control and OSD script

set -euo pipefail

# Check if brightnessctl is available
if ! command -v brightnessctl >/dev/null 2>&1; then
    exit 0
fi

# Execute the requested brightness command
action="$1"
if [[ "$action" == "up" ]]; then
    brightnessctl -q set +10%
elif [[ "$action" == "down" ]]; then
    brightnessctl -q set 10%-
else
    echo "Usage: $0 [up|down]"
    exit 1
fi

# Get the new brightness percentage
# brightnessctl -m format: device,class,current,percentage,max
# e.g. intel_backlight,backlight,120,4%,3000
percentage=$(brightnessctl -m | awk -F, '{print substr($4, 0, length($4)-1)}')

# Show OSD using quickshell IPC if available
if command -v quickshell >/dev/null 2>&1; then
    quickshell ipc call Osd showBrightness "$percentage" >/dev/null 2>&1 || true
fi

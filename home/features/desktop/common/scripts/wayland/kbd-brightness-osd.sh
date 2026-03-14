#!/usr/bin/env bash

# Keyboard backlight brightness control and OSD script
# Steps ±1 raw unit (keyboard backlights are typically discrete 0–3 steps)

set -euo pipefail

# Check if brightnessctl is available
if ! command -v brightnessctl >/dev/null 2>&1; then
    exit 0
fi

# Find keyboard backlight device
device=""
for candidate in /sys/class/leds/*kbd_backlight*; do
    [[ -e $candidate ]] && device="$(basename "$candidate")" && break
done
[[ -z $device ]] && exit 0

max=$(brightnessctl -d "$device" max 2>/dev/null || echo 0)
[[ $max -eq 0 ]] && exit 0

action="${1:-up}"
if [[ "$action" == "up" ]]; then
    brightnessctl -d "$device" set +1 -q
elif [[ "$action" == "down" ]]; then
    brightnessctl -d "$device" set 1- -q
else
    echo "Usage: $0 [up|down]" >&2
    exit 1
fi

current=$(brightnessctl -d "$device" get 2>/dev/null || echo 0)
percent=$((current * 100 / max))

# Show OSD using quickshell IPC if available
if command -v quickshell >/dev/null 2>&1; then
    quickshell ipc call Osd showKbdBrightness "$percent" >/dev/null 2>&1 || true
fi

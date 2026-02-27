#!/usr/bin/env bash

set -euo pipefail

# Check required commands
if ! command -v hyprctl >/dev/null 2>&1; then
    echo "Error: hyprctl not found" >&2
    exit 1
fi

# Get active window class
active_window_json=$(hyprctl activewindow -j 2>/dev/null || echo "{}")
if [[ -z "$active_window_json" || "$active_window_json" == "{}" ]]; then
    # No active window, just kill active
    hyprctl dispatch killactive ""
    exit 0
fi

# Check if jq is available for parsing
if command -v jq >/dev/null 2>&1; then
    window_class=$(echo "$active_window_json" | jq -r ".class // empty" 2>/dev/null || echo "")
else
    # Fallback: try to extract class from JSON manually
    window_class=$(echo "$active_window_json" | grep -o '"class":"[^"]*"' | cut -d'"' -f4 || echo "")
fi

# Handle Steam window specially
if [[ "$window_class" == "Steam" ]]; then
    if command -v ydotool >/dev/null 2>&1; then
        active_window=$(ydotool getactivewindow 2>/dev/null || echo "")
        if [[ -n "$active_window" ]]; then
            ydotool windowunmap "$active_window" 2>/dev/null || true
        else
            hyprctl dispatch killactive ""
        fi
    else
        # Fallback if ydotool not available
        hyprctl dispatch killactive ""
    fi
else
    hyprctl dispatch killactive ""
fi

#!/usr/bin/env bash

# SwayOSD Caps Lock indicator with proper state detection
# This script detects the actual caps lock state and shows appropriate OSD

set -euo pipefail

# Check if SwayOSD is available
if ! command -v swayosd-client >/dev/null 2>&1; then
    # Silently exit if SwayOSD is not available
    exit 0
fi

# Get caps lock state
get_caps_state() {
    # Method 1: Check via xset (most reliable on X11/Wayland)
    if command -v xset >/dev/null 2>&1; then
        if xset q 2>/dev/null | grep -q "Caps Lock:.*on"; then
            echo "on"
            return 0
        else
            echo "off"
            return 0
        fi
    fi

    # Method 2: Check via /sys/class/leds (Linux specific)
    local caps_led_path="/sys/class/leds"
    local caps_led_file
    caps_led_file=$(find "$caps_led_path" -name "*capslock*" -o -name "*caps*" 2>/dev/null | head -n1 || echo "")

    if [[ -n "$caps_led_file" && -r "$caps_led_file/brightness" ]]; then
        local brightness
        brightness=$(cat "$caps_led_file/brightness" 2>/dev/null || echo "0")
        if [[ "$brightness" == "1" ]]; then
            echo "on"
            return 0
        else
            echo "off"
            return 0
        fi
    fi

    # Method 3: Try to read from keyboard device (fallback)
    # This is less reliable but may work in some cases
    if command -v setleds >/dev/null 2>&1; then
        if setleds -L +caps 2>/dev/null | grep -q "on"; then
            echo "on"
            return 0
        else
            echo "off"
            return 0
        fi
    fi

    # If we can't determine state, return unknown
    echo "unknown"
    return 1
}

# Show OSD notification
show_osd() {
    # SwayOSD will handle the state toggle internally
    # We just need to trigger it
    if swayosd-client --caps-lock &>/dev/null; then
        return 0
    else
        # If SwayOSD fails, try to show a notification as fallback
        if command -v notify-send >/dev/null 2>&1; then
            local state
            state=$(get_caps_state || echo "toggled")
            notify-send -t 1000 -u low "Caps Lock" "Caps Lock: $state" 2>/dev/null || true
        fi
        return 1
    fi
}

# Main function
main() {
    # Get current state (for logging/debugging, but SwayOSD handles the toggle)
    local current_state
    current_state=$(get_caps_state || echo "unknown")

    # Show OSD (SwayOSD will toggle the state internally)
    show_osd
}

main "$@"

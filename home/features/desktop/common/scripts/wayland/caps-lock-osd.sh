#!/usr/bin/env bash

# Caps Lock indicator with proper state detection
# This script toggles Caps Lock and shows the new state in the OSD

set -euo pipefail

# Get caps lock state
get_caps_state() {
    # Method 1: Check via /sys/class/leds (most reliable on Wayland/Linux)
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

    # Method 2: Check via xset (fallback for X11/Wayland compatibility)
    if command -v xset >/dev/null 2>&1; then
        if xset q 2>/dev/null | grep -q "Caps Lock:.*on"; then
            echo "on"
            return 0
        else
            echo "off"
            return 0
        fi
    fi

    # Method 3: Try to read from keyboard device (fallback)
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

# Toggle Caps Lock
toggle_caps_lock() {
    # Method 1: Use ydotool (Wayland)
    if command -v ydotool >/dev/null 2>&1; then
        ydotool key 0x3A >/dev/null 2>&1 && return 0
    fi

    # Method 2: Use wtype (Wayland alternative)
    if command -v wtype >/dev/null 2>&1; then
        wtype -k Caps_Lock >/dev/null 2>&1 && return 0
    fi

    # Method 3: Use xdotool (X11/Wayland compatibility)
    if command -v xdotool >/dev/null 2>&1; then
        xdotool key Caps_Lock >/dev/null 2>&1 && return 0
    fi

    # Method 4: Use xkb-switch (if available)
    if command -v xkb-switch >/dev/null 2>&1; then
        # xkb-switch doesn't directly toggle, but we can use setxkbmap
        if command -v setxkbmap >/dev/null 2>&1; then
            # Toggle via setxkbmap (less reliable)
            return 1
        fi
    fi

    return 1
}

# Show OSD notification
show_osd() {
    local state="$1"

    # Try quickshell IPC
    if command -v quickshell >/dev/null 2>&1; then
        if quickshell ipc call Osd showCapslock "$state" >/dev/null 2>&1; then
            return 0
        fi
    fi

    # Fallback to notify-send
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -t 1000 -u low "Caps Lock" "Caps Lock: $state" 2>/dev/null || true
    fi
    return 1
}

# Main function
main() {
    # Get current state before toggle
    local current_state
    current_state=$(get_caps_state || echo "off")

    # Toggle Caps Lock
    if ! toggle_caps_lock; then
        # If toggle failed, try to read state anyway (key might have been toggled by system)
        # Wait a brief moment for state to update
        sleep 0.05
    else
        # Wait for state to update after toggle
        sleep 0.05
    fi

    # Get new state after toggle
    local new_state
    new_state=$(get_caps_state || echo "unknown")

    # If we couldn't determine new state, invert the old one
    if [[ "$new_state" == "unknown" ]]; then
        if [[ "$current_state" == "on" ]]; then
            new_state="off"
        else
            new_state="on"
        fi
    fi

    # Show OSD with new state
    show_osd "$new_state"
}

main "$@"

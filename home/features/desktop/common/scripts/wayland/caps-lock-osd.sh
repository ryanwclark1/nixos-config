#!/usr/bin/env bash

# Caps Lock OSD indicator
# The binding is non-consuming (bindn), so XKB handles the actual toggle.
# This script only reads the resulting state and shows the OSD.

set -euo pipefail

# Brief delay for XKB state to settle after key press
sleep 0.05

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

    # Method 2: Check via hyprctl (Hyprland compositor state)
    if command -v hyprctl >/dev/null 2>&1; then
        if hyprctl devices -j 2>/dev/null | grep -q '"capsLock": true'; then
            echo "on"
        else
            echo "off"
        fi
        return 0
    fi

    # Method 3: Check via xset (fallback for X11/Wayland compatibility)
    if command -v xset >/dev/null 2>&1; then
        if xset q 2>/dev/null | grep -q "Caps Lock:.*on"; then
            echo "on"
            return 0
        else
            echo "off"
            return 0
        fi
    fi

    # Method 4: Try to read from keyboard device (fallback)
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

state=$(get_caps_state || echo "unknown")

# Show OSD notification
if [[ "$state" != "unknown" ]] && command -v quickshell >/dev/null 2>&1; then
    quickshell ipc call Osd showCapslock "$state" >/dev/null 2>&1 || true
elif command -v notify-send >/dev/null 2>&1; then
    notify-send -t 1000 -u low "Caps Lock" "Caps Lock: $state" 2>/dev/null || true
fi

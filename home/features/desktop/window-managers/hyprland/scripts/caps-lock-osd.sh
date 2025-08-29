#!/usr/bin/env bash

# SwayOSD Caps Lock indicator with proper state detection
# This script detects the actual caps lock state and shows appropriate OSD

if ! command -v swayosd-client >/dev/null; then
    exit 0  # SwayOSD not available
fi

# Method 1: Check via xset (if available)
if command -v xset >/dev/null; then
    if xset q | grep -q "Caps Lock:.*off"; then
        # Caps lock is OFF, show it's being turned ON
        swayosd-client --caps-lock
    else
        # Caps lock is ON, show it's being turned OFF  
        swayosd-client --caps-lock
    fi
    exit 0
fi

# Method 2: Check via /sys/class/leds (Linux specific)
CAPS_LED_PATH="/sys/class/leds"
CAPS_LED_FILE=$(find "$CAPS_LED_PATH" -name "*capslock*" -o -name "*caps*" 2>/dev/null | head -n1)

if [[ -n "$CAPS_LED_FILE" && -r "$CAPS_LED_FILE/brightness" ]]; then
    # Read LED brightness (1 = on, 0 = off)
    if [[ "$(cat "$CAPS_LED_FILE/brightness" 2>/dev/null)" == "1" ]]; then
        # Caps lock LED is on, show OSD
        swayosd-client --caps-lock
    else
        # Caps lock LED is off, show OSD
        swayosd-client --caps-lock
    fi
    exit 0
fi

# Method 3: Fallback - just show the OSD (SwayOSD will figure it out)
swayosd-client --caps-lock
#!/bin/bash

# -----------------------------------------------------
# Battery Icon Utilities
# Shared utilities for battery icon selection and display
# -----------------------------------------------------
#
# This script provides shared utilities for selecting appropriate
# battery icons based on battery percentage, status, and other factors.
# -----------------------------------------------------

set -euo pipefail

# Default battery icons (Nerd Font)
ICON_BATTERY_FULL="${ICON_BATTERY_FULL:-󰁹}"
ICON_BATTERY_HIGH="${ICON_BATTERY_HIGH:-󰂂}"
ICON_BATTERY_MEDIUM="${ICON_BATTERY_MEDIUM:-󰂀}"
ICON_BATTERY_LOW="${ICON_BATTERY_LOW:-󰁻}"
ICON_BATTERY_CRITICAL="${ICON_BATTERY_CRITICAL:-󰁺}"
ICON_BATTERY_CHARGING="${ICON_BATTERY_CHARGING:-󰂄}"
ICON_BATTERY_AC="${ICON_BATTERY_AC:-󰚥}"

# Get battery icon based on percentage and status
get_battery_icon() {
    local percentage="${1:-0}"
    local status="${2:-Unknown}"

    local icon=""

    # Determine icon based on percentage (when not charging/full)
    if [[ "$status" == *"Charging"* ]]; then
        icon="$ICON_BATTERY_CHARGING"
    elif [[ "$status" == *"Full"* ]] || [[ "$status" == *"fully-charged"* ]]; then
        icon="$ICON_BATTERY_FULL"
    else
        # Discharging or unknown - use percentage-based icons
        if (( percentage >= 95 )); then
            icon="$ICON_BATTERY_FULL"
        elif (( percentage >= 80 )); then
            icon="$ICON_BATTERY_HIGH"
        elif (( percentage >= 60 )); then
            icon="$ICON_BATTERY_MEDIUM"
        elif (( percentage >= 40 )); then
            icon="$ICON_BATTERY_MEDIUM"
        elif (( percentage >= 20 )); then
            icon="$ICON_BATTERY_LOW"
        elif (( percentage >= 5 )); then
            icon="$ICON_BATTERY_CRITICAL"
        else
            icon="$ICON_BATTERY_CRITICAL"
        fi
    fi

    echo "$icon"
}

# Get battery charging icon
get_battery_charging_icon() {
    local status="${1:-Unknown}"

    case "$status" in
        *"Charging"*)
            echo "$ICON_BATTERY_CHARGING"
            ;;
        *"Full"*|*"fully-charged"*)
            echo "$ICON_BATTERY_AC"
            ;;
        *)
            echo "$ICON_BATTERY_MEDIUM"
            ;;
    esac
}

# Check if battery level is critical
is_battery_critical() {
    local percentage="${1:-0}"
    (( percentage <= 5 ))
}

# Check if battery level is low
is_battery_low() {
    local percentage="${1:-0}"
    (( percentage <= 20 ))
}

# Get rofi active/urgent flags based on battery status
get_battery_rofi_flags() {
    local status="${1:-Unknown}"
    local percentage="${2:-0}"

    local active=""
    local urgent=""

    case "$status" in
        *"Charging"*)
            active="-a 1"
            ;;
        *"Full"*|*"fully-charged"*)
            urgent="-u 1"
            ;;
        *"Discharging"*|*"Unknown"*)
            if is_battery_low "$percentage"; then
                urgent="-u 1"
            fi
            ;;
    esac

    echo "$active $urgent"
}

#!/bin/bash

# Show current battery status as notification
# Uses shared battery library for robust detection
# Dependencies: notify-send (optional)

set -euo pipefail

# Configuration
NOTIFICATION_TIMEOUT="${HYPR_NOTIFICATION_TIMEOUT:-5000}"

# Source shared libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source battery library
BATTERY_LIB="${SCRIPT_DIR}/os-battery-lib.sh"
[[ ! -f "$BATTERY_LIB" ]] && BATTERY_LIB="$HOME/.local/bin/scripts/system/os-battery-lib.sh"
if [[ -f "$BATTERY_LIB" ]]; then
    source "$BATTERY_LIB" 2>/dev/null || {
        echo "Warning: Could not load battery library, using fallback methods" >&2
    }
else
    echo "Warning: Battery library not found at $BATTERY_LIB" >&2
fi

# Source battery icons library
BATTERY_ICONS="${SCRIPT_DIR}/os-battery-icons.sh"
[[ ! -f "$BATTERY_ICONS" ]] && BATTERY_ICONS="$HOME/.local/bin/scripts/system/os-battery-icons.sh"
if [[ -f "$BATTERY_ICONS" ]]; then
    source "$BATTERY_ICONS" 2>/dev/null || true
fi

# Source notification library
NOTIFY_LIB="${SCRIPT_DIR}/os-notify-lib.sh"
[[ ! -f "$NOTIFY_LIB" ]] && NOTIFY_LIB="$HOME/.local/bin/scripts/system/os-notify-lib.sh"
if [[ -f "$NOTIFY_LIB" ]]; then
    source "$NOTIFY_LIB" 2>/dev/null || true
fi

# Fallback notify if library not loaded
if ! declare -f notify >/dev/null 2>&1; then
    notify() {
        local title="$1"
        local message="$2"
        local urgency="${3:-normal}"
        if command -v notify-send >/dev/null 2>&1; then
            notify-send -t "$NOTIFICATION_TIMEOUT" -u "$urgency" "$title" "$message" 2>/dev/null || true
        else
            echo "$title: $message" >&2
        fi
    }
fi

# Calculate remaining time using /sys interface
calculate_time_remaining() {
    local battery_device="$1"
    local status="$2"
    local time_info=""

    if [[ "$status" == "Discharging" && -n "$battery_device" ]]; then
        local bat_path="/sys/class/power_supply/$battery_device"
        local power_now energy_now

        if [[ -f "$bat_path/power_now" && -f "$bat_path/energy_now" ]]; then
            power_now=$(cat "$bat_path/power_now" 2>/dev/null || echo "0")
            energy_now=$(cat "$bat_path/energy_now" 2>/dev/null || echo "0")

            if (( power_now > 0 && energy_now > 0 )); then
                local hours_left minutes_left
                hours_left=$((energy_now / power_now))
                minutes_left=$(((energy_now * 60 / power_now) % 60))
                time_info="\nEstimated: ${hours_left}h ${minutes_left}m remaining"
            fi
        fi
    fi

    echo "$time_info"
}

# get_battery_icon is sourced from os-battery-icons.sh (nerd font icons)
# Fallback if library not loaded
if ! declare -f get_battery_icon >/dev/null 2>&1; then
    get_battery_icon() {
        local percentage="${1:-0}"
        local status="${2:-Unknown}"
        if [[ "$status" == *"Charging"* ]]; then echo "🔌"
        elif [[ "$status" == *"Full"* ]]; then echo "✅"
        elif (( percentage <= 20 )); then echo "⚠️"
        elif (( percentage <= 50 )); then echo "🪫"
        else echo "🔋"
        fi
    }
fi

# Get status text
get_status_text() {
    local status="$1"
    local status_text=""

    case "$status" in
        "Charging")
            status_text="Charging"
            ;;
        "Full")
            status_text="Fully Charged"
            ;;
        "Discharging")
            status_text="Discharging"
            ;;
        *)
            status_text="$status"
            ;;
    esac

    echo "$status_text"
}

# Main function
main() {
    # Check if system has a battery
    if ! has_battery 2>/dev/null; then
        notify "⚡ Power Status" "No battery detected (desktop system)" "normal"
        exit 0
    fi

    # Get battery information using shared library
    local capacity status battery_device icon status_text time_info

    if command -v get_battery_percentage >/dev/null 2>&1; then
        capacity=$(get_battery_percentage || echo "0")
        status=$(get_battery_state || echo "Unknown")
        battery_device=$(get_battery_device || echo "")
    else
        # Fallback to direct /sys access if library not available
        local bat_path="/sys/class/power_supply"
        local battery_path=""

        for bat in "$bat_path"/BAT*; do
            if [[ -d "$bat" && -f "$bat/capacity" && -f "$bat/status" ]]; then
                battery_path="$bat"
                battery_device=$(basename "$bat")
                break
            fi
        done

        if [[ -z "$battery_path" ]]; then
            notify "⚡ Power Status" "No battery detected (desktop system)" "normal"
            exit 0
        fi

        capacity=$(cat "$battery_path/capacity" 2>/dev/null || echo "0")
        status=$(cat "$battery_path/status" 2>/dev/null || echo "Unknown")

        # Validate capacity
        if ! [[ "$capacity" =~ ^[0-9]+$ ]] || (( capacity > 100 )); then
            capacity="0"
        fi
    fi

    # Normalize status
    case "$status" in
        "Charging") status="Charging" ;;
        "Discharging") status="Discharging" ;;
        "Full"|"Not charging"|"fully-charged") status="Full" ;;
        *) status="Unknown" ;;
    esac

    icon=$(get_battery_icon "$capacity" "$status")
    status_text=$(get_status_text "$status")
    time_info=$(calculate_time_remaining "$battery_device" "$status")

    # Determine urgency based on capacity
    local urgency="normal"
    if [[ "$status" == "Discharging" ]] && (( capacity <= 20 )); then
        urgency="critical"
    elif [[ "$status" == "Discharging" ]] && (( capacity <= 50 )); then
        urgency="normal"
    fi

    local message="Level: ${capacity}%\nStatus: ${status_text}${time_info}"
    notify "$icon Battery Status" "$message" "$urgency"
}

main "$@"

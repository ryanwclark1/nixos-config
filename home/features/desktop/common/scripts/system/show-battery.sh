#!/usr/bin/env bash

# Show current battery status as notification
# Dependencies: notify-send (optional)

set -euo pipefail

# Configuration
NOTIFICATION_TIMEOUT="${HYPR_NOTIFICATION_TIMEOUT:-5000}"

# Notification wrapper
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

# Find battery device
find_battery() {
    local bat_path="/sys/class/power_supply"
    local battery=""

    # Try to find first battery
    for bat in "$bat_path"/BAT*; do
        if [[ -d "$bat" && -f "$bat/capacity" && -f "$bat/status" ]]; then
            battery="$bat"
            break
        fi
    done

    echo "$battery"
}

# Get battery capacity
get_capacity() {
    local battery_path="$1"
    local capacity

    if [[ -f "$battery_path/capacity" ]]; then
        capacity=$(cat "$battery_path/capacity" 2>/dev/null || echo "0")
        # Validate capacity is numeric
        if ! [[ "$capacity" =~ ^[0-9]+$ ]] || [[ "$capacity" -gt 100 ]]; then
            capacity="0"
        fi
    else
        capacity="0"
    fi

    echo "$capacity"
}

# Get battery status
get_status() {
    local battery_path="$1"
    local status

    if [[ -f "$battery_path/status" ]]; then
        status=$(cat "$battery_path/status" 2>/dev/null || echo "Unknown")
    else
        status="Unknown"
    fi

    echo "$status"
}

# Calculate remaining time
calculate_time_remaining() {
    local battery_path="$1"
    local status="$2"
    local time_info=""

    if [[ "$status" == "Discharging" ]]; then
        local power_now energy_now

        if [[ -f "$battery_path/power_now" && -f "$battery_path/energy_now" ]]; then
            power_now=$(cat "$battery_path/power_now" 2>/dev/null || echo "0")
            energy_now=$(cat "$battery_path/energy_now" 2>/dev/null || echo "0")

            if [[ "$power_now" -gt 0 && "$energy_now" -gt 0 ]]; then
                local hours_left minutes_left
                hours_left=$((energy_now / power_now))
                minutes_left=$(((energy_now * 60 / power_now) % 60))
                time_info="\nEstimated: ${hours_left}h ${minutes_left}m remaining"
            fi
        fi
    fi

    echo "$time_info"
}

# Get battery icon based on status and capacity
get_battery_icon() {
    local status="$1"
    local capacity="$2"
    local icon=""

    case "$status" in
        "Charging")
            icon="🔌"
            ;;
        "Full")
            icon="✅"
            ;;
        "Discharging")
            if [[ "$capacity" -gt 80 ]]; then
                icon="🔋"
            elif [[ "$capacity" -gt 50 ]]; then
                icon="🔋"
            elif [[ "$capacity" -gt 20 ]]; then
                icon="🪫"
            else
                icon="⚠️"
            fi
            ;;
        *)
            icon="🔋"
            ;;
    esac

    echo "$icon"
}

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
    local battery_path
    battery_path=$(find_battery)

    if [[ -z "$battery_path" ]]; then
        notify "⚡ Power Status" "No battery detected (desktop system)" "normal"
        exit 0
    fi

    local capacity status icon status_text time_info
    capacity=$(get_capacity "$battery_path")
    status=$(get_status "$battery_path")
    icon=$(get_battery_icon "$status" "$capacity")
    status_text=$(get_status_text "$status")
    time_info=$(calculate_time_remaining "$battery_path" "$status")

    # Determine urgency based on capacity
    local urgency="normal"
    if [[ "$status" == "Discharging" && "$capacity" -le 20 ]]; then
        urgency="critical"
    elif [[ "$status" == "Discharging" && "$capacity" -le 50 ]]; then
        urgency="normal"
    fi

    local message="Level: ${capacity}%\nStatus: ${status_text}${time_info}"
    notify "$icon Battery Status" "$message" "$urgency"
}

main "$@"

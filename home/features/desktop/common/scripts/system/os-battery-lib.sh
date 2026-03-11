#!/bin/bash

## Shared Battery Utility Library
## Provides robust battery detection and information retrieval
## Supports multiple detection methods with automatic fallback

set -euo pipefail

# Battery detection methods in order of preference
# 1. acpi (most detailed, includes time estimates)
# 2. /sys/class/power_supply (direct kernel interface)
# 3. upower (DBus-based, works on most systems)

# Get battery device path using upower
get_battery_device_upower() {
    local device
    device=$(upower -e 2>/dev/null | grep -E 'BAT' | head -1 || echo "")
    echo "$device"
}

# Get battery device path from /sys
get_battery_device_sys() {
    local bat_path="/sys/class/power_supply"
    local battery=""

    if [[ -d "$bat_path" ]]; then
        for bat_dir in "$bat_path"/BAT*; do
            if [[ -d "$bat_dir" && -f "$bat_dir/capacity" && -f "$bat_dir/status" ]]; then
                battery="$(basename "$bat_dir")"
                echo "$battery"
                return 0
            fi
        done
    fi
    echo ""
}

# Get battery percentage using acpi
get_battery_percentage_acpi() {
    if ! command -v acpi >/dev/null 2>&1; then
        echo ""
        return 1
    fi

    local acpi_output
    acpi_output=$(acpi -b 2>/dev/null | head -n1 || echo "")

    if [[ -z "$acpi_output" ]]; then
        echo ""
        return 1
    fi

    local percentage
    percentage=$(echo "$acpi_output" | cut -d',' -f2 | tr -d ' %,' || echo "")

    # Validate percentage is numeric
    if [[ -n "$percentage" && "$percentage" =~ ^[0-9]+$ ]] && (( percentage <= 100 )); then
        echo "$percentage"
        return 0
    fi

    echo ""
    return 1
}

# Get battery percentage using /sys
get_battery_percentage_sys() {
    local battery_device="$1"
    local bat_path="/sys/class/power_supply/$battery_device"

    if [[ ! -f "$bat_path/capacity" ]]; then
        echo ""
        return 1
    fi

    local percentage
    percentage=$(cat "$bat_path/capacity" 2>/dev/null || echo "")

    # Validate percentage
    if [[ -n "$percentage" && "$percentage" =~ ^[0-9]+$ ]] && [[ "$percentage" -le 100 ]]; then
        echo "$percentage"
        return 0
    fi

    echo ""
    return 1
}

# Get battery percentage using upower
get_battery_percentage_upower() {
    local device="$1"

    if [[ -z "$device" ]]; then
        device=$(get_battery_device_upower)
    fi

    if [[ -z "$device" ]]; then
        echo ""
        return 1
    fi

    local percentage
    percentage=$(upower -i "$device" 2>/dev/null | awk -F: '/percentage/ {
        gsub(/[%[:space:]]/, "", $2);
        val=$2;
        printf("%d\n", (val+0.5))
        exit
    }' || echo "")

    # Validate percentage
    if [[ -n "$percentage" && "$percentage" =~ ^[0-9]+$ ]] && [[ "$percentage" -le 100 ]]; then
        echo "$percentage"
        return 0
    fi

    echo ""
    return 1
}

# Get battery state using acpi
get_battery_state_acpi() {
    if ! command -v acpi >/dev/null 2>&1; then
        echo ""
        return 1
    fi

    local acpi_output
    acpi_output=$(acpi -b 2>/dev/null | head -n1 || echo "")

    if [[ -z "$acpi_output" ]]; then
        echo ""
        return 1
    fi

    local status
    status=$(echo "$acpi_output" | cut -d',' -f1 | cut -d':' -f2 | tr -d ' ' || echo "")

    # Normalize status
    case "$status" in
        *"Charging"*) echo "Charging" ;;
        *"Discharging"*) echo "Discharging" ;;
        *"Full"*|*"Not charging"*) echo "Full" ;;
        *) echo "Unknown" ;;
    esac

    return 0
}

# Get battery state using /sys
get_battery_state_sys() {
    local battery_device="$1"
    local bat_path="/sys/class/power_supply/$battery_device"

    if [[ ! -f "$bat_path/status" ]]; then
        echo ""
        return 1
    fi

    local status
    status=$(cat "$bat_path/status" 2>/dev/null || echo "")

    # Normalize status
    case "$status" in
        "Charging") echo "Charging" ;;
        "Discharging") echo "Discharging" ;;
        "Full"|"Not charging") echo "Full" ;;
        *) echo "Unknown" ;;
    esac

    return 0
}

# Get battery state using upower
get_battery_state_upower() {
    local device="$1"

    if [[ -z "$device" ]]; then
        device=$(get_battery_device_upower)
    fi

    if [[ -z "$device" ]]; then
        echo ""
        return 1
    fi

    local status
    status=$(upower -i "$device" 2>/dev/null | grep -E "state" | awk '{print $2}' || echo "")

    # Convert upower status to normalized format
    case "$status" in
        "charging") echo "Charging" ;;
        "discharging") echo "Discharging" ;;
        "fully-charged"|"full") echo "Full" ;;
        *) echo "Unknown" ;;
    esac

    return 0
}

# Main function: Get battery percentage with automatic fallback
get_battery_percentage() {
    local percentage=""

    # Try acpi first
    percentage=$(get_battery_percentage_acpi)
    if [[ -n "$percentage" ]]; then
        echo "$percentage"
        return 0
    fi

    # Try /sys
    local battery_device
    battery_device=$(get_battery_device_sys)
    if [[ -n "$battery_device" ]]; then
        percentage=$(get_battery_percentage_sys "$battery_device")
        if [[ -n "$percentage" ]]; then
            echo "$percentage"
            return 0
        fi
    fi

    # Try upower
    percentage=$(get_battery_percentage_upower "")
    if [[ -n "$percentage" ]]; then
        echo "$percentage"
        return 0
    fi

    # No battery found or accessible
    echo ""
    return 1
}

# Main function: Get battery state with automatic fallback
get_battery_state() {
    local state=""

    # Try acpi first
    state=$(get_battery_state_acpi)
    if [[ -n "$state" && "$state" != "Unknown" ]]; then
        echo "$state"
        return 0
    fi

    # Try /sys
    local battery_device
    battery_device=$(get_battery_device_sys)
    if [[ -n "$battery_device" ]]; then
        state=$(get_battery_state_sys "$battery_device")
        if [[ -n "$state" && "$state" != "Unknown" ]]; then
            echo "$state"
            return 0
        fi
    fi

    # Try upower
    state=$(get_battery_state_upower "")
    if [[ -n "$state" && "$state" != "Unknown" ]]; then
        echo "$state"
        return 0
    fi

    # No battery found or accessible
    echo ""
    return 1
}

# Main function: Get battery device with automatic fallback
get_battery_device() {
    local device=""

    # Try /sys first (most reliable)
    device=$(get_battery_device_sys)
    if [[ -n "$device" ]]; then
        echo "$device"
        return 0
    fi

    # Try upower
    device=$(get_battery_device_upower)
    if [[ -n "$device" ]]; then
        echo "$device"
        return 0
    fi

    # No battery found
    echo ""
    return 1
}

# Get battery capacity in Wh using upower
get_battery_capacity_upower() {
    local device="$1"

    if [[ -z "$device" ]]; then
        device=$(get_battery_device_upower)
    fi

    if [[ -z "$device" ]]; then
        echo ""
        return 1
    fi

    local capacity
    capacity=$(upower -i "$device" 2>/dev/null | awk '/energy-full:/ {
        printf "%d", $2
        exit
    }' || echo "")

    # Validate capacity
    if [[ -n "$capacity" && "$capacity" =~ ^[0-9]+$ ]]; then
        echo "$capacity"
        return 0
    fi

    echo ""
    return 1
}

# Get battery capacity in Wh using /sys
get_battery_capacity_sys() {
    local battery_device="$1"
    local bat_path="/sys/class/power_supply/$battery_device"

    # Try energy_full_design first, then energy_full
    local energy_file=""
    if [[ -f "$bat_path/energy_full_design" ]]; then
        energy_file="$bat_path/energy_full_design"
    elif [[ -f "$bat_path/energy_full" ]]; then
        energy_file="$bat_path/energy_full"
    else
        echo ""
        return 1
    fi

    local energy_wh
    energy_wh=$(cat "$energy_file" 2>/dev/null || echo "")

    # Convert from µWh to Wh (divide by 1,000,000)
    if [[ -n "$energy_wh" && "$energy_wh" =~ ^[0-9]+$ ]]; then
        local capacity
        capacity=$((energy_wh / 1000000))
        echo "$capacity"
        return 0
    fi

    echo ""
    return 1
}

# Get battery power rate in W using upower
get_battery_power_rate_upower() {
    local device="$1"

    if [[ -z "$device" ]]; then
        device=$(get_battery_device_upower)
    fi

    if [[ -z "$device" ]]; then
        echo ""
        return 1
    fi

    local power_rate
    power_rate=$(upower -i "$device" 2>/dev/null | awk '/energy-rate/ {
        rounded = sprintf("%.1f", $2)
        sub(/\.0$/, "", rounded)
        print rounded
        exit
    }' || echo "")

    if [[ -n "$power_rate" ]]; then
        echo "$power_rate"
        return 0
    fi

    echo ""
    return 1
}

# Get battery time remaining using upower
get_battery_time_remaining_upower() {
    local device="$1"

    if [[ -z "$device" ]]; then
        device=$(get_battery_device_upower)
    fi

    if [[ -z "$device" ]]; then
        echo ""
        return 1
    fi

    local battery_info
    battery_info=$(upower -i "$device" 2>/dev/null)

    if [[ -z "$battery_info" ]]; then
        echo ""
        return 1
    fi

    local time_str
    time_str=$(echo "$battery_info" | awk '/time to (empty|full)/ {
        hours = int($4)
        minutes = int(($4 - hours) * 60)
        if (minutes > 0) {
            printf "%dh %dm", hours, minutes
        } else {
            printf "%dh", hours
        }
        exit
    }' || echo "")

    if [[ -n "$time_str" ]]; then
        echo "$time_str"
        return 0
    fi

    echo ""
    return 1
}

# Main function: Get battery capacity in Wh with automatic fallback
get_battery_capacity() {
    local capacity=""

    # Try upower first (most reliable for Wh)
    local device
    device=$(get_battery_device_upower)
    if [[ -n "$device" ]]; then
        capacity=$(get_battery_capacity_upower "$device")
        if [[ -n "$capacity" ]]; then
            echo "$capacity"
            return 0
        fi
    fi

    # Try /sys
    local battery_device
    battery_device=$(get_battery_device_sys)
    if [[ -n "$battery_device" ]]; then
        capacity=$(get_battery_capacity_sys "$battery_device")
        if [[ -n "$capacity" ]]; then
            echo "$capacity"
            return 0
        fi
    fi

    # No capacity found
    echo ""
    return 1
}

# Main function: Get battery power rate in W with automatic fallback
get_battery_power_rate() {
    local power_rate=""

    # Try upower (only reliable source for power rate)
    local device
    device=$(get_battery_device_upower)
    if [[ -n "$device" ]]; then
        power_rate=$(get_battery_power_rate_upower "$device")
        if [[ -n "$power_rate" ]]; then
            echo "$power_rate"
            return 0
        fi
    fi

    # No power rate found
    echo ""
    return 1
}

# Main function: Get battery time remaining with automatic fallback
get_battery_time_remaining() {
    local time_str=""

    # Try upower (most reliable for time estimates)
    local device
    device=$(get_battery_device_upower)
    if [[ -n "$device" ]]; then
        time_str=$(get_battery_time_remaining_upower "$device")
        if [[ -n "$time_str" ]]; then
            echo "$time_str"
            return 0
        fi
    fi

    # No time estimate found
    echo ""
    return 1
}

# Check if system has a battery
has_battery() {
    local device
    device=$(get_battery_device)
    if [[ -n "$device" ]]; then
        return 0
    fi
    return 1
}

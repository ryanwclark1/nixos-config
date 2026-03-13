#!/usr/bin/env bash
# Pure battery functions for tmux-forceline
# Source this file — not meant to be executed directly

# Guard: skip if already loaded via source_helpers.sh (which includes common.sh)
if [[ -z "${FL_VERSION:-}" ]]; then
    source "${FORCELINE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null && pwd)}/utils/pure_helpers.sh"
fi

# Get battery status (charging, discharging, charged, etc.)
battery_status() {
    if command_exists "pmset"; then
        pmset -g batt | awk -F '; *' 'NR==2 { print $2 }'
    elif command_exists "acpi"; then
        acpi -b | awk '{gsub(/,/, ""); print tolower($3); exit}'
    elif command_exists "upower"; then
        local battery
        battery=$(upower -e | grep -E 'battery|DisplayDevice' | tail -n1)
        if [ -n "$battery" ]; then
            upower -i "$battery" | awk '/state/ {print $2}'
        fi
    elif command_exists "apm"; then
        local battery
        battery=$(apm -a)
        if [ "$battery" -eq 0 ]; then
            echo "discharging"
        elif [ "$battery" -eq 1 ]; then
            echo "charging"
        fi
    elif command_exists "termux-battery-status" && command_exists "jq"; then
        termux-battery-status | jq -er '.status | ascii_downcase'
    elif is_wsl; then
        local battery
        battery=$(find /sys/class/power_supply/*/status 2>/dev/null | tail -n1)
        if [ -n "$battery" ]; then
            awk '{print tolower($0);}' "$battery"
        fi
    fi
}

# Get battery percentage
battery_percentage() {
    if command_exists "pmset"; then
        pmset -g batt | grep -o "[0-9]\{1,3\}%"
    elif command_exists "acpi"; then
        acpi -b | grep -m 1 -Eo "[0-9]+%"
    elif command_exists "upower"; then
        local battery
        battery=$(upower -e | grep -E 'battery|DisplayDevice' | tail -n1)
        if [ -z "$battery" ]; then
            return
        fi
        local percentage
        percentage=$(upower -i "$battery" | awk '/percentage:/ {print $2}')
        if [ -n "$percentage" ]; then
            echo "${percentage%.*%}"
            return
        fi
        local energy energy_full
        energy=$(upower -i "$battery" | awk '/energy:/ {sum+=$2} END {print sum}')
        energy_full=$(upower -i "$battery" | awk '/energy-full:/ {sum+=$2} END {print sum}')
        if [ -n "$energy" ] && [ -n "$energy_full" ]; then
            echo "$energy $energy_full" | awk '{printf("%d%%", ($1/$2)*100)}'
        fi
    elif command_exists "termux-battery-status" && command_exists "jq"; then
        termux-battery-status | jq -r '.percentage' | awk '{printf("%d%%", $1)}'
    elif command_exists "apm"; then
        apm -l | awk '{printf("%d%%", $1)}'
    elif is_wsl; then
        local battery
        battery=$(find /sys/class/power_supply/*/capacity 2>/dev/null | tail -n1)
        if [ -n "$battery" ]; then
            cat "$battery" | awk '{printf("%d%%", $1)}'
        fi
    fi
}

# Get battery color based on status and level
get_battery_color() {
    local color_type="${1:-bg}"
    local percentage="${2:-}"
    local status="${3:-}"
    local low_threshold="${4:-20}"
    local critical_threshold="${5:-10}"
    local charging_bg="${6:-#{@success\}}"
    local charging_fg="${7:-#{@base00\}}"
    local critical_bg="${8:-#{@error\}}"
    local critical_fg="${9:-#{@base00\}}"
    local low_bg="${10:-#{@warning\}}"
    local low_fg="${11:-#{@base00\}}"
    local normal_bg="${12:-#{@surface_0\}}"
    local normal_fg="${13:-#{@fg\}}"

    # If we don't have values, get them fresh
    if [ -z "$percentage" ]; then
        percentage=$(battery_percentage | sed 's/%//')
    fi
    if [ -z "$status" ]; then
        status=$(battery_status)
    fi

    # Remove % if present
    percentage=$(echo "$percentage" | sed 's/%//')

    # Determine color based on status and level
    if [ "$status" = "charging" ] || [ "$status" = "charged" ]; then
        if [ "$color_type" = "bg" ]; then echo "$charging_bg"; else echo "$charging_fg"; fi
    elif [ -n "$percentage" ] && [ "$percentage" -le "$critical_threshold" ] 2>/dev/null; then
        if [ "$color_type" = "bg" ]; then echo "$critical_bg"; else echo "$critical_fg"; fi
    elif [ -n "$percentage" ] && [ "$percentage" -le "$low_threshold" ] 2>/dev/null; then
        if [ "$color_type" = "bg" ]; then echo "$low_bg"; else echo "$low_fg"; fi
    else
        if [ "$color_type" = "bg" ]; then echo "$normal_bg"; else echo "$normal_fg"; fi
    fi
}

# Get battery icon based on percentage and status
get_battery_icon() {
    local percentage="${1:-}"
    local status="${2:-}"
    local icon_charging="${3:-󰂄}"
    local icon_charged="${4:-󰚥}"
    local icon_unknown="${5:-󰂑}"
    local icon_tier8="${6:-󰁹}"
    local icon_tier7="${7:-󰂁}"
    local icon_tier6="${8:-󰁿}"
    local icon_tier5="${9:-󰁾}"
    local icon_tier4="${10:-󰁽}"
    local icon_tier3="${11:-󰁼}"
    local icon_tier2="${12:-󰁻}"
    local icon_tier1="${13:-󰁺}"

    # If we don't have values, get them fresh
    if [ -z "$percentage" ]; then
        percentage=$(battery_percentage | sed 's/%//')
    fi
    if [ -z "$status" ]; then
        status=$(battery_status)
    fi

    # Status-based icons
    case "$status" in
        "charging")
            echo "$icon_charging"
            return
            ;;
        "charged"|"full")
            echo "$icon_charged"
            return
            ;;
        "unknown"|"not charging")
            echo "$icon_unknown"
            return
            ;;
    esac

    # Remove % symbol if present
    percentage=$(echo "$percentage" | sed 's/%//')

    if [ -z "$percentage" ] || [ "$percentage" = "" ]; then
        echo "$icon_unknown"
        return
    fi

    # Charge level icons (discharging)
    if [ "$percentage" -ge 95 ]; then
        echo "$icon_tier8"
    elif [ "$percentage" -ge 80 ]; then
        echo "$icon_tier7"
    elif [ "$percentage" -ge 65 ]; then
        echo "$icon_tier6"
    elif [ "$percentage" -ge 50 ]; then
        echo "$icon_tier5"
    elif [ "$percentage" -ge 35 ]; then
        echo "$icon_tier4"
    elif [ "$percentage" -ge 20 ]; then
        echo "$icon_tier3"
    elif [ "$percentage" -gt 10 ]; then
        echo "$icon_tier2"
    else
        echo "$icon_tier1"
    fi
}

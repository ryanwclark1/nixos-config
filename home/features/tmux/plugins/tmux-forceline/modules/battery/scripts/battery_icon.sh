#!/usr/bin/env bash
# Battery Icon Generator for tmux-forceline
# Provides dynamic battery icons based on charge level and status

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/helpers.sh"

# Get battery icon based on percentage and status
get_battery_icon() {
    local percentage=$(get_tmux_option "@_fl_battery_percentage" "")
    local status=$(get_tmux_option "@_fl_battery_status" "")
    
    # If we don't have cached values, get them fresh
    if [ -z "$percentage" ]; then
        local battery_data=$($CURRENT_DIR/battery_percentage.sh)
        percentage=$(echo "$battery_data" | sed 's/%//')
        tmux set-option -g "@_fl_battery_percentage" "$percentage"
    fi
    
    if [ -z "$status" ]; then
        status=$(battery_status)
        tmux set-option -g "@_fl_battery_status" "$status"
    fi
    
    # Status-based icons (charging, plugged, etc.)
    case "$status" in
        "charging")
            get_tmux_option "@batt_icon_status_charging" "󰂄"
            return
            ;;
        "charged"|"full")
            get_tmux_option "@batt_icon_status_charged" "󰚥"
            return
            ;;
        "unknown"|"not charging")
            get_tmux_option "@batt_icon_status_unknown" "󰂑"
            return
            ;;
    esac
    
    # Remove % symbol if present
    percentage=$(echo "$percentage" | sed 's/%//')
    
    # Charge level icons for discharging/normal state
    if [ -z "$percentage" ] || [ "$percentage" = "" ]; then
        get_tmux_option "@batt_icon_status_unknown" "󰂑"
        return
    fi
    
    # Battery level icons (discharging) - use configurable icons
    if [ "$percentage" -ge 95 ]; then
        get_tmux_option "@batt_icon_charge_tier8" "󰁹"  # 100%
    elif [ "$percentage" -ge 80 ]; then
        get_tmux_option "@batt_icon_charge_tier7" "󰂁"  # 90%
    elif [ "$percentage" -ge 65 ]; then
        get_tmux_option "@batt_icon_charge_tier6" "󰁿"  # 80%
    elif [ "$percentage" -ge 50 ]; then
        get_tmux_option "@batt_icon_charge_tier5" "󰁾"  # 70%
    elif [ "$percentage" -ge 35 ]; then
        get_tmux_option "@batt_icon_charge_tier4" "󰁽"  # 60%
    elif [ "$percentage" -ge 20 ]; then
        get_tmux_option "@batt_icon_charge_tier3" "󰁼"  # 50%
    elif [ "$percentage" -gt 10 ]; then
        get_tmux_option "@batt_icon_charge_tier2" "󰁻"  # 30%
    else
        get_tmux_option "@batt_icon_charge_tier1" "󰁺"  # 10% (critical)
    fi
}

main() {
    get_battery_icon
}

main
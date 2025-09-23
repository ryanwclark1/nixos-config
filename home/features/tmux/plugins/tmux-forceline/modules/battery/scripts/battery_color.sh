#!/usr/bin/env bash
# Battery Color Generator for tmux-forceline
# Provides dynamic colors based on battery level and charging status

# Source centralized path management
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../utils" && pwd)"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    source "$UTILS_DIR/common.sh"
    # shellcheck source=scripts/helpers.sh
    HELPERS_PATH="$(get_forceline_path "modules/battery/scripts/helpers.sh")"
    source "$HELPERS_PATH"
else
    # Fallback implementation if common.sh not available
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$CURRENT_DIR/helpers.sh"
fi

get_battery_color() {
    local color_type="$1"  # bg or fg
    
    # Get battery info
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
    
    # Remove % if present
    percentage=$(echo "$percentage" | sed 's/%//')
    
    # Get thresholds
    local low_threshold=$(get_tmux_option "@forceline_battery_low_threshold" "20")
    local critical_threshold=$(get_tmux_option "@forceline_battery_critical_threshold" "10")
    
    # Determine color based on status and level
    if [ "$status" = "charging" ] || [ "$status" = "charged" ]; then
        # Charging or fully charged - use success colors
        if [ "$color_type" = "bg" ]; then
            get_tmux_option "@forceline_battery_charging_bg" "#{@fl_success}"
        else
            get_tmux_option "@forceline_battery_charging_fg" "#{@fl_base00}"
        fi
    elif [ -n "$percentage" ] && [ "$percentage" -le "$critical_threshold" ] 2>/dev/null; then
        # Critical battery level - use error colors
        if [ "$color_type" = "bg" ]; then
            get_tmux_option "@forceline_battery_critical_bg" "#{@fl_error}"
        else
            get_tmux_option "@forceline_battery_critical_fg" "#{@fl_base00}"
        fi
    elif [ -n "$percentage" ] && [ "$percentage" -le "$low_threshold" ] 2>/dev/null; then
        # Low battery level - use warning colors
        if [ "$color_type" = "bg" ]; then
            get_tmux_option "@forceline_battery_low_bg" "#{@fl_warning}"
        else
            get_tmux_option "@forceline_battery_low_fg" "#{@fl_base00}"
        fi
    else
        # Normal battery level - use normal colors
        if [ "$color_type" = "bg" ]; then
            get_tmux_option "@forceline_battery_normal_bg" "#{@fl_surface_0}"
        else
            get_tmux_option "@forceline_battery_normal_fg" "#{@fl_fg}"
        fi
    fi
}

main() {
    local color_type="${1:-bg}"
    get_battery_color "$color_type"
}

main "$@"
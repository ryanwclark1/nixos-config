#!/usr/bin/env bash
# DateTime Module for tmux-forceline v2.0
# Cross-platform date and time display with timezone support

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# DateTime interpolation variables that will be available in tmux
datetime_interpolation=(
    "\#{datetime_date}"
    "\#{datetime_time}"
    "\#{datetime_day_of_week}"
    "\#{datetime_utc_time}"
    "\#{datetime_timestamp}"
)

# Corresponding command implementations
datetime_commands=(
    "#($CURRENT_DIR/scripts/date.sh)"
    "#($CURRENT_DIR/scripts/time.sh)"
    "#($CURRENT_DIR/scripts/day_of_week.sh)"
    "#($CURRENT_DIR/scripts/utc_time.sh)"
    "#(date +%s)"
)

# Helper functions from the tmux plugin system
get_tmux_option() {
    local option="$1"
    local default_value="$2"
    local option_value="$(tmux show-option -gqv "$option")"
    if [ -z "$option_value" ]; then
        echo "$default_value"
    else
        echo "$option_value"
    fi
}

set_tmux_option() {
    local option="$1"
    local value="$2"
    tmux set-option -gq "$option" "$value"
}

# Interpolate datetime variables in a string
do_interpolation() {
    local all_interpolated="$1"
    for ((i=0; i<${#datetime_commands[@]}; i++)); do
        all_interpolated=${all_interpolated//${datetime_interpolation[$i]}/${datetime_commands[$i]}}
    done
    echo "$all_interpolated"
}

# Update tmux option with datetime interpolation
update_tmux_option() {
    local option="$1"
    local option_value="$(get_tmux_option "$option")"
    local new_option_value="$(do_interpolation "$option_value")"
    set_tmux_option "$option" "$new_option_value"
}

# Main execution
main() {
    # Make scripts executable
    chmod +x "$CURRENT_DIR/scripts/"*.sh
    
    # Update status-left and status-right to support datetime interpolation
    update_tmux_option "status-right"
    update_tmux_option "status-left"
    
    # Set default datetime configurations if not already set
    set_tmux_option "@forceline_datetime_date_format" "$(get_tmux_option "@forceline_datetime_date_format" "%Y-%m-%d")"
    set_tmux_option "@forceline_datetime_time_format" "$(get_tmux_option "@forceline_datetime_time_format" "%H:%M")"
    set_tmux_option "@forceline_datetime_day_format" "$(get_tmux_option "@forceline_datetime_day_format" "%a")"
    set_tmux_option "@forceline_datetime_utc_format" "$(get_tmux_option "@forceline_datetime_utc_format" "%H:%M UTC")"
}

main
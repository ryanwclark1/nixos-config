#!/usr/bin/env bash
# Battery Module for tmux-forceline v2.0
# Integrates with the plugin system and provides Base24 theming

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Battery interpolation variables that will be available in tmux
battery_interpolation=(
    "\#{battery_color_bg}"
    "\#{battery_color_fg}"
    "\#{battery_icon}"
    "\#{battery_percentage}"
    "\#{battery_status}"
)

# Corresponding command implementations
battery_commands=(
    "#($CURRENT_DIR/scripts/battery_color.sh bg)"
    "#($CURRENT_DIR/scripts/battery_color.sh fg)"
    "#($CURRENT_DIR/scripts/battery_icon.sh)"
    "#($CURRENT_DIR/scripts/battery_percentage.sh)"
    "#($CURRENT_DIR/scripts/battery_status.sh)"
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

# Interpolate battery variables in a string
do_interpolation() {
    local all_interpolated="$1"
    for ((i=0; i<${#battery_commands[@]}; i++)); do
        all_interpolated=${all_interpolated//${battery_interpolation[$i]}/${battery_commands[$i]}}
    done
    echo "$all_interpolated"
}

# Update tmux option with battery interpolation
update_tmux_option() {
    local option="$1"
    local option_value="$(get_tmux_option "$option")"
    local new_option_value="$(do_interpolation "$option_value")"
    set_tmux_option "$option" "$new_option_value"
}

# Main execution
main() {
    # Update status-left and status-right to support battery interpolation
    update_tmux_option "status-right"
    update_tmux_option "status-left"
    
    # Cache initial battery data for performance
    "$CURRENT_DIR/scripts/battery_percentage.sh" >/dev/null &
    source "$CURRENT_DIR/scripts/helpers.sh" && battery_status >/dev/null &
}

main
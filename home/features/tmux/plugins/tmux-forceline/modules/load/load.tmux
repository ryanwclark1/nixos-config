#!/usr/bin/env bash
# Load Module for tmux-forceline v2.0
# Cross-platform system load monitoring with color indication

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load interpolation variables that will be available in tmux
load_interpolation=(
    "\#{load_average}"
    "\#{load_1min}"
    "\#{load_5min}"
    "\#{load_15min}"
    "\#{load_color_fg}"
    "\#{load_color_bg}"
)

# Corresponding command implementations
load_commands=(
    "#($CURRENT_DIR/scripts/load_average.sh)"
    "#($CURRENT_DIR/scripts/load_average.sh 1min)"
    "#($CURRENT_DIR/scripts/load_average.sh 5min)"
    "#($CURRENT_DIR/scripts/load_average.sh 15min)"
    "#($CURRENT_DIR/scripts/load_color.sh fg)"
    "#($CURRENT_DIR/scripts/load_color.sh bg)"
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

# Interpolate load variables in a string
do_interpolation() {
    local all_interpolated="$1"
    for ((i=0; i<${#load_commands[@]}; i++)); do
        all_interpolated=${all_interpolated//${load_interpolation[$i]}/${load_commands[$i]}}
    done
    echo "$all_interpolated"
}

# Update tmux option with load interpolation
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
    
    # Update status-left and status-right to support load interpolation
    update_tmux_option "status-right"
    update_tmux_option "status-left"
    
    # Set default load configurations if not already set
    set_tmux_option "@forceline_load_format" "$(get_tmux_option "@forceline_load_format" "average")"
    set_tmux_option "@forceline_load_precision" "$(get_tmux_option "@forceline_load_precision" "1")"
    set_tmux_option "@forceline_load_show_color" "$(get_tmux_option "@forceline_load_show_color" "yes")"
}

main
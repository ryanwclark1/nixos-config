#!/usr/bin/env bash
# Disk Usage Module for tmux-forceline v2.0
# Enhanced disk monitoring with configurable paths

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Disk usage interpolation variables that will be available in tmux
disk_usage_interpolation=(
    "\#{disk_usage}"
    "\#{disk_usage_status}"
    "\#{disk_usage_percentage}"
    "\#{disk_usage_used}"
    "\#{disk_usage_available}"
)

# Corresponding command implementations
disk_usage_commands=(
    "#($CURRENT_DIR/scripts/disk_usage_simple.sh)"
    "#($CURRENT_DIR/scripts/disk_usage.sh status)"
    "#($CURRENT_DIR/scripts/disk_usage_simple.sh)"
    "#(df -h / | awk 'NR==2 {print \$3}')"
    "#(df -h / | awk 'NR==2 {print \$4}')"
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

# Interpolate disk usage variables in a string
do_interpolation() {
    local all_interpolated="$1"
    for ((i=0; i<${#disk_usage_commands[@]}; i++)); do
        all_interpolated=${all_interpolated//${disk_usage_interpolation[$i]}/${disk_usage_commands[$i]}}
    done
    echo "$all_interpolated"
}

# Update tmux option with disk usage interpolation
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
    
    # Update status-left and status-right to support disk usage interpolation
    update_tmux_option "status-right"
    update_tmux_option "status-left"
    
    # Set default disk usage configurations if not already set
    set_tmux_option "@forceline_disk_usage_path" "$(get_tmux_option "@forceline_disk_usage_path" "/")"
    set_tmux_option "@forceline_disk_usage_format" "$(get_tmux_option "@forceline_disk_usage_format" "percentage")"
    set_tmux_option "@forceline_disk_usage_warning_threshold" "$(get_tmux_option "@forceline_disk_usage_warning_threshold" "80")"
    set_tmux_option "@forceline_disk_usage_critical_threshold" "$(get_tmux_option "@forceline_disk_usage_critical_threshold" "90")"
}

main
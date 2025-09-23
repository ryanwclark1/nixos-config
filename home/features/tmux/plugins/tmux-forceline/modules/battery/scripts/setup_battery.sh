#!/usr/bin/env bash
# Battery Setup Script for tmux-forceline
# Initializes battery monitoring and sets up tmux format variables

# Source centralized path management
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../utils" && pwd)"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    source "$UTILS_DIR/common.sh"
else
    # Fallback implementation if common.sh not available
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Set up tmux format variables for battery monitoring
# This creates #{battery_percentage}, #{battery_status}, #{battery_icon} etc.
# that can be used in tmux status lines

# Create format variables
tmux set-option -g "@battery_percentage_format" "#($CURRENT_DIR/battery_percentage.sh)"
tmux set-option -g "@battery_icon_format" "#($CURRENT_DIR/battery_icon.sh)"
tmux set-option -g "@battery_color_bg_format" "#($CURRENT_DIR/battery_color.sh bg)"
tmux set-option -g "@battery_color_fg_format" "#($CURRENT_DIR/battery_color.sh fg)"

# Set up interpolation for status-left and status-right
# This allows using #{battery_percentage}, #{battery_icon} etc. in status lines
tmux_option_exists() {
    local option="$1"
    tmux show-option -gq "$option" >/dev/null 2>&1
}

# Update existing status lines to support battery interpolation
update_status_interpolation() {
    local status_option="$1"
    local current_value=$(tmux show-option -gqv "$status_option")
    
    if [ -n "$current_value" ]; then
        # Replace battery interpolations with actual commands
        local new_value="$current_value"
        new_value="${new_value//\#{battery_percentage\}/#($CURRENT_DIR/battery_percentage.sh)}"
        new_value="${new_value//\#{battery_icon\}/#($CURRENT_DIR/battery_icon.sh)}"
        new_value="${new_value//\#{battery_color_bg\}/#($CURRENT_DIR/battery_color.sh bg)}"
        new_value="${new_value//\#{battery_color_fg\}/#($CURRENT_DIR/battery_color.sh fg)}"
        
        tmux set-option -g "$status_option" "$new_value"
    fi
}

# Update status lines
update_status_interpolation "status-left"
update_status_interpolation "status-right"

# Cache initial battery values for performance
"$CURRENT_DIR/battery_percentage.sh" >/dev/null &
source "$CURRENT_DIR/helpers.sh"
battery_status >/dev/null &
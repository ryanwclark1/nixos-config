#!/usr/bin/env bash
# DateTime Module for tmux-forceline v3.0
# Cross-platform date and time display with timezone support

set -euo pipefail

# Source centralized path management
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/utils"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    source "$UTILS_DIR/common.sh"
else
    # Fallback implementation if common.sh not available
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# DateTime interpolation variables that will be available in tmux
datetime_interpolation=(
    "\#{datetime_date}"
    "\#{datetime_time}"
    "\#{datetime_day_of_week}"
    "\#{datetime_utc_time}"
    "\#{datetime_timestamp}"
)

# Corresponding command implementations - use centralized or fallback paths
if command -v get_forceline_path >/dev/null 2>&1; then
  datetime_commands=(
    "#($(get_forceline_path "modules/datetime/scripts/date.sh"))"
    "#($(get_forceline_path "modules/datetime/scripts/time.sh"))"
    "#($(get_forceline_path "modules/datetime/scripts/day_of_week.sh"))"
    "#($(get_forceline_path "modules/datetime/scripts/utc_time.sh"))"
    "#(date +%s)"
  )
else
  datetime_commands=(
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/date.sh)"
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/time.sh)"
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/day_of_week.sh)"
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/utc_time.sh)"
    "#(date +%s)"
  )
fi

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
    if command -v get_forceline_path >/dev/null 2>&1; then
        chmod +x "$(get_forceline_path "modules/datetime/scripts")"/*.sh
    else
        chmod +x "${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/"*.sh
    fi
    
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
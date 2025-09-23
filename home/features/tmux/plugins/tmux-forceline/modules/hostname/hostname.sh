#!/usr/bin/env bash
# Hostname Module for tmux-forceline v3.0
# Cross-platform hostname display with format options

set -euo pipefail

# Source centralized path management
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/utils"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    source "$UTILS_DIR/common.sh"
else
    # Fallback implementation if common.sh not available
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Hostname interpolation variables that will be available in tmux
hostname_interpolation=(
    "\#{hostname}"
    "\#{hostname_short}"
    "\#{hostname_long}"
    "\#{hostname_icon}"
)

# Corresponding command implementations - use centralized or fallback paths
if command -v get_forceline_path >/dev/null 2>&1; then
  hostname_commands=(
    "#($(get_forceline_path "modules/hostname/scripts/hostname.sh"))"
    "#($(get_forceline_path "modules/hostname/scripts/hostname.sh") short)"
    "#($(get_forceline_path "modules/hostname/scripts/hostname.sh") long)"
    "#($(get_forceline_path "modules/hostname/scripts/hostname.sh") icon)"
  )
else
  hostname_commands=(
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/hostname.sh)"
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/hostname.sh short)"
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/hostname.sh long)"
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/hostname.sh icon)"
  )
fi

# Interpolate hostname variables in a string
do_interpolation() {
    local all_interpolated="$1"
    for ((i=0; i<${#hostname_commands[@]}; i++)); do
        all_interpolated=${all_interpolated//${hostname_interpolation[$i]}/${hostname_commands[$i]}}
    done
    echo "$all_interpolated"
}

# Update tmux option with hostname interpolation
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
        chmod +x "$(get_forceline_path "modules/hostname/scripts")"/*.sh
    else
        chmod +x "${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/"*.sh
    fi
    
    # Update status-left and status-right to support hostname interpolation
    update_tmux_option "status-right"
    update_tmux_option "status-left"
    
    # Set default hostname configurations if not already set
    set_tmux_option "@forceline_hostname_format" "$(get_tmux_option "@forceline_hostname_format" "short")"
    set_tmux_option "@forceline_hostname_show_icon" "$(get_tmux_option "@forceline_hostname_show_icon" "no")"
}

main
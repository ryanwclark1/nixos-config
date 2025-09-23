#!/usr/bin/env bash
# VCS Module for tmux-forceline v3.0
# Enhanced Git integration with status monitoring and Base24 theming

set -euo pipefail

# Source centralized path management
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/utils"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    source "$UTILS_DIR/common.sh"
else
    # Fallback implementation if common.sh not available
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# VCS interpolation variables that will be available in tmux
vcs_interpolation=(
    "\#{vcs_branch}"
    "\#{vcs_status}"
    "\#{vcs_status_counts}"
    "\#{vcs_type}"
    "\#{vcs_color_fg}"
    "\#{vcs_color_bg}"
)

# Corresponding command implementations - use centralized or fallback paths
if command -v get_forceline_path >/dev/null 2>&1; then
  vcs_commands=(
    "#($(get_forceline_path "modules/vcs/scripts/vcs_branch.sh"))"
    "#($(get_forceline_path "modules/vcs/scripts/vcs_status.sh"))"
    "#($(get_forceline_path "modules/vcs/scripts/vcs_status.sh") counts)"
    "#($(get_forceline_path "modules/vcs/scripts/vcs_branch.sh") type)"
    "#($(get_forceline_path "modules/vcs/scripts/vcs_color.sh") fg)"
    "#($(get_forceline_path "modules/vcs/scripts/vcs_color.sh") bg)"
  )
else
  vcs_commands=(
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/vcs_branch.sh)"
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/vcs_status.sh)"
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/vcs_status.sh counts)"
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/vcs_branch.sh type)"
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/vcs_color.sh fg)"
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/vcs_color.sh bg)"
  )
fi

# Interpolate VCS variables in a string
do_interpolation() {
    local all_interpolated="$1"
    for ((i=0; i<${#vcs_commands[@]}; i++)); do
        all_interpolated=${all_interpolated//${vcs_interpolation[$i]}/${vcs_commands[$i]}}
    done
    echo "$all_interpolated"
}

# Update tmux option with VCS interpolation
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
        chmod +x "$(get_forceline_path "modules/vcs/scripts")"/*.sh
    else
        chmod +x "${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/"*.sh
    fi
    
    # Update status-left and status-right to support VCS interpolation
    update_tmux_option "status-right"
    update_tmux_option "status-left"
    
    # Set default VCS configurations if not already set
    set_tmux_option "@forceline_vcs_show_icon" "$(get_tmux_option "@forceline_vcs_show_icon" "yes")"
    set_tmux_option "@forceline_vcs_branch_max_len" "$(get_tmux_option "@forceline_vcs_branch_max_len" "20")"
    set_tmux_option "@forceline_vcs_truncate_symbol" "$(get_tmux_option "@forceline_vcs_truncate_symbol" "…")"
    set_tmux_option "@forceline_vcs_show_symbols" "$(get_tmux_option "@forceline_vcs_show_symbols" "yes")"
    set_tmux_option "@forceline_vcs_show_zero" "$(get_tmux_option "@forceline_vcs_show_zero" "no")"
}

main
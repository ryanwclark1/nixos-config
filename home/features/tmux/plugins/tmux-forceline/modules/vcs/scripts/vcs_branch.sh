#!/usr/bin/env bash
# VCS branch script for tmux-forceline v3.0
# Enhanced Git branch detection with status indicators

# Source centralized path management
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../utils" && pwd)"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    # shellcheck source=../../../utils/common.sh
    source "$UTILS_DIR/common.sh"
    # shellcheck source=scripts/vcs_helpers.sh
    HELPERS_PATH="$(get_forceline_path "modules/vcs/scripts/vcs_helpers.sh")"
    source "$HELPERS_PATH"
else
    # Fallback implementation if common.sh not available
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$CURRENT_DIR/vcs_helpers.sh"
    get_tmux_option() {
        local option="$1"
        local default="$2"
        tmux show-option -gqv "$option" 2>/dev/null || echo "$default"
    }
fi

# Main VCS branch function
main() {
    # Get configuration from tmux options
    local show_icon max_len truncate_symbol format
    
    show_icon=$(get_tmux_option "@forceline_vcs_show_icon" "yes")
    max_len=$(get_tmux_option "@forceline_vcs_branch_max_len" "20")
    truncate_symbol=$(get_tmux_option "@forceline_vcs_truncate_symbol" "…")
    format=$(get_tmux_option "@forceline_vcs_format" "branch")
    
    # Set environment variables for helpers
    export FORCELINE_VCS_SHOW_SYMBOL="$show_icon"
    export FORCELINE_VCS_BRANCH_MAX_LEN="$max_len"
    export FORCELINE_VCS_TRUNCATE_SYMBOL="$truncate_symbol"
    
    # Get VCS status
    local vcs_status
    vcs_status=$(get_vcs_status_with_icon "$show_icon")
    
    if [ $? -ne 0 ] || [ -z "$vcs_status" ]; then
        return 1
    fi
    
    # Parse status: icon+branch:modified:staged:untracked:ahead:behind:vcs_type
    local branch_part status_part vcs_type
    branch_part=$(echo "$vcs_status" | cut -d: -f1)
    status_part=$(echo "$vcs_status" | cut -d: -f2-6)
    vcs_type=$(echo "$vcs_status" | cut -d: -f7)
    
    case "$format" in
        "branch")
            echo "$branch_part"
            ;;
        "status")
            echo "$status_part"
            ;;
        "type")
            echo "$vcs_type"
            ;;
        "full")
            echo "$vcs_status"
            ;;
        *)
            echo "$branch_part"
            ;;
    esac
}

# Execute if run directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
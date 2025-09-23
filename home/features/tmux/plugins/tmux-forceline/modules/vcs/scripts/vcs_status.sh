#!/usr/bin/env bash
# VCS status script for tmux-forceline v3.0
# Git status indicators with count display

# Source centralized path management
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../utils" && pwd)"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    # shellcheck source=../../../utils/common.sh
    source "$UTILS_DIR/common.sh"
    
    # Source helpers using centralized path management
    HELPERS_PATH="$(get_forceline_path "modules/vcs/scripts/vcs_helpers.sh")"
    source "$HELPERS_PATH"
else
    # Fallback implementation if common.sh not available
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$CURRENT_DIR/vcs_helpers.sh"
    
    # Fallback implementation if common.sh not available
    get_tmux_option() {
        local option="$1"
        local default="$2"
        tmux show-option -gqv "$option" 2>/dev/null || echo "$default"
    }
fi

# Format status counts with symbols
format_status_counts() {
    local status_data="$1"
    local show_symbols="$2"
    local show_zero="$3"
    
    local modified staged untracked ahead behind
    IFS=: read -r modified staged untracked ahead behind <<< "$status_data"
    
    local result=""
    local has_changes=false
    
    # Staged changes
    if [ "$staged" -gt 0 ] || [ "$show_zero" = "yes" ]; then
        if [ "$show_symbols" = "yes" ]; then
            result="${result}+${staged} "
        else
            result="${result}S:${staged} "
        fi
        has_changes=true
    fi
    
    # Modified files
    if [ "$modified" -gt 0 ] || [ "$show_zero" = "yes" ]; then
        if [ "$show_symbols" = "yes" ]; then
            result="${result}±${modified} "
        else
            result="${result}M:${modified} "
        fi
        has_changes=true
    fi
    
    # Untracked files
    if [ "$untracked" -gt 0 ] || [ "$show_zero" = "yes" ]; then
        if [ "$show_symbols" = "yes" ]; then
            result="${result}?${untracked} "
        else
            result="${result}U:${untracked} "
        fi
        has_changes=true
    fi
    
    # Ahead/behind indicators
    if [ "$ahead" -gt 0 ]; then
        if [ "$show_symbols" = "yes" ]; then
            result="${result}↑${ahead} "
        else
            result="${result}A:${ahead} "
        fi
        has_changes=true
    fi
    
    if [ "$behind" -gt 0 ]; then
        if [ "$show_symbols" = "yes" ]; then
            result="${result}↓${behind} "
        else
            result="${result}B:${behind} "
        fi
        has_changes=true
    fi
    
    # Clean indicator
    if [ "$has_changes" = "false" ]; then
        if [ "$show_symbols" = "yes" ]; then
            result="✓"
        else
            result="CLEAN"
        fi
    else
        result=$(echo "$result" | sed 's/ $//')  # Remove trailing space
    fi
    
    echo "$result"
}

# Main VCS status function
main() {
    local format="$1"
    
    # Get configuration from tmux options
    local show_symbols show_zero
    
    show_symbols=$(get_tmux_option "@forceline_vcs_show_symbols" "yes")
    show_zero=$(get_tmux_option "@forceline_vcs_show_zero" "no")
    
    # Get VCS status
    local vcs_status
    vcs_status=$(get_vcs_status_with_icon "no")
    
    if [ $? -ne 0 ] || [ -z "$vcs_status" ]; then
        return 1
    fi
    
    # Parse status: branch:modified:staged:untracked:ahead:behind:vcs_type
    local status_data
    status_data=$(echo "$vcs_status" | cut -d: -f2-6)
    
    case "$format" in
        "counts")
            format_status_counts "$status_data" "$show_symbols" "$show_zero"
            ;;
        "raw")
            echo "$status_data"
            ;;
        *)
            format_status_counts "$status_data" "$show_symbols" "$show_zero"
            ;;
    esac
}

# Execute if run directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
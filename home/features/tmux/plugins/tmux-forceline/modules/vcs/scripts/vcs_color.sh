#!/usr/bin/env bash
# VCS color script for tmux-forceline v2.0
# Provides Base24 colors based on Git status

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/vcs_helpers.sh"

# Get tmux option or use default
get_tmux_option() {
    local option="$1"
    local default="$2"
    tmux show-option -gqv "$option" 2>/dev/null || echo "$default"
}

# Determine VCS status level
get_vcs_status_level() {
    local status_data="$1"
    
    local modified staged untracked ahead behind
    IFS=: read -r modified staged untracked ahead behind <<< "$status_data"
    
    # Determine overall status level
    if [ "$modified" -gt 0 ] || [ "$untracked" -gt 0 ]; then
        echo "DIRTY"
    elif [ "$staged" -gt 0 ]; then
        echo "STAGED"
    elif [ "$ahead" -gt 0 ] || [ "$behind" -gt 0 ]; then
        echo "DIVERGED"
    else
        echo "CLEAN"
    fi
}

# Main color function
main() {
    local color_type="$1"  # fg or bg
    
    # Get VCS status
    local vcs_status
    vcs_status=$(get_vcs_status_with_icon "no")
    
    if [ $? -ne 0 ] || [ -z "$vcs_status" ]; then
        # No VCS - return default colors
        if [ "$color_type" = "fg" ]; then
            echo "#{@fl_fg}"
        else
            echo "#{@fl_surface_0}"
        fi
        return 0
    fi
    
    # Parse status
    local status_data
    status_data=$(echo "$vcs_status" | cut -d: -f2-6)
    
    local status_level
    status_level=$(get_vcs_status_level "$status_data")
    
    # Get color configuration
    local clean_fg clean_bg staged_fg staged_bg diverged_fg diverged_bg dirty_fg dirty_bg
    
    clean_fg=$(get_tmux_option "@forceline_vcs_clean_fg" "#{@fl_fg}")
    clean_bg=$(get_tmux_option "@forceline_vcs_clean_bg" "#{@fl_success}")
    staged_fg=$(get_tmux_option "@forceline_vcs_staged_fg" "#{@fl_base00}")
    staged_bg=$(get_tmux_option "@forceline_vcs_staged_bg" "#{@fl_info}")
    diverged_fg=$(get_tmux_option "@forceline_vcs_diverged_fg" "#{@fl_base00}")
    diverged_bg=$(get_tmux_option "@forceline_vcs_diverged_bg" "#{@fl_warning}")
    dirty_fg=$(get_tmux_option "@forceline_vcs_dirty_fg" "#{@fl_base00}")
    dirty_bg=$(get_tmux_option "@forceline_vcs_dirty_bg" "#{@fl_error}")
    
    # Return appropriate color based on status and type
    case "$status_level" in
        "CLEAN")
            if [ "$color_type" = "fg" ]; then
                echo "$clean_fg"
            else
                echo "$clean_bg"
            fi
            ;;
        "STAGED")
            if [ "$color_type" = "fg" ]; then
                echo "$staged_fg"
            else
                echo "$staged_bg"
            fi
            ;;
        "DIVERGED")
            if [ "$color_type" = "fg" ]; then
                echo "$diverged_fg"
            else
                echo "$diverged_bg"
            fi
            ;;
        "DIRTY")
            if [ "$color_type" = "fg" ]; then
                echo "$dirty_fg"
            else
                echo "$dirty_bg"
            fi
            ;;
        *)
            if [ "$color_type" = "fg" ]; then
                echo "$clean_fg"
            else
                echo "$clean_bg"
            fi
            ;;
    esac
}

# Execute if run directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
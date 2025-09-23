#!/usr/bin/env bash
# Load color script for tmux-forceline v3.0
# Provides Base24 colors based on load levels

# Source centralized tmux functions
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../utils" && pwd)"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    # shellcheck source=../../../utils/common.sh
    source "$UTILS_DIR/common.sh"
    
    # Source helpers using centralized path management
    HELPERS_PATH="$(get_forceline_path "modules/load/scripts/load_helpers.sh")"
    source "$HELPERS_PATH"
else
    # Fallback implementation if common.sh not available
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$CURRENT_DIR/load_helpers.sh"
    
    # Fallback implementation
    get_tmux_option() {
        local option="$1"
        local default="$2"
        tmux show-option -gqv "$option" 2>/dev/null || echo "$default"
    }
fi

# Main color function
main() {
    local color_type="$1"  # fg or bg
    local load_with_status
    local status
    local load_value
    
    # Get load with status
    load_with_status=$(get_load_with_color "1min" "2" "yes")
    status=$(echo "$load_with_status" | cut -d':' -f1)
    load_value=$(echo "$load_with_status" | cut -d':' -f2)
    
    # Get color configuration
    local normal_fg normal_bg high_fg high_bg critical_fg critical_bg
    
    normal_fg=$(get_tmux_option "@forceline_load_normal_fg" "#{@fl_fg}")
    normal_bg=$(get_tmux_option "@forceline_load_normal_bg" "#{@fl_surface_0}")
    high_fg=$(get_tmux_option "@forceline_load_high_fg" "#{@fl_base00}")
    high_bg=$(get_tmux_option "@forceline_load_high_bg" "#{@fl_warning}")
    critical_fg=$(get_tmux_option "@forceline_load_critical_fg" "#{@fl_base00}")
    critical_bg=$(get_tmux_option "@forceline_load_critical_bg" "#{@fl_error}")
    
    # Return appropriate color based on status and type
    case "$status" in
        "CRITICAL")
            if [ "$color_type" = "fg" ]; then
                echo "$critical_fg"
            else
                echo "$critical_bg"
            fi
            ;;
        "HIGH")
            if [ "$color_type" = "fg" ]; then
                echo "$high_fg"
            else
                echo "$high_bg"
            fi
            ;;
        *)
            if [ "$color_type" = "fg" ]; then
                echo "$normal_fg"
            else
                echo "$normal_bg"
            fi
            ;;
    esac
}

# Execute if run directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
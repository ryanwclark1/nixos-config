#!/usr/bin/env bash
# WAN IP color script for tmux-forceline v3.0
# Provides Base24 colors based on WAN IP status

# Source centralized tmux functions
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../utils" && pwd)"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    # shellcheck source=../../../utils/common.sh
    source "$UTILS_DIR/common.sh"
    
    # Source helpers using centralized path management
    HELPERS_PATH="$(get_forceline_path "modules/wan_ip/scripts/wan_ip_helpers.sh")"
    source "$HELPERS_PATH"
else
    # Fallback implementation if common.sh not available
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$CURRENT_DIR/wan_ip_helpers.sh"
    
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
    local ip_with_status status ip_value
    
    # Get WAN IP with status
    local cache_ttl timeout providers
    cache_ttl=$(get_tmux_option "@forceline_wan_ip_cache_ttl" "900")
    timeout=$(get_tmux_option "@forceline_wan_ip_timeout" "3")
    providers=$(get_tmux_option "@forceline_wan_ip_providers" "ipify,icanhazip,checkip")
    
    ip_with_status=$(get_wan_ip_cached "$cache_ttl" "$timeout" "$providers" "yes")
    status=$(echo "$ip_with_status" | cut -d':' -f1)
    ip_value=$(echo "$ip_with_status" | cut -d':' -f2)
    
    # Get color configuration
    local online_fg online_bg cached_fg cached_bg stale_fg stale_bg offline_fg offline_bg
    
    online_fg=$(get_tmux_option "@forceline_wan_ip_online_fg" "#{@fl_fg}")
    online_bg=$(get_tmux_option "@forceline_wan_ip_online_bg" "#{@fl_success}")
    cached_fg=$(get_tmux_option "@forceline_wan_ip_cached_fg" "#{@fl_fg}")
    cached_bg=$(get_tmux_option "@forceline_wan_ip_cached_bg" "#{@fl_surface_0}")
    stale_fg=$(get_tmux_option "@forceline_wan_ip_stale_fg" "#{@fl_base00}")
    stale_bg=$(get_tmux_option "@forceline_wan_ip_stale_bg" "#{@fl_warning}")
    offline_fg=$(get_tmux_option "@forceline_wan_ip_offline_fg" "#{@fl_base00}")
    offline_bg=$(get_tmux_option "@forceline_wan_ip_offline_bg" "#{@fl_error}")
    
    # Return appropriate color based on status and type
    case "$status" in
        "FRESH")
            if [ "$color_type" = "fg" ]; then
                echo "$online_fg"
            else
                echo "$online_bg"
            fi
            ;;
        "CACHED")
            if [ "$color_type" = "fg" ]; then
                echo "$cached_fg"
            else
                echo "$cached_bg"
            fi
            ;;
        "STALE")
            if [ "$color_type" = "fg" ]; then
                echo "$stale_fg"
            else
                echo "$stale_bg"
            fi
            ;;
        "FAILED"|"MISSING")
            if [ "$color_type" = "fg" ]; then
                echo "$offline_fg"
            else
                echo "$offline_bg"
            fi
            ;;
        *)
            if [ "$color_type" = "fg" ]; then
                echo "$cached_fg"
            else
                echo "$cached_bg"
            fi
            ;;
    esac
}

# Execute if run directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
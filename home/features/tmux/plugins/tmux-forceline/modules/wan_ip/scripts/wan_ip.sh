#!/usr/bin/env bash
# WAN IP script for tmux-forceline v3.0
# Enhanced WAN IP detection with caching and multiple providers

# Source centralized path management
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../utils" && pwd)"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    # shellcheck source=../../../utils/common.sh
    source "$UTILS_DIR/common.sh"
    # shellcheck source=scripts/wan_ip_helpers.sh
    HELPERS_PATH="$(get_forceline_path "modules/wan_ip/scripts/wan_ip_helpers.sh")"
    if [[ -f "$HELPERS_PATH" ]]; then
        source "$HELPERS_PATH"
    fi
else
    # Fallback implementation if common.sh not available
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    get_tmux_option() {
        local option="$1"
        local default="$2"
        tmux show-option -gqv "$option" 2>/dev/null || echo "$default"
    }
    # Source local helpers if available
    if [[ -f "$CURRENT_DIR/wan_ip_helpers.sh" ]]; then
        source "$CURRENT_DIR/wan_ip_helpers.sh"
    fi
fi

# Main WAN IP function
main() {
    # Get configuration from tmux options
    local cache_ttl timeout providers show_status
    
    cache_ttl=$(get_tmux_option "@forceline_wan_ip_cache_ttl" "900")
    timeout=$(get_tmux_option "@forceline_wan_ip_timeout" "3")
    providers=$(get_tmux_option "@forceline_wan_ip_providers" "ipify,icanhazip,checkip")
    show_status=$(get_tmux_option "@forceline_wan_ip_show_status" "no")
    
    # Set environment variables for helpers
    export FORCELINE_WAN_IP_CACHE_TTL="$cache_ttl"
    export FORCELINE_WAN_IP_TIMEOUT="$timeout"
    export FORCELINE_WAN_IP_PROVIDERS="$providers"
    
    # Get and display WAN IP
    get_wan_ip_cached "$cache_ttl" "$timeout" "$providers" "$show_status"
}

# Execute if run directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
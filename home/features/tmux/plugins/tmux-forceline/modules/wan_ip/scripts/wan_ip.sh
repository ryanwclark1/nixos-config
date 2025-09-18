#!/usr/bin/env bash
# WAN IP script for tmux-forceline v2.0
# Enhanced WAN IP detection with caching and multiple providers

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/wan_ip_helpers.sh"

# Get tmux option or use default
get_tmux_option() {
    local option="$1"
    local default="$2"
    tmux show-option -gqv "$option" 2>/dev/null || echo "$default"
}

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
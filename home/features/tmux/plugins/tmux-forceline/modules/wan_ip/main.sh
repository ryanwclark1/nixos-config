#!/usr/bin/env bash
set -euo pipefail

source "${FORCELINE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null && pwd)}/utils/source_helpers.sh"

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
source "$CURRENT_DIR/functions.sh"

cmd="${1:-enhanced}"; shift || true

case "$cmd" in
    data)
        cache_ttl="${1:-$(get_tmux_option "@forceline_wan_ip_cache_ttl" "900")}"
        timeout="${2:-$(get_tmux_option "@forceline_wan_ip_timeout" "3")}"
        providers="${3:-$(get_tmux_option "@forceline_wan_ip_providers" "ipify,icanhazip,checkip")}"
        show_status="${4:-$(get_tmux_option "@forceline_wan_ip_show_status" "no")}"
        get_wan_ip_cached "$cache_ttl" "$timeout" "$providers" "$show_status"
        ;;
    color)
        color_type="${1:-bg}"; shift || true
        get_wan_ip_color "$color_type" \
            "$(get_tmux_option "@forceline_wan_ip_cache_ttl" "900")" \
            "$(get_tmux_option "@forceline_wan_ip_timeout" "3")" \
            "$(get_tmux_option "@forceline_wan_ip_providers" "ipify,icanhazip,checkip")" \
            "$(get_tmux_option "@forceline_wan_ip_online_fg" "#{@fg}")" \
            "$(get_tmux_option "@forceline_wan_ip_online_bg" "#{@success}")" \
            "$(get_tmux_option "@forceline_wan_ip_cached_fg" "#{@fg}")" \
            "$(get_tmux_option "@forceline_wan_ip_cached_bg" "#{@surface_0}")" \
            "$(get_tmux_option "@forceline_wan_ip_stale_fg" "#{@base00}")" \
            "$(get_tmux_option "@forceline_wan_ip_stale_bg" "#{@warning}")" \
            "$(get_tmux_option "@forceline_wan_ip_offline_fg" "#{@base00}")" \
            "$(get_tmux_option "@forceline_wan_ip_offline_bg" "#{@error}")"
        ;;
    enhanced)
        get_wan_info_enhanced \
            "${1:-$(get_tmux_option "@forceline_wan_ip_cache_ttl" "900")}" \
            "${2:-$(get_tmux_option "@forceline_wan_ip_timeout" "3")}" \
            "${3:-$(get_tmux_option "@forceline_wan_ip_format" "ip")}"
        ;;
    *)
        echo "Usage: main.sh {data|color|enhanced|init} [args...]" >&2
        exit 1
        ;;
esac

#!/usr/bin/env bash
set -euo pipefail
source "${FORCELINE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null && pwd)}/utils/source_helpers.sh"
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
source "$CURRENT_DIR/functions.sh"

cmd="${1:-data}"; shift || true

case "$cmd" in
    data)
        format="${1:-$(get_tmux_option "@forceline_lan_ip_format" "primary")}"
        interface="${2:-$(get_tmux_option "@forceline_lan_ip_interface" "")}"
        show_interface="${3:-$(get_tmux_option "@forceline_lan_ip_show_interface" "no")}"
        case "$format" in
            "all") get_all_lan_ips "$show_interface" ;;
            *)     get_primary_lan_ip "$interface" "$show_interface" ;;
        esac
        ;;
    *)
        echo "Usage: main.sh data [format] [interface] [show_interface]" >&2
        echo "       main.sh init" >&2
        exit 1
        ;;
esac

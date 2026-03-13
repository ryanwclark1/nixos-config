#!/usr/bin/env bash
set -euo pipefail
source "${FORCELINE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null && pwd)}/utils/source_helpers.sh"
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
source "$CURRENT_DIR/functions.sh"

# Read tmux options
enabled="$(get_tmux_option "@forceline_transient_enabled" "true")"
duration="$(get_tmux_option "@forceline_transient_duration" "10")"
priority="$(get_tmux_option "@forceline_transient_priority" "medium")"

cmd="${1:-status}"; shift || true

case "$cmd" in
    status)
        get_transient_status "$enabled" "$duration" "$priority"
        ;;
    success)
        trigger_success "${1:-}" "${2:-}"
        ;;
    warning)
        trigger_warning "${1:-}" "${2:-}"
        ;;
    error)
        trigger_error "${1:-}" "${2:-}"
        ;;
    info)
        trigger_info "${1:-}" "${2:-}"
        ;;
    clear)
        cache_dir=$(_transient_get_cache_dir) && rm -f "$cache_dir"/transient_*.cache 2>/dev/null || true
        ;;
    *)
        echo "Usage: $0 {status|success|warning|error|info|clear} [message] [duration]" >&2
        exit 1
        ;;
esac

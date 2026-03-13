#!/usr/bin/env bash
set -euo pipefail
source "${FORCELINE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null && pwd)}/utils/source_helpers.sh"
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
source "$CURRENT_DIR/functions.sh"

cmd="${1:-data}"; shift || true

case "$cmd" in
    data)
        path="${1:-$(get_tmux_option "@forceline_disk_usage_path" "/")}"
        format="${2:-$(get_tmux_option "@forceline_disk_usage_format" "percentage")}"
        show_path="${3:-$(get_tmux_option "@forceline_disk_usage_show_path" "no")}"
        show_status="${4:-$(get_tmux_option "@forceline_disk_usage_show_status" "no")}"
        warning_thresh="${5:-$(get_tmux_option "@forceline_disk_usage_warning_threshold" "80")}"
        critical_thresh="${6:-$(get_tmux_option "@forceline_disk_usage_critical_threshold" "90")}"
        get_disk_usage_with_status "$path" "$format" "$show_path" "$show_status" "$warning_thresh" "$critical_thresh"
        ;;
    *)
        echo "Usage: main.sh data [path] [format] [show_path] [show_status] [warning_thresh] [critical_thresh]" >&2
        echo "       main.sh init" >&2
        exit 1
        ;;
esac

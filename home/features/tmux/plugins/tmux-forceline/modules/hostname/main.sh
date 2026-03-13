#!/usr/bin/env bash
set -euo pipefail
source "${FORCELINE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null && pwd)}/utils/source_helpers.sh"
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
source "$CURRENT_DIR/functions.sh"

cmd="${1:-data}"; shift || true

case "$cmd" in
    data)
        format="${1:-$(get_tmux_option "@forceline_hostname_format" "short")}"
        custom="${2:-$(get_tmux_option "@forceline_hostname_custom" "")}"
        show_icon="${3:-$(get_tmux_option "@forceline_hostname_show_icon" "no")}"
        get_hostname_with_icon "$format" "$custom" "$show_icon"
        ;;
    *)
        echo "Usage: main.sh data [format] [custom] [show_icon]" >&2
        exit 1
        ;;
esac

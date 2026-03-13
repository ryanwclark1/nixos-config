#!/usr/bin/env bash
set -euo pipefail
source "${FORCELINE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null && pwd)}/utils/source_helpers.sh"
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
source "$CURRENT_DIR/functions.sh"

cmd="${1:-average}"; shift || true

case "$cmd" in
    average)
        format="${1:-$(get_tmux_option "@forceline_load_format" "average")}"
        precision="${2:-$(get_tmux_option "@forceline_load_precision" "1")}"
        show_color="${3:-$(get_tmux_option "@forceline_load_show_color" "no")}"
        get_load_with_color "$format" "$precision" "$show_color"
        ;;
    *)
        echo "Usage: main.sh average [format] [precision] [show_color]" >&2
        exit 1
        ;;
esac

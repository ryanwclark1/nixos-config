#!/usr/bin/env bash
set -euo pipefail
source "${FORCELINE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null && pwd)}/utils/source_helpers.sh"
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
source "$CURRENT_DIR/functions.sh"

cmd="${1:-data}"; shift || true

case "$cmd" in
    data)
        format="${1:-$(get_tmux_option "@forceline_uptime_format" "short")}"
        get_uptime "$format"
        ;;
    *)
        echo "Usage: main.sh data [format]" >&2
        exit 1
        ;;
esac

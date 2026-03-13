#!/usr/bin/env bash
set -euo pipefail

source "${FORCELINE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null && pwd)}/utils/source_helpers.sh"

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
source "$CURRENT_DIR/functions.sh"

cmd="${1:-percentage}"; shift || true

case "$cmd" in
    percentage)
        fmt="${1:-}"
        if [[ -z "$fmt" ]]; then
            fmt="$(get_tmux_option "@memory_percentage_format" "%3.1f%%")"
        fi
        print_memory_percentage "$fmt"
        ;;
    *)
        echo "Usage: main.sh {percentage|init} [args...]" >&2
        exit 1
        ;;
esac

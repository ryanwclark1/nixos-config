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
            fmt="$(get_tmux_option "@cpu_percentage_format" "%3.1f%%")"
        fi
        print_cpu_percentage "$fmt"
        ;;
    temp)
        fmt="${1:-}"; unit="${2:-}"
        if [[ -z "$fmt" ]]; then
            fmt="$(get_tmux_option "@cpu_temp_format" "%2.0f")"
            unit="${unit:-$(get_tmux_option "@cpu_temp_unit" "C")}"
        fi
        print_cpu_temp "$fmt" "${unit:-C}"
        ;;
    *)
        echo "Usage: main.sh {percentage|temp|init} [args...]" >&2
        exit 1
        ;;
esac

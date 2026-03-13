#!/usr/bin/env bash
set -euo pipefail
source "${FORCELINE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null && pwd)}/utils/source_helpers.sh"
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
source "$CURRENT_DIR/functions.sh"

cmd="${1:-data}"; shift || true

case "$cmd" in
    data)
        location="$(get_tmux_option "@forceline_weather_location" "")"
        format="$(get_tmux_option "@forceline_weather_format" "1")"
        units="$(get_tmux_option "@forceline_weather_units" "u")"
        interval="$(get_tmux_option "@forceline_weather_interval" "15")"
        get_weather "$location" "$format" "$units" "$interval"
        ;;
    *)
        echo "Usage: $0 {data|init}" >&2
        exit 1
        ;;
esac

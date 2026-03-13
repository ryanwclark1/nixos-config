#!/usr/bin/env bash
set -euo pipefail
source "${FORCELINE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null && pwd)}/utils/source_helpers.sh"
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"

# Read tmux options before sourcing functions so the variables are set correctly
FORCELINE_CAVA_BARS="$(get_tmux_option "@forceline_cava_bars" "16")"
FORCELINE_CAVA_COLOR="$(get_tmux_option "@forceline_cava_color" "none")"
FORCELINE_CAVA_TTL="$(get_tmux_option "@forceline_cava_ttl" "1")"
FORCELINE_CAVA_SYMBOLS="$(get_tmux_option "@forceline_cava_symbols" "▁▂▃▄▅▆▇█")"
FORCELINE_CAVA_PALETTE="$(get_tmux_option "@forceline_cava_palette" "24,27,33,40,76,178,208,196")"
export FORCELINE_CAVA_BARS FORCELINE_CAVA_COLOR FORCELINE_CAVA_TTL FORCELINE_CAVA_SYMBOLS FORCELINE_CAVA_PALETTE

source "$CURRENT_DIR/functions.sh"

# Initialize computed variables (resolves color mode, sets cache paths, etc.)
_cava_init_computed

trap cava_cleanup EXIT

cmd="${1:-}"; shift || true

case "$cmd" in
    stream) stream_output ;;
    fresh)  capture_frame || echo "$FALLBACK" ;;
    test)   run_test ;;
    *)      cached_output ;;
esac

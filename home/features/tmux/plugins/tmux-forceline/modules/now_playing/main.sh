#!/usr/bin/env bash
set -euo pipefail
source "${FORCELINE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null && pwd)}/utils/source_helpers.sh"
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
source "$CURRENT_DIR/functions.sh"

# Read tmux options
max_len="$(get_tmux_option "@forceline_now_playing_max_len" "30")"
truncate_symbol="$(get_tmux_option "@forceline_now_playing_truncate_symbol" "…")"
show_player="$(get_tmux_option "@forceline_now_playing_show_player" "no")"

cmd="${1:-}"; shift || true

# Validate
[[ "$max_len" =~ ^[0-9]+$ ]] && [ "$max_len" -ge 5 ] && [ "$max_len" -le 200 ] || max_len=30
[[ "$show_player" =~ ^(yes|no)$ ]] || show_player="no"

export FORCELINE_NOW_PLAYING_MAX_LEN="$max_len"
export FORCELINE_NOW_PLAYING_TRUNCATE_SYMBOL="$truncate_symbol"
export FORCELINE_NOW_PLAYING_SHOW_PLAYER="$show_player"

case "$cmd" in
    icon)
        get_player_icon 2>/dev/null || echo "♪"
        ;;
    player)
        detect_active_player
        ;;
    status)
        if detect_active_player >/dev/null 2>&1; then
            echo "playing"
        else
            echo "stopped"
        fi
        ;;
    cached|"")
        get_cached_now_playing_status
        ;;
    *)
        get_cached_now_playing_status
        ;;
esac

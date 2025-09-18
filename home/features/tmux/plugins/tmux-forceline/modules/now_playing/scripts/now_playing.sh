#!/usr/bin/env bash
# Now playing script for tmux-forceline v2.0
# Enhanced media player monitoring with cross-platform support

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/now_playing_helpers.sh"

# Get tmux option or use default
get_tmux_option() {
    local option="$1"
    local default="$2"
    tmux show-option -gqv "$option" 2>/dev/null || echo "$default"
}

# Main now playing function
main() {
    local format="$1"
    
    # Get configuration from tmux options
    local max_len truncate_symbol show_player
    
    max_len=$(get_tmux_option "@forceline_now_playing_max_len" "30")
    truncate_symbol=$(get_tmux_option "@forceline_now_playing_truncate_symbol" "…")
    show_player=$(get_tmux_option "@forceline_now_playing_show_player" "no")
    
    # Set environment variables for helpers
    export FORCELINE_NOW_PLAYING_MAX_LEN="$max_len"
    export FORCELINE_NOW_PLAYING_TRUNCATE_SYMBOL="$truncate_symbol"
    export FORCELINE_NOW_PLAYING_SHOW_PLAYER="$show_player"
    
    case "$format" in
        "icon")
            get_player_icon
            ;;
        "player")
            local status_output
            if status_output=$(get_spotify_status); then
                echo "spotify"
            elif status_output=$(get_apple_music_status); then
                echo "apple_music"
            elif status_output=$(get_mpd_status); then
                echo "mpd"
            else
                echo "none"
            fi
            ;;
        *)
            get_now_playing_status "$show_player" "$max_len" "$truncate_symbol"
            ;;
    esac
}

# Execute if run directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
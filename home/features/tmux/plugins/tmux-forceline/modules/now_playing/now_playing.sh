#!/usr/bin/env bash
# Now playing script for tmux-forceline v3.0
# Enhanced media player monitoring with cross-platform support and caching

set -euo pipefail

# Global configuration
readonly SCRIPT_VERSION="3.0"
readonly CACHE_DURATION=5  # seconds
readonly MAX_RETRIES=3

# Source centralized path management
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/utils"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    # shellcheck source=../../utils/common.sh
    source "$UTILS_DIR/common.sh"
    
    # Source helpers using centralized path management
    HELPERS_PATH="$(get_forceline_path "modules/now_playing/scripts/now_playing_helpers.sh")"
    if [[ -f "$HELPERS_PATH" ]]; then
        source "$HELPERS_PATH"
    else
        echo "Error: Helper script not found" >&2
        exit 1
    fi
    
    # Enhanced tmux option getter with now_playing-specific validation
    get_tmux_option_validated() {
        local option="$1"
        local default="$2"
        local value
        
        value=$(get_tmux_option "$option" "$default")
        
        # Validate now_playing-specific options
        case "$option" in
            "@forceline_now_playing_max_len")
                if [[ "$value" =~ ^[0-9]+$ ]] && [ "$value" -ge 5 ] && [ "$value" -le 200 ]; then
                    echo "$value"
                else
                    echo "30"  # Safe default
                fi
                ;;
            "@forceline_now_playing_show_player")
                [[ "$value" =~ ^(yes|no)$ ]] && echo "$value" || echo "no"
                ;;
            *)
                echo "$value"
                ;;
        esac
    }
    
    # Override get_tmux_option to use validated version for this module
    get_tmux_option() {
        get_tmux_option_validated "$@"
    }
else
    # Fallback implementation if common.sh not available
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ -f "$CURRENT_DIR/scripts/now_playing_helpers.sh" ]]; then
        source "$CURRENT_DIR/scripts/now_playing_helpers.sh"
    else
        echo "Error: Helper script not found" >&2
        exit 1
    fi
    
    # Fallback implementation with validation
    get_tmux_option() {
        local option="$1"
        local default="$2"
        local value
        
        value=$(tmux show-option -gqv "$option" 2>/dev/null || echo "$default")
        
        # Validate specific options
        case "$option" in
            "@forceline_now_playing_max_len")
                if [[ "$value" =~ ^[0-9]+$ ]] && [ "$value" -ge 5 ] && [ "$value" -le 200 ]; then
                    echo "$value"
                else
                    echo "30"  # Safe default
                fi
                ;;
            "@forceline_now_playing_show_player")
                [[ "$value" =~ ^(yes|no)$ ]] && echo "$value" || echo "no"
                ;;
            *)
                echo "$value"
                ;;
        esac
    }
fi

# Get cache directory for status caching
get_cache_dir() {
    local cache_dir="${TMUX_TMPDIR:-${TMPDIR:-/tmp}}/tmux-forceline"
    mkdir -p "$cache_dir" 2>/dev/null || {
        echo "/tmp" # Fallback
        return 1
    }
    echo "$cache_dir"
}

# Check if cached result is still valid
is_cache_valid() {
    local cache_file="$1"
    local max_age="$2"
    
    [[ -f "$cache_file" ]] || return 1
    
    local file_age
    if command -v stat >/dev/null 2>&1; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            file_age=$(stat -f %m "$cache_file" 2>/dev/null || echo 0)
        else
            file_age=$(stat -c %Y "$cache_file" 2>/dev/null || echo 0)
        fi
    else
        return 1
    fi
    
    local current_time
    current_time=$(date +%s)
    
    [ $((current_time - file_age)) -lt "$max_age" ]
}

# Get cached status or generate new one
get_cached_status() {
    local cache_dir cache_file
    cache_dir=$(get_cache_dir) || return 1
    cache_file="$cache_dir/now_playing_status.cache"
    
    # Return cached result if valid
    if is_cache_valid "$cache_file" "$CACHE_DURATION"; then
        cat "$cache_file" 2>/dev/null && return 0
    fi
    
    # Generate new status
    local status show_player max_len truncate_symbol
    show_player="${FORCELINE_NOW_PLAYING_SHOW_PLAYER:-no}"
    max_len="${FORCELINE_NOW_PLAYING_MAX_LEN:-30}"
    truncate_symbol="${FORCELINE_NOW_PLAYING_TRUNCATE_SYMBOL:-…}"
    
    status=$(get_now_playing_status "$show_player" "$max_len" "$truncate_symbol" 2>/dev/null)
    local exit_code=$?
    
    # Cache the result (even if empty, to avoid frequent polling)
    {
        echo "$status"
    } > "$cache_file" 2>/dev/null || true
    
    echo "$status"
    return $exit_code
}

# Detect active player with retry logic
detect_active_player() {
    local retry_count=0
    
    while [ $retry_count -lt $MAX_RETRIES ]; do
        # Try each player in priority order
        if get_spotify_status >/dev/null 2>&1; then
            echo "spotify"
            return 0
        elif get_spotifyd_status >/dev/null 2>&1; then
            echo "spotifyd"
            return 0
        elif command -v osascript >/dev/null 2>&1 && get_apple_music_status >/dev/null 2>&1; then
            echo "apple_music"
            return 0
        elif command -v mpc >/dev/null 2>&1 && get_mpd_status >/dev/null 2>&1; then
            echo "mpd"
            return 0
        fi
        
        retry_count=$((retry_count + 1))
        [ $retry_count -lt $MAX_RETRIES ] && sleep 0.1
    done
    
    echo "none"
    return 1
}

# Main now playing function with enhanced error handling
main() {
    local format="${1:-}"
    
    # Get configuration from tmux options with validation
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
            if command -v get_player_icon >/dev/null 2>&1; then
                get_player_icon 2>/dev/null || echo "♪"
            else
                echo "♪"
            fi
            ;;
        "player")
            detect_active_player
            ;;
        "status")
            # Quick status check without full details
            if detect_active_player >/dev/null 2>&1; then
                echo "playing"
            else
                echo "stopped"
            fi
            ;;
        "cached")
            # Use cached status for better performance
            get_cached_status
            ;;
        "")
            # Default behavior - full status with caching
            get_cached_status
            ;;
        *)
            # Unknown format - fall back to default
            get_cached_status
            ;;
    esac
}

# Enhanced error handling for direct execution
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    # Trap errors and provide meaningful feedback
    trap 'echo "Error in now_playing script" >&2; exit 1' ERR
    
    main "$@"
fi
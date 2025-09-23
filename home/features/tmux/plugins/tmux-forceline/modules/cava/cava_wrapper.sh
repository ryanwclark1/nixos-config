#!/usr/bin/env bash

# Simple Cava Wrapper - Direct solution for non-streaming cava output
# Wraps the original cava.sh and captures output in place

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ORIGINAL_CAVA="${SCRIPT_DIR}/cava.sh"
readonly CACHE_FILE="/tmp/cava_wrapper_cache"
readonly CACHE_DURATION="${CAVA_CACHE_SECONDS:-1}"

# Function to get single frame from original cava.sh
get_single_frame() {
    if [[ ! -f "$ORIGINAL_CAVA" ]]; then
        echo "♪♫♪♫♪♫♪♫"
        return 0
    fi
    
    # Check if cava command exists
    if ! command -v cava >/dev/null 2>&1; then
        echo "♪♫♪♫♪♫♪♫"
        return 0
    fi
    
    # Capture first line of output from the original cava.sh with timeout
    local output=""
    if output=$(timeout 2s "$ORIGINAL_CAVA" 2>/dev/null | head -n 1 | tr -d '\r\n'); then
        # Clean up any control characters and limit length
        output=$(echo "$output" | sed 's/[[:cntrl:]]//g' | cut -c 1-20)
        
        # Return output if we got something meaningful
        if [[ -n "$output" && ${#output} -ge 3 ]]; then
            echo "$output"
        else
            echo "♪♫♪♫♪♫♪♫"
        fi
    else
        echo "♪♫♪♫♪♫♪♫"
    fi
}

# Function to get cached output
get_cached_frame() {
    local current_time=$(date +%s)
    
    # Check cache validity
    if [[ -f "$CACHE_FILE" ]]; then
        local cache_time=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo "0")
        local cache_age=$((current_time - cache_time))
        
        if [[ $cache_age -lt $CACHE_DURATION ]]; then
            cat "$CACHE_FILE" 2>/dev/null && return 0
        fi
    fi
    
    # Generate and cache new output
    local fresh_output
    fresh_output=$(get_single_frame)
    echo "$fresh_output" | tee "$CACHE_FILE"
}

# Main function
case "${1:-cached}" in
    "cached"|"")
        get_cached_frame
        ;;
    "fresh")
        get_single_frame
        ;;
    "tmux")
        # Get output and escape for tmux
        get_cached_frame | sed 's/[#$]/\\&/g'
        ;;
    "test")
        echo "🧪 Testing cava wrapper..."
        echo "Original cava.sh: $([ -f "$ORIGINAL_CAVA" ] && echo "✅ Found" || echo "❌ Missing")"
        echo "Cava command: $(command -v cava >/dev/null 2>&1 && echo "✅ Available" || echo "❌ Not found")"
        echo ""
        echo "Fresh output: $(get_single_frame)"
        echo "Cached output: $(get_cached_frame)"
        echo "Tmux-safe: $(get_cached_frame | sed 's/[#$]/\\&/g')"
        ;;
    "clear")
        rm -f "$CACHE_FILE"
        echo "Cache cleared"
        ;;
    "monitor")
        echo "Monitoring cava wrapper output (Ctrl+C to stop):"
        while true; do
            printf "\r\033[K🎵 %s [%s]" "$(get_cached_frame)" "$(date '+%H:%M:%S')"
            sleep "$CACHE_DURATION"
        done
        ;;
    "help"|"--help"|"-h")
        cat << EOF
🎵 Simple Cava Wrapper

DESCRIPTION:
    Wraps the original cava.sh module to provide static, non-streaming output.
    Captures single frames instead of continuous streaming.

USAGE:
    $0 [command]

COMMANDS:
    cached      Get cached output (default, updates every ${CACHE_DURATION}s)
    fresh       Get fresh output (bypass cache)
    tmux        Get tmux-safe output
    test        Test functionality
    clear       Clear cache
    monitor     Monitor output updates
    help        Show this help

ENVIRONMENT:
    CAVA_CACHE_SECONDS=1    # Cache duration in seconds

TMUX INTEGRATION:
    # Add to tmux.conf:
    set -g status-right "#($0 tmux) %H:%M"
    set -g status-interval 1

    # Or with icon:
    set -g status-right "🎵 #($0) %H:%M"

EXAMPLES:
    $0                      # Get current cached output
    $0 fresh               # Force fresh capture
    $0 monitor             # Watch updates in real-time
EOF
        ;;
    *)
        echo "❌ Unknown command: $1"
        echo "💡 Use '$0 help' for usage"
        exit 1
        ;;
esac
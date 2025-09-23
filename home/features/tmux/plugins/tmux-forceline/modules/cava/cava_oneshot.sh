#!/usr/bin/env bash

# tmux-forceline One-Shot Cava Module
# Captures a single frame of cava output instead of streaming

set -euo pipefail

# Configuration
readonly CACHE_FILE="/tmp/tmux-forceline-cava-oneshot"
readonly CACHE_TTL="${FORCELINE_CAVA_TTL:-2}"
readonly MAX_WIDTH="${FORCELINE_CAVA_WIDTH:-16}"
readonly SHOW_ICON="${FORCELINE_CAVA_ICON:-true}"
readonly TIMEOUT_DURATION="${FORCELINE_CAVA_TIMEOUT:-3}"

# Cava configuration
readonly CAVA_CONFIG="/tmp/cava_oneshot_config"

# Create cava config for one-shot capture
create_cava_config() {
    cat > "$CAVA_CONFIG" << 'EOF'
[general]
framerate = 60
bars = 16
sleep_timer = 0

[input]
method = pulse

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
bit_format = 8bit
EOF
}

# Function to get one frame of cava output
get_cava_frame() {
    local output=""
    local bar="▁▂▃▄▅▆▇█"
    
    # Check if cava is available
    if ! command -v cava >/dev/null 2>&1; then
        echo "♪♫♪♫♪♫♪♫"
        return 0
    fi
    
    # Create cava config
    create_cava_config
    
    # Capture one frame from cava with timeout
    if output=$(timeout "$TIMEOUT_DURATION" cava -p "$CAVA_CONFIG" 2>/dev/null | head -n 1); then
        # Convert numbers to bars
        local result=""
        local i=0
        while [[ $i -lt ${#output} && ${#result} -lt $MAX_WIDTH ]]; do
            local char="${output:$i:1}"
            if [[ "$char" =~ ^[0-7]$ ]]; then
                result="${result}${bar:$char:1}"
            elif [[ "$char" != ";" ]]; then
                result="${result}${char}"
            fi
            ((i++))
        done
        
        # Clean up any remaining control characters
        result=$(echo "$result" | tr -d '\r\n\t' | sed 's/[[:cntrl:]]//g')
        
        # Ensure we have some output
        if [[ -z "$result" || ${#result} -lt 3 ]]; then
            result="♪♫♪♫♪♫♪♫"
        fi
        
        echo "$result"
    else
        # Fallback if cava fails
        echo "♪♫♪♫♪♫♪♫"
    fi
    
    # Cleanup
    rm -f "$CAVA_CONFIG"
}

# Function to get cached output
get_cached_output() {
    local current_time=$(date +%s)
    
    # Check if cache exists and is still valid
    if [[ -f "$CACHE_FILE" ]]; then
        local cache_time=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo "0")
        local cache_age=$((current_time - cache_time))
        
        if [[ $cache_age -lt $CACHE_TTL ]]; then
            cat "$CACHE_FILE" 2>/dev/null || get_fresh_output
            return 0
        fi
    fi
    
    # Generate fresh output
    get_fresh_output
}

# Function to get fresh output and cache it
get_fresh_output() {
    local output
    output=$(get_cava_frame)
    
    # Add icon if enabled
    if [[ "$SHOW_ICON" == "true" ]]; then
        output="🎵 ${output}"
    fi
    
    # Cache the output
    echo "$output" > "$CACHE_FILE"
    echo "$output"
}

# Function to get tmux-safe output
get_tmux_safe_output() {
    local output
    output=$(get_cached_output)
    
    # Escape characters that could cause issues in tmux
    output=$(echo "$output" | sed 's/[#$]/\\&/g')
    
    echo "$output"
}

# Function to test the module
test_module() {
    echo "🧪 Testing one-shot cava module..."
    echo ""
    
    echo "🔍 Checking dependencies:"
    echo "   cava: $(command -v cava >/dev/null 2>&1 && echo "✅ Available" || echo "❌ Not found")"
    echo "   timeout: $(command -v timeout >/dev/null 2>&1 && echo "✅ Available" || echo "❌ Not found")"
    echo ""
    
    echo "📊 Configuration:"
    echo "   Cache TTL: ${CACHE_TTL}s"
    echo "   Max Width: $MAX_WIDTH"
    echo "   Show Icon: $SHOW_ICON"
    echo "   Timeout: ${TIMEOUT_DURATION}s"
    echo ""
    
    echo "🎵 Testing output generation:"
    local test_output
    test_output=$(get_fresh_output)
    echo "   Raw output: '$test_output'"
    echo "   Length: ${#test_output}"
    echo ""
    
    echo "🔒 Testing tmux-safe output:"
    local safe_output
    safe_output=$(get_tmux_safe_output)
    echo "   Safe output: '$safe_output'"
    echo ""
    
    echo "⚡ Performance test (5 calls):"
    local start_time end_time
    start_time=$(date +%s%N)
    for i in {1..5}; do
        get_cached_output >/dev/null
    done
    end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 ))
    echo "   Total time: ${duration}ms (avg: $((duration / 5))ms per call)"
    
    echo ""
    echo "✅ Test completed"
}

# Function to monitor output in real-time
monitor_output() {
    echo "🎵 Monitoring cava one-shot output (Ctrl+C to stop)"
    echo ""
    
    while true; do
        printf "\r\033[K🎵 %s" "$(get_cached_output | sed 's/🎵 //')"
        sleep 1
    done
}

# Function to clear cache
clear_cache() {
    if [[ -f "$CACHE_FILE" ]]; then
        rm -f "$CACHE_FILE"
        echo "🗑️  Cache cleared"
    else
        echo "ℹ️  No cache to clear"
    fi
}

# Main function
main() {
    case "${1:-output}" in
        "output"|"")
            get_cached_output
            ;;
        "fresh")
            get_fresh_output
            ;;
        "tmux")
            get_tmux_safe_output
            ;;
        "test")
            test_module
            ;;
        "monitor")
            monitor_output
            ;;
        "clear"|"clear-cache")
            clear_cache
            ;;
        "help"|"--help"|"-h")
            cat << EOF
🎵 tmux-forceline One-Shot Cava Module

DESCRIPTION:
    Captures a single frame of cava audio visualization instead of streaming.
    Perfect for tmux status bars that need static, non-scrolling output.

USAGE:
    $0 [command]

COMMANDS:
    output      Get cached cava output (default)
    fresh       Get fresh cava output (bypass cache)
    tmux        Get tmux-safe output with escaped characters
    test        Test module functionality and performance
    monitor     Monitor output in real-time
    clear       Clear output cache
    help        Show this help message

CONFIGURATION:
    Environment variables:
    
    FORCELINE_CAVA_TTL=2        # Cache time-to-live in seconds
    FORCELINE_CAVA_WIDTH=16     # Maximum output width
    FORCELINE_CAVA_ICON=true    # Show music note icon
    FORCELINE_CAVA_TIMEOUT=3    # Timeout for cava capture

TMUX INTEGRATION:
    Add to your tmux.conf:
    
    # Basic integration
    set -g status-right "#($0 tmux) %H:%M"
    
    # With faster updates
    set -g status-right "#($0) %H:%M"
    set -g status-interval 1
    
    # Performance optimized
    set -g status-right "#($0 tmux) %H:%M"
    set -g status-interval 2

EXAMPLES:
    $0                          # Get current output
    $0 fresh                    # Force fresh capture
    $0 tmux                     # Get tmux-safe output
    
    # Test if working properly
    $0 test
    
    # Monitor output live
    $0 monitor

PERFORMANCE:
    - Uses caching to reduce cava calls
    - Timeout protection prevents hanging
    - Single frame capture (no streaming)
    - Optimized for tmux status bar updates
EOF
            ;;
        *)
            echo "❌ Unknown command: $1"
            echo "💡 Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Cleanup on exit
trap 'rm -f "$CAVA_CONFIG" 2>/dev/null || true' EXIT

# Run main function
main "$@"
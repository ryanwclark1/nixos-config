#!/usr/bin/env bash

# tmux-forceline Static Cava v2 - Better handling of cava streaming
# Captures single frame and prevents streaming output

set -euo pipefail

# Configuration
readonly CACHE_FILE="/tmp/tmux-forceline-cava-static"
readonly CACHE_TTL="${FORCELINE_CAVA_TTL:-1}"
readonly BARS="${FORCELINE_CAVA_BARS:-12}"
readonly SHOW_ICON="${FORCELINE_CAVA_ICON:-true}"
readonly FALLBACK_PATTERN="${FORCELINE_CAVA_FALLBACK:-♪♫♪♫♪♫}"

# Create optimized cava config for single frame capture
create_cava_config() {
    local config_file="/tmp/cava_static_config_$$"
    cat > "$config_file" << EOF
[general]
framerate = 30
bars = $BARS
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
    echo "$config_file"
}

# Function to capture one frame using a different approach
capture_cava_frame() {
    local config_file
    config_file=$(create_cava_config)
    local bar_chars="▁▂▃▄▅▆▇█"
    local result=""
    
    # Use a more controlled approach to get just one frame
    if command -v cava >/dev/null 2>&1; then
        # Start cava in background and capture first complete line
        local temp_output="/tmp/cava_capture_$$"
        
        # Run cava with timeout and capture to file
        timeout 2s cava -p "$config_file" > "$temp_output" 2>/dev/null &
        local cava_pid=$!
        
        # Wait a moment for cava to start producing output
        sleep 0.5
        
        # Kill cava and read the output
        kill $cava_pid 2>/dev/null || true
        wait $cava_pid 2>/dev/null || true
        
        # Process the captured output
        if [[ -f "$temp_output" ]]; then
            # Get the last complete line (most recent frame)
            local raw_line=$(tail -n 1 "$temp_output" 2>/dev/null | tr -d '\r\n')
            
            # Convert to bars
            local i=0
            while [[ $i -lt ${#raw_line} && ${#result} -lt $BARS ]]; do
                local char="${raw_line:$i:1}"
                if [[ "$char" =~ ^[0-7]$ ]]; then
                    result="${result}${bar_chars:$char:1}"
                elif [[ "$char" != ";" && "$char" != " " ]]; then
                    # Skip separators but keep other characters
                    result="${result}${char}"
                fi
                ((i++))
            done
            
            # Clean up
            rm -f "$temp_output"
        fi
        
        # Clean up config
        rm -f "$config_file"
    fi
    
    # Return result or fallback
    if [[ -n "$result" && ${#result} -ge 3 ]]; then
        echo "$result"
    else
        echo "$FALLBACK_PATTERN"
    fi
}

# Alternative method using head to capture first line
capture_cava_head() {
    local config_file
    config_file=$(create_cava_config)
    local bar_chars="▁▂▃▄▅▆▇█"
    local result=""
    
    if command -v cava >/dev/null 2>&1; then
        # Use head to get just the first line of output
        local raw_output
        if raw_output=$(timeout 2s cava -p "$config_file" 2>/dev/null | head -n 1 | tr -d '\r\n'); then
            # Convert to visualization
            local i=0
            while [[ $i -lt ${#raw_output} && ${#result} -lt $BARS ]]; do
                local char="${raw_output:$i:1}"
                if [[ "$char" =~ ^[0-7]$ ]]; then
                    result="${result}${bar_chars:$char:1}"
                elif [[ "$char" != ";" ]]; then
                    result="${result}${char}"
                fi
                ((i++))
            done
        fi
        rm -f "$config_file"
    fi
    
    # Return result or fallback
    if [[ -n "$result" && ${#result} -ge 3 ]]; then
        echo "$result"
    else
        echo "$FALLBACK_PATTERN"
    fi
}

# Get static output with caching
get_static_output() {
    local current_time=$(date +%s)
    
    # Check cache validity
    if [[ -f "$CACHE_FILE" ]]; then
        local cache_time=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo "0")
        local cache_age=$((current_time - cache_time))
        
        if [[ $cache_age -lt $CACHE_TTL ]]; then
            cat "$CACHE_FILE" 2>/dev/null && return 0
        fi
    fi
    
    # Generate fresh output
    local output
    output=$(capture_cava_head)  # Try head method first
    
    # If that didn't work, try frame capture method
    if [[ "$output" == "$FALLBACK_PATTERN" ]]; then
        output=$(capture_cava_frame)
    fi
    
    # Add icon if requested
    if [[ "$SHOW_ICON" == "true" ]]; then
        output="🎵 ${output}"
    fi
    
    # Cache and return
    echo "$output" | tee "$CACHE_FILE"
}

# Get tmux-safe output
get_tmux_output() {
    local output
    output=$(get_static_output)
    # Escape special characters for tmux
    echo "$output" | sed 's/[#$]/\\&/g'
}

# Test different capture methods
test_capture_methods() {
    echo "🧪 Testing different cava capture methods..."
    echo ""
    
    echo "📋 Method 1: Head capture"
    local method1_output
    method1_output=$(capture_cava_head)
    echo "   Output: '$method1_output'"
    echo "   Length: ${#method1_output}"
    echo ""
    
    echo "📋 Method 2: Frame capture"
    local method2_output
    method2_output=$(capture_cava_frame)
    echo "   Output: '$method2_output'"
    echo "   Length: ${#method2_output}"
    echo ""
    
    echo "📋 Combined result:"
    local final_output
    final_output=$(get_static_output)
    echo "   Final: '$final_output'"
    echo ""
}

# Simple monitoring without streaming
monitor_static() {
    echo "🎵 Static cava monitoring (Ctrl+C to stop)"
    echo "Updates every ${CACHE_TTL}s with static output"
    echo ""
    
    while true; do
        local output
        output=$(get_static_output)
        printf "\r\033[K%s [%s]" "$output" "$(date '+%H:%M:%S')"
        sleep "$CACHE_TTL"
    done
}

# Show current configuration
show_config() {
    cat << EOF
🎵 Cava Static v2 Configuration

📊 Settings:
   Cache TTL: ${CACHE_TTL}s
   Bars: $BARS
   Show Icon: $SHOW_ICON
   Fallback: $FALLBACK_PATTERN

📁 Files:
   Cache: $CACHE_FILE
   
🎛️  Environment Variables:
   FORCELINE_CAVA_TTL      - Cache duration (default: 1)
   FORCELINE_CAVA_BARS     - Number of bars (default: 12)  
   FORCELINE_CAVA_ICON     - Show icon (default: true)
   FORCELINE_CAVA_FALLBACK - Fallback pattern

📝 Usage:
   $0           - Get static output (cached)
   $0 fresh     - Force fresh capture
   $0 tmux      - Get tmux-safe output
   $0 test      - Test capture methods
   $0 monitor   - Monitor static updates
EOF
}

# Main execution
main() {
    case "${1:-output}" in
        "output"|"")
            get_static_output
            ;;
        "fresh")
            rm -f "$CACHE_FILE"
            get_static_output
            ;;
        "tmux")
            get_tmux_output
            ;;
        "test")
            test_capture_methods
            ;;
        "monitor")
            monitor_static
            ;;
        "config")
            show_config
            ;;
        "clear")
            rm -f "$CACHE_FILE"
            echo "🗑️  Cache cleared"
            ;;
        "help"|"--help"|"-h")
            cat << EOF
🎵 tmux-forceline Static Cava v2

DESCRIPTION:
    Improved static cava wrapper that captures single frames without streaming.
    Uses multiple capture methods for better reliability.

USAGE:
    $0 [command]

COMMANDS:
    output      Get cached static output (default)
    fresh       Force fresh capture (ignore cache)
    tmux        Get tmux-safe output
    test        Test different capture methods
    monitor     Monitor static updates
    config      Show configuration
    clear       Clear cache
    help        Show this help

TMUX INTEGRATION:
    # Add to tmux.conf
    set -g status-right "#($0 tmux) %H:%M"
    set -g status-interval 1

CUSTOMIZATION:
    export FORCELINE_CAVA_TTL=2        # Update every 2 seconds
    export FORCELINE_CAVA_BARS=16      # 16 bars wide
    export FORCELINE_CAVA_ICON=false   # No icon
EOF
            ;;
        *)
            echo "❌ Unknown command: $1"
            echo "💡 Use '$0 help' for usage"
            exit 1
            ;;
    esac
}

# Cleanup on exit
trap 'rm -f /tmp/cava_static_config_$$ /tmp/cava_capture_$$ 2>/dev/null || true' EXIT

# Run main
main "$@"
#!/usr/bin/env bash

# tmux-forceline Static Cava Module Wrapper
# Wraps cava.sh module to provide static, non-streaming output

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CAVA_MODULE="${SCRIPT_DIR}/cava.sh"
readonly UPDATE_INTERVAL="${FORCELINE_CAVA_UPDATE_INTERVAL:-1}"
readonly MAX_WIDTH="${FORCELINE_CAVA_MAX_WIDTH:-20}"
readonly SHOW_TITLE="${FORCELINE_CAVA_SHOW_TITLE:-true}"

# Check if cava module exists
if [[ ! -f "$CAVA_MODULE" ]]; then
    echo "❌ Cava module not found: $CAVA_MODULE"
    exit 1
fi

# Check if cava is installed
if ! command -v cava >/dev/null 2>&1; then
    echo "🎵 ──────"
    exit 0
fi

# Function to get static cava output
get_static_cava_output() {
    local output=""
    local title=""
    
    # Get current audio visualization from cava module
    if [[ -x "$CAVA_MODULE" ]]; then
        # Capture cava output with timeout to prevent hanging
        if output=$(timeout 2s "$CAVA_MODULE" 2>/dev/null || echo ""); then
            # Clean up the output - remove ANSI escape sequences and control characters
            output=$(echo "$output" | sed 's/\x1b\[[0-9;]*m//g' | tr -d '\r\n' | head -c "$MAX_WIDTH")
            
            # If output is empty or too short, provide fallback
            if [[ -z "$output" || ${#output} -lt 3 ]]; then
                output="♪ ─────"
            fi
        else
            output="♪ ─────"
        fi
    else
        output="♪ ─────"
    fi
    
    # Add title if enabled
    if [[ "$SHOW_TITLE" == "true" ]]; then
        title="🎵 "
    fi
    
    echo "${title}${output}"
}

# Function to get cached output (for performance)
get_cached_cava_output() {
    local cache_file="/tmp/tmux-forceline-cava-cache"
    local cache_ttl=1  # 1 second cache
    local current_time=$(date +%s)
    
    # Check if cache exists and is still valid
    if [[ -f "$cache_file" ]]; then
        local cache_time=$(stat -c %Y "$cache_file" 2>/dev/null || echo "0")
        local cache_age=$((current_time - cache_time))
        
        if [[ $cache_age -lt $cache_ttl ]]; then
            cat "$cache_file"
            return 0
        fi
    fi
    
    # Generate new output and cache it
    local output
    output=$(get_static_cava_output)
    echo "$output" > "$cache_file"
    echo "$output"
}

# Function to run in monitoring mode (for development/testing)
run_monitoring_mode() {
    echo "🎵 Starting cava static output monitoring..."
    echo "Press Ctrl+C to stop"
    echo ""
    
    # Clear screen and position cursor
    printf "\033[2J\033[H"
    
    local line_count=0
    while true; do
        # Move cursor to beginning of line and clear it
        printf "\r\033[K"
        
        # Get and display current output
        local output
        output=$(get_cached_cava_output)
        printf "%s" "$output"
        
        # Update counter
        ((line_count++))
        
        # Show update info every 10 updates
        if [[ $((line_count % 10)) -eq 0 ]]; then
            printf " [Updated: %d times]" "$line_count"
        fi
        
        sleep "$UPDATE_INTERVAL"
    done
}

# Function to create a tmux-friendly output
get_tmux_output() {
    local output
    output=$(get_cached_cava_output)
    
    # Ensure output is tmux-safe (no special characters that could break tmux)
    output=$(echo "$output" | sed 's/[#$]/\\&/g')
    
    echo "$output"
}

# Function to test cava module
test_cava_module() {
    echo "🧪 Testing cava module wrapper..."
    echo ""
    
    echo "📍 Module location: $CAVA_MODULE"
    echo "📍 Module exists: $([ -f "$CAVA_MODULE" ] && echo "✅ Yes" || echo "❌ No")"
    echo "📍 Module executable: $([ -x "$CAVA_MODULE" ] && echo "✅ Yes" || echo "❌ No")"
    echo "📍 Cava installed: $(command -v cava >/dev/null 2>&1 && echo "✅ Yes" || echo "❌ No")"
    echo ""
    
    echo "🔄 Testing output generation..."
    local test_output
    test_output=$(get_static_cava_output)
    echo "📤 Output: '$test_output'"
    echo "📏 Length: ${#test_output} characters"
    echo ""
    
    echo "🎯 Testing tmux-safe output..."
    local tmux_output
    tmux_output=$(get_tmux_output)
    echo "📤 Tmux output: '$tmux_output'"
    echo ""
    
    echo "✅ Test completed"
}

# Function to show configuration
show_config() {
    cat << EOF
🎵 Cava Static Module Configuration

📁 Paths:
   Script Directory: $SCRIPT_DIR
   Cava Module: $CAVA_MODULE
   Cache File: /tmp/tmux-forceline-cava-cache

⚙️  Settings:
   Update Interval: ${UPDATE_INTERVAL}s
   Max Width: $MAX_WIDTH characters
   Show Title: $SHOW_TITLE
   Cache TTL: 1 second

🎛️  Environment Variables:
   FORCELINE_CAVA_UPDATE_INTERVAL: Update frequency in seconds
   FORCELINE_CAVA_MAX_WIDTH: Maximum output width
   FORCELINE_CAVA_SHOW_TITLE: Show music note title (true/false)

📝 Usage Examples:
   $0                    # Get current static output
   $0 monitor           # Run in monitoring mode
   $0 tmux             # Get tmux-safe output
   $0 test             # Test module functionality
   $0 config           # Show this configuration
EOF
}

# Main function
main() {
    local mode="${1:-output}"
    
    case "$mode" in
        "output"|"")
            get_static_cava_output
            ;;
        "cached")
            get_cached_cava_output
            ;;
        "tmux")
            get_tmux_output
            ;;
        "monitor"|"monitoring")
            run_monitoring_mode
            ;;
        "test")
            test_cava_module
            ;;
        "config"|"configuration")
            show_config
            ;;
        "help"|"--help"|"-h")
            cat << EOF
🎵 tmux-forceline Static Cava Module Wrapper

DESCRIPTION:
    Provides static, non-streaming audio visualization output from cava.
    Designed for use in tmux status bars and other static display contexts.

USAGE:
    $0 [MODE]

MODES:
    output      Get current static cava output (default)
    cached      Get cached output (faster, 1s cache)
    tmux        Get tmux-safe output (escaped special characters)
    monitor     Run in monitoring mode (live updates)
    test        Test module functionality
    config      Show configuration settings
    help        Show this help message

CONFIGURATION:
    Set environment variables to customize behavior:
    
    export FORCELINE_CAVA_UPDATE_INTERVAL=1    # Update every 1 second
    export FORCELINE_CAVA_MAX_WIDTH=20         # Max 20 characters wide
    export FORCELINE_CAVA_SHOW_TITLE=true      # Show music note emoji

EXAMPLES:
    # Basic usage (for tmux status bar)
    $0

    # Get tmux-safe output
    $0 tmux

    # Monitor output in real-time
    $0 monitor

    # Test if everything is working
    $0 test

TMUX INTEGRATION:
    Add to your tmux configuration:
    
    set -g status-right "#($SCRIPT_DIR/$(basename "$0") tmux)"
    
    Or use in tmux-forceline:
    
    set -g @fl_cava_enabled "on"
    set -g @fl_cava_static "on"

REQUIREMENTS:
    - cava installed and in PATH
    - Original cava.sh module present
    - Bash 4.0+
EOF
            ;;
        *)
            echo "❌ Unknown mode: $mode"
            echo "💡 Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Error handling
trap 'echo "❌ Error occurred in cava static wrapper"; exit 1' ERR

# Run main function with all arguments
main "$@"
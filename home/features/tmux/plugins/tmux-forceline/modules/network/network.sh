#!/usr/bin/env bash
# Network statistics script for tmux-forceline v3.0
# Enhanced interface bandwidth monitoring with cross-platform support

set -euo pipefail

# Global configuration
readonly SCRIPT_VERSION="3.0"
readonly CACHE_RETENTION_MINUTES=30
readonly MIN_UPDATE_INTERVAL=1

# Source centralized tmux functions
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/utils"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    # shellcheck source=../utils/common.sh
    source "$UTILS_DIR/common.sh"
    
    # Enhanced tmux option getter with network-specific validation
    get_tmux_option_validated() {
        local option="$1"
        local default="$2"
        local value
        value=$(get_tmux_option "$option" "$default")
        
        # Validate network-specific options
        case "$option" in
            "@forceline_network_units")
                [[ "$value" =~ ^(auto|B|KB|MB|GB)$ ]] || value="auto"
                ;;
            "@forceline_network_interval")
                [[ "$value" =~ ^[0-9]+$ ]] && [ "$value" -ge "$MIN_UPDATE_INTERVAL" ] || value="2"
                ;;
        esac
        
        echo "$value"
    }
    
    # Override get_tmux_option to use validated version for this module
    get_tmux_option() {
        get_tmux_option_validated "$@"
    }
else
    # Fallback implementation with validation
    get_tmux_option() {
        local option="$1"
        local default="$2"
        local value
        value=$(tmux show-option -gqv "$option" 2>/dev/null || echo "$default")
        
        # Validate common options
        case "$option" in
            "@forceline_network_units")
                [[ "$value" =~ ^(auto|B|KB|MB|GB)$ ]] || value="auto"
                ;;
            "@forceline_network_interval")
                [[ "$value" =~ ^[0-9]+$ ]] && [ "$value" -ge "$MIN_UPDATE_INTERVAL" ] || value="2"
                ;;
        esac
        
        echo "$value"
    }
fi

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Get cache directory with cleanup
get_cache_dir() {
    local cache_dir="${TMUX_TMPDIR:-${TMPDIR:-/tmp}}/tmux-forceline"
    mkdir -p "$cache_dir" 2>/dev/null || {
        echo "/tmp" # Fallback if creation fails
        return 1
    }
    
    # Cleanup old cache files periodically
    find "$cache_dir" -name "network_*.cache" -mmin +$CACHE_RETENTION_MINUTES -delete 2>/dev/null || true
    
    echo "$cache_dir"
}

# Enhanced format bytes with decimal precision for auto mode
format_bytes() {
    local bytes="$1"
    local unit="$2"
    local precision="${3:-1}" # Default 1 decimal place
    
    # Input validation
    if [[ ! "$bytes" =~ ^[0-9]+$ ]] || [ "$bytes" -eq 0 ]; then
        echo "0B"
        return
    fi
    
    case "$unit" in
        "auto")
            if [ "$bytes" -ge 1073741824 ]; then
                # GB with decimal precision
                local gb_whole=$((bytes / 1073741824))
                local gb_decimal=$(((bytes % 1073741824) * 10 / 1073741824))
                echo "${gb_whole}.${gb_decimal}GB"
            elif [ "$bytes" -ge 1048576 ]; then
                # MB with decimal precision
                local mb_whole=$((bytes / 1048576))
                local mb_decimal=$(((bytes % 1048576) * 10 / 1048576))
                echo "${mb_whole}.${mb_decimal}MB"
            elif [ "$bytes" -ge 1024 ]; then
                # KB - usually no decimals needed
                echo "$((bytes / 1024))KB"
            else
                echo "${bytes}B"
            fi
            ;;
        "GB")
            local gb_value=$((bytes / 1073741824))
            echo "${gb_value}GB"
            ;;
        "MB")
            local mb_value=$((bytes / 1048576))
            echo "${mb_value}MB"
            ;;
        "KB")
            local kb_value=$((bytes / 1024))
            echo "${kb_value}KB"
            ;;
        *)
            echo "${bytes}B"
            ;;
    esac
}

# Get network interface statistics (Linux)
get_linux_network_stats() {
    local interface="$1"
    
    if [ ! -r "/proc/net/dev" ]; then
        return 1
    fi
    
    local stats
    stats=$(grep "^[[:space:]]*$interface:" /proc/net/dev 2>/dev/null)
    
    if [ -z "$stats" ]; then
        return 1
    fi
    
    # Parse /proc/net/dev format: interface: rx_bytes ... tx_bytes ...
    local rx_bytes tx_bytes
    rx_bytes=$(echo "$stats" | awk '{print $2}')
    tx_bytes=$(echo "$stats" | awk '{print $10}')
    
    echo "$rx_bytes:$tx_bytes"
}

# Get network interface statistics (macOS)
get_macos_network_stats() {
    local interface="$1"
    
    if ! command_exists netstat; then
        return 1
    fi
    
    local stats
    stats=$(netstat -ibn | grep "^$interface" | head -1 2>/dev/null)
    
    if [ -z "$stats" ]; then
        return 1
    fi
    
    # Parse netstat output
    local rx_bytes tx_bytes
    rx_bytes=$(echo "$stats" | awk '{print $7}')
    tx_bytes=$(echo "$stats" | awk '{print $10}')
    
    echo "$rx_bytes:$tx_bytes"
}

# Get primary network interface
get_primary_interface() {
    local interface=""
    
    if command_exists ip; then
        # Linux with iproute2
        interface=$(ip route | grep '^default' | head -1 | sed 's/.*dev \([^ ]*\).*/\1/')
    elif command_exists route; then
        # macOS/BSD
        if [[ "$OSTYPE" == "darwin"* ]]; then
            interface=$(route -n get default | grep interface | awk '{print $2}')
        else
            interface=$(route -n | grep '^0.0.0.0' | head -1 | awk '{print $NF}')
        fi
    fi
    
    echo "$interface"
}

# Enhanced bandwidth calculation with overflow protection and smoothing
calculate_bandwidth() {
    local current_stats="$1"
    local interface="$2"
    local unit="$3"
    
    local cache_dir cache_file
    cache_dir=$(get_cache_dir) || return 1
    cache_file="$cache_dir/network_${interface}.cache"
    
    local current_time current_rx current_tx
    current_time=$(date +%s)
    IFS=: read -r current_rx current_tx <<< "$current_stats"
    
    # Validate input data
    if [[ ! "$current_rx" =~ ^[0-9]+$ ]] || [[ ! "$current_tx" =~ ^[0-9]+$ ]]; then
        echo "N/A"
        return 1
    fi
    
    # Check if we have previous data
    if [ -f "$cache_file" ] && [ -r "$cache_file" ]; then
        local prev_time prev_rx prev_tx
        IFS=: read -r prev_time prev_rx prev_tx < "$cache_file" 2>/dev/null
        
        if [[ "$prev_time" =~ ^[0-9]+$ ]] && [[ "$prev_rx" =~ ^[0-9]+$ ]] && [[ "$prev_tx" =~ ^[0-9]+$ ]]; then
            local time_diff rx_diff tx_diff rx_rate tx_rate
            time_diff=$((current_time - prev_time))
            
            # Only calculate if we have a reasonable time difference
            if [ "$time_diff" -ge "$MIN_UPDATE_INTERVAL" ] && [ "$time_diff" -lt 3600 ]; then
                # Handle counter overflow (32-bit counters wrap at ~4GB)
                if [ "$current_rx" -ge "$prev_rx" ]; then
                    rx_diff=$((current_rx - prev_rx))
                else
                    # Counter wrapped, estimate the difference
                    rx_diff=$((4294967296 + current_rx - prev_rx))
                fi
                
                if [ "$current_tx" -ge "$prev_tx" ]; then
                    tx_diff=$((current_tx - prev_tx))
                else
                    # Counter wrapped, estimate the difference
                    tx_diff=$((4294967296 + current_tx - prev_tx))
                fi
                
                # Calculate rates (bytes per second)
                rx_rate=$((rx_diff / time_diff))
                tx_rate=$((tx_diff / time_diff))
                
                # Sanity check: reject unrealistic values (>10Gbps)
                local max_rate=$((1250000000)) # 10Gbps in bytes/sec
                if [ "$rx_rate" -le "$max_rate" ] && [ "$tx_rate" -le "$max_rate" ]; then
                    # Format output
                    local rx_formatted tx_formatted
                    rx_formatted=$(format_bytes "$rx_rate" "$unit")
                    tx_formatted=$(format_bytes "$tx_rate" "$unit")
                    
                    echo "↓${rx_formatted}/s ↑${tx_formatted}/s"
                else
                    echo "N/A"
                fi
            fi
        fi
    fi
    
    # Save current stats for next calculation (with error handling)
    {
        echo "$current_time:$current_rx:$current_tx"
    } > "$cache_file" 2>/dev/null || true
}

# Main network statistics function
main() {
    local format="${1:-}"
    
    # Get configuration from tmux options
    local interface unit show_interface
    
    interface=$(get_tmux_option "@forceline_network_interface" "")
    unit=$(get_tmux_option "@forceline_network_unit" "auto")
    show_interface=$(get_tmux_option "@forceline_network_show_interface" "no")
    
    # Auto-detect interface if not specified or set to "auto"
    if [ -z "$interface" ] || [ "$interface" = "auto" ]; then
        interface=$(get_primary_interface)
    fi
    
    if [ -z "$interface" ]; then
        echo "N/A"
        return 1
    fi
    
    # Get interface statistics
    local stats=""
    if [[ "$OSTYPE" == "darwin"* ]]; then
        stats=$(get_macos_network_stats "$interface")
    else
        stats=$(get_linux_network_stats "$interface")
    fi
    
    if [ -z "$stats" ]; then
        echo "N/A"
        return 1
    fi
    
    case "$format" in
        "bandwidth")
            calculate_bandwidth "$stats" "$interface" "$unit"
            ;;
        "interface")
            echo "$interface"
            ;;
        "total")
            local rx_bytes tx_bytes
            IFS=: read -r rx_bytes tx_bytes <<< "$stats"
            local rx_formatted tx_formatted
            rx_formatted=$(format_bytes "$rx_bytes" "$unit")
            tx_formatted=$(format_bytes "$tx_bytes" "$unit")
            echo "↓${rx_formatted} ↑${tx_formatted}"
            ;;
        *)
            calculate_bandwidth "$stats" "$interface" "$unit"
            ;;
    esac
    
    return 0
}

# Execute if run directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
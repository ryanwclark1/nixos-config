#!/usr/bin/env bash
# Pure network functions for tmux-forceline
# Source this file — not meant to be executed directly

if [[ -z "${FL_VERSION:-}" ]]; then
    source "${FORCELINE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null && pwd)}/utils/pure_helpers.sh"
fi

# Global configuration
readonly NETWORK_CACHE_RETENTION_MINUTES=30
readonly NETWORK_MIN_UPDATE_INTERVAL=1

# command_exists, get_module_cache_dir, is_cache_valid are provided by pure_helpers.sh
get_cache_dir() {
    local cache_dir
    cache_dir=$(get_module_cache_dir "network") || { echo "/tmp"; return 1; }
    # Cleanup old cache files periodically
    find "$cache_dir" -name "network_*.cache" -mmin +$NETWORK_CACHE_RETENTION_MINUTES -delete 2>/dev/null || true
    echo "$cache_dir"
}

# Enhanced format bytes with decimal precision for auto mode
format_bytes() {
    local bytes="$1"
    local unit="$2"

    # Input validation
    if [[ ! "$bytes" =~ ^[0-9]+$ ]] || [ "$bytes" -eq 0 ]; then
        echo "0B"
        return
    fi

    case "$unit" in
        "auto")
            if [ "$bytes" -ge 1073741824 ]; then
                local gb_whole=$((bytes / 1073741824))
                local gb_decimal=$(((bytes % 1073741824) * 10 / 1073741824))
                echo "${gb_whole}.${gb_decimal}GB"
            elif [ "$bytes" -ge 1048576 ]; then
                local mb_whole=$((bytes / 1048576))
                local mb_decimal=$(((bytes % 1048576) * 10 / 1048576))
                echo "${mb_whole}.${mb_decimal}MB"
            elif [ "$bytes" -ge 1024 ]; then
                echo "$((bytes / 1024))KB"
            else
                echo "${bytes}B"
            fi
            ;;
        "GB")
            echo "$((bytes / 1073741824))GB"
            ;;
        "MB")
            echo "$((bytes / 1048576))MB"
            ;;
        "KB")
            echo "$((bytes / 1024))KB"
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

    local rx_bytes tx_bytes
    rx_bytes=$(echo "$stats" | awk '{print $7}')
    tx_bytes=$(echo "$stats" | awk '{print $10}')

    echo "$rx_bytes:$tx_bytes"
}

# Get primary network interface
get_primary_interface() {
    local interface=""

    if command_exists ip; then
        interface=$(ip route | grep '^default' | head -1 | sed 's/.*dev \([^ ]*\).*/\1/')
    elif command_exists route; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            interface=$(route -n get default | grep interface | awk '{print $2}')
        else
            interface=$(route -n | grep '^0.0.0.0' | head -1 | awk '{print $NF}')
        fi
    fi

    echo "$interface"
}

# Enhanced bandwidth calculation with overflow protection
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

            if [ "$time_diff" -ge "$NETWORK_MIN_UPDATE_INTERVAL" ] && [ "$time_diff" -lt 3600 ]; then
                # Handle counter overflow (32-bit counters wrap at ~4GB)
                if [ "$current_rx" -ge "$prev_rx" ]; then
                    rx_diff=$((current_rx - prev_rx))
                else
                    rx_diff=$((4294967296 + current_rx - prev_rx))
                fi

                if [ "$current_tx" -ge "$prev_tx" ]; then
                    tx_diff=$((current_tx - prev_tx))
                else
                    tx_diff=$((4294967296 + current_tx - prev_tx))
                fi

                rx_rate=$((rx_diff / time_diff))
                tx_rate=$((tx_diff / time_diff))

                # Sanity check: reject unrealistic values (>10Gbps)
                local max_rate=$((1250000000))
                if [ "$rx_rate" -le "$max_rate" ] && [ "$tx_rate" -le "$max_rate" ]; then
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

    # Save current stats for next calculation
    {
        echo "$current_time:$current_rx:$current_tx"
    } > "$cache_file" 2>/dev/null || true
}

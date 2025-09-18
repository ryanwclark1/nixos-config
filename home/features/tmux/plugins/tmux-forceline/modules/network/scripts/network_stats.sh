#!/usr/bin/env bash
# Network statistics script for tmux-forceline v2.0
# Interface bandwidth monitoring with cross-platform support

# Get tmux option or use default
get_tmux_option() {
    local option="$1"
    local default="$2"
    tmux show-option -gqv "$option" 2>/dev/null || echo "$default"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Get cache directory
get_cache_dir() {
    local cache_dir="${TMUX_TMPDIR:-${TMPDIR:-/tmp}}/tmux-forceline"
    mkdir -p "$cache_dir" 2>/dev/null
    echo "$cache_dir"
}

# Format bytes for display
format_bytes() {
    local bytes="$1"
    local unit="$2"
    
    if [ -z "$bytes" ] || [ "$bytes" = "0" ]; then
        echo "0B"
        return
    fi
    
    case "$unit" in
        "auto")
            if [ "$bytes" -gt 1073741824 ]; then
                echo "$((bytes / 1073741824))GB"
            elif [ "$bytes" -gt 1048576 ]; then
                echo "$((bytes / 1048576))MB"
            elif [ "$bytes" -gt 1024 ]; then
                echo "$((bytes / 1024))KB"
            else
                echo "${bytes}B"
            fi
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

# Calculate bandwidth from cached values
calculate_bandwidth() {
    local current_stats="$1"
    local interface="$2"
    local unit="$3"
    
    local cache_dir cache_file
    cache_dir=$(get_cache_dir)
    cache_file="$cache_dir/network_${interface}.cache"
    
    local current_time current_rx current_tx
    current_time=$(date +%s)
    IFS=: read -r current_rx current_tx <<< "$current_stats"
    
    # Check if we have previous data
    if [ -f "$cache_file" ]; then
        local prev_time prev_rx prev_tx
        IFS=: read -r prev_time prev_rx prev_tx < "$cache_file"
        
        if [ -n "$prev_time" ] && [ -n "$prev_rx" ] && [ -n "$prev_tx" ]; then
            local time_diff rx_diff tx_diff rx_rate tx_rate
            time_diff=$((current_time - prev_time))
            
            if [ "$time_diff" -gt 0 ]; then
                rx_diff=$((current_rx - prev_rx))
                tx_diff=$((current_tx - prev_tx))
                
                rx_rate=$((rx_diff / time_diff))
                tx_rate=$((tx_diff / time_diff))
                
                # Format output
                local rx_formatted tx_formatted
                rx_formatted=$(format_bytes "$rx_rate" "$unit")
                tx_formatted=$(format_bytes "$tx_rate" "$unit")
                
                echo "↓${rx_formatted}/s ↑${tx_formatted}/s"
            fi
        fi
    fi
    
    # Save current stats for next calculation
    echo "$current_time:$current_rx:$current_tx" > "$cache_file"
}

# Main network statistics function
main() {
    local format="$1"
    
    # Get configuration from tmux options
    local interface unit show_interface
    
    interface=$(get_tmux_option "@forceline_network_interface" "")
    unit=$(get_tmux_option "@forceline_network_unit" "auto")
    show_interface=$(get_tmux_option "@forceline_network_show_interface" "no")
    
    # Auto-detect interface if not specified
    if [ -z "$interface" ]; then
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
#!/usr/bin/env bash
# Load Average Helper Functions for tmux-forceline v2.0
# Cross-platform system load monitoring

# Default configurations
LOAD_FORMAT="${FORCELINE_LOAD_FORMAT:-average}"
LOAD_PRECISION="${FORCELINE_LOAD_PRECISION:-1}"

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect platform
is_linux() {
    [[ "$OSTYPE" == "linux-gnu"* ]]
}

is_macos() {
    [[ "$OSTYPE" == "darwin"* ]]
}

is_bsd() {
    [[ "$OSTYPE" == "freebsd"* ]] || [[ "$OSTYPE" == "openbsd"* ]] || [[ "$OSTYPE" == "netbsd"* ]]
}

# Get load average using various methods
get_load_average() {
    local load_data=""
    
    # Try uptime first (most universal)
    if command_exists uptime; then
        load_data=$(uptime | sed 's/.*load average[s]*: *//' | sed 's/,//g')
    # Try /proc/loadavg on Linux
    elif [ -r /proc/loadavg ]; then
        load_data=$(cat /proc/loadavg | cut -d' ' -f1-3)
    # Try sysctl on macOS/BSD
    elif command_exists sysctl; then
        if is_macos; then
            local load1 load5 load15
            load1=$(sysctl -n vm.loadavg | cut -d' ' -f2)
            load5=$(sysctl -n vm.loadavg | cut -d' ' -f3)
            load15=$(sysctl -n vm.loadavg | cut -d' ' -f4)
            load_data="$load1 $load5 $load15"
        else
            # BSD variants
            load_data=$(sysctl -n vm.loadavg 2>/dev/null | sed 's/{ //;s/ }//')
        fi
    fi
    
    echo "$load_data"
}

# Format load average according to specified format
format_load() {
    local format="$1"
    local precision="$2"
    local load_data
    
    load_data=$(get_load_average)
    
    if [ -z "$load_data" ]; then
        echo "N/A"
        return 1
    fi
    
    # Parse load values
    local load1 load5 load15
    read -r load1 load5 load15 <<< "$load_data"
    
    case "$format" in
        "1min"|"1m")
            printf "%.${precision}f" "$load1" 2>/dev/null || echo "$load1"
            ;;
        "5min"|"5m")
            printf "%.${precision}f" "$load5" 2>/dev/null || echo "$load5"
            ;;
        "15min"|"15m")
            printf "%.${precision}f" "$load15" 2>/dev/null || echo "$load15"
            ;;
        "average"|"avg")
            printf "%.${precision}f %.${precision}f %.${precision}f" "$load1" "$load5" "$load15" 2>/dev/null || echo "$load1 $load5 $load15"
            ;;
        "compact")
            printf "%.1f/%.1f/%.1f" "$load1" "$load5" "$load15" 2>/dev/null || echo "$load1/$load5/$load15"
            ;;
        *)
            printf "%.${precision}f %.${precision}f %.${precision}f" "$load1" "$load5" "$load15" 2>/dev/null || echo "$load1 $load5 $load15"
            ;;
    esac
}

# Get load with color indication based on CPU cores
get_load_with_color() {
    local format="$1"
    local precision="$2"
    local show_color="$3"
    local load_value
    
    load_value=$(format_load "$format" "$precision")
    
    if [ "$show_color" = "yes" ]; then
        # Get number of CPU cores for comparison
        local cpu_cores=1
        if [ -r /proc/cpuinfo ]; then
            cpu_cores=$(grep -c "^processor" /proc/cpuinfo 2>/dev/null || echo "1")
        elif command_exists sysctl; then
            cpu_cores=$(sysctl -n hw.ncpu 2>/dev/null || echo "1")
        elif command_exists nproc; then
            cpu_cores=$(nproc 2>/dev/null || echo "1")
        fi
        
        # Get first load value for comparison
        local load1
        load1=$(echo "$load_value" | awk '{print $1}')
        
        # Color coding based on load relative to CPU cores
        if command_exists bc && [ -n "$load1" ] && [ "$load1" != "N/A" ]; then
            local load_ratio
            load_ratio=$(echo "scale=2; $load1 / $cpu_cores" | bc 2>/dev/null || echo "0")
            local high_threshold="0.8"
            local critical_threshold="1.5"
            
            if [ "$(echo "$load_ratio > $critical_threshold" | bc 2>/dev/null)" = "1" ]; then
                echo "CRITICAL:$load_value"
            elif [ "$(echo "$load_ratio > $high_threshold" | bc 2>/dev/null)" = "1" ]; then
                echo "HIGH:$load_value"
            else
                echo "NORMAL:$load_value"
            fi
        else
            echo "NORMAL:$load_value"
        fi
    else
        echo "$load_value"
    fi
}
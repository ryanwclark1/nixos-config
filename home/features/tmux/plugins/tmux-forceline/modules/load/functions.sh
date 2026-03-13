#!/usr/bin/env bash
# Pure load functions for tmux-forceline
# Source this file — not meant to be executed directly
if [[ -z "${FL_VERSION:-}" ]]; then
    source "${FORCELINE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null && pwd)}/utils/pure_helpers.sh"
fi

is_macos() { is_osx; }
is_bsd() { is_freebsd || is_openbsd; }

# Get load average using various methods
get_load_average() {
    local load_data=""

    if command_exists uptime; then
        load_data=$(uptime | sed 's/.*load average[s]*: *//' | sed 's/,//g')
    elif [ -r /proc/loadavg ]; then
        load_data=$(cat /proc/loadavg | cut -d' ' -f1-3)
    elif command_exists sysctl; then
        if is_macos; then
            local load1 load5 load15
            load1=$(sysctl -n vm.loadavg | cut -d' ' -f2)
            load5=$(sysctl -n vm.loadavg | cut -d' ' -f3)
            load15=$(sysctl -n vm.loadavg | cut -d' ' -f4)
            load_data="$load1 $load5 $load15"
        else
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
        local cpu_cores=1
        if [ -r /proc/cpuinfo ]; then
            cpu_cores=$(grep -c "^processor" /proc/cpuinfo 2>/dev/null || echo "1")
        elif command_exists sysctl; then
            cpu_cores=$(sysctl -n hw.ncpu 2>/dev/null || echo "1")
        elif command_exists nproc; then
            cpu_cores=$(nproc 2>/dev/null || echo "1")
        fi

        local load1
        load1=$(echo "$load_value" | awk '{print $1}')

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

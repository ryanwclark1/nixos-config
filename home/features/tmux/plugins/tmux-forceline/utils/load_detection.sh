#!/usr/bin/env bash
# System Load Detection Utilities for tmux-forceline v3.0
# Cross-platform system load monitoring for adaptive module behavior
# Based on Tao of Tmux principles for intelligent resource management

set -euo pipefail

# Global configuration
readonly LOAD_DETECTOR_VERSION="3.0"
readonly LOAD_CACHE_TTL=2  # Very short TTL for accurate load monitoring
readonly LOAD_HISTORY_SIZE=10  # Number of historical load samples to keep

# Source centralized utilities
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    source "$UTILS_DIR/common.sh"
fi

# Default load thresholds for different system contexts
declare -A DEFAULT_LOAD_THRESHOLDS=(
    # Laptop/portable device thresholds (battery conscious)
    ["laptop_low"]="0.3"
    ["laptop_medium"]="0.6"
    ["laptop_high"]="1.0"
    
    # Desktop/workstation thresholds (performance focused)
    ["desktop_low"]="0.5"
    ["desktop_medium"]="1.0"
    ["desktop_high"]="2.0"
    
    # Server thresholds (availability focused)
    ["server_low"]="0.7"
    ["server_medium"]="1.5"
    ["server_high"]="3.0"
    
    # Development environment thresholds (responsive UI focused)
    ["development_low"]="0.4"
    ["development_medium"]="0.8"
    ["development_high"]="1.5"
)

# Get number of CPU cores for load normalization
get_cpu_cores() {
    local cores
    
    # Try different methods across platforms
    if command -v nproc >/dev/null 2>&1; then
        cores=$(nproc 2>/dev/null)
    elif [[ -r /proc/cpuinfo ]]; then
        cores=$(grep -c "^processor" /proc/cpuinfo 2>/dev/null || echo "1")
    elif command -v sysctl >/dev/null 2>&1; then
        # macOS and BSD systems
        cores=$(sysctl -n hw.ncpu 2>/dev/null || echo "1")
    elif [[ -r /sys/devices/system/cpu/online ]]; then
        # Alternative Linux method
        local online_range
        online_range=$(cat /sys/devices/system/cpu/online 2>/dev/null || echo "0")
        if [[ "$online_range" =~ ^[0-9]+-[0-9]+$ ]]; then
            local max_cpu="${online_range##*-}"
            cores=$((max_cpu + 1))
        else
            cores="1"
        fi
    else
        cores="1"  # Conservative fallback
    fi
    
    # Validate result
    if [[ "$cores" =~ ^[0-9]+$ ]] && [[ $cores -gt 0 ]]; then
        echo "$cores"
    else
        echo "1"
    fi
}

# Get current system load average
get_load_average() {
    local period="${1:-1}"  # 1, 5, or 15 minute average
    local load_value
    
    case "$period" in
        1|5|15) ;;
        *) period="1" ;;  # Default to 1-minute average
    esac
    
    # Try different methods across platforms
    if command -v uptime >/dev/null 2>&1; then
        # Most common method - parse uptime output
        local uptime_output
        uptime_output=$(uptime 2>/dev/null)
        
        if [[ "$uptime_output" =~ load[[:space:]]average[s]?:[[:space:]]*([0-9]+\.[0-9]+)[[:space:]]*,[[:space:]]*([0-9]+\.[0-9]+)[[:space:]]*,[[:space:]]*([0-9]+\.[0-9]+) ]]; then
            case "$period" in
                1) load_value="${BASH_REMATCH[1]}" ;;
                5) load_value="${BASH_REMATCH[2]}" ;;
                15) load_value="${BASH_REMATCH[3]}" ;;
            esac
        fi
    elif [[ -r /proc/loadavg ]]; then
        # Linux-specific method
        local loadavg_content
        loadavg_content=$(cat /proc/loadavg 2>/dev/null)
        read -r load1 load5 load15 _ <<< "$loadavg_content"
        
        case "$period" in
            1) load_value="$load1" ;;
            5) load_value="$load5" ;;
            15) load_value="$load15" ;;
        esac
    elif command -v sysctl >/dev/null 2>&1; then
        # macOS and BSD systems
        local sysctl_key
        case "$period" in
            1) sysctl_key="vm.loadavg" ;;
            5) sysctl_key="vm.loadavg" ;;
            15) sysctl_key="vm.loadavg" ;;
        esac
        
        local sysctl_output
        sysctl_output=$(sysctl -n "$sysctl_key" 2>/dev/null || echo "")
        if [[ -n "$sysctl_output" ]]; then
            # Parse sysctl output: { 1.23 1.45 1.67 }
            if [[ "$sysctl_output" =~ \{[[:space:]]*([0-9]+\.[0-9]+)[[:space:]]+([0-9]+\.[0-9]+)[[:space:]]+([0-9]+\.[0-9]+)[[:space:]]*\} ]]; then
                case "$period" in
                    1) load_value="${BASH_REMATCH[1]}" ;;
                    5) load_value="${BASH_REMATCH[2]}" ;;
                    15) load_value="${BASH_REMATCH[3]}" ;;
                esac
            fi
        fi
    fi
    
    # Validate and return load value
    if [[ -n "$load_value" ]] && [[ "$load_value" =~ ^[0-9]+\.[0-9]+$ ]]; then
        echo "$load_value"
    else
        echo "0.0"  # Fallback if load cannot be determined
    fi
}

# Get normalized load (load per CPU core)
get_normalized_load() {
    local period="${1:-1}"
    local raw_load cores normalized_load
    
    raw_load=$(get_load_average "$period")
    cores=$(get_cpu_cores)
    
    if command -v bc >/dev/null 2>&1; then
        normalized_load=$(echo "scale=2; $raw_load / $cores" | bc)
    else
        # Fallback calculation using awk
        normalized_load=$(awk "BEGIN { printf \"%.2f\", $raw_load / $cores }")
    fi
    
    echo "$normalized_load"
}

# Detect system context for appropriate load thresholds
detect_system_context() {
    local context="desktop"  # Default fallback
    
    # Battery detection for laptop identification
    if [[ -d /sys/class/power_supply ]]; then
        if ls /sys/class/power_supply/BAT* >/dev/null 2>&1; then
            context="laptop"
        fi
    elif command -v pmset >/dev/null 2>&1; then
        # macOS battery detection
        if pmset -g batt | grep -q "Battery"; then
            context="laptop"
        fi
    fi
    
    # Server environment detection
    if [[ -f /etc/systemd/system.conf ]] || [[ -d /etc/systemd/system ]]; then
        # Check for typical server indicators
        if systemctl list-units --type=service 2>/dev/null | grep -qE "(httpd|nginx|apache|mysql|postgresql|docker)"; then
            context="server"
        fi
    fi
    
    # Development environment detection
    if [[ -n "${TMUX:-}" ]] || [[ -n "${VSCODE_PID:-}" ]] || [[ -n "${TERM_PROGRAM:-}" ]]; then
        # Check for development tools
        if command -v git >/dev/null 2>&1 && [[ -d .git || -n "$(git rev-parse --git-dir 2>/dev/null)" ]]; then
            context="development"
        fi
    fi
    
    echo "$context"
}

# Get load thresholds for current system context
get_load_thresholds() {
    local context="${1:-$(detect_system_context)}"
    local threshold_type="${2:-low}"  # low, medium, high
    
    local threshold_key="${context}_${threshold_type}"
    local threshold="${DEFAULT_LOAD_THRESHOLDS[$threshold_key]:-}"
    
    if [[ -z "$threshold" ]]; then
        # Fallback to desktop thresholds if context not found
        threshold_key="desktop_${threshold_type}"
        threshold="${DEFAULT_LOAD_THRESHOLDS[$threshold_key]:-0.5}"
    fi
    
    echo "$threshold"
}

# Determine current load level (low, medium, high, critical)
get_load_level() {
    local period="${1:-1}"
    local context="${2:-$(detect_system_context)}"
    
    local current_load
    current_load=$(get_normalized_load "$period")
    
    local low_threshold medium_threshold high_threshold
    low_threshold=$(get_load_thresholds "$context" "low")
    medium_threshold=$(get_load_thresholds "$context" "medium")
    high_threshold=$(get_load_thresholds "$context" "high")
    
    # Compare load against thresholds
    if command -v bc >/dev/null 2>&1; then
        if (( $(echo "$current_load < $low_threshold" | bc -l) )); then
            echo "low"
        elif (( $(echo "$current_load < $medium_threshold" | bc -l) )); then
            echo "medium"
        elif (( $(echo "$current_load < $high_threshold" | bc -l) )); then
            echo "high"
        else
            echo "critical"
        fi
    else
        # Fallback comparison using awk
        awk -v load="$current_load" -v low="$low_threshold" -v med="$medium_threshold" -v high="$high_threshold" \
            'BEGIN {
                if (load < low) print "low"
                else if (load < med) print "medium"
                else if (load < high) print "high"
                else print "critical"
            }'
    fi
}

# Check if system is under high load
is_high_load() {
    local period="${1:-1}"
    local context="${2:-$(detect_system_context)}"
    local threshold="${3:-}"  # Optional custom threshold
    
    local current_load load_level
    current_load=$(get_normalized_load "$period")
    
    if [[ -n "$threshold" ]]; then
        # Use custom threshold
        if command -v bc >/dev/null 2>&1; then
            (( $(echo "$current_load >= $threshold" | bc -l) ))
        else
            awk -v load="$current_load" -v threshold="$threshold" \
                'BEGIN { exit (load >= threshold ? 0 : 1) }'
        fi
    else
        # Use load level classification
        load_level=$(get_load_level "$period" "$context")
        [[ "$load_level" == "high" || "$load_level" == "critical" ]]
    fi
}

# Store load history for trend analysis
update_load_history() {
    local period="${1:-1}"
    local history_env="FORCELINE_LOAD_HISTORY_${period}M"
    
    local current_load timestamp
    current_load=$(get_normalized_load "$period")
    timestamp=$(date +%s)
    
    # Get existing history
    local history_json
    history_json=$(tmux show-environment -g "$history_env" 2>/dev/null | cut -d= -f2- || echo "[]")
    
    if command -v jq >/dev/null 2>&1; then
        # Add new sample and maintain history size
        local updated_history
        updated_history=$(echo "$history_json" | jq \
            --arg load "$current_load" \
            --arg ts "$timestamp" \
            --argjson max_size "$LOAD_HISTORY_SIZE" \
            '. + [{"load": ($load | tonumber), "timestamp": ($ts | tonumber)}] | 
             if length > $max_size then .[-$max_size:] else . end')
        
        tmux set-environment -g "$history_env" "$updated_history"
    fi
}

# Get load trend (increasing, decreasing, stable)
get_load_trend() {
    local period="${1:-1}"
    local samples="${2:-5}"  # Number of samples to analyze
    local history_env="FORCELINE_LOAD_HISTORY_${period}M"
    
    local history_json
    history_json=$(tmux show-environment -g "$history_env" 2>/dev/null | cut -d= -f2- || echo "[]")
    
    if ! command -v jq >/dev/null 2>&1; then
        echo "stable"  # Fallback
        return
    fi
    
    # Get recent samples
    local recent_loads
    recent_loads=$(echo "$history_json" | jq -r --argjson count "$samples" \
        '.[-$count:] | map(.load) | join(" ")' 2>/dev/null || echo "")
    
    if [[ -z "$recent_loads" ]]; then
        echo "stable"
        return
    fi
    
    # Calculate trend using simple linear regression slope
    local loads=($recent_loads)
    local count=${#loads[@]}
    
    if [[ $count -lt 3 ]]; then
        echo "stable"
        return
    fi
    
    # Calculate average change between consecutive samples
    local total_change=0
    for ((i = 1; i < count; i++)); do
        if command -v bc >/dev/null 2>&1; then
            local change
            change=$(echo "${loads[i]} - ${loads[i-1]}" | bc -l)
            total_change=$(echo "$total_change + $change" | bc -l)
        fi
    done
    
    if command -v bc >/dev/null 2>&1; then
        local avg_change
        avg_change=$(echo "scale=4; $total_change / ($count - 1)" | bc -l)
        
        if (( $(echo "$avg_change > 0.05" | bc -l) )); then
            echo "increasing"
        elif (( $(echo "$avg_change < -0.05" | bc -l) )); then
            echo "decreasing"
        else
            echo "stable"
        fi
    else
        echo "stable"
    fi
}

# Get memory pressure information
get_memory_pressure() {
    local pressure="low"  # Default
    
    if [[ -r /proc/meminfo ]]; then
        # Linux memory analysis
        local mem_total mem_available mem_used_percent
        mem_total=$(awk '/MemTotal:/ {print $2}' /proc/meminfo 2>/dev/null || echo "0")
        mem_available=$(awk '/MemAvailable:/ {print $2}' /proc/meminfo 2>/dev/null || echo "$mem_total")
        
        if [[ $mem_total -gt 0 ]]; then
            if command -v bc >/dev/null 2>&1; then
                mem_used_percent=$(echo "scale=2; (1 - $mem_available / $mem_total) * 100" | bc)
                
                if (( $(echo "$mem_used_percent > 90" | bc -l) )); then
                    pressure="critical"
                elif (( $(echo "$mem_used_percent > 75" | bc -l) )); then
                    pressure="high"
                elif (( $(echo "$mem_used_percent > 50" | bc -l) )); then
                    pressure="medium"
                fi
            fi
        fi
    elif command -v vm_stat >/dev/null 2>&1; then
        # macOS memory analysis
        local vm_output
        vm_output=$(vm_stat 2>/dev/null)
        
        if [[ -n "$vm_output" ]]; then
            local free_pages inactive_pages
            free_pages=$(echo "$vm_output" | awk '/Pages free:/ {print $3}' | tr -d '.')
            inactive_pages=$(echo "$vm_output" | awk '/Pages inactive:/ {print $3}' | tr -d '.')
            
            # Simplified pressure detection for macOS
            if [[ -n "$free_pages" && $free_pages -lt 50000 ]]; then
                pressure="high"
            elif [[ -n "$free_pages" && $free_pages -lt 100000 ]]; then
                pressure="medium"
            fi
        fi
    fi
    
    echo "$pressure"
}

# Get comprehensive system load report
get_system_load_report() {
    local context
    context=$(detect_system_context)
    
    local load_1m load_5m load_15m
    load_1m=$(get_normalized_load "1")
    load_5m=$(get_normalized_load "5")
    load_15m=$(get_normalized_load "15")
    
    local load_level_1m load_level_5m
    load_level_1m=$(get_load_level "1" "$context")
    load_level_5m=$(get_load_level "5" "$context")
    
    local load_trend memory_pressure
    load_trend=$(get_load_trend "1" 5)
    memory_pressure=$(get_memory_pressure)
    
    local cpu_cores
    cpu_cores=$(get_cpu_cores)
    
    # Output structured report
    cat <<EOF
System Load Report - tmux-forceline v$LOAD_DETECTOR_VERSION
Generated: $(date)

System Context: $context
CPU Cores: $cpu_cores

Load Averages (normalized):
  1-minute:  $load_1m ($load_level_1m)
  5-minute:  $load_5m ($load_level_5m)
  15-minute: $load_15m

Load Trend: $load_trend
Memory Pressure: $memory_pressure

Thresholds for $context context:
  Low:    $(get_load_thresholds "$context" "low")
  Medium: $(get_load_thresholds "$context" "medium")
  High:   $(get_load_thresholds "$context" "high")
EOF
}

# Main CLI interface
main() {
    local command="${1:-report}"
    shift || true
    
    case "$command" in
        "load")
            get_normalized_load "$@"
            ;;
        "level")
            get_load_level "$@"
            ;;
        "context")
            detect_system_context
            ;;
        "cores")
            get_cpu_cores
            ;;
        "trend")
            update_load_history
            get_load_trend "$@"
            ;;
        "memory")
            get_memory_pressure
            ;;
        "high-load")
            if is_high_load "$@"; then
                echo "true"
                exit 0
            else
                echo "false"
                exit 1
            fi
            ;;
        "report"|*)
            get_system_load_report
            ;;
    esac
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
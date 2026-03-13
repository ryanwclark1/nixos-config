#!/usr/bin/env bash
# Pure transient functions for tmux-forceline
# Source this file — not meant to be executed directly

if [[ -z "${FL_VERSION:-}" ]]; then
    source "${FORCELINE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null && pwd)}/utils/pure_helpers.sh"
fi

# Global configuration
readonly TRANSIENT_CACHE_DURATION=5  # Short cache for responsive updates

# get_module_cache_dir and is_cache_valid are provided by pure_helpers.sh
_transient_get_cache_dir() { get_module_cache_dir "transient"; }

# Store transient status with timestamp
store_transient_status() {
    local status_type="$1"
    local message="$2"
    local duration="${3:-10}"
    local priority="${4:-medium}"

    local cache_dir cache_file
    cache_dir=$(_transient_get_cache_dir) || return 1
    cache_file="$cache_dir/transient_${status_type}.cache"

    local timestamp
    timestamp=$(date +%s)
    local expires_at=$((timestamp + duration))

    cat > "$cache_file" <<EOF
{
  "type": "$status_type",
  "message": "$message",
  "priority": "$priority",
  "timestamp": $timestamp,
  "expires_at": $expires_at
}
EOF
}

# Get active transient status (highest priority, non-expired)
get_active_transient_status() {
    local cache_dir
    cache_dir=$(_transient_get_cache_dir) || return 1

    local current_time
    current_time=$(date +%s)

    local highest_priority=""
    local priority_value=0
    local status_message=""

    for cache_file in "$cache_dir"/transient_*.cache; do
        [[ -f "$cache_file" ]] || continue

        local expires_at priority message
        expires_at=$(grep '"expires_at":' "$cache_file" 2>/dev/null | cut -d: -f2 | tr -d ' ,}')
        priority=$(grep '"priority":' "$cache_file" 2>/dev/null | cut -d'"' -f4)
        message=$(grep '"message":' "$cache_file" 2>/dev/null | cut -d'"' -f4)

        if [[ -n "$expires_at" ]] && [ "$current_time" -gt "$expires_at" ]; then
            rm -f "$cache_file" 2>/dev/null || true
            continue
        fi

        local current_priority_value=0
        case "$priority" in
            "high")   current_priority_value=3 ;;
            "medium") current_priority_value=2 ;;
            "low")    current_priority_value=1 ;;
        esac

        if [ "$current_priority_value" -gt "$priority_value" ]; then
            priority_value="$current_priority_value"
            highest_priority="$priority"
            status_message="$message"
        fi
    done

    if [[ -n "$status_message" ]]; then
        echo "$status_message"
        return 0
    fi

    return 1
}

# Check system conditions and trigger transient status
check_system_conditions() {
    local conditions_checked=0

    if command -v acpi >/dev/null 2>&1; then
        local battery_info
        battery_info=$(acpi -b 2>/dev/null | head -1)
        if [[ "$battery_info" =~ ([0-9]+)% ]]; then
            local battery_level="${BASH_REMATCH[1]}"
            if [ "$battery_level" -le 15 ] && [[ "$battery_info" == *"Discharging"* ]]; then
                store_transient_status "battery_low" "Battery Low: ${battery_level}%" 30 "high"
                conditions_checked=1
            fi
        fi
    fi

    if command -v free >/dev/null 2>&1; then
        local memory_usage
        memory_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
        if [[ "$memory_usage" =~ ^[0-9]+$ ]] && [ "$memory_usage" -ge 90 ]; then
            store_transient_status "memory_high" "Memory: ${memory_usage}%" 15 "medium"
            conditions_checked=1
        fi
    fi

    if command -v uptime >/dev/null 2>&1; then
        local load_avg
        load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')
        local cpu_cores
        cpu_cores=$(nproc 2>/dev/null || echo 1)

        if command -v bc >/dev/null 2>&1 && [[ "$load_avg" =~ ^[0-9]+\.?[0-9]*$ ]]; then
            local load_percentage
            load_percentage=$(echo "scale=0; ($load_avg / $cpu_cores) * 100" | bc 2>/dev/null || echo 0)
            if [ "$load_percentage" -ge 80 ]; then
                store_transient_status "cpu_high" "CPU: ${load_percentage}%" 10 "medium"
                conditions_checked=1
            fi
        fi
    fi

    if ! ping -c 1 -W 1 8.8.8.8 >/dev/null 2>&1; then
        store_transient_status "network_down" "Network Down" 20 "high"
        conditions_checked=1
    fi

    local disk_usage
    disk_usage=$(df / 2>/dev/null | awk 'NR==2 {print $(NF-1)}' | tr -d '%')
    if [[ "$disk_usage" =~ ^[0-9]+$ ]] && [ "$disk_usage" -ge 90 ]; then
        store_transient_status "disk_full" "Disk Full: ${disk_usage}%" 60 "high"
        conditions_checked=1
    fi

    return $conditions_checked
}

# Main transient status retrieval
get_transient_status() {
    local enabled="${1:-true}"
    local duration="${2:-10}"
    local priority="${3:-medium}"

    [[ "$enabled" =~ ^(true|false)$ ]] || enabled="true"
    [[ "$duration" =~ ^[0-9]+$ ]] && [ "$duration" -ge 3 ] && [ "$duration" -le 60 ] || duration="10"
    [[ "$priority" =~ ^(high|medium|low)$ ]] || priority="medium"

    [[ "$enabled" == "true" ]] || return 1

    local cache_dir cache_file
    cache_dir=$(_transient_get_cache_dir) || return 1
    cache_file="$cache_dir/transient_check.cache"

    if ! is_cache_valid "$cache_file" "$TRANSIENT_CACHE_DURATION"; then
        check_system_conditions
        touch "$cache_file" 2>/dev/null || true
    fi

    get_active_transient_status
}

# Public API functions for other modules to trigger transient status
trigger_success() {
    local message="${1:-Operation Successful}"
    local duration="${2:-5}"
    store_transient_status "success" "$message" "$duration" "low"
}

trigger_warning() {
    local message="${1:-Warning}"
    local duration="${2:-10}"
    store_transient_status "warning" "$message" "$duration" "medium"
}

trigger_error() {
    local message="${1:-Error}"
    local duration="${2:-15}"
    store_transient_status "error" "$message" "$duration" "high"
}

trigger_info() {
    local message="${1:-Information}"
    local duration="${2:-8}"
    store_transient_status "info" "$message" "$duration" "low"
}

#!/usr/bin/env bash
# Transient Status module for tmux-forceline v3.0
# Dynamic status indicators for temporary system states and conditions
#
# ENHANCED IMPLEMENTATION EXCEPTION:
# This module intentionally uses an enhanced pattern beyond the standard centralized approach.
# It implements a sophisticated transient status system with features including:
# - JSON-like structured caching with metadata
# - Priority-based status management (high/medium/low)
# - Automatic system condition monitoring (battery, memory, CPU, network, disk)
# - Public API for external modules to trigger transient notifications
# - Temporal status management with automatic expiration
# - Cross-module notification system
#
# The enhanced validation and extended functionality justify this exception to the
# standard migration pattern. This module serves as a centralized notification
# system for the entire tmux-forceline ecosystem.

set -euo pipefail

# Global configuration
readonly SCRIPT_VERSION="3.0"
readonly CACHE_DURATION=5  # Short cache for responsive updates
readonly DEFAULT_TIMEOUT=1 # Fast response time

# Source centralized path management
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../utils" && pwd)"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    # shellcheck source=../../../utils/common.sh
    source "$UTILS_DIR/common.sh"
    
    # Enhanced tmux option getter with transient-specific validation
    get_tmux_option_validated() {
        local option="$1"
        local default="$2"
        local value
        value=$(get_tmux_option "$option" "$default")
        
        # Validate transient-specific options
        case "$option" in
            "@forceline_transient_enabled")
                [[ "$value" =~ ^(true|false)$ ]] || value="true"
                ;;
            "@forceline_transient_duration")
                [[ "$value" =~ ^[0-9]+$ ]] && [ "$value" -ge 3 ] && [ "$value" -le 60 ] || value="10"
                ;;
            "@forceline_transient_priority")
                [[ "$value" =~ ^(high|medium|low)$ ]] || value="medium"
                ;;
        esac
        
        echo "$value"
    }
    
    # Override get_tmux_option to use validated version for this module
    get_tmux_option() {
        get_tmux_option_validated "$@"
    }
else
    # Fallback implementation if common.sh not available
    get_tmux_option() {
        local option="$1"
        local default="$2"
        local value
        value=$(tmux show-option -gqv "$option" 2>/dev/null || echo "$default")
        
        # Apply transient-specific validation
        case "$option" in
            "@forceline_transient_enabled")
                [[ "$value" =~ ^(true|false)$ ]] || value="true"
                ;;
            "@forceline_transient_duration")
                [[ "$value" =~ ^[0-9]+$ ]] && [ "$value" -ge 3 ] && [ "$value" -le 60 ] || value="10"
                ;;
            "@forceline_transient_priority")
                [[ "$value" =~ ^(high|medium|low)$ ]] || value="medium"
                ;;
        esac
        
        echo "$value"
    }
    
    get_forceline_dir() {
        echo "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    }
fi

# Get cache directory
get_cache_dir() {
    local cache_dir="${TMUX_TMPDIR:-${TMPDIR:-/tmp}}/tmux-forceline"
    mkdir -p "$cache_dir" 2>/dev/null || {
        echo "/tmp" # Fallback
        return 1
    }
    echo "$cache_dir"
}

# Check if cached result is still valid
is_cache_valid() {
    local cache_file="$1"
    local max_age="$2"
    
    [[ -f "$cache_file" ]] || return 1
    
    local file_age
    if command -v stat >/dev/null 2>&1; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            file_age=$(stat -f %m "$cache_file" 2>/dev/null || echo 0)
        else
            file_age=$(stat -c %Y "$cache_file" 2>/dev/null || echo 0)
        fi
    else
        return 1
    fi
    
    local current_time
    current_time=$(date +%s)
    
    [ $((current_time - file_age)) -lt "$max_age" ]
}

# Store transient status with timestamp
store_transient_status() {
    local status_type="$1"
    local message="$2"
    local duration="${3:-10}"
    local priority="${4:-medium}"
    
    local cache_dir cache_file
    cache_dir=$(get_cache_dir) || return 1
    cache_file="$cache_dir/transient_${status_type}.cache"
    
    local timestamp
    timestamp=$(date +%s)
    local expires_at=$((timestamp + duration))
    
    # Store status with metadata
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

# Get active transient status
get_active_transient_status() {
    local cache_dir
    cache_dir=$(get_cache_dir) || return 1
    
    local current_time
    current_time=$(date +%s)
    
    local highest_priority=""
    local priority_value=0
    local status_message=""
    
    # Check all transient status files
    for cache_file in "$cache_dir"/transient_*.cache; do
        [[ -f "$cache_file" ]] || continue
        
        # Parse JSON-like cache file
        local expires_at priority message
        expires_at=$(grep '"expires_at":' "$cache_file" 2>/dev/null | cut -d: -f2 | tr -d ' ,}')
        priority=$(grep '"priority":' "$cache_file" 2>/dev/null | cut -d'"' -f4)
        message=$(grep '"message":' "$cache_file" 2>/dev/null | cut -d'"' -f4)
        
        # Skip expired entries
        if [[ -n "$expires_at" ]] && [ "$current_time" -gt "$expires_at" ]; then
            rm -f "$cache_file" 2>/dev/null || true
            continue
        fi
        
        # Determine priority value
        local current_priority_value=0
        case "$priority" in
            "high") current_priority_value=3 ;;
            "medium") current_priority_value=2 ;;
            "low") current_priority_value=1 ;;
        esac
        
        # Select highest priority status
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
    
    # Battery level check (if available)
    if command -v acpi >/dev/null 2>&1; then
        local battery_info
        battery_info=$(acpi -b 2>/dev/null | head -1)
        if [[ "$battery_info" =~ ([0-9]+)% ]]; then
            local battery_level="${BASH_REMATCH[1]}"
            if [ "$battery_level" -le 15 ] && [[ "$battery_info" == *"Discharging"* ]]; then
                store_transient_status "battery_low" "🔋 Battery Low: ${battery_level}%" 30 "high"
                conditions_checked=1
            fi
        fi
    fi
    
    # Memory usage check
    if command -v free >/dev/null 2>&1; then
        local memory_usage
        memory_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
        if [[ "$memory_usage" =~ ^[0-9]+$ ]] && [ "$memory_usage" -ge 90 ]; then
            store_transient_status "memory_high" "🧠 Memory: ${memory_usage}%" 15 "medium"
            conditions_checked=1
        fi
    fi
    
    # CPU load check
    if command -v uptime >/dev/null 2>&1; then
        local load_avg
        load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')
        local cpu_cores
        cpu_cores=$(nproc 2>/dev/null || echo 1)
        
        if command -v bc >/dev/null 2>&1 && [[ "$load_avg" =~ ^[0-9]+\.?[0-9]*$ ]]; then
            local load_percentage
            load_percentage=$(echo "scale=0; ($load_avg / $cpu_cores) * 100" | bc 2>/dev/null || echo 0)
            if [ "$load_percentage" -ge 80 ]; then
                store_transient_status "cpu_high" "⚡ CPU: ${load_percentage}%" 10 "medium"
                conditions_checked=1
            fi
        fi
    fi
    
    # Network connectivity check
    if ! ping -c 1 -W 1 8.8.8.8 >/dev/null 2>&1; then
        store_transient_status "network_down" "🌐 Network Down" 20 "high"
        conditions_checked=1
    fi
    
    # Disk space check
    local disk_usage
    disk_usage=$(df / 2>/dev/null | awk 'NR==2 {print $(NF-1)}' | tr -d '%')
    if [[ "$disk_usage" =~ ^[0-9]+$ ]] && [ "$disk_usage" -ge 90 ]; then
        store_transient_status "disk_full" "💾 Disk Full: ${disk_usage}%" 60 "high"
        conditions_checked=1
    fi
    
    return $conditions_checked
}

# Main transient status function
get_transient_status() {
    local enabled duration priority
    enabled=$(get_tmux_option "@forceline_transient_enabled" "true")
    duration=$(get_tmux_option "@forceline_transient_duration" "10")
    priority=$(get_tmux_option "@forceline_transient_priority" "medium")
    
    # Return if disabled
    [[ "$enabled" == "true" ]] || return 1
    
    local cache_dir cache_file
    cache_dir=$(get_cache_dir) || return 1
    cache_file="$cache_dir/transient_check.cache"
    
    # Check system conditions periodically
    if ! is_cache_valid "$cache_file" "$CACHE_DURATION"; then
        check_system_conditions
        touch "$cache_file" 2>/dev/null || true
    fi
    
    # Get and return active status
    get_active_transient_status
}

# Public API functions for other modules to trigger transient status
trigger_success() {
    local message="${1:-✅ Operation Successful}"
    local duration="${2:-5}"
    store_transient_status "success" "$message" "$duration" "low"
}

trigger_warning() {
    local message="${1:-⚠️ Warning}"
    local duration="${2:-10}"
    store_transient_status "warning" "$message" "$duration" "medium"
}

trigger_error() {
    local message="${1:-❌ Error}"
    local duration="${2:-15}"
    store_transient_status "error" "$message" "$duration" "high"
}

trigger_info() {
    local message="${1:-ℹ️ Information}"
    local duration="${2:-8}"
    store_transient_status "info" "$message" "$duration" "low"
}

# Main function
main() {
    local action="${1:-status}"
    
    case "$action" in
        "status")
            get_transient_status
            ;;
        "success")
            trigger_success "$2" "$3"
            ;;
        "warning")
            trigger_warning "$2" "$3"
            ;;
        "error")
            trigger_error "$2" "$3"
            ;;
        "info")
            trigger_info "$2" "$3"
            ;;
        "clear")
            local cache_dir
            cache_dir=$(get_cache_dir) && rm -f "$cache_dir"/transient_*.cache 2>/dev/null || true
            ;;
        *)
            echo "Usage: $0 {status|success|warning|error|info|clear} [message] [duration]"
            return 1
            ;;
    esac
}

# Enhanced error handling for direct execution
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    # Trap errors and provide meaningful feedback
    trap 'exit 1' ERR
    
    main "$@"
fi
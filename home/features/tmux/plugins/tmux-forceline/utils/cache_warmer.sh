#!/usr/bin/env bash
# Cache Warming System for tmux-forceline v3.0
# Proactive cache updates for expensive operations
# Based on Tao of Tmux principles for optimal performance

set -euo pipefail

# Global configuration
readonly WARMER_VERSION="3.0"
readonly WARMER_PID_FILE="${TMUX_TMPDIR:-${TMPDIR:-/tmp}}/tmux-forceline/.warmer.pid"
readonly WARMER_LOG_FILE="${TMUX_TMPDIR:-${TMPDIR:-/tmp}}/tmux-forceline/.warmer.log"
readonly WARMER_CONFIG_FILE="${TMUX_TMPDIR:-${TMPDIR:-/tmp}}/tmux-forceline/.warmer.conf"

# Source centralized utilities
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    source "$UTILS_DIR/common.sh"
fi

if [[ -f "$UTILS_DIR/adaptive_cache.sh" ]]; then
    source "$UTILS_DIR/adaptive_cache.sh"
else
    echo "Error: adaptive_cache.sh not found" >&2
    exit 1
fi

# Warming profiles for different system types and usage patterns
declare -A WARMING_PROFILES=(
    # Conservative: Focus on most critical, least expensive modules
    ["conservative"]="battery,hostname,uptime"
    
    # Balanced: Mix of important and moderately expensive modules  
    ["balanced"]="battery,hostname,uptime,disk_usage,weather"
    
    # Aggressive: All modules including expensive network operations
    ["aggressive"]="battery,hostname,uptime,disk_usage,weather,wan_ip,vcs"
    
    # Development: Focus on development-relevant modules
    ["development"]="vcs,battery,hostname,uptime,cpu,memory"
    
    # Server: Focus on system monitoring modules
    ["server"]="cpu,memory,load,disk_usage,uptime,network"
    
    # Laptop: Focus on battery and portable usage
    ["laptop"]="battery,wan_ip,hostname,uptime,weather"
)

# Warming schedules (percentage of TTL at which to warm)
declare -A WARMING_SCHEDULES=(
    ["battery"]="80"      # Warm at 80% of TTL
    ["weather"]="85"      # Warm at 85% of TTL (expensive API call)
    ["wan_ip"]="90"       # Warm at 90% of TTL (very expensive)
    ["disk_usage"]="75"   # Warm at 75% of TTL
    ["vcs"]="70"          # Warm at 70% of TTL (can be expensive)
    ["default"]="80"      # Default warming threshold
)

# Initialize warming system
init_warming_system() {
    local cache_dir="${1:-$(dirname "$WARMER_PID_FILE")}"
    
    mkdir -p "$cache_dir" 2>/dev/null || return 1
    
    # Create default configuration if not exists
    if [[ ! -f "$WARMER_CONFIG_FILE" ]]; then
        cat > "$WARMER_CONFIG_FILE" <<EOF
{
  "version": "$WARMER_VERSION",
  "enabled": true,
  "profile": "balanced",
  "interval": 30,
  "max_concurrent": 3,
  "timeout": 10,
  "created": "$(date -Iseconds)"
}
EOF
    fi
    
    return 0
}

# Get warming configuration
get_warming_config() {
    local key="$1"
    local default="$2"
    
    if [[ -f "$WARMER_CONFIG_FILE" ]] && command -v jq >/dev/null 2>&1; then
        jq -r --arg key "$key" --arg default "$default" \
           '.[$key] // $default' "$WARMER_CONFIG_FILE" 2>/dev/null || echo "$default"
    else
        # Fallback configuration
        case "$key" in
            "enabled") echo "true" ;;
            "profile") echo "balanced" ;;
            "interval") echo "30" ;;
            "max_concurrent") echo "3" ;;
            "timeout") echo "10" ;;
            *) echo "$default" ;;
        esac
    fi
}

# Get modules for warming based on profile
get_warming_modules() {
    local profile="$1"
    local modules_string="${WARMING_PROFILES[$profile]:-${WARMING_PROFILES[balanced]}}"
    echo "$modules_string" | tr ',' ' '
}

# Check if module needs warming
needs_warming() {
    local module="$1"
    local context="${2:-default}"
    
    # Get cache file and metadata
    local cache_key
    cache_key=$(generate_cache_key "$module" "$context")
    local cache_file
    cache_file=$(get_cache_file "$cache_key")
    
    [[ -f "$cache_file" ]] || return 0  # No cache file = needs warming
    
    # Get warming threshold and TTL
    local warming_threshold="${WARMING_SCHEDULES[$module]:-${WARMING_SCHEDULES[default]}}"
    local ttl
    ttl=$(get_adaptive_ttl "$module")
    
    # Calculate warming time (when to start warming)
    local warming_age
    if command -v bc >/dev/null 2>&1; then
        warming_age=$(echo "scale=0; $ttl * $warming_threshold / 100" | bc)
    else
        warming_age=$((ttl * warming_threshold / 100))
    fi
    
    # Check if cache age exceeds warming threshold
    local file_age current_time
    current_time=$(date +%s)
    
    if command -v stat >/dev/null 2>&1; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            file_age=$(stat -f %m "$cache_file" 2>/dev/null || echo 0)
        else
            file_age=$(stat -c %Y "$cache_file" 2>/dev/null || echo 0)
        fi
    else
        return 0  # Assume needs warming if can't check
    fi
    
    local cache_age=$((current_time - file_age))
    [[ $cache_age -ge $warming_age ]]
}

# Find module script for warming
find_module_script() {
    local module="$1"
    local forceline_dir
    forceline_dir=$(get_forceline_dir 2>/dev/null || echo "$(dirname "$UTILS_DIR")")
    
    # Try different possible locations
    local possible_paths=(
        "$forceline_dir/modules/$module/$module.sh"
        "$forceline_dir/modules/$module/scripts/${module}.sh"
        "$forceline_dir/modules/$module/scripts/${module}_*.sh"
    )
    
    for path_pattern in "${possible_paths[@]}"; do
        # Handle glob patterns
        for path in $path_pattern; do
            if [[ -f "$path" && -x "$path" ]]; then
                echo "$path"
                return 0
            fi
        done
    done
    
    return 1
}

# Warm a single module
warm_module() {
    local module="$1"
    local timeout="${2:-10}"
    local context="${3:-default}"
    
    log_message "Warming module: $module"
    
    # Find module script
    local module_script
    if ! module_script=$(find_module_script "$module"); then
        log_message "WARNING: Cannot find script for module: $module"
        return 1
    fi
    
    # Execute module with timeout and cache result
    local result exit_code=0
    if result=$(timeout "$timeout" "$module_script" 2>/dev/null); then
        if cache_set "$module" "$result" "$context"; then
            log_message "Successfully warmed $module: ${result:0:50}..."
            return 0
        else
            log_message "ERROR: Failed to cache result for $module"
            return 1
        fi
    else
        exit_code=$?
        if [[ $exit_code -eq 124 ]]; then
            log_message "WARNING: Timeout warming module $module"
        else
            log_message "ERROR: Failed to execute module $module (exit: $exit_code)"
        fi
        return $exit_code
    fi
}

# Log message with timestamp
log_message() {
    local message="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$WARMER_LOG_FILE"
}

# Warm modules based on profile
warm_profile() {
    local profile="${1:-balanced}"
    local max_concurrent="${2:-3}"
    local timeout="${3:-10}"
    
    local modules
    read -ra modules <<< "$(get_warming_modules "$profile")"
    
    log_message "Starting warming cycle for profile: $profile"
    log_message "Modules to check: ${modules[*]}"
    
    local active_jobs=0
    local warmed_count=0
    
    for module in "${modules[@]}"; do
        # Check if module needs warming
        if needs_warming "$module"; then
            # Wait if too many concurrent jobs
            while [[ $active_jobs -ge $max_concurrent ]]; do
                wait -n 2>/dev/null || true  # Wait for any job to complete
                active_jobs=$((active_jobs - 1))
            done
            
            # Start warming in background
            warm_module "$module" "$timeout" &
            active_jobs=$((active_jobs + 1))
            warmed_count=$((warmed_count + 1))
        fi
    done
    
    # Wait for all warming jobs to complete
    wait
    
    log_message "Warming cycle completed: $warmed_count modules processed"
    return 0
}

# Continuous warming daemon
warming_daemon() {
    local profile="${1:-balanced}"
    local interval="${2:-30}"
    
    log_message "Starting warming daemon (profile: $profile, interval: ${interval}s)"
    
    # Store daemon PID
    echo $$ > "$WARMER_PID_FILE"
    
    # Cleanup handler
    trap 'log_message "Warming daemon stopped"; rm -f "$WARMER_PID_FILE"; exit 0' TERM INT
    
    while true; do
        # Check if still enabled
        local enabled
        enabled=$(get_warming_config "enabled" "true")
        if [[ "$enabled" != "true" ]]; then
            log_message "Warming disabled, stopping daemon"
            break
        fi
        
        # Get current configuration
        local current_profile current_interval max_concurrent timeout
        current_profile=$(get_warming_config "profile" "$profile")
        current_interval=$(get_warming_config "interval" "$interval")
        max_concurrent=$(get_warming_config "max_concurrent" "3")
        timeout=$(get_warming_config "timeout" "10")
        
        # Perform warming cycle
        warm_profile "$current_profile" "$max_concurrent" "$timeout"
        
        # Sleep until next cycle
        sleep "$current_interval"
    done
    
    rm -f "$WARMER_PID_FILE"
}

# Check if warming daemon is running
is_daemon_running() {
    [[ -f "$WARMER_PID_FILE" ]] || return 1
    
    local pid
    pid=$(cat "$WARMER_PID_FILE" 2>/dev/null)
    [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null
}

# Start warming daemon
start_daemon() {
    local profile="${1:-}"
    local interval="${2:-}"
    
    if is_daemon_running; then
        echo "Warming daemon is already running"
        return 1
    fi
    
    init_warming_system || {
        echo "Failed to initialize warming system"
        return 1
    }
    
    # Use configuration defaults if not provided
    [[ -z "$profile" ]] && profile=$(get_warming_config "profile" "balanced")
    [[ -z "$interval" ]] && interval=$(get_warming_config "interval" "30")
    
    # Start daemon in background
    nohup bash "$0" --daemon "$profile" "$interval" </dev/null >/dev/null 2>&1 &
    
    sleep 1  # Give daemon time to start
    
    if is_daemon_running; then
        echo "Warming daemon started (profile: $profile, interval: ${interval}s)"
        return 0
    else
        echo "Failed to start warming daemon"
        return 1
    fi
}

# Stop warming daemon
stop_daemon() {
    if ! is_daemon_running; then
        echo "Warming daemon is not running"
        return 1
    fi
    
    local pid
    pid=$(cat "$WARMER_PID_FILE" 2>/dev/null)
    
    if [[ -n "$pid" ]] && kill "$pid" 2>/dev/null; then
        # Wait for daemon to stop
        local timeout=10
        while [[ $timeout -gt 0 ]] && is_daemon_running; do
            sleep 1
            timeout=$((timeout - 1))
        done
        
        if is_daemon_running; then
            echo "Daemon did not stop gracefully, forcing termination"
            kill -KILL "$pid" 2>/dev/null || true
            rm -f "$WARMER_PID_FILE"
        fi
        
        echo "Warming daemon stopped"
        return 0
    else
        echo "Failed to stop warming daemon"
        rm -f "$WARMER_PID_FILE"  # Cleanup stale PID file
        return 1
    fi
}

# Show warming daemon status
daemon_status() {
    if is_daemon_running; then
        local pid
        pid=$(cat "$WARMER_PID_FILE" 2>/dev/null)
        echo "Warming daemon is running (PID: $pid)"
        
        # Show configuration
        local profile interval enabled
        profile=$(get_warming_config "profile" "unknown")
        interval=$(get_warming_config "interval" "unknown")
        enabled=$(get_warming_config "enabled" "unknown")
        
        echo "  Profile: $profile"
        echo "  Interval: ${interval}s"
        echo "  Enabled: $enabled"
        
        # Show recent log entries
        if [[ -f "$WARMER_LOG_FILE" ]]; then
            echo ""
            echo "Recent activity:"
            tail -5 "$WARMER_LOG_FILE" 2>/dev/null | sed 's/^/  /'
        fi
    else
        echo "Warming daemon is not running"
        return 1
    fi
}

# Configure warming system
configure_warming() {
    local key="$1"
    local value="$2"
    
    init_warming_system || return 1
    
    # Update configuration
    if command -v jq >/dev/null 2>&1; then
        local temp_file="${WARMER_CONFIG_FILE}.tmp"
        jq --arg key "$key" --arg value "$value" \
           '.[$key] = $value' \
           "$WARMER_CONFIG_FILE" > "$temp_file" && mv "$temp_file" "$WARMER_CONFIG_FILE"
    else
        echo "jq required for configuration updates"
        return 1
    fi
    
    echo "Updated $key = $value"
    
    # Restart daemon if running to pick up new configuration
    if is_daemon_running; then
        echo "Restarting daemon to apply new configuration..."
        stop_daemon && sleep 2 && start_daemon
    fi
}

# Show warming logs
show_logs() {
    local lines="${1:-20}"
    
    if [[ -f "$WARMER_LOG_FILE" ]]; then
        tail -n "$lines" "$WARMER_LOG_FILE"
    else
        echo "No warming logs available"
    fi
}

# Main CLI interface
main() {
    local command="${1:-help}"
    shift || true
    
    case "$command" in
        "--daemon")
            # Internal daemon mode
            warming_daemon "$@"
            ;;
        "start")
            start_daemon "$@"
            ;;
        "stop")
            stop_daemon
            ;;
        "restart")
            stop_daemon
            sleep 2
            start_daemon "$@"
            ;;
        "status")
            daemon_status
            ;;
        "warm")
            warm_profile "$@"
            ;;
        "config")
            configure_warming "$@"
            ;;
        "logs")
            show_logs "$@"
            ;;
        "help"|*)
            cat <<EOF
Cache Warming System for tmux-forceline v3.0

USAGE:
    $0 <command> [arguments]

COMMANDS:
    start [profile] [interval]
        Start warming daemon with optional profile and interval
        
    stop
        Stop warming daemon
        
    restart [profile] [interval]
        Restart warming daemon with new configuration
        
    status
        Show daemon status and configuration
        
    warm [profile] [max_concurrent] [timeout]
        Perform one-time warming cycle
        
    config <key> <value>
        Update configuration (enabled, profile, interval, max_concurrent, timeout)
        
    logs [lines]
        Show recent warming activity logs
        
    help
        Show this help message

PROFILES:
    conservative  - Critical modules only (battery, hostname, uptime)
    balanced      - Important modules (default)
    aggressive    - All modules including expensive operations
    development   - Development-focused modules
    server        - System monitoring modules
    laptop        - Battery and portable usage modules

EXAMPLES:
    $0 start balanced 30
    $0 warm aggressive
    $0 config profile development
    $0 status
    $0 logs 50
EOF
            ;;
    esac
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
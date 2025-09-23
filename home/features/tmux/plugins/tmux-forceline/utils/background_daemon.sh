#!/usr/bin/env bash
# Background Update Daemon for tmux-forceline v3.0
# Asynchronous processing system for non-blocking status bar updates
# Based on Tao of Tmux principles for optimal performance and native integration

set -euo pipefail

# Global configuration
readonly DAEMON_VERSION="3.0"
readonly DAEMON_PID_ENV="FORCELINE_DAEMON_PID"
readonly DAEMON_STATUS_ENV="FORCELINE_DAEMON_STATUS" 
readonly DAEMON_QUEUE_ENV="FORCELINE_DAEMON_QUEUE"
readonly DAEMON_CONFIG_ENV="FORCELINE_DAEMON_CONFIG"

# Default configuration
readonly DEFAULT_UPDATE_INTERVAL=5
readonly DEFAULT_MAX_CONCURRENT=3
readonly DEFAULT_TIMEOUT=15
readonly DEFAULT_PRIORITY_LEVELS=5

# Source centralized utilities
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    source "$UTILS_DIR/common.sh"
fi

if [[ -f "$UTILS_DIR/adaptive_cache.sh" ]]; then
    source "$UTILS_DIR/adaptive_cache.sh"
else
    echo "Error: adaptive_cache.sh required for daemon operation" >&2
    exit 1
fi

# Module priority definitions based on importance and cost
declare -A MODULE_PRIORITIES=(
    # Priority 1: Critical, fast updates (system-local data)
    ["battery"]="1"
    ["hostname"]="1"
    ["session"]="1"
    ["datetime"]="1"
    
    # Priority 2: Important, medium cost (local system monitoring)
    ["cpu"]="2"
    ["memory"]="2"
    ["load"]="2"
    ["uptime"]="2"
    
    # Priority 3: Useful, higher cost (filesystem operations)
    ["disk_usage"]="3"
    ["vcs"]="3"
    ["directory"]="3"
    
    # Priority 4: Network-dependent, expensive (local network)
    ["lan_ip"]="4"
    ["network"]="4"
    
    # Priority 5: Most expensive (external network dependencies)
    ["wan_ip"]="5"
    ["weather"]="5"
)

# Priority queue implementation using tmux environment variables
init_priority_queue() {
    tmux set-environment -g "$DAEMON_QUEUE_ENV" "{}"
}

# Add module to priority queue
enqueue_module() {
    local module="$1"
    local priority="${MODULE_PRIORITIES[$module]:-3}"
    local timestamp="$(date +%s)"
    
    # Get current queue state
    local queue_json
    queue_json=$(tmux show-environment -g "$DAEMON_QUEUE_ENV" 2>/dev/null | cut -d= -f2- || echo "{}")
    
    # Add module to appropriate priority level
    local updated_queue
    if command -v jq >/dev/null 2>&1; then
        updated_queue=$(echo "$queue_json" | jq \
            --arg module "$module" \
            --arg priority "$priority" \
            --arg timestamp "$timestamp" \
            '.[$priority] = (.[$priority] // []) + [{"module": $module, "timestamp": ($timestamp | tonumber)}]')
    else
        # Fallback without jq
        updated_queue="$queue_json"
    fi
    
    tmux set-environment -g "$DAEMON_QUEUE_ENV" "$updated_queue"
}

# Get next module from priority queue
dequeue_module() {
    local queue_json
    queue_json=$(tmux show-environment -g "$DAEMON_QUEUE_ENV" 2>/dev/null | cut -d= -f2- || echo "{}")
    
    if ! command -v jq >/dev/null 2>&1; then
        echo ""
        return 1
    fi
    
    # Find highest priority with pending modules
    for priority in {1..5}; do
        local module_info
        module_info=$(echo "$queue_json" | jq -r --arg p "$priority" \
            'if .[$p] and (.[$p] | length > 0) then .[$p][0] else empty end' 2>/dev/null)
        
        if [[ -n "$module_info" ]]; then
            local module
            module=$(echo "$module_info" | jq -r '.module' 2>/dev/null)
            
            if [[ -n "$module" && "$module" != "null" ]]; then
                # Remove module from queue
                local updated_queue
                updated_queue=$(echo "$queue_json" | jq --arg p "$priority" \
                    '.[$p] = (.[$p] // [])[1:]')
                tmux set-environment -g "$DAEMON_QUEUE_ENV" "$updated_queue"
                
                echo "$module"
                return 0
            fi
        fi
    done
    
    echo ""
    return 1
}

# Get daemon configuration from tmux environment
get_daemon_config() {
    local key="$1"
    local default="$2"
    
    local config_json
    config_json=$(tmux show-environment -g "$DAEMON_CONFIG_ENV" 2>/dev/null | cut -d= -f2- || echo "{}")
    
    if command -v jq >/dev/null 2>&1; then
        echo "$config_json" | jq -r --arg key "$key" --arg default "$default" \
            '.[$key] // $default' 2>/dev/null || echo "$default"
    else
        # Fallback configuration
        case "$key" in
            "update_interval") echo "$DEFAULT_UPDATE_INTERVAL" ;;
            "max_concurrent") echo "$DEFAULT_MAX_CONCURRENT" ;;
            "timeout") echo "$DEFAULT_TIMEOUT" ;;
            "enabled") echo "true" ;;
            *) echo "$default" ;;
        esac
    fi
}

# Set daemon configuration
set_daemon_config() {
    local key="$1"
    local value="$2"
    
    local config_json
    config_json=$(tmux show-environment -g "$DAEMON_CONFIG_ENV" 2>/dev/null | cut -d= -f2- || echo "{}")
    
    if command -v jq >/dev/null 2>&1; then
        local updated_config
        updated_config=$(echo "$config_json" | jq --arg key "$key" --arg value "$value" \
            '.[$key] = $value')
        tmux set-environment -g "$DAEMON_CONFIG_ENV" "$updated_config"
        return 0
    else
        echo "jq required for configuration updates" >&2
        return 1
    fi
}

# Find module script for execution
find_module_script() {
    local module="$1"
    local forceline_dir
    forceline_dir=$(get_forceline_dir 2>/dev/null || echo "$(dirname "$UTILS_DIR")")
    
    # Try different possible locations
    local possible_paths=(
        "$forceline_dir/modules/$module/$module.sh"
        "$forceline_dir/modules/$module/scripts/${module}.sh"
        "$forceline_dir/modules/$module/scripts/${module}_*.sh"
        "$forceline_dir/plugins/core/$module/$module.sh"
        "$forceline_dir/plugins/extended/$module/$module.sh"
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

# Execute module and store result in tmux environment
execute_module() {
    local module="$1"
    local timeout="${2:-$DEFAULT_TIMEOUT}"
    
    log_daemon "Executing module: $module"
    
    # Find module script
    local module_script
    if ! module_script=$(find_module_script "$module"); then
        log_daemon "WARNING: Cannot find script for module: $module"
        return 1
    fi
    
    # Execute module with timeout
    local result exit_code=0 timestamp
    timestamp=$(date +%s)
    
    if result=$(timeout "$timeout" "$module_script" 2>/dev/null); then
        # Store result in tmux environment
        local env_var="FORCELINE_${module}_VALUE"
        local ts_var="FORCELINE_${module}_TIMESTAMP"
        
        tmux set-environment -g "$env_var" "$result"
        tmux set-environment -g "$ts_var" "$timestamp"
        
        # Also update cache for consistency
        cache_set "$module" "$result" "daemon" >/dev/null 2>&1 || true
        
        log_daemon "Successfully executed $module: ${result:0:50}..."
        return 0
    else
        exit_code=$?
        if [[ $exit_code -eq 124 ]]; then
            log_daemon "WARNING: Timeout executing module $module"
        else
            log_daemon "ERROR: Failed to execute module $module (exit: $exit_code)"
        fi
        return $exit_code
    fi
}

# Get module value from daemon cache (tmux environment)
get_daemon_value() {
    local module="$1"
    local max_age="${2:-300}"  # Default 5 minutes
    
    local env_var="FORCELINE_${module}_VALUE"
    local ts_var="FORCELINE_${module}_TIMESTAMP"
    
    # Check if value exists
    local value timestamp current_time age
    value=$(tmux show-environment -g "$env_var" 2>/dev/null | cut -d= -f2- || echo "")
    timestamp=$(tmux show-environment -g "$ts_var" 2>/dev/null | cut -d= -f2 || echo "0")
    current_time=$(date +%s)
    age=$((current_time - timestamp))
    
    if [[ -n "$value" && $age -le $max_age ]]; then
        echo "$value"
        return 0
    else
        return 1
    fi
}

# Log daemon messages
log_daemon() {
    local message="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Use tmux display-message for logging when possible
    if tmux list-sessions >/dev/null 2>&1; then
        tmux display-message -d 0 "[$timestamp] DAEMON: $message" 2>/dev/null || true
    fi
    
    # Also log to stderr for debugging
    echo "[$timestamp] DAEMON: $message" >&2
}

# Process pending modules with concurrency control
process_update_cycle() {
    local max_concurrent="${1:-$DEFAULT_MAX_CONCURRENT}"
    local timeout="${2:-$DEFAULT_TIMEOUT}"
    
    local active_jobs=0
    local processed_count=0
    
    log_daemon "Starting update cycle (max_concurrent: $max_concurrent, timeout: ${timeout}s)"
    
    # Process modules from priority queue
    while true; do
        local module
        if ! module=$(dequeue_module) || [[ -z "$module" ]]; then
            break  # No more modules in queue
        fi
        
        # Wait if too many concurrent jobs
        while [[ $active_jobs -ge $max_concurrent ]]; do
            wait -n 2>/dev/null || true  # Wait for any job to complete
            active_jobs=$((active_jobs - 1))
        done
        
        # Execute module in background
        execute_module "$module" "$timeout" &
        active_jobs=$((active_jobs + 1))
        processed_count=$((processed_count + 1))
    done
    
    # Wait for all jobs to complete
    wait
    
    log_daemon "Update cycle completed: $processed_count modules processed"
}

# Populate queue with modules that need updates
populate_update_queue() {
    local forceline_dir
    forceline_dir=$(get_forceline_dir 2>/dev/null || echo "$(dirname "$UTILS_DIR")")
    
    # Scan for available modules
    local modules_dir="$forceline_dir/modules"
    if [[ -d "$modules_dir" ]]; then
        for module_path in "$modules_dir"/*; do
            if [[ -d "$module_path" ]]; then
                local module="$(basename "$module_path")"
                
                # Check if module needs update
                if should_update_module "$module"; then
                    enqueue_module "$module"
                fi
            fi
        done
    fi
    
    # Also check plugin modules
    local plugins_dir="$forceline_dir/plugins"
    if [[ -d "$plugins_dir" ]]; then
        for category in "core" "extended"; do
            local category_dir="$plugins_dir/$category"
            if [[ -d "$category_dir" ]]; then
                for module_path in "$category_dir"/*; do
                    if [[ -d "$module_path" ]]; then
                        local module="$(basename "$module_path")"
                        
                        if should_update_module "$module"; then
                            enqueue_module "$module"
                        fi
                    fi
                done
            fi
        done
    fi
}

# Check if module needs update based on TTL and current value
should_update_module() {
    local module="$1"
    
    # Check cache age first
    if cache_get "$module" >/dev/null 2>&1; then
        return 1  # Cache is still valid
    fi
    
    # Check daemon cache age
    local max_age
    max_age=$(get_adaptive_ttl "$module" 2>/dev/null || echo "300")
    
    if get_daemon_value "$module" "$max_age" >/dev/null 2>&1; then
        return 1  # Daemon cache is still valid
    fi
    
    return 0  # Needs update
}

# Main daemon loop
daemon_main_loop() {
    local update_interval="${1:-$DEFAULT_UPDATE_INTERVAL}"
    
    log_daemon "Starting daemon main loop (interval: ${update_interval}s)"
    
    # Initialize daemon environment
    init_priority_queue
    tmux set-environment -g "$DAEMON_STATUS_ENV" "running"
    
    # Store daemon PID
    tmux set-environment -g "$DAEMON_PID_ENV" "$$"
    
    # Cleanup handler
    trap 'cleanup_daemon; exit 0' TERM INT
    
    while true; do
        # Check if daemon should continue running
        local enabled
        enabled=$(get_daemon_config "enabled" "true")
        if [[ "$enabled" != "true" ]]; then
            log_daemon "Daemon disabled, stopping"
            break
        fi
        
        # Get current configuration
        local current_interval max_concurrent timeout
        current_interval=$(get_daemon_config "update_interval" "$update_interval")
        max_concurrent=$(get_daemon_config "max_concurrent" "$DEFAULT_MAX_CONCURRENT")
        timeout=$(get_daemon_config "timeout" "$DEFAULT_TIMEOUT")
        
        # Populate queue with modules that need updates
        populate_update_queue
        
        # Process updates
        process_update_cycle "$max_concurrent" "$timeout"
        
        # Sleep until next cycle
        sleep "$current_interval"
    done
    
    cleanup_daemon
}

# Cleanup daemon environment
cleanup_daemon() {
    log_daemon "Cleaning up daemon environment"
    
    tmux set-environment -gu "$DAEMON_PID_ENV" 2>/dev/null || true
    tmux set-environment -gu "$DAEMON_STATUS_ENV" 2>/dev/null || true
    tmux set-environment -gu "$DAEMON_QUEUE_ENV" 2>/dev/null || true
    
    # Don't remove config to preserve user settings
}

# Check if daemon is running
is_daemon_running() {
    local daemon_pid
    daemon_pid=$(tmux show-environment -g "$DAEMON_PID_ENV" 2>/dev/null | cut -d= -f2 || echo "")
    
    [[ -n "$daemon_pid" ]] && kill -0 "$daemon_pid" 2>/dev/null
}

# Start daemon
start_daemon() {
    local update_interval="${1:-}"
    local max_concurrent="${2:-}"
    local timeout="${3:-}"
    
    if is_daemon_running; then
        echo "Background daemon is already running"
        return 1
    fi
    
    # Set initial configuration
    local config="{}"
    if command -v jq >/dev/null 2>&1; then
        config=$(echo '{}' | jq \
            --arg interval "${update_interval:-$DEFAULT_UPDATE_INTERVAL}" \
            --arg concurrent "${max_concurrent:-$DEFAULT_MAX_CONCURRENT}" \
            --arg timeout "${timeout:-$DEFAULT_TIMEOUT}" \
            '.update_interval = ($interval | tonumber) |
             .max_concurrent = ($concurrent | tonumber) |
             .timeout = ($timeout | tonumber) |
             .enabled = true')
    fi
    tmux set-environment -g "$DAEMON_CONFIG_ENV" "$config"
    
    # Start daemon in background
    nohup bash "$0" --daemon-mode "${update_interval:-$DEFAULT_UPDATE_INTERVAL}" \
        </dev/null >/dev/null 2>&1 &
    
    sleep 1  # Give daemon time to start
    
    if is_daemon_running; then
        echo "Background daemon started successfully"
        echo "  Update interval: ${update_interval:-$DEFAULT_UPDATE_INTERVAL}s"
        echo "  Max concurrent: ${max_concurrent:-$DEFAULT_MAX_CONCURRENT}"
        echo "  Timeout: ${timeout:-$DEFAULT_TIMEOUT}s"
        return 0
    else
        echo "Failed to start background daemon"
        return 1
    fi
}

# Stop daemon
stop_daemon() {
    if ! is_daemon_running; then
        echo "Background daemon is not running"
        return 1
    fi
    
    local daemon_pid
    daemon_pid=$(tmux show-environment -g "$DAEMON_PID_ENV" 2>/dev/null | cut -d= -f2 || echo "")
    
    if [[ -n "$daemon_pid" ]] && kill "$daemon_pid" 2>/dev/null; then
        # Wait for daemon to stop
        local timeout=10
        while [[ $timeout -gt 0 ]] && is_daemon_running; do
            sleep 1
            timeout=$((timeout - 1))
        done
        
        if is_daemon_running; then
            echo "Daemon did not stop gracefully, forcing termination"
            kill -KILL "$daemon_pid" 2>/dev/null || true
            cleanup_daemon
        fi
        
        echo "Background daemon stopped"
        return 0
    else
        echo "Failed to stop background daemon"
        cleanup_daemon  # Cleanup stale environment
        return 1
    fi
}

# Show daemon status
daemon_status() {
    if is_daemon_running; then
        local daemon_pid
        daemon_pid=$(tmux show-environment -g "$DAEMON_PID_ENV" 2>/dev/null | cut -d= -f2 || echo "")
        echo "Background daemon is running (PID: $daemon_pid)"
        
        # Show configuration
        if command -v jq >/dev/null 2>&1; then
            local config_json
            config_json=$(tmux show-environment -g "$DAEMON_CONFIG_ENV" 2>/dev/null | cut -d= -f2- || echo "{}")
            
            echo "Configuration:"
            echo "$config_json" | jq -r 'to_entries | map("  \(.key): \(.value)") | join("\n")' 2>/dev/null || echo "  Unable to parse configuration"
        fi
        
        # Show queue status
        if command -v jq >/dev/null 2>&1; then
            local queue_json
            queue_json=$(tmux show-environment -g "$DAEMON_QUEUE_ENV" 2>/dev/null | cut -d= -f2- || echo "{}")
            
            local queue_count
            queue_count=$(echo "$queue_json" | jq '[.[] | length] | add // 0' 2>/dev/null || echo "0")
            echo "Queue: $queue_count pending modules"
        fi
        
        return 0
    else
        echo "Background daemon is not running"
        return 1
    fi
}

# Configure daemon
configure_daemon() {
    local key="$1"
    local value="$2"
    
    if ! set_daemon_config "$key" "$value"; then
        echo "Failed to update configuration"
        return 1
    fi
    
    echo "Updated $key = $value"
    
    # If daemon is running, it will pick up changes on next cycle
    if is_daemon_running; then
        echo "Configuration will take effect on next update cycle"
    fi
}

# Force immediate module update
force_update_module() {
    local module="$1"
    local timeout="${2:-$DEFAULT_TIMEOUT}"
    
    if ! is_daemon_running; then
        echo "Daemon not running, executing module directly"
        execute_module "$module" "$timeout"
        return $?
    fi
    
    # Add to high priority queue for immediate processing
    local old_priority="${MODULE_PRIORITIES[$module]:-3}"
    MODULE_PRIORITIES["$module"]="1"
    
    enqueue_module "$module"
    echo "Module $module queued for immediate update"
    
    # Restore original priority
    MODULE_PRIORITIES["$module"]="$old_priority"
}

# Main CLI interface
main() {
    local command="${1:-help}"
    shift || true
    
    case "$command" in
        "--daemon-mode")
            # Internal daemon mode
            daemon_main_loop "$@"
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
        "config")
            configure_daemon "$@"
            ;;
        "update")
            force_update_module "$@"
            ;;
        "help"|*)
            cat <<EOF
Background Update Daemon for tmux-forceline v3.0

USAGE:
    $0 <command> [arguments]

COMMANDS:
    start [interval] [max_concurrent] [timeout]
        Start background daemon with optional configuration
        
    stop
        Stop background daemon
        
    restart [interval] [max_concurrent] [timeout]
        Restart daemon with new configuration
        
    status
        Show daemon status and configuration
        
    config <key> <value>
        Update daemon configuration
        Keys: update_interval, max_concurrent, timeout, enabled
        
    update <module> [timeout]
        Force immediate update of specific module
        
    help
        Show this help message

CONFIGURATION:
    update_interval   - Seconds between update cycles (default: $DEFAULT_UPDATE_INTERVAL)
    max_concurrent    - Maximum concurrent module executions (default: $DEFAULT_MAX_CONCURRENT)
    timeout          - Timeout for individual module execution (default: $DEFAULT_TIMEOUT)
    enabled          - Enable/disable daemon (true/false)

MODULE PRIORITIES:
    Priority 1: battery, hostname, session, datetime (critical, fast)
    Priority 2: cpu, memory, load, uptime (important, medium cost)
    Priority 3: disk_usage, vcs, directory (useful, higher cost)
    Priority 4: lan_ip, network (network-dependent, expensive)
    Priority 5: wan_ip, weather (most expensive, external APIs)

EXAMPLES:
    $0 start 5 3 15
    $0 config update_interval 10
    $0 update weather 30
    $0 status
EOF
            ;;
    esac
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
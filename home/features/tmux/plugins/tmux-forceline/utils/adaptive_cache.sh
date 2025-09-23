#!/usr/bin/env bash
# Adaptive Cache Framework for tmux-forceline v3.0
# Implements intelligent caching with module-specific TTLs and adaptive behavior
# Based on Tao of Tmux principles for optimal performance

set -euo pipefail

# Global configuration
readonly CACHE_VERSION="3.0"
readonly DEFAULT_CACHE_DIR="${TMUX_TMPDIR:-${TMPDIR:-/tmp}}/tmux-forceline"
readonly CACHE_METADATA_FILE="$DEFAULT_CACHE_DIR/.cache_metadata"
readonly CACHE_STATS_FILE="$DEFAULT_CACHE_DIR/.cache_stats"

# Source centralized utilities if available
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    source "$UTILS_DIR/common.sh"
else
    # Fallback implementation
    get_tmux_option() {
        local option="$1"
        local default="$2"
        tmux show-option -gqv "$option" 2>/dev/null || echo "$default"
    }
fi

# Source load detection utilities for adaptive behavior
if [[ -f "$UTILS_DIR/load_detection.sh" ]]; then
    source "$UTILS_DIR/load_detection.sh"
fi

# Module-specific cache profiles based on data volatility analysis
declare -A CACHE_PROFILES=(
    # High volatility - frequent updates needed
    ["cpu"]="2"
    ["memory"]="3"
    ["load"]="2"
    ["network"]="5"
    
    # Medium volatility - moderate update frequency
    ["battery"]="30"
    ["disk_usage"]="15"
    ["datetime"]="1"
    ["hostname"]="300"
    
    # Low volatility - infrequent updates acceptable
    ["weather"]="900"
    ["wan_ip"]="3600"
    ["uptime"]="60"
    ["vcs"]="10"
    
    # Very low volatility - rarely changes
    ["session_info"]="300"
    ["system_info"]="3600"
)

# Performance budget multipliers based on system load
declare -A LOAD_MULTIPLIERS=(
    ["conservative"]="3.0"
    ["balanced"]="1.5"
    ["aggressive"]="1.0"
    ["high_load"]="2.0"
)

# Initialize cache system
init_cache_system() {
    local cache_dir="${1:-$DEFAULT_CACHE_DIR}"
    
    # Create cache directory with proper permissions
    if ! mkdir -p "$cache_dir" 2>/dev/null; then
        echo "Warning: Cannot create cache directory $cache_dir" >&2
        return 1
    fi
    
    # Initialize metadata if not exists
    if [[ ! -f "$CACHE_METADATA_FILE" ]]; then
        cat > "$CACHE_METADATA_FILE" <<EOF
{
  "version": "$CACHE_VERSION",
  "created": "$(date -Iseconds)",
  "last_cleanup": "$(date -Iseconds)",
  "profiles": $(printf '%s\n' "${!CACHE_PROFILES[@]}" | jq -R . | jq -s 'map({(.): ($CACHE_PROFILES[.]|tonumber)}) | add'),
  "stats": {
    "hits": 0,
    "misses": 0,
    "evictions": 0,
    "errors": 0
  }
}
EOF
    fi
    
    # Initialize stats tracking
    [[ ! -f "$CACHE_STATS_FILE" ]] && echo "{}" > "$CACHE_STATS_FILE"
    
    return 0
}

# Get system load for adaptive behavior
get_system_load() {
    local load_avg
    if command -v uptime >/dev/null 2>&1; then
        load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')
        echo "${load_avg:-0.0}"
    else
        echo "0.0"
    fi
}

# Determine performance budget level
get_performance_budget() {
    local budget_level
    budget_level=$(get_tmux_option "@forceline_performance_budget" "balanced")
    
    # Auto-detect high load condition
    local current_load
    current_load=$(get_system_load)
    if command -v bc >/dev/null 2>&1 && (( $(echo "$current_load > 2.0" | bc -l) )); then
        echo "high_load"
    else
        echo "$budget_level"
    fi
}

# Calculate adaptive TTL for a module with load-aware behavior
get_adaptive_ttl() {
    local module="$1"
    local base_ttl="${CACHE_PROFILES[$module]:-60}"
    local budget_level
    budget_level=$(get_performance_budget)
    local multiplier="${LOAD_MULTIPLIERS[$budget_level]:-1.5}"
    
    # Apply load-aware adjustment if load detection is available
    local load_adjustment=1
    if command -v get_load_level >/dev/null 2>&1; then
        local load_level
        load_level=$(get_load_level 1 2>/dev/null || echo "medium")
        
        case "$load_level" in
            "low") 
                load_adjustment="0.8"  # Reduce TTL for more frequent updates when system is idle
                ;;
            "medium") 
                load_adjustment="1.0"  # Normal TTL
                ;;
            "high") 
                load_adjustment="1.5"  # Extend TTL to reduce system pressure
                ;;
            "critical") 
                load_adjustment="2.0"  # Significantly extend TTL to preserve resources
                ;;
        esac
    fi
    
    # Calculate adaptive TTL with both budget and load considerations
    if command -v bc >/dev/null 2>&1; then
        local adaptive_ttl
        adaptive_ttl=$(echo "scale=0; $base_ttl * $multiplier * $load_adjustment" | bc)
        echo "${adaptive_ttl%.*}"  # Remove decimal part
    else
        # Fallback without bc - simplified calculation
        local budget_multiplied
        case "$budget_level" in
            "conservative") budget_multiplied=$((base_ttl * 3)) ;;
            "balanced") budget_multiplied=$((base_ttl * 3 / 2)) ;;
            "aggressive") budget_multiplied="$base_ttl" ;;
            "high_load") budget_multiplied=$((base_ttl * 2)) ;;
            *) budget_multiplied="$base_ttl" ;;
        esac
        
        # Apply simplified load adjustment
        if command -v get_load_level >/dev/null 2>&1; then
            local load_level
            load_level=$(get_load_level 1 2>/dev/null || echo "medium")
            case "$load_level" in
                "high"|"critical") echo $((budget_multiplied * 3 / 2)) ;;  # 1.5x
                "low") echo $((budget_multiplied * 4 / 5)) ;;  # 0.8x
                *) echo "$budget_multiplied" ;;
            esac
        else
            echo "$budget_multiplied"
        fi
    fi
}

# Generate cache key for a module
generate_cache_key() {
    local module="$1"
    local context="${2:-default}"
    echo "${module}_${context}"
}

# Get cache file path
get_cache_file() {
    local cache_key="$1"
    local cache_dir="${2:-$DEFAULT_CACHE_DIR}"
    echo "$cache_dir/${cache_key}.cache"
}

# Check if cache entry is valid
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
    
    [[ $((current_time - file_age)) -lt "$max_age" ]]
}

# Update cache statistics
update_cache_stats() {
    local event="$1"  # hit, miss, set, evict, error
    local module="$2"
    
    [[ -f "$CACHE_STATS_FILE" ]] || echo "{}" > "$CACHE_STATS_FILE"
    
    # Update overall stats
    local temp_file="${CACHE_STATS_FILE}.tmp"
    jq --arg event "$event" --arg module "$module" \
       '.overall[$event] = (.overall[$event] // 0) + 1 |
        .by_module[$module][$event] = (.by_module[$module][$event] // 0) + 1 |
        .last_updated = now' \
       "$CACHE_STATS_FILE" > "$temp_file" 2>/dev/null && mv "$temp_file" "$CACHE_STATS_FILE" || {
        # Fallback if jq fails
        echo "{\"overall\":{\"$event\":1},\"by_module\":{\"$module\":{\"$event\":1}},\"last_updated\":$(date +%s)}" > "$CACHE_STATS_FILE"
    }
}

# Set cache value with metadata
cache_set() {
    local module="$1"
    local data="$2"
    local context="${3:-default}"
    local cache_dir="${4:-$DEFAULT_CACHE_DIR}"
    
    # Initialize cache system if needed
    init_cache_system "$cache_dir" || return 1
    
    local cache_key
    cache_key=$(generate_cache_key "$module" "$context")
    local cache_file
    cache_file=$(get_cache_file "$cache_key" "$cache_dir")
    local ttl
    ttl=$(get_adaptive_ttl "$module")
    
    # Create cache entry with metadata
    local cache_entry
    cache_entry=$(cat <<EOF
{
  "module": "$module",
  "context": "$context",
  "data": $(echo "$data" | jq -R .),
  "timestamp": $(date +%s),
  "ttl": $ttl,
  "expires_at": $(($(date +%s) + ttl)),
  "budget_level": "$(get_performance_budget)",
  "system_load": "$(get_system_load)"
}
EOF
)
    
    # Write cache entry atomically
    if echo "$cache_entry" > "${cache_file}.tmp" && mv "${cache_file}.tmp" "$cache_file"; then
        update_cache_stats "set" "$module"
        return 0
    else
        update_cache_stats "error" "$module"
        return 1
    fi
}

# Get cache value
cache_get() {
    local module="$1"
    local context="${2:-default}"
    local cache_dir="${3:-$DEFAULT_CACHE_DIR}"
    local max_age_override="$4"  # Optional TTL override
    
    local cache_key
    cache_key=$(generate_cache_key "$module" "$context")
    local cache_file
    cache_file=$(get_cache_file "$cache_key" "$cache_dir")
    
    # Check if cache file exists
    if [[ ! -f "$cache_file" ]]; then
        update_cache_stats "miss" "$module"
        return 1
    fi
    
    # Determine TTL to use
    local ttl
    if [[ -n "$max_age_override" ]]; then
        ttl="$max_age_override"
    else
        ttl=$(get_adaptive_ttl "$module")
    fi
    
    # Check if cache is still valid
    if is_cache_valid "$cache_file" "$ttl"; then
        # Extract data from cache entry
        local cached_data
        if cached_data=$(jq -r '.data' "$cache_file" 2>/dev/null); then
            update_cache_stats "hit" "$module"
            echo "$cached_data"
            return 0
        else
            # Malformed cache entry
            rm -f "$cache_file" 2>/dev/null || true
            update_cache_stats "error" "$module"
            return 1
        fi
    else
        # Cache expired
        rm -f "$cache_file" 2>/dev/null || true
        update_cache_stats "miss" "$module"
        return 1
    fi
}

# Invalidate cache for a module
cache_invalidate() {
    local module="$1"
    local context="${2:-default}"
    local reason="${3:-manual}"
    local cache_dir="${4:-$DEFAULT_CACHE_DIR}"
    
    local cache_key
    cache_key=$(generate_cache_key "$module" "$context")
    local cache_file
    cache_file=$(get_cache_file "$cache_key" "$cache_dir")
    
    if [[ -f "$cache_file" ]]; then
        rm -f "$cache_file" 2>/dev/null || true
        update_cache_stats "evict" "$module"
        return 0
    else
        return 1
    fi
}

# Invalidate all cache entries for a module
cache_invalidate_module() {
    local module="$1"
    local cache_dir="${2:-$DEFAULT_CACHE_DIR}"
    
    local count=0
    for cache_file in "$cache_dir"/${module}_*.cache; do
        [[ -f "$cache_file" ]] || continue
        rm -f "$cache_file" 2>/dev/null && ((count++))
    done
    
    [[ $count -gt 0 ]] && update_cache_stats "evict" "$module"
    echo "$count"
}

# Clean up expired cache entries
cache_cleanup() {
    local cache_dir="${1:-$DEFAULT_CACHE_DIR}"
    local force="${2:-false}"
    
    [[ -d "$cache_dir" ]] || return 0
    
    local cleaned=0
    local current_time
    current_time=$(date +%s)
    
    for cache_file in "$cache_dir"/*.cache; do
        [[ -f "$cache_file" ]] || continue
        
        # Check if file is expired based on metadata
        local expires_at
        if expires_at=$(jq -r '.expires_at // empty' "$cache_file" 2>/dev/null); then
            if [[ -n "$expires_at" ]] && [[ "$current_time" -gt "$expires_at" ]]; then
                rm -f "$cache_file" 2>/dev/null && ((cleaned++))
            fi
        elif [[ "$force" == "true" ]]; then
            # Force cleanup of files without metadata
            rm -f "$cache_file" 2>/dev/null && ((cleaned++))
        fi
    done
    
    # Update cleanup timestamp
    if [[ -f "$CACHE_METADATA_FILE" ]] && command -v jq >/dev/null 2>&1; then
        local temp_file="${CACHE_METADATA_FILE}.tmp"
        jq --arg timestamp "$(date -Iseconds)" \
           '.last_cleanup = $timestamp' \
           "$CACHE_METADATA_FILE" > "$temp_file" && mv "$temp_file" "$CACHE_METADATA_FILE"
    fi
    
    echo "$cleaned"
}

# Get cache statistics
cache_stats() {
    local module="${1:-}"
    local format="${2:-human}"
    
    if [[ ! -f "$CACHE_STATS_FILE" ]]; then
        echo "No cache statistics available"
        return 1
    fi
    
    case "$format" in
        "json")
            if [[ -n "$module" ]]; then
                jq --arg module "$module" '.by_module[$module] // {}' "$CACHE_STATS_FILE"
            else
                cat "$CACHE_STATS_FILE"
            fi
            ;;
        "human"|*)
            if [[ -n "$module" ]]; then
                echo "Cache statistics for module: $module"
                jq -r --arg module "$module" '
                    .by_module[$module] // {} |
                    to_entries |
                    map("  \(.key): \(.value)") |
                    join("\n")
                ' "$CACHE_STATS_FILE"
            else
                echo "Overall cache statistics:"
                jq -r '
                    .overall // {} |
                    to_entries |
                    map("  \(.key): \(.value)") |
                    join("\n")
                ' "$CACHE_STATS_FILE"
                
                local hit_rate
                hit_rate=$(jq -r '
                    (.overall.hit // 0) as $hits |
                    (($hits + (.overall.miss // 0)) // 1) as $total |
                    ($hits * 100 / $total | floor)
                ' "$CACHE_STATS_FILE")
                echo "  hit_rate: ${hit_rate}%"
            fi
            ;;
    esac
}

# Cache warming for expensive operations
cache_warm() {
    local modules=("$@")
    local cache_dir="${CACHE_DIR:-$DEFAULT_CACHE_DIR}"
    
    if [[ ${#modules[@]} -eq 0 ]]; then
        # Default expensive modules to warm
        modules=("weather" "wan_ip" "battery" "disk_usage")
    fi
    
    echo "Warming cache for modules: ${modules[*]}" >&2
    
    for module in "${modules[@]}"; do
        local module_script
        module_script=$(find "$(dirname "$UTILS_DIR")" -name "${module}.sh" -o -name "${module}_*.sh" | head -1)
        
        if [[ -n "$module_script" && -x "$module_script" ]]; then
            echo "  Warming $module..." >&2
            
            # Execute module script and cache result
            local result
            if result=$("$module_script" 2>/dev/null); then
                cache_set "$module" "$result" "default" "$cache_dir"
            fi
        fi
    done
}

# Get cache information for debugging
cache_info() {
    local cache_dir="${1:-$DEFAULT_CACHE_DIR}"
    
    echo "Cache System Information:"
    echo "  Cache directory: $cache_dir"
    echo "  Cache version: $CACHE_VERSION"
    echo "  Performance budget: $(get_performance_budget)"
    echo "  System load: $(get_system_load)"
    echo ""
    
    if [[ -d "$cache_dir" ]]; then
        local total_files expired_files total_size
        total_files=$(find "$cache_dir" -name "*.cache" | wc -l)
        expired_files=0
        total_size=0
        
        local current_time
        current_time=$(date +%s)
        
        for cache_file in "$cache_dir"/*.cache; do
            [[ -f "$cache_file" ]] || continue
            
            # Check if expired
            local expires_at
            if expires_at=$(jq -r '.expires_at // empty' "$cache_file" 2>/dev/null); then
                [[ -n "$expires_at" ]] && [[ "$current_time" -gt "$expires_at" ]] && ((expired_files++))
            fi
            
            # Add to total size
            if command -v stat >/dev/null 2>&1; then
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    total_size=$((total_size + $(stat -f %z "$cache_file" 2>/dev/null || echo 0)))
                else
                    total_size=$((total_size + $(stat -c %s "$cache_file" 2>/dev/null || echo 0)))
                fi
            fi
        done
        
        echo "  Total cache files: $total_files"
        echo "  Expired files: $expired_files"
        echo "  Total cache size: ${total_size} bytes"
        echo ""
        
        cache_stats
    else
        echo "  Cache directory does not exist"
    fi
}

# Main CLI interface
main() {
    local command="${1:-help}"
    shift || true
    
    case "$command" in
        "set")
            cache_set "$@"
            ;;
        "get")
            cache_get "$@"
            ;;
        "invalidate")
            cache_invalidate "$@"
            ;;
        "invalidate-module")
            cache_invalidate_module "$@"
            ;;
        "cleanup")
            local cleaned
            cleaned=$(cache_cleanup "$@")
            echo "Cleaned up $cleaned expired cache entries"
            ;;
        "stats")
            cache_stats "$@"
            ;;
        "warm")
            cache_warm "$@"
            ;;
        "info")
            cache_info "$@"
            ;;
        "init")
            init_cache_system "$@"
            ;;
        "help"|*)
            cat <<EOF
Adaptive Cache Framework for tmux-forceline v3.0

USAGE:
    $0 <command> [arguments]

COMMANDS:
    set <module> <data> [context] [cache_dir]
        Store data in cache for the specified module
        
    get <module> [context] [cache_dir] [max_age]
        Retrieve cached data for the specified module
        
    invalidate <module> [context] [reason] [cache_dir]
        Remove specific cache entry
        
    invalidate-module <module> [cache_dir]
        Remove all cache entries for a module
        
    cleanup [cache_dir] [force]
        Remove expired cache entries
        
    stats [module] [format]
        Show cache statistics (format: human|json)
        
    warm [modules...]
        Pre-populate cache for expensive operations
        
    info [cache_dir]
        Show cache system information
        
    init [cache_dir]
        Initialize cache system
        
    help
        Show this help message

EXAMPLES:
    $0 set cpu "45.2%" default
    $0 get weather
    $0 stats cpu
    $0 warm weather wan_ip battery
    $0 cleanup
EOF
            ;;
    esac
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
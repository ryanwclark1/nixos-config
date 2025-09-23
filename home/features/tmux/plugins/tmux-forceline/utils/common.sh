#!/usr/bin/env bash
# Common Utility Functions for tmux-forceline
# Provides consistent error handling, logging, and helper functions

# Strict error handling
set -euo pipefail

# Global constants
readonly FL_VERSION="3.0.0"
readonly FL_CACHE_DIR="${HOME}/.cache/tmux-forceline"
readonly FL_CONFIG_DIR="${HOME}/.config/tmux/forceline"
readonly FL_DEBUG="${FL_DEBUG:-0}"

# Color constants for consistent styling
readonly FL_COLOR_RESET='\033[0m'
readonly FL_COLOR_RED='\033[0;31m'
readonly FL_COLOR_GREEN='\033[0;32m'
readonly FL_COLOR_YELLOW='\033[0;33m'
readonly FL_COLOR_BLUE='\033[0;34m'
readonly FL_COLOR_PURPLE='\033[0;35m'
readonly FL_COLOR_CYAN='\033[0;36m'

# Ensure required directories exist
init_directories() {
    mkdir -p "$FL_CACHE_DIR" "$FL_CONFIG_DIR"
}

# Logging functions with consistent formatting
log_debug() {
    [[ "$FL_DEBUG" -eq 1 ]] && echo -e "${FL_COLOR_BLUE}[DEBUG]${FL_COLOR_RESET} $*" >&2
}

log_info() {
    echo -e "${FL_COLOR_GREEN}[INFO]${FL_COLOR_RESET} $*" >&2
}

log_warn() {
    echo -e "${FL_COLOR_YELLOW}[WARN]${FL_COLOR_RESET} $*" >&2
}

log_error() {
    echo -e "${FL_COLOR_RED}[ERROR]${FL_COLOR_RESET} $*" >&2
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Safe command execution with fallback
safe_execute() {
    local cmd="$1"
    local fallback="${2:-N/A}"
    local timeout="${3:-5}"

    if command_exists timeout; then
        if timeout "$timeout" bash -c "$cmd" 2>/dev/null; then
            return 0
        fi
    else
        if eval "$cmd" 2>/dev/null; then
            return 0
        fi
    fi

    echo "$fallback"
    return 1
}

# Get tmux option with fallback
get_tmux_option() {
    local option="$1"
    local default="${2:-}"
    local scope="${3:-auto}"
    local value=""
    
    # Input validation
    if [[ -z "$option" ]]; then
        log_warn "get_tmux_option: option parameter is required"
        echo "$default"
        return 1
    fi
    
    # Check if tmux is available and running
    if ! command_exists tmux; then
        log_debug "tmux command not available, using default: $default"
        echo "$default"
        return 1
    fi
    
    # Check if we're in a tmux session
    if [[ -z "${TMUX:-}" ]] && [[ "$scope" == "session" ]]; then
        log_debug "not in tmux session, forcing global scope"
        scope="global"
    fi
    
    # Get option value based on scope strategy
    case "$scope" in
        "session")
            # Try session first, then global
            value="$(tmux show-option -qv "$option" 2>/dev/null)" || value=""
            if [[ -z "$value" ]]; then
                value="$(tmux show-option -gqv "$option" 2>/dev/null)" || value=""
            fi
            ;;
        "global")
            # Global scope only
            value="$(tmux show-option -gqv "$option" 2>/dev/null)" || value=""
            ;;
        "auto"|*)
            # Smart detection: use global for @forceline_* options, session fallback for others
            if [[ "$option" =~ ^@forceline_ ]]; then
                value="$(tmux show-option -gqv "$option" 2>/dev/null)" || value=""
            else
                value="$(tmux show-option -qv "$option" 2>/dev/null)" || value=""
                if [[ -z "$value" ]]; then
                    value="$(tmux show-option -gqv "$option" 2>/dev/null)" || value=""
                fi
            fi
            ;;
    esac
    
    # Return value or default
    if [[ -n "$value" ]]; then
        echo "$value"
        return 0
    else
        echo "$default"
        return 2  # Indicates default was used
    fi
}

# Get forceline root directory from centralized tmux option
get_forceline_dir() {
    local forceline_dir
    forceline_dir="$(get_tmux_option "@forceline_dir" "")"
    if [[ -n "$forceline_dir" ]]; then
        echo "$forceline_dir"
        return 0
    else
        # Fallback: try to find forceline.tmux in common locations
        local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        if [[ -f "$script_dir/../forceline.tmux" ]]; then
            echo "$(cd "$script_dir/.." && pwd)"
            return 0
        else
            log_warn "Could not determine forceline directory"
            echo ""
            return 1
        fi
    fi
}

# Enhanced path helper functions for consistent directory management
get_forceline_modules_dir() {
    local forceline_dir
    forceline_dir="$(get_forceline_dir)"
    if [[ -n "$forceline_dir" ]]; then
        echo "$forceline_dir/modules"
    else
        return 1
    fi
}

get_forceline_utils_dir() {
    local forceline_dir
    forceline_dir="$(get_forceline_dir)"
    if [[ -n "$forceline_dir" ]]; then
        echo "$forceline_dir/utils"
    else
        return 1
    fi
}

get_forceline_themes_dir() {
    local forceline_dir
    forceline_dir="$(get_forceline_dir)"
    if [[ -n "$forceline_dir" ]]; then
        echo "$forceline_dir/themes"
    else
        return 1
    fi
}

# Get path relative to forceline root directory
get_forceline_path() {
    local relative_path="$1"
    local forceline_dir
    forceline_dir="$(get_forceline_dir)"
    if [[ -n "$forceline_dir" && -n "$relative_path" ]]; then
        echo "$forceline_dir/$relative_path"
    else
        return 1
    fi
}

# DEPRECATED: Use get_forceline_dir() instead of calculating CURRENT_DIR
# This function is provided for backward compatibility during migration
get_current_script_dir() {
    echo "$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
}

# Set tmux option with robust error handling and scope control
# Usage: set_tmux_option OPTION VALUE [SCOPE] [FLAGS]
# SCOPE: "session", "global" (default), "auto"
# FLAGS: additional tmux set-option flags (e.g., "-a" for append)
set_tmux_option() {
    local option="$1"
    local value="$2"
    local scope="${3:-global}"
    local flags="${4:-}"
    local tmux_cmd=""
    
    # Input validation
    if [[ -z "$option" ]]; then
        log_warn "set_tmux_option: option parameter is required"
        return 1
    fi
    
    if [[ -z "$value" ]]; then
        log_warn "set_tmux_option: value parameter is required"
        return 1
    fi
    
    # Check if tmux is available
    if ! command_exists tmux; then
        log_error "tmux command not available"
        return 1
    fi
    
    # Build tmux command based on scope
    case "$scope" in
        "session")
            tmux_cmd="tmux set-option -q $flags \"$option\" \"$value\""
            ;;
        "global")
            tmux_cmd="tmux set-option -gq $flags \"$option\" \"$value\""
            ;;
        "auto")
            # Smart detection: use global for @forceline_* options, session for others
            if [[ "$option" =~ ^@forceline_ ]]; then
                tmux_cmd="tmux set-option -gq $flags \"$option\" \"$value\""
            else
                tmux_cmd="tmux set-option -q $flags \"$option\" \"$value\""
            fi
            ;;
        *)
            log_warn "set_tmux_option: invalid scope '$scope', using global"
            tmux_cmd="tmux set-option -gq $flags \"$option\" \"$value\""
            ;;
    esac
    
    # Execute command with error handling
    if eval "$tmux_cmd" 2>/dev/null; then
        log_debug "Successfully set tmux option: $option=$value (scope: $scope)"
        return 0
    else
        log_warn "Failed to set tmux option: $option=$value (scope: $scope)"
        return 1
    fi
}

# Convenience wrapper for backward compatibility - deprecated, use get_tmux_option
get_tmux_option_simple() {
    get_tmux_option "$1" "$2" "global"
}

# Check if tmux option exists (regardless of value)
tmux_option_exists() {
    local option="$1"
    
    if ! command_exists tmux; then
        return 1
    fi
    
    # Check if option exists in any scope
    tmux show-option -gqv "$option" >/dev/null 2>&1 || tmux show-option -qv "$option" >/dev/null 2>&1
}

# Remove/unset tmux option
unset_tmux_option() {
    local option="$1"
    local scope="${2:-global}"
    
    if [[ -z "$option" ]]; then
        log_warn "unset_tmux_option: option parameter is required"
        return 1
    fi
    
    if ! command_exists tmux; then
        log_error "tmux command not available"
        return 1
    fi
    
    case "$scope" in
        "session")
            tmux set-option -uq "$option" 2>/dev/null
            ;;
        "global")
            tmux set-option -ugq "$option" 2>/dev/null
            ;;
        "both")
            tmux set-option -uq "$option" 2>/dev/null
            tmux set-option -ugq "$option" 2>/dev/null
            ;;
        *)
            log_warn "unset_tmux_option: invalid scope '$scope', using global"
            tmux set-option -ugq "$option" 2>/dev/null
            ;;
    esac
}

# Format percentage with consistent styling
format_percentage() {
    local value="$1"
    local threshold_warn="${2:-80}"
    local threshold_crit="${3:-90}"

    # Remove % if present and ensure numeric
    value="${value%\%}"

    if [[ "$value" =~ ^[0-9]+$ ]]; then
        if [[ "$value" -ge "$threshold_crit" ]]; then
            echo "${value}%"  # Critical - no color prefix, let tmux handle it
        elif [[ "$value" -ge "$threshold_warn" ]]; then
            echo "${value}%"  # Warning
        else
            echo "${value}%"  # Normal
        fi
    else
        echo "N/A"
    fi
}

# Cache management functions
cache_get() {
    local key="$1"
    local ttl="${2:-300}"  # 5 minutes default
    local cache_file="$FL_CACHE_DIR/$key"

    if [[ -f "$cache_file" ]]; then
        local age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0)))
        if [[ "$age" -lt "$ttl" ]]; then
            cat "$cache_file"
            return 0
        fi
    fi
    return 1
}

cache_set() {
    local key="$1"
    local value="$2"
    local cache_file="$FL_CACHE_DIR/$key"

    echo "$value" > "$cache_file" 2>/dev/null || {
        log_warn "Failed to write cache: $key"
        return 1
    }
}

# Network connectivity check
check_connectivity() {
    local host="${1:-1.1.1.1}"
    local timeout="${2:-3}"

    if command_exists ping; then
        ping -c 1 -W "$timeout" "$host" >/dev/null 2>&1
    elif command_exists nc; then
        nc -z -w "$timeout" "$host" 53 >/dev/null 2>&1
    else
        return 1
    fi
}

# Sanitize output for tmux
sanitize_output() {
    local input="$1"
    local max_length="${2:-50}"

    # Remove control characters and limit length
    echo "$input" | tr -d '\000-\031' | cut -c1-"$max_length"
}

# Format time duration
format_duration() {
    local seconds="$1"
    local days=$((seconds / 86400))
    local hours=$(((seconds % 86400) / 3600))
    local minutes=$(((seconds % 3600) / 60))

    if [[ "$days" -gt 0 ]]; then
        echo "${days}d"
    elif [[ "$hours" -gt 0 ]]; then
        echo "${hours}h${minutes}m"
    else
        echo "${minutes}m"
    fi
}


# Initialize on source
init_directories

# Export functions for use in other scripts
export -f log_debug log_info log_warn log_error
export -f command_exists safe_execute
export -f get_tmux_option get_tmux_option_simple set_tmux_option unset_tmux_option tmux_option_exists
export -f get_forceline_dir get_forceline_modules_dir get_forceline_utils_dir get_forceline_themes_dir get_forceline_path get_current_script_dir
export -f format_percentage sanitize_output format_duration
export -f cache_get cache_set check_connectivity

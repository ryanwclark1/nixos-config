#!/usr/bin/env bash
# Pure module bootstrap for tmux-forceline — NO tmux dependencies
# Data scripts source this instead of source_helpers.sh
#
# Provides: platform.sh + module_cache.sh + cherry-picked pure functions

# Strict error handling
set -euo pipefail

export FORCELINE_DIR="${FORCELINE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
FORCELINE_UTILS_DIR="$FORCELINE_DIR/utils"

source "$FORCELINE_UTILS_DIR/platform.sh"
source "$FORCELINE_UTILS_DIR/module_cache.sh"

# Global constants (guarded for re-source)
if [[ -z "${FL_PURE_LOADED:-}" ]]; then
    readonly FL_PURE_LOADED=1
    readonly FL_DEBUG="${FL_DEBUG:-0}"
fi

# Logging functions with consistent formatting (no color — pure stderr)
log_debug() {
    [[ "${FL_DEBUG:-0}" -eq 1 ]] && echo "[DEBUG] $*" >&2
    return 0
}

log_info() {
    echo "[INFO] $*" >&2
}

log_warn() {
    echo "[WARN] $*" >&2
}

log_error() {
    echo "[ERROR] $*" >&2
}

# Check if command(s) exist — supports multiple args (all must exist)
command_exists() {
    local cmd
    for cmd in "$@"; do
        command -v "$cmd" >/dev/null 2>&1 || return 1
    done
}

# Safe command execution with fallback
# Usage: safe_execute <fallback> <timeout> <command> [args...]
safe_execute() {
    local fallback="${1:-N/A}"; shift
    local timeout_val="${1:-5}"; shift

    if command_exists timeout; then
        timeout "$timeout_val" "$@" 2>/dev/null || { echo "$fallback"; return 1; }
    else
        "$@" 2>/dev/null || { echo "$fallback"; return 1; }
    fi
}

# Sanitize output — remove control characters and limit length
sanitize_output() {
    local input="$1"
    local max_length="${2:-50}"
    echo "$input" | tr -d '\000-\031' | cut -c1-"$max_length"
}

# Format time duration from seconds
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

# Network connectivity check
check_connectivity() {
    local host="${1:-1.1.1.1}"
    local timeout_val="${2:-3}"

    if command_exists ping; then
        ping -c 1 -W "$timeout_val" "$host" >/dev/null 2>&1
    elif command_exists nc; then
        nc -z -w "$timeout_val" "$host" 53 >/dev/null 2>&1
    else
        return 1
    fi
}

# Backward compat alias for battery_helpers.sh
cpus_number() { get_nproc; }

export -f command_exists log_debug log_info log_warn log_error \
         safe_execute sanitize_output format_duration check_connectivity cpus_number

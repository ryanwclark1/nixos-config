#!/usr/bin/env bash

# Get current working directory of active terminal
# Supports multiple Wayland compositors (Hyprland, Sway, etc.) and fallback methods

set -euo pipefail

# Configuration
FALLBACK_DIR="${HOME}"

# Logging function (optional, can be disabled)
log() {
    [[ "${DEBUG:-0}" == "1" ]] && echo "[DEBUG] $*" >&2 || true
}

# Get PID of currently active window
# Supports multiple Wayland compositors
get_active_window_pid() {
    local pid

    # Method 1: Hyprland (JSON output - most reliable)
    if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
        pid=$(hyprctl activewindow -j 2>/dev/null | jq -r '.pid // empty' 2>/dev/null || echo "")
        if [[ -n "$pid" && "$pid" != "null" && "$pid" != "0" ]]; then
            log "Found PID via Hyprland JSON: $pid"
            echo "$pid"
            return 0
        fi
    fi

    # Method 2: Hyprland (text output parsing)
    if command -v hyprctl >/dev/null 2>&1; then
        pid=$(hyprctl activewindow 2>/dev/null | awk '/pid:/ {print $2}' | head -n1 || echo "")
        if [[ -n "$pid" && "$pid" =~ ^[0-9]+$ ]]; then
            log "Found PID via Hyprland text parsing: $pid"
            echo "$pid"
            return 0
        fi
    fi

    # Method 3: Sway (i3-compatible)
    if command -v swaymsg >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
        pid=$(swaymsg -t get_tree 2>/dev/null | jq -r '.. | select(.focused?) | .pid // empty' 2>/dev/null | head -n1 || echo "")
        if [[ -n "$pid" && "$pid" != "null" && "$pid" != "0" ]]; then
            log "Found PID via Sway: $pid"
            echo "$pid"
            return 0
        fi
    fi

    return 1
}

# Find shell process from terminal PID
find_shell_pid() {
    local terminal_pid="$1"
    local shell_pid

    if [[ -z "$terminal_pid" || ! "$terminal_pid" =~ ^[0-9]+$ ]]; then
        return 1
    fi

    # Try to find child shell process
    shell_pid=$(pgrep -P "$terminal_pid" 2>/dev/null | head -n1 || echo "")

    if [[ -n "$shell_pid" && "$shell_pid" =~ ^[0-9]+$ ]]; then
        log "Found shell PID: $shell_pid"
        echo "$shell_pid"
        return 0
    fi

    # Fallback: check if terminal PID itself is a shell
    local comm
    comm=$(cat "/proc/$terminal_pid/comm" 2>/dev/null || echo "")
    if [[ "$comm" =~ (bash|zsh|fish|sh) ]]; then
        log "Terminal PID is a shell: $terminal_pid"
        echo "$terminal_pid"
        return 0
    fi

    return 1
}

# Get CWD from process
get_process_cwd() {
    local pid="$1"
    local cwd

    if [[ -z "$pid" || ! "$pid" =~ ^[0-9]+$ ]]; then
        return 1
    fi

    # Try to read CWD from /proc
    if [[ -r "/proc/$pid/cwd" ]]; then
        cwd=$(readlink -f "/proc/$pid/cwd" 2>/dev/null || echo "")
        if [[ -n "$cwd" && -d "$cwd" ]]; then
            log "Found CWD: $cwd"
            echo "$cwd"
            return 0
        fi
    fi

    return 1
}

# Main function
main() {
    local terminal_pid
    local shell_pid
    local cwd

    # Get active window PID
    terminal_pid=$(get_active_window_pid || echo "")

    if [[ -z "$terminal_pid" ]]; then
        log "No active window PID found, using fallback: $FALLBACK_DIR"
        echo "$FALLBACK_DIR"
        exit 0
    fi

    # Find shell process
    shell_pid=$(find_shell_pid "$terminal_pid" || echo "")

    if [[ -z "$shell_pid" ]]; then
        log "No shell PID found, trying terminal PID directly"
        shell_pid="$terminal_pid"
    fi

    # Get CWD
    cwd=$(get_process_cwd "$shell_pid" || echo "")

    if [[ -z "$cwd" || ! -d "$cwd" ]]; then
        log "Invalid CWD, using fallback: $FALLBACK_DIR"
        echo "$FALLBACK_DIR"
    else
        echo "$cwd"
    fi
}

main "$@"

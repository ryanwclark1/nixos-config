#!/usr/bin/env bash

# Open a new terminal in the current terminal's working directory
# Supports multiple terminal emulators with fallback

set -euo pipefail

# Configuration
TERMINAL="${HYPR_TERMINAL:-}"
NOTIFICATION_TIMEOUT="${HYPR_NOTIFICATION_TIMEOUT:-2000}"

# Detect terminal emulator
detect_terminal() {
    if [[ -n "$TERMINAL" ]]; then
        echo "$TERMINAL"
        return 0
    fi

    # Try common terminals in order of preference
    for term in kitty alacritty wezterm foot gnome-terminal konsole xterm; do
        if command -v "$term" >/dev/null 2>&1; then
            echo "$term"
            return 0
        fi
    done

    return 1
}

# Notification wrapper
notify() {
    local title="$1"
    local message="$2"
    local urgency="${3:-normal}"

    if command -v notify-send >/dev/null 2>&1; then
        notify-send -t "$NOTIFICATION_TIMEOUT" -u "$urgency" "$title" "$message" 2>/dev/null || true
    fi
}

# Get current working directory
get_cwd() {
    if command -v terminal-cwd >/dev/null 2>&1; then
        terminal-cwd 2>/dev/null || echo "$HOME"
    else
        # Fallback: try to get from active window
        local terminal_pid
        terminal_pid=$(hyprctl activewindow -j 2>/dev/null | jq -r '.pid // empty' 2>/dev/null || echo "")

        if [[ -n "$terminal_pid" && "$terminal_pid" != "null" ]]; then
            local shell_pid
            shell_pid=$(pgrep -P "$terminal_pid" 2>/dev/null | head -n1 || echo "")

            if [[ -n "$shell_pid" ]]; then
                readlink -f "/proc/$shell_pid/cwd" 2>/dev/null || echo "$HOME"
            else
                echo "$HOME"
            fi
        else
            echo "$HOME"
        fi
    fi
}

# Main function
main() {
    local terminal
    terminal=$(detect_terminal)

    if [[ -z "$terminal" ]]; then
        notify "Error" "No terminal emulator found" "critical"
        echo "Error: No terminal emulator found. Please install kitty, alacritty, wezterm, foot, gnome-terminal, konsole, or xterm." >&2
        exit 1
    fi

    local current_dir
    current_dir=$(get_cwd)

    if [[ ! -d "$current_dir" ]]; then
        notify "Warning" "Directory not found, using home: $current_dir" "normal"
        current_dir="$HOME"
    fi

    # Launch terminal in background
    if cd "$current_dir"; then
        "$terminal" &>/dev/null &
        notify "Terminal" "Opened in: $current_dir" "low"
    else
        notify "Error" "Failed to change directory" "critical"
        echo "Error: Failed to change directory" >&2
        exit 1
    fi
}

main "$@"

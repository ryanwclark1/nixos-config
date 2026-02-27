#!/usr/bin/env bash
#  _   _                  _     _ _
# | | | |_   _ _ __  _ __(_) __| | | ___
# | |_| | | | | '_ \| '__| |/ _` | |/ _ \
# |  _  | |_| | |_) | |  | | (_| | |  __/
# |_| |_|\__, | .__/|_|  |_|\__,_|\__|
#        |___/|_|
#

set -euo pipefail

SERVICE="hypridle"

# Check if service is running
is_running() {
    pgrep -x "$SERVICE" >/dev/null 2>&1
}

# Get status
get_status() {
    sleep 1
    if is_running; then
        echo '{"text": "RUNNING", "class": "active", "tooltip": "Screen locking active\nLeft: Deactivate"}'
    else
        echo '{"text": "NOT RUNNING", "class": "notactive", "tooltip": "Screen locking deactivated\nLeft: Activate"}'
    fi
}

# Toggle service
toggle_service() {
    if is_running; then
        if pkill -x "$SERVICE" >/dev/null 2>&1; then
            echo "Hypridle stopped" >&2
        else
            echo "Error: Failed to stop hypridle" >&2
            exit 1
        fi
    else
        if command -v "$SERVICE" >/dev/null 2>&1; then
            "$SERVICE" >/dev/null 2>&1 &
            echo "Hypridle started" >&2
        else
            echo "Error: $SERVICE not found" >&2
            exit 1
        fi
    fi
}

# Main logic
case "${1:-}" in
    "status")
        get_status
        ;;
    "toggle")
        toggle_service
        ;;
    *)
        echo "Usage: $0 {status|toggle}" >&2
        exit 1
        ;;
esac

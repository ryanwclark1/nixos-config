#!/usr/bin/env bash

# Toggle hypridle daemon on/off

set -euo pipefail

# Script configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly DAEMON_NAME="hypridle"

# Logging function
log() {
    echo "[$SCRIPT_NAME] $1" >&2
}

# Notification wrapper
notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -t 3000 "$@"
    else
        log "$*"
    fi
}

# Check if daemon is running
is_daemon_running() {
    pgrep -x "$DAEMON_NAME" >/dev/null 2>&1
}

# Start the daemon
start_daemon() {
    if ! command -v uwsm-app >/dev/null 2>&1; then
        log "Error: uwsm-app command not found"
        notify "Error" "uwsm-app command not found. Cannot start $DAEMON_NAME."
        exit 1
    fi

    if ! command -v "$DAEMON_NAME" >/dev/null 2>&1; then
        log "Error: $DAEMON_NAME command not found"
        notify "Error" "$DAEMON_NAME command not found. Please install it."
        exit 1
    fi

    log "Starting $DAEMON_NAME daemon"
    uwsm-app -- "$DAEMON_NAME" >/dev/null 2>&1 &
    sleep 0.5  # Give it time to start
    if is_daemon_running; then
        notify "🔒 Idle Enabled" "Computer will lock when idle"
        return 0
    else
        log "Warning: $DAEMON_NAME may have failed to start"
        notify "Warning" "$DAEMON_NAME may have failed to start"
        return 1
    fi
}

# Stop the daemon
stop_daemon() {
    log "Stopping $DAEMON_NAME daemon"
    if pkill -x "$DAEMON_NAME" 2>/dev/null; then
        sleep 0.2  # Give it time to stop
        if ! is_daemon_running; then
            notify "🔓 Idle Disabled" "Computer will not lock when idle"
            return 0
        else
            log "Warning: $DAEMON_NAME may still be running"
            notify "Warning" "$DAEMON_NAME may still be running"
            return 1
        fi
    else
        log "Warning: No $DAEMON_NAME process found to stop"
        return 1
    fi
}

# Main logic
main() {
    if is_daemon_running; then
        stop_daemon
    else
        start_daemon
    fi
}

main "$@"

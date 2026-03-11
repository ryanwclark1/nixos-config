#!/usr/bin/env bash

# Toggle hyprsunset nightlight mode on/off

set -euo pipefail

# Script configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly DAEMON_NAME="hyprsunset"
readonly ON_TEMP="${NIGHTLIGHT_ON_TEMP:-4000}"
readonly OFF_TEMP="${NIGHTLIGHT_OFF_TEMP:-6000}"

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

# Ensure hyprsunset daemon is running
ensure_daemon_running() {
    if ! is_daemon_running; then
        log "Starting $DAEMON_NAME daemon"
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

        setsid uwsm-app -- "$DAEMON_NAME" >/dev/null 2>&1 &
        sleep 1  # Give it time to register
        if ! is_daemon_running; then
            log "Error: $DAEMON_NAME failed to start"
            notify "Error" "$DAEMON_NAME failed to start"
            exit 1
        fi
    fi
}

# Get current temperature
get_current_temperature() {
    if ! command -v hyprctl >/dev/null 2>&1; then
        log "Error: hyprctl command not found"
        return 1
    fi

    local temp_output
    temp_output=$(hyprctl hyprsunset temperature 2>/dev/null || echo "")

    if [[ -z "$temp_output" ]]; then
        log "Warning: Could not query hyprsunset temperature"
        return 1
    fi

    local temp
    temp=$(echo "$temp_output" | grep -oE '[0-9]+' | head -n1)

    if [[ -z "$temp" ]] || ! [[ "$temp" =~ ^[0-9]+$ ]]; then
        log "Warning: Invalid temperature value: $temp"
        return 1
    fi

    echo "$temp"
}

# Set temperature
set_temperature() {
    local temp="$1"

    if ! [[ "$temp" =~ ^[0-9]+$ ]]; then
        log "Error: Invalid temperature value: $temp"
        return 1
    fi

    if ! command -v hyprctl >/dev/null 2>&1; then
        log "Error: hyprctl command not found"
        return 1
    fi

    if hyprctl hyprsunset temperature "$temp" >/dev/null 2>&1; then
        return 0
    else
        log "Error: Failed to set temperature to $temp"
        return 1
    fi
}

# Main logic
main() {
    ensure_daemon_running

    local current_temp
    current_temp=$(get_current_temperature)

    if [[ -z "$current_temp" ]]; then
        log "Error: Could not determine current temperature"
        notify "Error" "Could not determine current temperature"
        exit 1
    fi

    log "Current temperature: ${current_temp}K"

    if [[ "$current_temp" == "$OFF_TEMP" ]]; then
        if set_temperature "$ON_TEMP"; then
            notify "🌙 Nightlight" "Screen temperature: ${ON_TEMP}K (warm)"
            log "Set temperature to ${ON_TEMP}K (warm)"
        else
            notify "Error" "Failed to set nightlight temperature"
            exit 1
        fi
    else
        if set_temperature "$OFF_TEMP"; then
            notify "☀️ Daylight" "Screen temperature: ${OFF_TEMP}K (cool)"
            log "Set temperature to ${OFF_TEMP}K (cool)"
        else
            notify "Error" "Failed to set daylight temperature"
            exit 1
        fi
    fi
}

main "$@"

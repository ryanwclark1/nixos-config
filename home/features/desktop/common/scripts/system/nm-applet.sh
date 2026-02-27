#!/usr/bin/env bash

# Network Manager Applet Controller
# Controls the nm-applet process (start, stop, toggle, status)

set -euo pipefail

# Configuration
NOTIFICATION_TIMEOUT="${HYPR_NOTIFICATION_TIMEOUT:-2000}"

# Check dependencies
check_dependencies() {
    if ! command -v nm-applet >/dev/null 2>&1; then
        echo "Error: nm-applet not found. Please install network-manager-applet" >&2
        exit 1
    fi
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

# Check if nm-applet is running
is_running() {
    pgrep -x "nm-applet" >/dev/null 2>&1
}

# Start nm-applet
start_applet() {
    if is_running; then
        echo "nm-applet is already running"
        notify "Network Manager" "Applet is already running" "normal"
        return 0
    fi

    if nm-applet --indicator &>/dev/null &; then
        sleep 0.5  # Give it time to start
        if is_running; then
            echo "Started"
            notify "Network Manager" "Applet started" "normal"
            return 0
        else
            echo "Failed to start"
            notify "Network Manager" "Failed to start applet" "critical"
            return 1
        fi
    else
        echo "Failed to start"
        notify "Network Manager" "Failed to start applet" "critical"
        return 1
    fi
}

# Stop nm-applet
stop_applet() {
    if ! is_running; then
        echo "nm-applet is not running"
        notify "Network Manager" "Applet is not running" "normal"
        return 0
    fi

    if pkill -x "nm-applet" &>/dev/null; then
        sleep 0.5  # Give it time to stop
        if ! is_running; then
            echo "Stopped"
            notify "Network Manager" "Applet stopped" "normal"
            return 0
        else
            echo "Failed to stop"
            notify "Network Manager" "Failed to stop applet" "critical"
            return 1
        fi
    else
        echo "Failed to stop"
        notify "Network Manager" "Failed to stop applet" "critical"
        return 1
    fi
}

# Toggle nm-applet
toggle_applet() {
    if is_running; then
        stop_applet
    else
        start_applet
    fi
}

# Show status
show_status() {
    if is_running; then
        echo "Running"
        local pid
        pid=$(pgrep -x "nm-applet" | head -n1)
        echo "PID: $pid"
        return 0
    else
        echo "Stopped"
        return 1
    fi
}

# Usage information
usage() {
    cat << EOF
Network Manager Applet Controller

Usage: $0 <command> [OPTIONS]

Commands:
    start       Start nm-applet
    stop        Stop nm-applet
    toggle      Toggle nm-applet (start if stopped, stop if running)
    status      Show current status
    help        Show this help message

Environment Variables:
    HYPR_NOTIFICATION_TIMEOUT  Notification duration (default: 2000ms)

Examples:
    $0 start     # Start the applet
    $0 stop      # Stop the applet
    $0 toggle    # Toggle the applet
    $0 status    # Show status
EOF
}

# Main function
main() {
    local command="${1:-start}"

    if [[ "$command" == "-h" || "$command" == "--help" || "$command" == "help" ]]; then
        usage
        exit 0
    fi

    check_dependencies

    case "$command" in
        "start")
            start_applet
            ;;
        "stop")
            stop_applet
            ;;
        "toggle")
            toggle_applet
            ;;
        "status")
            show_status
            ;;
        *)
            echo "Error: Unknown command '$command'" >&2
            usage >&2
            exit 1
            ;;
    esac
}

main "$@"

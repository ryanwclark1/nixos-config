#!/usr/bin/env bash

# Get window information for current active window
# Supports multiple output formats: text (default), json, rofi, notify

set -euo pipefail

# Configuration
OUTPUT_FORMAT="${HYPR_WINDOW_INFO_FORMAT:-text}"
NOTIFICATION_TIMEOUT="${HYPR_NOTIFICATION_TIMEOUT:-5000}"

# Check dependencies
check_dependencies() {
    if ! command -v hyprctl >/dev/null 2>&1; then
        echo "Error: hyprctl not found" >&2
        exit 1
    fi

    if ! command -v jq >/dev/null 2>&1; then
        echo "Error: jq not found" >&2
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

# Get window information as JSON
get_window_json() {
    hyprctl activewindow -j 2>/dev/null || echo "null"
}

# Format boolean
format_bool() {
    [[ "$1" == "true" || "$1" == "1" ]] && echo "Yes" || echo "No"
}

# Output as text
output_text() {
    local window_info="$1"

    if [[ -z "$window_info" || "$window_info" == "null" ]]; then
        echo "No active window found"
        return 1
    fi

    local title class pid workspace pos_x pos_y size_w size_h floating fullscreen

    title=$(echo "$window_info" | jq -r '.title // "Unknown"' 2>/dev/null || echo "Unknown")
    class=$(echo "$window_info" | jq -r '.class // "Unknown"' 2>/dev/null || echo "Unknown")
    pid=$(echo "$window_info" | jq -r '.pid // "Unknown"' 2>/dev/null || echo "Unknown")
    workspace=$(echo "$window_info" | jq -r '.workspace.name // "Unknown"' 2>/dev/null || echo "Unknown")
    pos_x=$(echo "$window_info" | jq -r '.at[0] // 0' 2>/dev/null || echo "0")
    pos_y=$(echo "$window_info" | jq -r '.at[1] // 0' 2>/dev/null || echo "0")
    size_w=$(echo "$window_info" | jq -r '.size[0] // 0' 2>/dev/null || echo "0")
    size_h=$(echo "$window_info" | jq -r '.size[1] // 0' 2>/dev/null || echo "0")
    floating=$(echo "$window_info" | jq -r '.floating // false' 2>/dev/null || echo "false")
    fullscreen=$(echo "$window_info" | jq -r '.fullscreen // false' 2>/dev/null || echo "false")

    cat << EOF
Active Window Information:
=========================
Title:      $title
Class:      $class
PID:        $pid
Workspace:  $workspace
Position:   ${pos_x},${pos_y}
Size:       ${size_w}x${size_h}
Floating:   $(format_bool "$floating")
Fullscreen: $(format_bool "$fullscreen")
EOF
}

# Output as JSON
output_json() {
    local window_info="$1"

    if [[ -z "$window_info" || "$window_info" == "null" ]]; then
        echo "{}"
        return 1
    fi

    echo "$window_info" | jq '.' 2>/dev/null || echo "{}"
}

# Output as rofi format
output_rofi() {
    local window_info="$1"

    if [[ -z "$window_info" || "$window_info" == "null" ]]; then
        echo "No active window"
        return 1
    fi

    local title class workspace
    title=$(echo "$window_info" | jq -r '.title // "Unknown"' 2>/dev/null || echo "Unknown")
    class=$(echo "$window_info" | jq -r '.class // "Unknown"' 2>/dev/null || echo "Unknown")
    workspace=$(echo "$window_info" | jq -r '.workspace.name // "Unknown"' 2>/dev/null || echo "Unknown")

    echo -e "Title: $title\nClass: $class\nWorkspace: $workspace"
}

# Output as notification
output_notify() {
    local window_info="$1"

    if [[ -z "$window_info" || "$window_info" == "null" ]]; then
        notify "Window Info" "No active window found" "normal"
        return 1
    fi

    local title class workspace
    title=$(echo "$window_info" | jq -r '.title // "Unknown"' 2>/dev/null || echo "Unknown")
    class=$(echo "$window_info" | jq -r '.class // "Unknown"' 2>/dev/null || echo "Unknown")
    workspace=$(echo "$window_info" | jq -r '.workspace.name // "Unknown"' 2>/dev/null || echo "Unknown")

    local message
    message="Class: $class\nWorkspace: $workspace"

    notify "Window: $title" "$message" "normal"
}

# Usage information
usage() {
    cat << EOF
Window Information Utility

Usage: $0 [FORMAT]

Formats:
    text      Text output (default)
    json      JSON output
    rofi      Rofi-friendly format
    notify    Show as notification

Environment Variables:
    HYPR_WINDOW_INFO_FORMAT    Output format (default: text)
    HYPR_NOTIFICATION_TIMEOUT  Notification duration (default: 5000ms)

Examples:
    $0
    $0 json
    $0 notify
    HYPR_WINDOW_INFO_FORMAT=rofi $0
EOF
}

# Main function
main() {
    local format="${1:-$OUTPUT_FORMAT}"

    # Handle help
    if [[ "$format" == "-h" || "$format" == "--help" ]]; then
        usage
        exit 0
    fi

    check_dependencies

    local window_info
    window_info=$(get_window_json)

    case "$format" in
        "text"|"")
            output_text "$window_info"
            ;;
        "json")
            output_json "$window_info"
            ;;
        "rofi")
            output_rofi "$window_info"
            ;;
        "notify"|"notification")
            output_notify "$window_info"
            ;;
        *)
            echo "Error: Unknown format '$format'" >&2
            echo "Use '$0 --help' for usage information" >&2
            exit 1
            ;;
    esac
}

main "$@"

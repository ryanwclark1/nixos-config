#!/usr/bin/env bash

# Audio sink switcher - cycles through available audio outputs
# Dependencies: wpctl, notify-send

set -euo pipefail

# Configuration
PATH="/run/current-system/sw/bin:/usr/bin:$PATH"
NOTIFICATION_TIMEOUT="${HYPR_NOTIFICATION_TIMEOUT:-2000}"

# Check dependencies
check_dependencies() {
    local missing=()

    if ! command -v wpctl >/dev/null 2>&1; then
        missing+=("wpctl")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Error: Missing required dependencies: ${missing[*]}" >&2
        echo "Please install wireplumber or pipewire-wireplumber" >&2
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

# Get all available audio sinks
get_audio_sinks() {
    local sinks
    sinks=$(wpctl status 2>/dev/null | sed -n '/Sinks:/,/Sources:/p' | grep -E '^\s*│\s+\*?\s*[0-9]+\.' | sed -E 's/^[^0-9]*([0-9]+)\..*/\1/' || echo "")

    if [[ -z "$sinks" ]]; then
        return 1
    fi

    echo "$sinks"
}

# Get current active audio sink
get_current_sink() {
    wpctl status 2>/dev/null | sed -n '/Sinks:/,/Sources:/p' | grep '^\s*│\s*\*' | sed -E 's/^[^0-9]*([0-9]+)\..*/\1/' | head -n1 || echo ""
}

# Get sink name by ID
get_sink_name() {
    local sink_id="$1"
    wpctl status 2>/dev/null | sed -n '/Sinks:/,/Sources:/p' | grep "^\s*│\s*\*\?\s*$sink_id\." | sed -E 's/^[^.]*\.\s*//' | head -n1 || echo "Unknown"
}

# Switch to next audio sink
switch_audio_sink() {
    local sinks_str
    sinks_str=$(get_audio_sinks) || {
        notify "Audio Output" "No audio sinks found" "critical"
        echo "Error: No audio sinks found" >&2
        return 1
    }

    # Convert to array
    local sinks=()
    while IFS= read -r sink; do
        [[ -n "$sink" ]] && sinks+=("$sink")
    done <<< "$sinks_str"

    if [[ ${#sinks[@]} -eq 0 ]]; then
        notify "Audio Output" "No audio sinks found" "critical"
        echo "Error: No audio sinks found" >&2
        return 1
    fi

    # Get current sink
    local current
    current=$(get_current_sink)

    # Find next sink (cycle through)
    local next=""
    if [[ -n "$current" ]]; then
        local i
        for i in "${!sinks[@]}"; do
            if [[ "${sinks[$i]}" == "$current" ]]; then
                next="${sinks[$(((i + 1) % ${#sinks[@]}))]}"
                break
            fi
        done
    fi

    # Fallback to first sink
    next="${next:-${sinks[0]}}"

    # Get sink name
    local sink_name
    sink_name=$(get_sink_name "$next")

    # Switch to next sink and unmute
    if wpctl set-default "$next" &>/dev/null && wpctl set-mute "$next" 0 &>/dev/null; then
        notify "Audio Output" "Switched to: $sink_name" "normal"
        return 0
    else
        notify "Audio Output" "Failed to switch to: $sink_name" "critical"
        echo "Error: Failed to switch audio sink" >&2
        return 1
    fi
}

# Usage information
usage() {
    cat << EOF
Audio Sink Switcher

Usage: $0 [OPTIONS]

Options:
    -h, --help    Show this help message

Description:
    Cycles through available audio output devices (sinks) and switches
    to the next one. Automatically unmutes the new sink.

Environment Variables:
    HYPR_NOTIFICATION_TIMEOUT    Notification duration (default: 2000ms)

Examples:
    $0              # Switch to next audio sink
EOF
}

# Main function
main() {
    local arg="${1:-}"

    if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
        usage
        exit 0
    fi

    check_dependencies
    switch_audio_sink
}

main "$@"

#!/usr/bin/env bash

# Toggle workspace gaps on/off for the currently active workspace

set -euo pipefail

# Script configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly GAPS_OUT="${WORKSPACE_GAPS_OUT:-10}"
readonly GAPS_IN="${WORKSPACE_GAPS_IN:-5}"
readonly BORDER_SIZE="${WORKSPACE_BORDER_SIZE:-2}"

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

# Check dependencies
check_dependencies() {
    local missing_deps=()

    command -v hyprctl >/dev/null 2>&1 || missing_deps+=("hyprctl")
    command -v jq >/dev/null 2>&1 || missing_deps+=("jq")

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log "Error: Missing required dependencies: ${missing_deps[*]}"
        notify "Error" "Missing dependencies: ${missing_deps[*]}"
        exit 1
    fi
}

# Get active workspace ID
get_active_workspace_id() {
    local workspace_json
    workspace_json=$(hyprctl activeworkspace -j 2>/dev/null || echo "")

    if [[ -z "$workspace_json" ]]; then
        log "Error: Could not get active workspace information"
        return 1
    fi

    local workspace_id
    workspace_id=$(echo "$workspace_json" | jq -r '.id // empty' 2>/dev/null || echo "")

    if [[ -z "$workspace_id" ]] || [[ "$workspace_id" == "null" ]]; then
        log "Error: Invalid workspace ID"
        return 1
    fi

    echo "$workspace_id"
}

# Get current gaps for workspace
get_current_gaps() {
    local workspace_id="$1"
    local rules_json
    rules_json=$(hyprctl workspacerules -j 2>/dev/null || echo "")

    if [[ -z "$rules_json" ]]; then
        log "Warning: Could not get workspace rules, assuming gaps are off"
        echo "0"
        return 0
    fi

    local gaps
    gaps=$(echo "$rules_json" | jq -r ".[] | select(.workspaceString==\"$workspace_id\") | .gapsOut[0] // 0" 2>/dev/null || echo "0")

    if ! [[ "$gaps" =~ ^[0-9]+$ ]]; then
        log "Warning: Invalid gaps value, assuming 0"
        gaps="0"
    fi

    echo "$gaps"
}

# Set workspace gaps
set_workspace_gaps() {
    local workspace_id="$1"
    local gaps_out="$2"
    local gaps_in="$3"
    local border_size="$4"

    if ! [[ "$workspace_id" =~ ^[0-9]+$ ]]; then
        log "Error: Invalid workspace ID: $workspace_id"
        return 1
    fi

    if ! [[ "$gaps_out" =~ ^[0-9]+$ ]] || ! [[ "$gaps_in" =~ ^[0-9]+$ ]] || ! [[ "$border_size" =~ ^[0-9]+$ ]]; then
        log "Error: Invalid gap/border values"
        return 1
    fi

    local keyword="workspace $workspace_id, gapsout:$gaps_out, gapsin:$gaps_in, bordersize:$border_size"
    log "Setting workspace $workspace_id: gapsout=$gaps_out, gapsin=$gaps_in, bordersize=$border_size"

    if hyprctl keyword "$keyword" >/dev/null 2>&1; then
        return 0
    else
        log "Error: Failed to set workspace gaps"
        return 1
    fi
}

# Main logic
main() {
    check_dependencies

    local workspace_id
    workspace_id=$(get_active_workspace_id)

    if [[ -z "$workspace_id" ]]; then
        notify "Error" "Could not determine active workspace"
        exit 1
    fi

    log "Active workspace: $workspace_id"

    local current_gaps
    current_gaps=$(get_current_gaps "$workspace_id")

    log "Current gaps: $current_gaps"

    if [[ "$current_gaps" == "0" ]]; then
        if set_workspace_gaps "$workspace_id" "$GAPS_OUT" "$GAPS_IN" "$BORDER_SIZE"; then
            notify "Gaps Enabled" "Workspace $workspace_id gaps enabled"
            log "Enabled gaps for workspace $workspace_id"
        else
            notify "Error" "Failed to enable gaps"
            exit 1
        fi
    else
        if set_workspace_gaps "$workspace_id" "0" "0" "0"; then
            notify "Gaps Disabled" "Workspace $workspace_id gaps disabled"
            log "Disabled gaps for workspace $workspace_id"
        else
            notify "Error" "Failed to disable gaps"
            exit 1
        fi
    fi
}

main "$@"

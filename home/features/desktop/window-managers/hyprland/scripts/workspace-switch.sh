#!/usr/bin/env bash

# Smart workspace switcher (create workspace if it doesn't exist)
# Supports both numeric and named workspaces

set -euo pipefail

# Configuration
NOTIFICATION_TIMEOUT="${HYPR_NOTIFICATION_TIMEOUT:-1500}"

# Check dependencies
check_dependencies() {
    if ! command -v hyprctl >/dev/null 2>&1; then
        echo "Error: hyprctl not found. Make sure Hyprland is installed and running." >&2
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

# Validate workspace name/number
validate_workspace() {
    local workspace="$1"

    # Allow numeric workspaces (1-9, 10-99, etc.)
    if [[ "$workspace" =~ ^[0-9]+$ ]]; then
        return 0
    fi

    # Allow named workspaces (alphanumeric, hyphens, underscores)
    if [[ "$workspace" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        return 0
    fi

    return 1
}

# Get current workspace
get_current_workspace() {
    hyprctl activeworkspace -j 2>/dev/null | jq -r '.name // empty' 2>/dev/null || echo ""
}

# Switch to workspace
switch_workspace() {
    local workspace="$1"

    if ! validate_workspace "$workspace"; then
        echo "Error: Invalid workspace name '$workspace'" >&2
        echo "Workspace must be numeric (e.g., 1, 2, 10) or alphanumeric (e.g., web, code, mail)" >&2
        return 1
    fi

    # Switch to workspace (Hyprland will create it if it doesn't exist)
    if hyprctl dispatch workspace "$workspace" &>/dev/null; then
        local current
        current=$(get_current_workspace)
        notify "Workspace" "Switched to workspace: $current" "low"
        return 0
    else
        notify "Workspace" "Failed to switch to workspace: $workspace" "critical"
        return 1
    fi
}

# List available workspaces
list_workspaces() {
    hyprctl workspaces -j 2>/dev/null | jq -r '.[].name' 2>/dev/null | sort -V || echo ""
}

# Usage information
usage() {
    cat << EOF
Workspace Switcher

Usage: $0 <workspace> [OPTIONS]

Arguments:
    workspace    Workspace number (1-9, 10-99, etc.) or name (web, code, mail, etc.)

Options:
    -l, --list   List all available workspaces
    -h, --help   Show this help message

Environment Variables:
    HYPR_NOTIFICATION_TIMEOUT    Notification duration (default: 1500ms)

Examples:
    $0 1
    $0 10
    $0 web
    $0 code
    $0 --list
EOF
}

# Main function
main() {
    local workspace="${1:-}"

    # Handle options
    case "$workspace" in
        "-h"|"--help")
            usage
            exit 0
            ;;
        "-l"|"--list")
            check_dependencies
            echo "Available workspaces:"
            list_workspaces
            exit 0
            ;;
        "")
            echo "Error: Workspace not specified" >&2
            usage >&2
            exit 1
            ;;
    esac

    check_dependencies
    switch_workspace "$workspace"
}

main "$@"

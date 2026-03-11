#!/usr/bin/env bash

# Enhanced Workspace Switcher
# Consolidates functionality from hyprland-workspace.sh and switch-workspace.sh

set -euo pipefail

SCREENSHOT_DIR="/tmp/hyprland-workspace-previews"
mkdir -p "$SCREENSHOT_DIR"

# Configuration
ENABLE_PREVIEWS="${HYPR_WORKSPACE_PREVIEWS:-true}"
ROFI_THEME="${HYPR_WORKSPACE_THEME:-default}"

# Check required commands
if ! command -v hyprctl >/dev/null 2>&1; then
    echo "Error: hyprctl not found" >&2
    exit 1
fi

# Function to capture a screenshot of a workspace
capture_screenshot() {
    local workspace=$1
    local current_workspace

    # Get current workspace safely
    if command -v jq >/dev/null 2>&1; then
        current_workspace=$(hyprctl activewindow -j 2>/dev/null | jq -r '.workspace.name // empty' || echo "")
    else
        # Fallback: try to get current workspace another way
        current_workspace=$(hyprctl monitors -j 2>/dev/null | grep -o '"activeWorkspace":[0-9]*' | cut -d':' -f2 | head -1 || echo "")
    fi

    # If we can't determine current workspace, use workspace 1 as fallback
    if [[ -z "$current_workspace" ]]; then
        current_workspace="1"
    fi

    # Switch to workspace, take screenshot, switch back
    hyprctl dispatch workspace "$workspace" >/dev/null 2>&1 || return 1
    sleep 0.1

    if command -v grim >/dev/null 2>&1; then
        grim "$SCREENSHOT_DIR/workspace_$workspace.png" 2>/dev/null || return 1
    else
        echo "Warning: grim not found, cannot capture screenshot" >&2
        return 1
    fi

    hyprctl dispatch workspace "$current_workspace" >/dev/null 2>&1 || true
}

# Function to generate workspace list
gen_workspaces() {
    local use_previews="$1"
    local workspaces_json

    # Get workspaces JSON
    workspaces_json=$(hyprctl workspaces -j 2>/dev/null || echo "[]")

    if [[ -z "$workspaces_json" || "$workspaces_json" == "[]" ]]; then
        echo "1"  # Default to workspace 1 if none found
        return
    fi

    # Parse workspaces
    if command -v jq >/dev/null 2>&1; then
        while IFS= read -r workspace; do
            if [[ -z "$workspace" ]]; then
                continue
            fi

            if [[ "$use_previews" == "true" ]]; then
                # Generate screenshot if it doesn't exist
                if [[ ! -f "$SCREENSHOT_DIR/workspace_$workspace.png" ]]; then
                    capture_screenshot "$workspace" || true
                fi
                if [[ -f "$SCREENSHOT_DIR/workspace_$workspace.png" ]]; then
                    echo -en "$workspace\x00icon\x1f$SCREENSHOT_DIR/workspace_$workspace.png\n"
                else
                    echo "$workspace"
                fi
            else
                echo "$workspace"
            fi
        done < <(echo "$workspaces_json" | jq -r '.[].name' | sort -n)
    else
        # Fallback without jq
        echo "$workspaces_json" | grep -o '"name":[0-9]*' | cut -d':' -f2 | sort -n | while read -r workspace; do
            echo "$workspace"
        done
    fi
}

# Function to clean old screenshots
clean_screenshots() {
    local active_workspaces
    local workspaces_json

    workspaces_json=$(hyprctl workspaces -j 2>/dev/null || echo "[]")

    if command -v jq >/dev/null 2>&1; then
        readarray -t active_workspaces < <(echo "$workspaces_json" | jq -r '.[].name' 2>/dev/null || echo "")
    else
        # Fallback without jq
        readarray -t active_workspaces < <(echo "$workspaces_json" | grep -o '"name":[0-9]*' | cut -d':' -f2 || echo "")
    fi

    for screenshot in "$SCREENSHOT_DIR"/workspace_*.png; do
        if [[ -f "$screenshot" ]]; then
            local workspace_name
            workspace_name=$(basename "$screenshot" .png | sed 's/workspace_//')
            if ! printf '%s\n' "${active_workspaces[@]}" | grep -qx "$workspace_name"; then
                rm -f "$screenshot"
            fi
        fi
    done
}

# Usage information
usage() {
    cat << EOF
Enhanced Workspace Switcher

Usage: $0 [options] [workspace]

Options:
    --previews, -p      Enable workspace preview screenshots
    --simple, -s        Simple text-only interface
    --clean, -c         Clean old workspace screenshots
    --help, -h          Show this help

Arguments:
    workspace           Switch directly to specified workspace

Environment Variables:
    HYPR_WORKSPACE_PREVIEWS    Enable previews (default: true)
    HYPR_WORKSPACE_THEME       Rofi theme to use

Examples:
    $0                  # Interactive workspace selector with previews
    $0 --simple         # Interactive workspace selector (text only)
    $0 5                # Switch directly to workspace 5
    $0 --clean          # Clean old workspace screenshots
EOF
}

# Main function
main() {
    local use_previews="$ENABLE_PREVIEWS"
    local direct_workspace=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --previews|-p)
                use_previews="true"
                shift
                ;;
            --simple|-s)
                use_previews="false"
                shift
                ;;
            --clean|-c)
                clean_screenshots
                echo "Old workspace screenshots cleaned"
                exit 0
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            -*)
                echo "Unknown option: $1" >&2
                usage >&2
                exit 1
                ;;
            *)
                direct_workspace="$1"
                break
                ;;
        esac
    done

    # Direct workspace switch
    if [[ -n "$direct_workspace" ]]; then
        if hyprctl dispatch workspace "$direct_workspace" >/dev/null 2>&1; then
            exit 0
        else
            echo "Error: Failed to switch to workspace $direct_workspace" >&2
            exit 1
        fi
    fi

    # Interactive mode
    if ! command -v rofi >/dev/null 2>&1; then
        echo "Error: rofi not found" >&2
        exit 1
    fi

    local workspaces_list
    workspaces_list=$(gen_workspaces "$use_previews")

    if [[ -z "$workspaces_list" ]]; then
        echo "Error: No workspaces found" >&2
        exit 1
    fi

    # Add "empty" option at the beginning
    local choice
    if [[ "$use_previews" == "true" ]]; then
        workspaces_list="empty\n$workspaces_list"
        choice=$(echo -e "$workspaces_list" | rofi -dmenu -p "Switch Workspace:" -show-icons -columns 6 -width 400 -lines 3 -flow "horizontal" -location 1 -xoffset 0 -yoffset 0 -padding 10 -font "JetBrains Mono 12" -hide-scrollbar 2>/dev/null || echo "")
    else
        workspaces_list="empty\n$(echo -e "$workspaces_list")"
        choice=$(echo -e "$workspaces_list" | rofi -dmenu -p "Switch Workspace:" 2>/dev/null || echo "")
    fi

    # Process user selection
    if [[ -n "$choice" ]]; then
        if [[ "$choice" == "empty" ]]; then
            # Find the next available workspace number
            local next_workspace=1
            local existing_workspaces
            local workspaces_json

            workspaces_json=$(hyprctl workspaces -j 2>/dev/null || echo "[]")

            if command -v jq >/dev/null 2>&1; then
                readarray -t existing_workspaces < <(echo "$workspaces_json" | jq -r '.[].name' | sort -n 2>/dev/null || echo "")
            else
                readarray -t existing_workspaces < <(echo "$workspaces_json" | grep -o '"name":[0-9]*' | cut -d':' -f2 | sort -n 2>/dev/null || echo "")
            fi

            for ws in "${existing_workspaces[@]}"; do
                if [[ "$ws" =~ ^[0-9]+$ ]] && [[ "$ws" -eq "$next_workspace" ]]; then
                    ((next_workspace++))
                fi
            done

            if ! hyprctl dispatch workspace "$next_workspace" >/dev/null 2>&1; then
                echo "Error: Failed to switch to workspace $next_workspace" >&2
                exit 1
            fi
        else
            if ! hyprctl dispatch workspace "$choice" >/dev/null 2>&1; then
                echo "Error: Failed to switch to workspace $choice" >&2
                exit 1
            fi
        fi
    fi
}

# Run main function
main "$@"

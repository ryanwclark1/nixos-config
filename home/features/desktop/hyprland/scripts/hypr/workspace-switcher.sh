#!/usr/bin/env bash

# Enhanced Workspace Switcher
# Consolidates functionality from hyprland-workspace.sh and switch-workspace.sh

SCREENSHOT_DIR="/tmp/hyprland-workspace-previews"
mkdir -p "$SCREENSHOT_DIR"

# Configuration
ENABLE_PREVIEWS="${HYPR_WORKSPACE_PREVIEWS:-true}"
ROFI_THEME="${HYPR_WORKSPACE_THEME:-default}"

# Function to capture a screenshot of a workspace
capture_screenshot() {
    local workspace=$1
    local current_workspace=$(hyprctl activewindow -j | jq -r '.workspace.name')
    
    # Switch to workspace, take screenshot, switch back
    hyprctl dispatch workspace "$workspace" >/dev/null
    sleep 0.1
    grim "$SCREENSHOT_DIR/workspace_$workspace.png"
    hyprctl dispatch workspace "$current_workspace" >/dev/null
}

# Function to generate workspace list
gen_workspaces() {
    local use_previews="$1"
    
    for workspace in $(hyprctl workspaces -j | jq -r '.[].name' | sort -n); do
        if [[ "$use_previews" == "true" ]]; then
            # Generate screenshot if it doesn't exist
            if [[ ! -f "$SCREENSHOT_DIR/workspace_$workspace.png" ]]; then
                capture_screenshot "$workspace"
            fi
            echo -en "$workspace\x00icon\x1f$SCREENSHOT_DIR/workspace_$workspace.png\n"
        else
            echo "$workspace"
        fi
    done
}

# Function to clean old screenshots
clean_screenshots() {
    local active_workspaces
    readarray -t active_workspaces < <(hyprctl workspaces -j | jq -r '.[].name')
    
    for screenshot in "$SCREENSHOT_DIR"/workspace_*.png; do
        if [[ -f "$screenshot" ]]; then
            local workspace_name=$(basename "$screenshot" .png | sed 's/workspace_//')
            if ! printf '%s\n' "${active_workspaces[@]}" | grep -qx "$workspace_name"; then
                rm "$screenshot"
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
        hyprctl dispatch workspace "$direct_workspace"
        exit 0
    fi
    
    # Interactive mode
    local workspaces_list
    workspaces_list=$(gen_workspaces "$use_previews")
    
    # Add "empty" option at the beginning
    if [[ "$use_previews" == "true" ]]; then
        workspaces_list="empty\n$workspaces_list"
        choice=$(echo -e "$workspaces_list" | rofi -dmenu -p "Switch Workspace:" -show-icons -columns 6 -width 400 -lines 3 -flow "horizontal" -location 1 -xoffset 0 -yoffset 0 -padding 10 -font "JetBrains Mono 12" -hide-scrollbar)
    else
        workspaces_list="empty\n$(echo -e "$workspaces_list")"
        choice=$(echo -e "$workspaces_list" | rofi -dmenu -p "Switch Workspace:")
    fi
    
    # Process user selection
    if [[ -n "$choice" ]]; then
        if [[ "$choice" == "empty" ]]; then
            # Find the next available workspace number
            local next_workspace=1
            local existing_workspaces
            readarray -t existing_workspaces < <(hyprctl workspaces -j | jq -r '.[].name' | sort -n)
            
            for ws in "${existing_workspaces[@]}"; do
                if [[ "$ws" =~ ^[0-9]+$ ]] && [[ "$ws" -eq "$next_workspace" ]]; then
                    ((next_workspace++))
                fi
            done
            
            hyprctl dispatch workspace "$next_workspace"
        else
            hyprctl dispatch workspace "$choice"
        fi
    fi
}

# Run main function
main "$@"
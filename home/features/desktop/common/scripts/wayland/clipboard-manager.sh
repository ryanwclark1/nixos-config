#!/usr/bin/env bash

# -----------------------------------------------------
# Wayland Clipboard Manager Core Script
# Core clipboard history management functionality
# -----------------------------------------------------
#
# This script provides the core clipboard history management
# functionality for Wayland using cliphist.
# Can be sourced by other scripts or run standalone for non-UI operations.
#
# For rofi UI, see: rofi-clipboard-manager.sh
# -----------------------------------------------------

set -euo pipefail

# Configuration
SCRIPT_NAME="$(basename "$0")"
CLIPHIST_DB="${XDG_CACHE_HOME:-$HOME/.cache}/cliphist/db"

# Logging function
log() {
    echo "[$SCRIPT_NAME] $1" >&2
}

# Notification wrapper
notify() {
    if command -v notify-send >/dev/null; then
        notify-send -t 2000 "$@"
    fi
}

# Check core dependencies (without rofi)
check_core_dependencies() {
    local missing_deps=()

    command -v cliphist >/dev/null || missing_deps+=("cliphist")
    command -v wl-copy >/dev/null || missing_deps+=("wl-copy (wl-clipboard)")
    command -v wl-paste >/dev/null || missing_deps+=("wl-paste (wl-clipboard)")

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo "Error: Missing required dependencies:" >&2
        printf "  - %s\n" "${missing_deps[@]}" >&2
        echo "Please install the missing packages and try again." >&2
        echo "" >&2
        echo "Installation suggestions:" >&2
        echo "  NixOS: Add 'cliphist' and 'wl-clipboard' to your packages" >&2
        echo "  Arch:  pacman -S cliphist wl-clipboard" >&2
        echo "  Ubuntu: apt install wl-clipboard && install cliphist manually" >&2
        return 1
    fi
    return 0
}

# Get clipboard history count
get_history_count() {
    if [[ ! -f "$CLIPHIST_DB" ]]; then
        echo "0"
        return 0
    fi

    local count
    if count=$(cliphist list 2>/dev/null | wc -l); then
        echo "$count"
    else
        log "Warning: Failed to get clipboard history count"
        echo "0"
    fi
}

# Get clipboard history list
get_history_list() {
    cliphist list 2>/dev/null || echo ""
}

# Decode clipboard item
decode_clipboard_item() {
    local item="$1"
    echo "$item" | cliphist decode 2>/dev/null || return 1
}

# Copy content to clipboard
copy_to_clipboard() {
    local content="$1"
    echo "$content" | wl-copy 2>/dev/null || return 1
}

# Delete clipboard item
delete_clipboard_item() {
    local item="$1"
    echo "$item" | cliphist delete 2>/dev/null || return 1
}

# Clear all clipboard history
clear_all_history() {
    cliphist wipe 2>/dev/null || return 1
}

# Get preview of clipboard content (first line, truncated)
get_content_preview() {
    local content="$1"
    local max_length="${2:-50}"
    local preview
    preview=$(echo "$content" | head -n1 | cut -c1-"$max_length")
    [[ ${#preview} -gt $((max_length - 5)) ]] && preview="${preview:0:$((max_length - 5))}..."
    echo "$preview"
}

# Show clipboard history and select item (requires UI function)
# This function expects a UI selector function to be provided
show_clipboard_history_ui() {
    local select_item_func="$1"  # Function that takes prompt, message, items and returns selection
    local history_count
    history_count=$(get_history_count)

    if [[ $history_count -eq 0 ]]; then
        notify "Clipboard" "No clipboard history available"
        log "No clipboard history available"
        return 1
    fi

    log "Showing clipboard history ($history_count items)"

    # Get clipboard history and show in UI
    local selected_item
    selected_item=$(get_history_list | $select_item_func "Clipboard History" "Select item to copy ($history_count items)")

    if [[ -z "$selected_item" ]]; then
        log "No item selected"
        return 0
    fi

    # Decode and copy selected item to clipboard
    local decoded_content
    if ! decoded_content=$(decode_clipboard_item "$selected_item"); then
        notify "Error" "Failed to decode clipboard item"
        log "Error: Failed to decode clipboard item"
        return 1
    fi

    if copy_to_clipboard "$decoded_content"; then
        local preview
        preview=$(get_content_preview "$decoded_content" 50)
        notify "Clipboard" "Copied: $preview"
        log "Copied item to clipboard: $preview"
        return 0
    else
        notify "Error" "Failed to copy item to clipboard"
        log "Error: Failed to copy item to clipboard"
        return 1
    fi
}

# Delete specific clipboard entries (requires UI function)
delete_clipboard_entries_ui() {
    local select_item_func="$1"  # Function that takes prompt, message, items and returns selection
    local confirm_func="$2"      # Function that takes prompt, message, options and returns selection
    local history_count
    history_count=$(get_history_count)

    if [[ $history_count -eq 0 ]]; then
        notify "Clipboard" "No clipboard history to delete"
        log "No clipboard history available for deletion"
        return 1
    fi

    log "Showing clipboard deletion interface ($history_count items)"

    # Show delete interface
    local selected_item
    selected_item=$(get_history_list | $select_item_func "Delete Clipboard Item" "Select item to delete ($history_count items)")

    if [[ -z "$selected_item" ]]; then
        log "No item selected for deletion"
        return 0
    fi

    # Get preview for confirmation
    local decoded_content preview
    if ! decoded_content=$(decode_clipboard_item "$selected_item"); then
        notify "Error" "Failed to decode clipboard item"
        log "Error: Failed to decode clipboard item for preview"
        return 1
    fi

    preview=$(get_content_preview "$decoded_content" 30)

    # Confirm deletion
    local confirm
    confirm=$(echo -e "Delete\nCancel" | $confirm_func "Confirm Deletion" "Delete: $preview?")

    if [[ "$confirm" != "Delete" ]]; then
        log "Deletion cancelled"
        return 0
    fi

    if delete_clipboard_item "$selected_item"; then
        notify "Clipboard" "Deleted: $preview"
        log "Deleted clipboard item: $preview"
        return 0
    else
        notify "Error" "Failed to delete clipboard item"
        log "Error: Failed to delete clipboard item"
        return 1
    fi
}

# Clear all clipboard history (requires UI function)
clear_clipboard_history_ui() {
    local confirm_func="$1"  # Function that takes prompt, message, options and returns selection
    local history_count
    history_count=$(get_history_count)

    if [[ $history_count -eq 0 ]]; then
        notify "Clipboard" "No clipboard history to clear"
        log "No clipboard history to clear"
        return 0
    fi

    log "Confirming clipboard history clear ($history_count items)"

    # Confirm clearing all history
    local confirm
    confirm=$(echo -e "Clear All\nCancel" | $confirm_func "Clear Clipboard History" "Clear all $history_count clipboard entries?")

    if [[ "$confirm" == "Clear All" ]]; then
        if clear_all_history; then
            notify "Clipboard" "Cleared all clipboard history ($history_count items)"
            log "Cleared all clipboard history ($history_count items)"
        else
            notify "Error" "Failed to clear clipboard history"
            log "Failed to clear clipboard history"
            return 1
        fi
    else
        log "Clear operation cancelled"
    fi
}

# Show clipboard statistics
show_clipboard_stats() {
    local history_count db_size="0"
    history_count=$(get_history_count)

    if [[ -f "$CLIPHIST_DB" ]]; then
        db_size=$(du -h "$CLIPHIST_DB" 2>/dev/null | cut -f1 || echo "0")
    fi

    cat << EOF
Clipboard Manager Statistics:
  History entries: $history_count
  Database size: $db_size
  Database location: $CLIPHIST_DB

Recent entries (last 5):
EOF

    if [[ $history_count -gt 0 ]]; then
        get_history_list | head -n5 | while IFS= read -r line || [[ -n "$line" ]]; do
            local decoded_content preview
            if decoded_content=$(decode_clipboard_item "$line"); then
                preview=$(get_content_preview "$decoded_content" 60)
                echo "  - $preview"
            else
                echo "  - (failed to decode)"
            fi
        done
    else
        echo "  (no entries)"
    fi
}

# Start clipboard monitoring daemon
start_clipboard_daemon() {
    # Check if cliphist daemon is already running
    if pgrep -f "wl-paste.*cliphist" >/dev/null; then
        echo "Clipboard daemon is already running" >&2
        return 0
    fi

    log "Starting clipboard history daemon"
    notify "Clipboard" "Starting clipboard history monitoring"

    # Start clipboard monitoring in background
    wl-paste --watch cliphist store >/dev/null 2>&1 &
    local pid=$!

    # Wait a moment to see if it started successfully
    sleep 0.5
    if kill -0 "$pid" 2>/dev/null; then
        log "Clipboard daemon started (PID: $pid)"
        notify "Clipboard" "Clipboard history monitoring started"
        echo "Clipboard history daemon started successfully"
        return 0
    else
        log "Error: Clipboard daemon process died immediately"
        notify "Error" "Clipboard daemon failed to start"
        echo "Failed to start clipboard daemon" >&2
        return 1
    fi
}

# Stop clipboard monitoring daemon
stop_clipboard_daemon() {
    log "Stopping clipboard history daemon"

    local pids
    pids=$(pgrep -f "wl-paste.*cliphist" 2>/dev/null || true)

    if [[ -z "$pids" ]]; then
        log "No clipboard daemon found running"
        echo "No clipboard daemon found running" >&2
        return 0
    fi

    # Kill all clipboard monitoring processes
    if echo "$pids" | xargs kill 2>/dev/null; then
        sleep 0.2  # Give processes time to terminate
        notify "Clipboard" "Stopped clipboard history monitoring"
        log "Stopped clipboard daemon (PIDs: $pids)"
        echo "Clipboard history daemon stopped"
        return 0
    else
        log "Error: Failed to stop clipboard daemon"
        notify "Error" "Failed to stop clipboard daemon"
        return 1
    fi
}

# Show usage information
usage() {
    cat << EOF
Wayland Clipboard Manager Core Script

Usage: $0 [COMMAND]

Commands:
    stats        Show clipboard statistics
    daemon start Start clipboard monitoring daemon
    daemon stop  Stop clipboard monitoring daemon
    help         Show this help

Note: For UI operations (show, delete, clear), use rofi-clipboard-manager.sh

Examples:
    $0 stats              # Show clipboard statistics
    $0 daemon start       # Start monitoring daemon
    $0 daemon stop        # Stop monitoring daemon

Dependencies:
    - cliphist
    - wl-clipboard (wl-copy, wl-paste)
EOF
}

# Main function (for standalone execution)
main() {
    local command="${1:-}"

    # Handle help first (no dependency check needed)
    if [[ "$command" == "help" || "$command" == "-h" || "$command" == "--help" ]]; then
        usage
        exit 0
    fi

    # Handle daemon commands
    if [[ "$command" == "daemon" ]]; then
        local daemon_action="${2:-}"
        case "$daemon_action" in
            "start")
                check_core_dependencies || exit 1
                start_clipboard_daemon
                ;;
            "stop")
                stop_clipboard_daemon
                ;;
            *)
                echo "Error: daemon requires 'start' or 'stop'" >&2
                echo "Use '$0 help' for usage information" >&2
                exit 1
                ;;
        esac
        exit 0
    fi

    # Handle stats command
    if [[ "$command" == "stats" || "$command" == "status" ]]; then
        check_core_dependencies || exit 1
        show_clipboard_stats
        exit 0
    fi

    # If no command or unknown command, show usage
    if [[ -z "$command" ]]; then
        usage
        exit 0
    fi

    echo "Error: Unknown command '$command'" >&2
    echo "Use '$0 help' for usage information" >&2
    exit 1
}

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

#!/usr/bin/env bash

# -----------------------------------------------------
# Wayland Clipboard Manager Script
# Advanced clipboard history management with rofi interface
# -----------------------------------------------------
#
# This script provides comprehensive clipboard history management
# for Wayland using cliphist with a rofi interface.
# Supports viewing, selecting, deleting, and clearing clipboard history.
# -----------------------------------------------------

set -euo pipefail

# Configuration
SCRIPT_NAME="$(basename "$0")"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/rofi"
DEFAULT_THEME="config"
CLIPHIST_DB="${XDG_CACHE_HOME:-$HOME/.cache}/cliphist/db"

# Dependency check function
check_dependencies() {
    local missing_deps=()
    
    # Core dependencies
    command -v cliphist >/dev/null || missing_deps+=("cliphist")
    command -v rofi >/dev/null || missing_deps+=("rofi")
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
        exit 1
    fi
}

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

# Get rofi theme path
get_rofi_theme() {
    local theme_name="${1:-$DEFAULT_THEME}"
    local theme_path="$CONFIG_DIR/$theme_name.rasi"
    
    # Check for specific cliphist theme
    local cliphist_theme="$CONFIG_DIR/cliphist.rasi"
    if [[ -f "$cliphist_theme" ]]; then
        echo "$cliphist_theme"
        return
    fi
    
    # Check if specified theme exists
    if [[ -f "$theme_path" ]]; then
        echo "$theme_path"
    else
        # Return empty string to use default theme
        echo ""
    fi
}

# Run rofi with theme
run_rofi() {
    local prompt="$1"
    local message="${2:-}"
    local additional_args=("${@:3}")
    local theme_path
    theme_path=$(get_rofi_theme)
    
    local rofi_args=(
        -dmenu
        -p "$prompt"
        -i  # Case insensitive
        -format "s"  # Return selection
        -display-columns "1"
    )
    
    # Add message if provided
    [[ -n "$message" ]] && rofi_args+=(-mesg "$message")
    
    # Add theme if available
    [[ -n "$theme_path" ]] && rofi_args+=(-theme "$theme_path")
    
    # Add any additional arguments
    rofi_args+=("${additional_args[@]}")
    
    rofi "${rofi_args[@]}"
}

# Get clipboard history count
get_history_count() {
    if [[ -f "$CLIPHIST_DB" ]]; then
        cliphist list | wc -l
    else
        echo "0"
    fi
}

# Show clipboard history and select item
show_clipboard_history() {
    local history_count
    history_count=$(get_history_count)
    
    if [[ $history_count -eq 0 ]]; then
        notify "Clipboard" "No clipboard history available"
        log "No clipboard history available"
        return 1
    fi
    
    log "Showing clipboard history ($history_count items)"
    
    # Get clipboard history and show in rofi
    local selected_item
    selected_item=$(cliphist list | run_rofi "Clipboard History" "Select item to copy ($history_count items)" -replace)
    
    if [[ -n "$selected_item" ]]; then
        # Decode and copy selected item to clipboard
        if echo "$selected_item" | cliphist decode | wl-copy; then
            # Get first line of selection for notification (truncated)
            local preview
            preview=$(echo "$selected_item" | cliphist decode | head -n1 | cut -c1-50)
            [[ ${#preview} -gt 45 ]] && preview="${preview:0:45}..."
            
            notify "Clipboard" "Copied: $preview"
            log "Copied item to clipboard: $preview"
        else
            notify "Error" "Failed to copy item to clipboard"
            log "Failed to copy item to clipboard"
            return 1
        fi
    else
        log "No item selected"
    fi
}

# Delete specific clipboard entries
delete_clipboard_entries() {
    local history_count
    history_count=$(get_history_count)
    
    if [[ $history_count -eq 0 ]]; then
        notify "Clipboard" "No clipboard history to delete"
        log "No clipboard history available for deletion"
        return 1
    fi
    
    log "Showing clipboard deletion interface ($history_count items)"
    
    # Show delete interface with confirmation
    local selected_item
    selected_item=$(cliphist list | run_rofi "Delete Clipboard Item" "Select item to delete ($history_count items)" -replace)
    
    if [[ -n "$selected_item" ]]; then
        # Get preview for confirmation
        local preview
        preview=$(echo "$selected_item" | cliphist decode | head -n1 | cut -c1-30)
        [[ ${#preview} -gt 25 ]] && preview="${preview:0:25}..."
        
        # Confirm deletion
        local confirm
        confirm=$(echo -e "Delete\nCancel" | run_rofi "Confirm Deletion" "Delete: $preview?")
        
        if [[ "$confirm" == "Delete" ]]; then
            if echo "$selected_item" | cliphist delete; then
                notify "Clipboard" "Deleted: $preview"
                log "Deleted clipboard item: $preview"
            else
                notify "Error" "Failed to delete clipboard item"
                log "Failed to delete clipboard item"
                return 1
            fi
        else
            log "Deletion cancelled"
        fi
    else
        log "No item selected for deletion"
    fi
}

# Clear all clipboard history
clear_clipboard_history() {
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
    confirm=$(echo -e "Clear All\nCancel" | run_rofi "Clear Clipboard History" "Clear all $history_count clipboard entries?")
    
    if [[ "$confirm" == "Clear All" ]]; then
        if cliphist wipe; then
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
        cliphist list | head -n5 | while read -r line; do
            local preview
            preview=$(echo "$line" | cliphist decode | head -n1 | cut -c1-60)
            [[ ${#preview} -gt 55 ]] && preview="${preview:0:55}..."
            echo "  - $preview"
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
    wl-paste --watch cliphist store &
    local pid=$!
    
    # Wait a moment to see if it started successfully
    sleep 0.5
    if kill -0 "$pid" 2>/dev/null; then
        log "Clipboard daemon started (PID: $pid)"
        echo "Clipboard history daemon started successfully"
    else
        log "Failed to start clipboard daemon"
        echo "Failed to start clipboard daemon" >&2
        return 1
    fi
}

# Stop clipboard monitoring daemon
stop_clipboard_daemon() {
    log "Stopping clipboard history daemon"
    
    local pids
    pids=$(pgrep -f "wl-paste.*cliphist" || true)
    
    if [[ -n "$pids" ]]; then
        # Kill all clipboard monitoring processes
        echo "$pids" | xargs kill
        notify "Clipboard" "Stopped clipboard history monitoring"
        log "Stopped clipboard daemon"
        echo "Clipboard history daemon stopped"
    else
        echo "No clipboard daemon found running" >&2
    fi
}

# Show usage information
usage() {
    cat << EOF
Wayland Clipboard Manager Script

Usage: $0 [COMMAND]

Commands:
    show         Show clipboard history and select item (default)
    delete       Delete specific clipboard entries
    clear        Clear all clipboard history
    stats        Show clipboard statistics
    daemon start Start clipboard monitoring daemon
    daemon stop  Stop clipboard monitoring daemon
    help         Show this help

Keyboard shortcuts (when running):
    Enter        Copy selected item
    Delete       Delete selected item (in delete mode)
    Escape       Cancel/exit

Configuration:
    Theme: ~/.config/rofi/cliphist.rasi (fallback to config.rasi)
    Database: ~/.cache/cliphist/db

Examples:
    $0                    # Show clipboard history
    $0 show               # Same as above
    $0 delete             # Delete specific entries
    $0 clear              # Clear all history
    $0 daemon start       # Start monitoring daemon

Dependencies:
    - cliphist
    - rofi  
    - wl-clipboard (wl-copy, wl-paste)
EOF
}

# Main function
main() {
    local command="${1:-show}"
    
    # Handle help first (no dependency check needed)
    if [[ "$command" == "help" || "$command" == "-h" || "$command" == "--help" ]]; then
        usage
        exit 0
    fi
    
    # Handle daemon commands (partial dependency check)
    if [[ "$command" == "daemon" ]]; then
        local daemon_action="${2:-}"
        case "$daemon_action" in
            "start")
                # Only need cliphist and wl-paste for daemon
                command -v cliphist >/dev/null || { echo "Error: cliphist not found" >&2; exit 1; }
                command -v wl-paste >/dev/null || { echo "Error: wl-paste not found" >&2; exit 1; }
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
    
    # Check all dependencies for other commands
    check_dependencies
    
    case "$command" in
        "show"|"")
            show_clipboard_history
            ;;
        "delete"|"d")
            delete_clipboard_entries
            ;;
        "clear"|"wipe"|"w")
            clear_clipboard_history
            ;;
        "stats"|"status")
            show_clipboard_stats
            ;;
        *)
            echo "Error: Unknown command '$command'" >&2
            echo "Use '$0 help' for usage information" >&2
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
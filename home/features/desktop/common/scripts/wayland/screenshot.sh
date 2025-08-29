#!/usr/bin/env bash

# -----------------------------------------------------
# Wayland Screenshot Script
# Advanced screenshot functionality using grimblast/grim with editing support
# -----------------------------------------------------
#
# This script provides comprehensive screenshot functionality for Wayland
# compositors. Uses grimblast for enhanced features with fallback to grim.
# Includes automatic saving, clipboard copying, and post-capture actions.
# -----------------------------------------------------

set -euo pipefail

# Configuration
SCRIPT_NAME="$(basename "$0")"
SCREENSHOTS_DIR="${SCREENSHOTS_DIR:-$HOME/Pictures/Screenshots}"
DEFAULT_FORMAT="png"
QUALITY=95  # For JPEG format

# Dependency check function
check_dependencies() {
    local missing_deps=()
    local screenshot_tools=()
    
    # Core utilities
    command -v date >/dev/null || missing_deps+=("date")
    command -v mkdir >/dev/null || missing_deps+=("mkdir")
    
    # Screenshot tools (at least one required)
    command -v grimblast >/dev/null && screenshot_tools+=("grimblast")
    command -v grim >/dev/null && screenshot_tools+=("grim")
    command -v slurp >/dev/null && screenshot_tools+=("slurp")  # Area selection
    
    if [[ ${#screenshot_tools[@]} -eq 0 ]]; then
        missing_deps+=("screenshot tool (grimblast or grim+slurp)")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo "Error: Missing required dependencies:" >&2
        printf "  - %s\n" "${missing_deps[@]}" >&2
        echo "Please install the missing packages and try again." >&2
        echo "" >&2
        echo "Installation suggestions:" >&2
        echo "  NixOS: Add 'grimblast' or 'grim' + 'slurp' to your packages" >&2
        echo "  Arch:  pacman -S grimshot or grim slurp" >&2
        echo "  Ubuntu: apt install grim slurp" >&2
        exit 1
    fi
    
    # Set preferred screenshot tool
    if command -v grimblast >/dev/null; then
        SCREENSHOT_TOOL="grimblast"
    elif command -v grim >/dev/null && command -v slurp >/dev/null; then
        SCREENSHOT_TOOL="grim"
    else
        echo "Error: No suitable screenshot tool found" >&2
        exit 1
    fi
    
    export SCREENSHOT_TOOL
}

# Logging function
log() {
    echo "[$SCRIPT_NAME] $1" >&2
}

# Notification wrapper
notify() {
    if command -v notify-send >/dev/null; then
        notify-send -t 3000 "$@"
    fi
}

# Enhanced notification with actions
notify_with_actions() {
    local title="$1"
    local message="$2"
    local screenshot_path="$3"
    
    if command -v notify-send >/dev/null; then
        local result
        result=$(notify-send \
            -a "Screenshot" \
            -i "image-x-generic-symbolic" \
            -h "string:image-path:$screenshot_path" \
            -A "file=Show in Files" \
            -A "view=View" \
            -A "edit=Edit" \
            -A "copy=Copy Path" \
            "$title" \
            "$message" 2>/dev/null || echo "")
        
        case "$result" in
            "file") 
                log "Opening file manager"
                xdg-open "$(dirname "$screenshot_path")" 2>/dev/null & 
                ;;
            "view") 
                log "Opening image viewer"
                xdg-open "$screenshot_path" 2>/dev/null & 
                ;;
            "edit") 
                edit_screenshot "$screenshot_path"
                ;;
            "copy")
                if command -v wl-copy >/dev/null; then
                    echo "$screenshot_path" | wl-copy
                    notify "Path Copied" "Screenshot path copied to clipboard"
                fi
                ;;
        esac
    fi
}

# Edit screenshot with available editor
edit_screenshot() {
    local screenshot_path="$1"
    
    # Try different image editors
    local editors=(
        "swappy -f"      # Wayland screenshot editor
        "krita"          # Full featured editor
        "gimp"           # Full featured editor  
        "pinta"          # Simple editor
        "drawing"        # GNOME simple editor
        "kolourpaint"    # KDE simple editor
    )
    
    for editor in "${editors[@]}"; do
        local editor_cmd="${editor%% *}"  # Get first word
        if command -v "$editor_cmd" >/dev/null; then
            log "Opening screenshot in $editor_cmd"
            notify "Edit Screenshot" "Opening in $editor_cmd"
            $editor "$screenshot_path" &
            return 0
        fi
    done
    
    # Fallback to any image viewer/editor
    log "No image editor found, opening with default application"
    xdg-open "$screenshot_path" &
}

# Generate screenshot filename
generate_filename() {
    local prefix="${1:-screenshot}"
    local format="${2:-$DEFAULT_FORMAT}"
    local timestamp
    
    # Create screenshots directory if it doesn't exist
    mkdir -p "$SCREENSHOTS_DIR"
    
    # Generate timestamp
    timestamp=$(date '+%Y-%m-%d_%H-%M-%S')
    
    # Add milliseconds for uniqueness if available
    if command -v date >/dev/null && date --help 2>&1 | grep -q '%3N'; then
        timestamp="${timestamp}-$(date '+%3N')"
    fi
    
    echo "$SCREENSHOTS_DIR/${prefix}_${timestamp}.${format}"
}

# Take screenshot using grimblast
screenshot_with_grimblast() {
    local mode="$1"
    local output_file="$2"
    local freeze_flag="$3"
    local wait_time="$4"
    local copy_to_clipboard="$5"
    
    local args=()
    
    # Add freeze flag if requested
    [[ "$freeze_flag" == "true" ]] && args+=("--freeze")
    
    # Add wait time if specified
    [[ -n "$wait_time" ]] && args+=("--wait" "$wait_time")
    
    # Add cursor flag for screen/area shots
    if [[ "$mode" == "screen" || "$mode" == "area" ]]; then
        args+=("--cursor")
    fi
    
    # Determine action based on clipboard preference
    local action="save"
    if [[ "$copy_to_clipboard" == "true" ]]; then
        action="copysave"  # Both copy to clipboard and save to file
    fi
    
    # Execute grimblast
    case "$mode" in
        "screen")
            grimblast "${args[@]}" "$action" output "$output_file"
            ;;
        "area")
            grimblast "${args[@]}" "$action" area "$output_file"
            ;;
        "window")
            grimblast "${args[@]}" "$action" active "$output_file"
            ;;
        *)
            log "Unknown mode: $mode"
            return 1
            ;;
    esac
}

# Take screenshot using grim+slurp
screenshot_with_grim() {
    local mode="$1"
    local output_file="$2"
    local freeze_flag="$3"
    local wait_time="$4"
    local copy_to_clipboard="$5"
    
    # Wait if specified
    [[ -n "$wait_time" ]] && sleep "$wait_time"
    
    local grim_args=()
    
    case "$mode" in
        "screen")
            # Full screen
            grim "$output_file"
            ;;
        "area")
            # Interactive area selection
            local geometry
            if [[ "$freeze_flag" == "true" ]] && command -v wayfreeze >/dev/null; then
                # Use wayfreeze for frozen selection if available
                geometry=$(wayfreeze slurp 2>/dev/null || slurp 2>/dev/null)
            else
                geometry=$(slurp 2>/dev/null)
            fi
            
            if [[ -n "$geometry" ]]; then
                grim -g "$geometry" "$output_file"
            else
                log "Area selection cancelled"
                return 1
            fi
            ;;
        "window")
            # Active window (requires compositor support)
            local window_geometry
            if command -v hyprctl >/dev/null; then
                # Hyprland specific
                window_geometry=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' 2>/dev/null)
            elif command -v swaymsg >/dev/null; then
                # Sway specific  
                window_geometry=$(swaymsg -t get_tree | jq -r '.. | select(.focused?) | "\(.rect.x),\(.rect.y) \(.rect.width)x\(.rect.height)"' 2>/dev/null)
            fi
            
            if [[ -n "$window_geometry" ]]; then
                grim -g "$window_geometry" "$output_file"
            else
                log "Could not determine active window geometry, falling back to area selection"
                geometry=$(slurp 2>/dev/null)
                if [[ -n "$geometry" ]]; then
                    grim -g "$geometry" "$output_file"
                else
                    return 1
                fi
            fi
            ;;
        *)
            log "Unknown mode: $mode"
            return 1
            ;;
    esac
    
    # Copy to clipboard if requested
    if [[ "$copy_to_clipboard" == "true" ]] && command -v wl-copy >/dev/null; then
        if [[ -f "$output_file" ]]; then
            wl-copy < "$output_file"
            log "Screenshot copied to clipboard"
        fi
    fi
}

# Main screenshot function
take_screenshot() {
    local mode="$1"
    local output_file="$2" 
    local freeze="${3:-false}"
    local wait_time="${4:-}"
    local copy_to_clipboard="${5:-true}"
    local format="${6:-$DEFAULT_FORMAT}"
    
    log "Taking $mode screenshot"
    log "Output: $output_file"
    [[ "$freeze" == "true" ]] && log "Using freeze mode"
    [[ -n "$wait_time" ]] && log "Wait time: ${wait_time}s"
    [[ "$copy_to_clipboard" == "true" ]] && log "Will copy to clipboard"
    
    # Take screenshot based on available tool
    local result=0
    case "$SCREENSHOT_TOOL" in
        "grimblast")
            screenshot_with_grimblast "$mode" "$output_file" "$freeze" "$wait_time" "$copy_to_clipboard" || result=$?
            ;;
        "grim")
            screenshot_with_grim "$mode" "$output_file" "$freeze" "$wait_time" "$copy_to_clipboard" || result=$?
            ;;
    esac
    
    if [[ $result -eq 0 && -f "$output_file" ]]; then
        local file_size
        file_size=$(du -h "$output_file" | cut -f1)
        log "Screenshot saved: $output_file ($file_size)"
        
        # Show notification with actions
        notify_with_actions \
            "Screenshot Captured" \
            "Saved to $(basename "$output_file") ($file_size)" \
            "$output_file"
        
        return 0
    else
        log "Screenshot failed"
        notify "Screenshot Error" "Failed to capture screenshot"
        return 1
    fi
}

# Show usage information
usage() {
    cat << EOF
Wayland Screenshot Script

Usage: $0 [MODE] [OPTIONS]

Modes:
    screen      Capture entire screen (default)
    area        Interactive area selection
    window      Capture active window

Options:
    -f, --freeze       Freeze screen during area selection
    -w, --wait TIME    Wait TIME seconds before capture
    -o, --output FILE  Specify output file
    -F, --format FMT   Image format (png, jpg, webp) 
    --no-copy          Don't copy to clipboard
    --no-notify        Disable notifications
    -h, --help         Show this help

Examples:
    $0                          # Full screen screenshot
    $0 area                     # Interactive area selection
    $0 window --freeze          # Active window with frozen screen
    $0 screen -w 3              # Full screen after 3 second delay
    $0 area -o ~/my-shot.png    # Area selection to specific file

Environment Variables:
    SCREENSHOTS_DIR    Screenshot directory (default: ~/Pictures/Screenshots)

Dependencies:
    - grimblast (recommended) or grim+slurp
    - wl-copy (for clipboard)
    - notify-send (for notifications)
    - Optional: swappy, wayfreeze, image editors
EOF
}

# Main function
main() {
    local mode="screen"  # default
    local freeze="false"
    local wait_time=""
    local output_file=""
    local format="$DEFAULT_FORMAT"
    local copy_to_clipboard="true"
    local show_notifications="true"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            screen|area|window)
                mode="$1"
                shift
                ;;
            -f|--freeze)
                freeze="true"
                shift
                ;;
            -w|--wait)
                if [[ -n "${2:-}" ]] && [[ "$2" =~ ^[0-9]+$ ]]; then
                    wait_time="$2"
                    shift 2
                else
                    echo "Error: --wait requires a numeric argument" >&2
                    exit 1
                fi
                ;;
            -o|--output)
                if [[ -n "${2:-}" ]]; then
                    output_file="$2"
                    shift 2
                else
                    echo "Error: --output requires a file path" >&2
                    exit 1
                fi
                ;;
            -F|--format)
                if [[ -n "${2:-}" ]]; then
                    format="$2"
                    shift 2
                else
                    echo "Error: --format requires a format (png, jpg, webp)" >&2
                    exit 1
                fi
                ;;
            --no-copy)
                copy_to_clipboard="false"
                shift
                ;;
            --no-notify)
                show_notifications="false"
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                echo "Error: Unknown option '$1'" >&2
                echo "Use '$0 --help' for usage information" >&2
                exit 1
                ;;
        esac
    done
    
    # Check dependencies
    check_dependencies
    
    # Generate output filename if not specified
    if [[ -z "$output_file" ]]; then
        output_file=$(generate_filename "screenshot" "$format")
    fi
    
    # Disable notifications if requested
    if [[ "$show_notifications" == "false" ]]; then
        notify() { :; }
        notify_with_actions() { :; }
    fi
    
    # Take screenshot
    take_screenshot "$mode" "$output_file" "$freeze" "$wait_time" "$copy_to_clipboard" "$format"
}

# Run main function with all arguments
main "$@"
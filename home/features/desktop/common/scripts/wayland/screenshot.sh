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
    local clipboard_only="${6:-false}"

    local args=()

    # Add freeze flag if requested
    [[ "$freeze_flag" == "true" ]] && args+=("--freeze")

    # Add wait time if specified
    [[ -n "$wait_time" ]] && args+=("--wait" "$wait_time")

    # Add cursor flag only for screen shots (not area - grimblast doesn't support it)
    if [[ "$mode" == "screen" ]]; then
        args+=("--cursor")
    fi

    # Determine action based on clipboard preference
    local action="save"
    if [[ "$clipboard_only" == "true" ]]; then
        action="copy"  # Copy to clipboard only
    elif [[ "$copy_to_clipboard" == "true" ]]; then
        action="copysave"  # Both copy to clipboard and save to file
    fi

    # Execute grimblast
    case "$mode" in
        "screen")
            if [[ "$clipboard_only" == "true" ]]; then
                grimblast "${args[@]}" "$action" output -
            else
                grimblast "${args[@]}" "$action" output "$output_file"
            fi
            ;;
        "area")
            if [[ "$clipboard_only" == "true" ]]; then
                grimblast "${args[@]}" "$action" area -
            else
                grimblast "${args[@]}" "$action" area "$output_file"
            fi
            ;;
        "window")
            if [[ "$clipboard_only" == "true" ]]; then
                grimblast "${args[@]}" "$action" active -
            else
                grimblast "${args[@]}" "$action" active "$output_file"
            fi
            ;;
        *)
            log "Unknown mode: $mode"
            return 1
            ;;
    esac
}

# Get rectangles for smart mode (windows and outputs on active workspace)
get_rectangles() {
    if ! command -v hyprctl >/dev/null || ! command -v jq >/dev/null; then
        return 1
    fi

    local active_workspace
    active_workspace=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .activeWorkspace.id')

    # Output monitors on active workspace
    hyprctl monitors -j | jq -r --arg ws "$active_workspace" \
        '.[] | select(.activeWorkspace.id == ($ws | tonumber)) | "\(.x),\(.y) \((.width / .scale) | floor)x\((.height / .scale) | floor)"'

    # Output windows on active workspace
    hyprctl clients -j | jq -r --arg ws "$active_workspace" \
        '.[] | select(.workspace.id == ($ws | tonumber)) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"'
}

# Take screenshot using grim+slurp
screenshot_with_grim() {
    local mode="$1"
    local output_file="$2"
    local freeze_flag="$3"
    local wait_time="$4"
    local copy_to_clipboard="$5"
    local use_satty="${6:-false}"
    local clipboard_only="${7:-false}"

    # Wait if specified
    [[ -n "$wait_time" ]] && sleep "$wait_time"

    local geometry=""
    local selection_cancelled=false

    case "$mode" in
        "screen"|"fullscreen")
            # Full screen - get focused monitor
            if command -v hyprctl >/dev/null && command -v jq >/dev/null; then
                geometry=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | "\(.x),\(.y) \((.width / .scale) | floor)x\((.height / .scale) | floor)"')
            fi
            # Fallback to full screen if hyprctl not available
            [[ -z "$geometry" ]] && geometry=""
            ;;
        "area"|"region")
            # Interactive area selection
            if [[ "$freeze_flag" == "true" ]] && command -v wayfreeze >/dev/null; then
                wayfreeze & local freeze_pid=$!
                sleep 0.1
                geometry=$(slurp 2>/dev/null)
                kill "$freeze_pid" 2>/dev/null || true
            else
                geometry=$(slurp 2>/dev/null)
            fi
            [[ -z "$geometry" ]] && selection_cancelled=true
            ;;
        "windows")
            # Select from windows on active workspace
            local rects
            rects=$(get_rectangles)
            if [[ -n "$rects" ]]; then
                if [[ "$freeze_flag" == "true" ]] && command -v wayfreeze >/dev/null; then
                    wayfreeze & local freeze_pid=$!
                    sleep 0.1
                    geometry=$(echo "$rects" | slurp -r 2>/dev/null)
                    kill "$freeze_pid" 2>/dev/null || true
                else
                    geometry=$(echo "$rects" | slurp -r 2>/dev/null)
                fi
            fi
            [[ -z "$geometry" ]] && selection_cancelled=true
            ;;
        "window")
            # Active window (requires compositor support)
            if command -v hyprctl >/dev/null && command -v jq >/dev/null; then
                geometry=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' 2>/dev/null)
            elif command -v swaymsg >/dev/null && command -v jq >/dev/null; then
                geometry=$(swaymsg -t get_tree | jq -r '.. | select(.focused?) | "\(.rect.x),\(.rect.y) \(.rect.width)x\(.rect.height)"' 2>/dev/null)
            fi

            if [[ -z "$geometry" ]]; then
                log "Could not determine active window geometry, falling back to area selection"
                geometry=$(slurp 2>/dev/null)
                [[ -z "$geometry" ]] && selection_cancelled=true
            fi
            ;;
        "smart")
            # Smart mode: show windows and outputs, auto-select if tiny selection
            local rects
            rects=$(get_rectangles)
            if [[ -n "$rects" ]]; then
                if [[ "$freeze_flag" == "true" ]] && command -v wayfreeze >/dev/null; then
                    wayfreeze & local freeze_pid=$!
                    sleep 0.1
                    geometry=$(echo "$rects" | slurp 2>/dev/null)
                    kill "$freeze_pid" 2>/dev/null || true
                else
                    geometry=$(echo "$rects" | slurp 2>/dev/null)
                fi

                # If selection is very small (< 20 pixels), assume user clicked on a window/output
                if [[ "$geometry" =~ ^([0-9]+),([0-9]+)[[:space:]]([0-9]+)x([0-9]+)$ ]]; then
                    local width="${BASH_REMATCH[3]}"
                    local height="${BASH_REMATCH[4]}"
                    if (( width * height < 20 )); then
                        local click_x="${BASH_REMATCH[1]}"
                        local click_y="${BASH_REMATCH[2]}"
                        while IFS= read -r rect; do
                            if [[ "$rect" =~ ^([0-9]+),([0-9]+)[[:space:]]([0-9]+)x([0-9]+)$ ]]; then
                                local rect_x="${BASH_REMATCH[1]}"
                                local rect_y="${BASH_REMATCH[2]}"
                                local rect_width="${BASH_REMATCH[3]}"
                                local rect_height="${BASH_REMATCH[4]}"
                                if (( click_x >= rect_x && click_x < rect_x + rect_width &&
                                      click_y >= rect_y && click_y < rect_y + rect_height )); then
                                    geometry="${rect_x},${rect_y} ${rect_width}x${rect_height}"
                                    break
                                fi
                            fi
                        done <<< "$rects"
                    fi
                fi
            fi
            [[ -z "$geometry" ]] && selection_cancelled=true
            ;;
        *)
            log "Unknown mode: $mode"
            return 1
            ;;
    esac

    # Exit if selection was cancelled
    if [[ "$selection_cancelled" == "true" ]]; then
        log "Selection cancelled"
        return 130  # Exit code for cancellation
    fi

    # Clipboard-only mode: pipe directly to wl-copy
    if [[ "$clipboard_only" == "true" ]] && command -v wl-copy >/dev/null; then
        if [[ -n "$geometry" ]]; then
            grim -g "$geometry" - | wl-copy
        else
            grim - | wl-copy
        fi
        log "Screenshot copied to clipboard"
        return 0
    fi

    # If using satty, pipe through satty for editing
    if [[ "$use_satty" == "true" ]] && command -v satty >/dev/null; then
        if [[ -n "$geometry" ]]; then
            grim -g "$geometry" - | satty \
                --filename - \
                --output-filename "$output_file" \
                --early-exit \
                --actions-on-enter save-to-clipboard \
                --save-after-copy \
                --copy-command 'wl-copy' 2>/dev/null
        else
            grim - | satty \
                --filename - \
                --output-filename "$output_file" \
                --early-exit \
                --actions-on-enter save-to-clipboard \
                --save-after-copy \
                --copy-command 'wl-copy' 2>/dev/null
        fi
        return $?
    fi

    # Standard capture
    if [[ -n "$geometry" ]]; then
        grim -g "$geometry" "$output_file"
    else
        grim "$output_file"
    fi

    # Copy to clipboard if requested
    if [[ "$copy_to_clipboard" == "true" ]] && command -v wl-copy >/dev/null; then
        if [[ -f "$output_file" ]]; then
            wl-copy < "$output_file"
            log "Screenshot copied to clipboard"
        elif [[ -n "$geometry" ]]; then
            # If no file but we have geometry, copy directly
            grim -g "$geometry" - | wl-copy
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
    local use_satty="${7:-false}"
    local clipboard_only="${8:-false}"

    log "Taking $mode screenshot"
    [[ "$clipboard_only" != "true" ]] && log "Output: $output_file"
    [[ "$freeze" == "true" ]] && log "Using freeze mode"
    [[ -n "$wait_time" ]] && log "Wait time: ${wait_time}s"
    [[ "$copy_to_clipboard" == "true" ]] && log "Will copy to clipboard"
    [[ "$clipboard_only" == "true" ]] && log "Clipboard-only mode"
    [[ "$use_satty" == "true" ]] && log "Using satty for editing"

    # Stop any existing slurp instances to avoid conflicts
    pkill slurp 2>/dev/null || true

    # Take screenshot based on available tool
    local result=0
    case "$SCREENSHOT_TOOL" in
        "grimblast")
            # Note: grimblast doesn't support smart/windows modes, fall back to grim for those
            if [[ "$mode" == "smart" || "$mode" == "windows" ]]; then
                screenshot_with_grim "$mode" "$output_file" "$freeze" "$wait_time" "$copy_to_clipboard" "$use_satty" "$clipboard_only" || result=$?
            else
                screenshot_with_grimblast "$mode" "$output_file" "$freeze" "$wait_time" "$copy_to_clipboard" "$clipboard_only" || result=$?
            fi
            ;;
        "grim")
            screenshot_with_grim "$mode" "$output_file" "$freeze" "$wait_time" "$copy_to_clipboard" "$use_satty" "$clipboard_only" || result=$?
            ;;
    esac

    # Handle cancellation (exit code 130)
    if [[ $result -eq 130 ]]; then
        log "Screenshot cancelled by user"
        return 130
    fi

    # Check if screenshot was saved (either file exists or satty handled it)
    if [[ $result -eq 0 ]]; then
        if [[ -f "$output_file" ]]; then
            local file_size
            file_size=$(du -h "$output_file" | cut -f1)
            log "Screenshot saved: $output_file ($file_size)"

            # Show notification with actions (unless using satty, which has its own notifications)
            if [[ "$use_satty" != "true" ]]; then
                notify_with_actions \
                    "Screenshot Captured" \
                    "Saved to $(basename "$output_file") ($file_size)" \
                    "$output_file"
            fi
            return 0
        elif [[ "$use_satty" == "true" ]]; then
            # Satty may have copied to clipboard without saving
            log "Screenshot processed by satty"
            return 0
        fi
    fi

    log "Screenshot failed"
    notify "Screenshot Error" "Failed to capture screenshot"
    return 1
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
    smart       Smart selection with window/output detection
    windows     Select from visible windows
    fullscreen  Capture focused monitor
    region      Alias for area

Options:
    -f, --freeze       Freeze screen during area selection
    -w, --wait TIME    Wait TIME seconds before capture
    -o, --output FILE  Specify output file
    -F, --format FMT   Image format (png, jpg, webp)
    --satty            Use satty for editing after capture
    --clipboard-only   Copy to clipboard only, don't save to file
    --no-copy          Don't copy to clipboard
    --no-notify        Disable notifications
    -h, --help         Show this help

Examples:
    $0                          # Full screen screenshot
    $0 area                     # Interactive area selection
    $0 smart                    # Smart mode with window detection
    $0 window --freeze          # Active window with frozen screen
    $0 screen -w 3              # Full screen after 3 second delay
    $0 area -o ~/my-shot.png    # Area selection to specific file
    $0 smart --satty             # Smart mode with satty editor

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
    local use_satty="false"
    local clipboard_only="false"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            screen|area|window|smart|windows|fullscreen|region)
                mode="$1"
                # Normalize region to area
                [[ "$mode" == "region" ]] && mode="area"
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
            --satty)
                use_satty="true"
                shift
                ;;
            --clipboard-only)
                clipboard_only="true"
                copy_to_clipboard="true"
                shift
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
        if [[ "$clipboard_only" == "true" ]]; then
            # Use a temporary file that will be cleaned up
            output_file="/tmp/screenshot-$$.${format}"
        else
            output_file=$(generate_filename "screenshot" "$format")
        fi
    fi

    # Disable notifications if requested
    if [[ "$show_notifications" == "false" ]]; then
        notify() { :; }
        notify_with_actions() { :; }
    fi

    # Take screenshot
    local result
    take_screenshot "$mode" "$output_file" "$freeze" "$wait_time" "$copy_to_clipboard" "$format" "$use_satty" "$clipboard_only"
    result=$?

    # Clean up temporary file if clipboard-only mode
    if [[ "$clipboard_only" == "true" && -f "$output_file" && "$output_file" == /tmp/screenshot-* ]]; then
        rm -f "$output_file"
    fi

    exit $result
}

# Run main function with all arguments
main "$@"

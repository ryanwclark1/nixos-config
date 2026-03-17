#!/usr/bin/env bash

# -----------------------------------------------------
# Wayland Screenshot Script
# Advanced screenshot functionality using grim+slurp with editing support
# -----------------------------------------------------
#
# This script provides comprehensive screenshot functionality for Wayland
# compositors. Uses grim+slurp directly (no grimblast dependency).
# Includes automatic saving, clipboard copying, and post-capture actions.
# Enhanced with Hyprland-specific features (hyprpicker for freeze, window rectangles).
#
# See SCREENRECORDING.md for detailed documentation and usage examples
# -----------------------------------------------------

set -uo pipefail

# Configuration
SCRIPT_NAME="$(basename "$0")"
SCREENSHOTS_DIR="${SCREENSHOTS_DIR:-$HOME/Pictures/Screenshots}"
DEFAULT_FORMAT="png"

# Cleanup trap: always kill hyprpicker on exit (matches grimblast behavior)
cleanup() {
    pkill hyprpicker 2>/dev/null || true
}
trap cleanup EXIT

# Dependency check function
check_dependencies() {
    local missing_deps=()

    # Core utilities
    command -v date >/dev/null || missing_deps+=("date")
    command -v mkdir >/dev/null || missing_deps+=("mkdir")

    # Screenshot tools (required)
    command -v grim >/dev/null || missing_deps+=("grim")
    command -v slurp >/dev/null || missing_deps+=("slurp")

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo "Error: Missing required dependencies:" >&2
        printf "  - %s\n" "${missing_deps[@]}" >&2
        echo "Please install the missing packages and try again." >&2
        echo "" >&2
        echo "Installation suggestions:" >&2
        echo "  NixOS: Add 'grim' + 'slurp' to your packages" >&2
        echo "  Arch:  pacman -S grim slurp" >&2
        echo "  Ubuntu: apt install grim slurp" >&2
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
        notify-send -t 3000 "$@"
    fi
}

# Enhanced notification with actions
notify_with_actions() {
    local title="$1"
    local message="$2"
    local screenshot_path="$3"

    if [[ ! -f "$screenshot_path" ]]; then
        log "Warning: Screenshot file does not exist for notification: $screenshot_path"
        notify "$title" "$message"
        return 0
    fi

    if ! command -v notify-send >/dev/null 2>&1; then
        notify "$title" "$message"
        return 0
    fi

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
            if command -v xdg-open >/dev/null 2>&1; then
                xdg-open "$(dirname "$screenshot_path")" >/dev/null 2>&1 &
            else
                log "Warning: xdg-open not available"
            fi
            ;;
        "view")
            log "Opening image viewer"
            if command -v xdg-open >/dev/null 2>&1; then
                xdg-open "$screenshot_path" >/dev/null 2>&1 &
            else
                log "Warning: xdg-open not available"
            fi
            ;;
        "edit")
            edit_screenshot "$screenshot_path"
            ;;
        "copy")
            if command -v wl-copy >/dev/null 2>&1; then
                if echo "$screenshot_path" | wl-copy 2>/dev/null; then
                    notify "Path Copied" "Screenshot path copied to clipboard"
                else
                    log "Warning: Failed to copy path to clipboard"
                fi
            else
                log "Warning: wl-copy not available"
            fi
            ;;
    esac
}

# Edit screenshot with available editor
edit_screenshot() {
    local screenshot_path="$1"

    if [[ ! -f "$screenshot_path" ]]; then
        log "Error: Screenshot file does not exist: $screenshot_path"
        notify "Error" "Screenshot file not found"
        return 1
    fi

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
        if command -v "$editor_cmd" >/dev/null 2>&1; then
            log "Opening screenshot in $editor_cmd"
            notify "Edit Screenshot" "Opening in $editor_cmd"
            if $editor "$screenshot_path" >/dev/null 2>&1 & then
                return 0
            else
                log "Warning: Failed to start $editor_cmd"
            fi
        fi
    done

    # Fallback to any image viewer/editor
    log "No image editor found, opening with default application"
    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$screenshot_path" >/dev/null 2>&1 &
    else
        log "Error: xdg-open not available"
        notify "Error" "No image editor or xdg-open found"
        return 1
    fi
}

# Generate screenshot filename
generate_filename() {
    local prefix="${1:-screenshot}"
    local format="${2:-$DEFAULT_FORMAT}"
    local timestamp

    # Validate prefix (sanitize)
    prefix=$(echo "$prefix" | tr -cd '[:alnum:]-_' | head -c 50)
    [[ -z "$prefix" ]] && prefix="screenshot"

    # Create screenshots directory if it doesn't exist
    if ! mkdir -p "$SCREENSHOTS_DIR" 2>/dev/null; then
        log "Error: Failed to create screenshots directory: $SCREENSHOTS_DIR"
        return 1
    fi

    # Generate timestamp
    if ! timestamp=$(date '+%Y-%m-%d_%H-%M-%S' 2>/dev/null); then
        log "Error: Failed to generate timestamp"
        return 1
    fi

    # Add milliseconds for uniqueness if available
    if command -v date >/dev/null 2>&1 && date --help 2>&1 | grep -q '%3N' 2>/dev/null; then
        local milliseconds
        milliseconds=$(date '+%3N' 2>/dev/null || echo "")
        [[ -n "$milliseconds" ]] && timestamp="${timestamp}-${milliseconds}"
    fi

    local filename="$SCREENSHOTS_DIR/${prefix}_${timestamp}.${format}"
    echo "$filename"
}

# Freeze screen using hyprpicker (like grimblast) or wayfreeze as fallback.
# hyprpicker -r renders on inactive displays, -z disables the zoom lens.
freezescreen() {
    if command -v hyprpicker >/dev/null 2>&1; then
        hyprpicker -rz &
        sleep 0.2
    elif command -v wayfreeze >/dev/null 2>&1; then
        wayfreeze &
        sleep 0.1
    fi
}

killhyprpicker() {
    pkill hyprpicker 2>/dev/null || true
}

# Get rectangles for smart mode (windows and outputs on active workspace)
get_rectangles() {
    if ! command -v hyprctl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
        log "Warning: hyprctl or jq not available for smart mode"
        return 1
    fi

    local active_workspace monitors_json clients_json
    monitors_json=$(hyprctl monitors -j 2>/dev/null || echo "")
    clients_json=$(hyprctl clients -j 2>/dev/null || echo "")

    if [[ -z "$monitors_json" ]]; then
        log "Warning: Could not get monitor information"
        return 1
    fi

    active_workspace=$(echo "$monitors_json" | jq -r '.[] | select(.focused == true) | .activeWorkspace.id // empty' 2>/dev/null | head -n1)

    if [[ -z "$active_workspace" ]] || [[ "$active_workspace" == "null" ]]; then
        log "Warning: Could not determine active workspace"
        return 1
    fi

    # Output monitors on active workspace
    echo "$monitors_json" | jq -r --arg ws "$active_workspace" \
        '.[] | select(.activeWorkspace.id == ($ws | tonumber)) | "\(.x),\(.y) \((.width / .scale) | floor)x\((.height / .scale) | floor)"' 2>/dev/null || true

    # Output windows on active workspace
    if [[ -n "$clients_json" ]]; then
        echo "$clients_json" | jq -r --arg ws "$active_workspace" \
            '.[] | select(.workspace.id == ($ws | tonumber)) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' 2>/dev/null || true
    fi
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

    # Wait if specified, with countdown notification
    if [[ -n "$wait_time" ]] && [[ "$wait_time" =~ ^[0-9]+$ ]]; then
        local remaining=$wait_time
        while [[ $remaining -gt 0 ]]; do
            if command -v notify-send >/dev/null 2>&1; then
                notify-send -t 1000 "📷 Screenshot" "Screenshot in $remaining seconds..." 2>/dev/null || true
            fi
            sleep 1
            remaining=$((remaining - 1))
        done
    fi

    local geometry=""
    local selection_cancelled=false

    case "$mode" in
        "screen"|"fullscreen")
            # Full screen - get focused monitor
            if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
                local monitors_json
                monitors_json=$(hyprctl monitors -j 2>/dev/null || echo "")
                if [[ -n "$monitors_json" ]]; then
                    geometry=$(echo "$monitors_json" | jq -r '.[] | select(.focused == true) | "\(.x),\(.y) \((.width / .scale) | floor)x\((.height / .scale) | floor)"' 2>/dev/null | head -n1 || echo "")
                fi
            fi
            # Fallback to full screen if hyprctl not available
            [[ -z "$geometry" ]] && geometry=""
            ;;
        "area"|"region")
            # Interactive area selection with window rectangles (like grimblast)
            if [[ "$freeze_flag" == "true" ]]; then
                freezescreen
            fi

            # Disable animation for layer namespace "selection" (slurp)
            if command -v hyprctl >/dev/null 2>&1; then
                hyprctl keyword layerrule "match:selection, no_anim on" >/dev/null 2>&1 || true
            fi

            # Get window rectangles for area selection (like grimblast)
            local rects=""
            if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
                local fullscreen_workspaces workspaces windows
                fullscreen_workspaces="$(hyprctl workspaces -j | jq -r 'map(select(.hasfullscreen) | .id)' 2>/dev/null || echo "[]")"
                workspaces="$(hyprctl monitors -j | jq -r '[(foreach .[] as $monitor (0; if $monitor.specialWorkspace.name == "" then $monitor.activeWorkspace else $monitor.specialWorkspace end)).id]' 2>/dev/null || echo "[]")"
                windows="$(hyprctl clients -j | jq -r --argjson workspaces "$workspaces" --argjson fullscreenWorkspaces "$fullscreen_workspaces" 'map((select(([.workspace.id] | inside($workspaces)) and ([.workspace.id] | inside($fullscreenWorkspaces) | not) or .fullscreen > 0)))' 2>/dev/null || echo "[]")"
                rects=$(echo "$windows" | jq -r '.[] | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' 2>/dev/null || echo "")
            fi

            # Use window rectangles if available, otherwise plain slurp
            if [[ -n "$rects" ]]; then
                geometry=$(echo -n "$rects" | slurp) || true
            else
                geometry=$(slurp) || true
            fi

            killhyprpicker

            [[ -z "$geometry" ]] && selection_cancelled=true
            ;;
        "windows")
            # Select from windows on active workspace
            local rects
            rects=$(get_rectangles) || true
            if [[ -n "$rects" ]]; then
                if [[ "$freeze_flag" == "true" ]]; then
                    freezescreen
                fi
                geometry=$(echo "$rects" | slurp -r) || true
                killhyprpicker
            fi
            [[ -z "$geometry" ]] && selection_cancelled=true
            ;;
        "window")
            # Active window (requires compositor support)
            if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
                local window_json
                window_json=$(hyprctl activewindow -j 2>/dev/null || echo "")
                if [[ -n "$window_json" ]]; then
                    geometry=$(echo "$window_json" | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' 2>/dev/null || echo "")
                fi
            elif command -v swaymsg >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
                local tree_json
                tree_json=$(swaymsg -t get_tree 2>/dev/null || echo "")
                if [[ -n "$tree_json" ]]; then
                    geometry=$(echo "$tree_json" | jq -r '.. | select(.focused?) | "\(.rect.x),\(.rect.y) \(.rect.width)x\(.rect.height)"' 2>/dev/null | head -n1 || echo "")
                fi
            fi

            if [[ -z "$geometry" ]]; then
                log "Could not determine active window geometry, falling back to area selection"
                geometry=$(slurp) || true
                [[ -z "$geometry" ]] && selection_cancelled=true
            fi
            ;;
        "smart")
            # Smart mode: show windows and outputs, auto-select if tiny selection
            local rects
            rects=$(get_rectangles) || true
            if [[ -n "$rects" ]]; then
                if [[ "$freeze_flag" == "true" ]]; then
                    freezescreen
                fi
                geometry=$(echo "$rects" | slurp) || true
                killhyprpicker

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

    # Stop any existing instances to avoid conflicts
    pkill slurp 2>/dev/null || true
    killhyprpicker

    # Take screenshot using grim+slurp (no longer depends on grimblast)
    local result=0
    screenshot_with_grim "$mode" "$output_file" "$freeze" "$wait_time" "$copy_to_clipboard" "$use_satty" "$clipboard_only" || result=$?

    # Handle cancellation (exit code 130)
    if [[ $result -eq 130 ]]; then
        log "Screenshot cancelled by user"
        return 130
    fi

    # Check if screenshot was saved (either file exists or satty handled it)
    if [[ $result -eq 0 ]]; then
        if [[ -f "$output_file" ]]; then
            local file_size
            if file_size=$(du -h "$output_file" 2>/dev/null | cut -f1); then
                log "Screenshot saved: $output_file ($file_size)"
            else
                log "Screenshot saved: $output_file"
                file_size="unknown"
            fi

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
        elif [[ "$clipboard_only" == "true" ]]; then
            # Clipboard-only mode succeeded
            log "Screenshot copied to clipboard"
            return 0
        fi
    fi

    log "Screenshot failed (exit code: $result, mode: $mode)"

    # Provide more specific error message
    local error_msg="Failed to capture screenshot"
    if [[ $result -eq 1 ]]; then
        error_msg="grim/slurp failed. Ensure wayland compositor is running"
    fi

    notify "Screenshot Error" "$error_msg"
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
    --open-folder      Open screenshots directory in file manager
    -h, --help         Show this help

Examples:
    $0                          # Full screen screenshot
    $0 area                     # Interactive area selection
    $0 smart                    # Smart mode with window detection
    $0 window --freeze          # Active window with frozen screen
    $0 screen -w 3              # Full screen after 3 second delay (with countdown)
    $0 area -o ~/my-shot.png    # Area selection to specific file
    $0 smart --satty             # Smart mode with satty editor
    $0 --open-folder            # Open screenshots directory

Environment Variables:
    SCREENSHOTS_DIR    Screenshot directory (default: ~/Pictures/Screenshots)

Dependencies:
    - grim + slurp (required)
    - wl-copy (for clipboard)
    - notify-send (for notifications)
    - Optional: hyprpicker (for freeze mode in Hyprland), wayfreeze (fallback freeze), swappy, image editors
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
    local open_folder="false"

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
            --open-folder|--folder)
                open_folder="true"
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

    # Handle --open-folder flag (open screenshots directory)
    if [[ "$open_folder" == "true" ]]; then
        # Load XDG directories if available
        if [[ -f ~/.config/user-dirs.dirs ]]; then
            source ~/.config/user-dirs.dirs
        fi

        local screenshot_dir="${SCREENSHOTS_DIR:-${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots}"
        mkdir -p "$screenshot_dir"

        # Try to open with available file manager
        if command -v nautilus >/dev/null 2>&1; then
            nautilus "$screenshot_dir" &
        elif command -v thunar >/dev/null 2>&1; then
            thunar "$screenshot_dir" &
        elif command -v dolphin >/dev/null 2>&1; then
            dolphin "$screenshot_dir" &
        elif command -v xdg-open >/dev/null 2>&1; then
            xdg-open "$screenshot_dir" &
        else
            echo "Screenshot directory: $screenshot_dir"
            log "No file manager found. Screenshot directory: $screenshot_dir"
        fi
        exit 0
    fi

    # Check dependencies
    check_dependencies

    # Generate output filename if not specified
    if [[ -z "$output_file" ]]; then
        if [[ "$clipboard_only" == "true" ]]; then
            # Use a temporary file that will be cleaned up
            output_file="/tmp/screenshot-$$.${format}"
        else
            output_file=$(generate_filename "screenshot" "$format")
            if [[ -z "$output_file" ]]; then
                log "Error: Failed to generate output filename"
                notify "Error" "Failed to generate output filename"
                exit 1
            fi
        fi
    fi

    # Validate format
    case "$format" in
        png|jpg|jpeg|webp)
            # Valid format
            ;;
        *)
            log "Warning: Unknown format '$format', using PNG"
            format="png"
            output_file="${output_file%.*}.png"
            ;;
    esac

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

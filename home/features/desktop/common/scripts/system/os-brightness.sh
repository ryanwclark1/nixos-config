#!/usr/bin/env bash

# -----------------------------------------------------
# System Brightness Control Script
# Screen brightness management with rofi interface
# -----------------------------------------------------
#
# This script provides a rofi-based interface for brightness control
# Compatible with any window manager that supports rofi
# Uses 'light' for brightness control with fallbacks
# -----------------------------------------------------

set -euo pipefail

# Configuration
SCRIPT_NAME="$(basename "$0")"
DEFAULT_ROFI_THEME="${HOME}/.config/rofi/applets/type-3/style-3.rasi"

# Dependency check function
check_dependencies() {
    local missing_deps=()
    local brightness_tools=()
    
    # Core dependencies
    command -v rofi >/dev/null || missing_deps+=("rofi")
    command -v awk >/dev/null || missing_deps+=("awk")
    
    # Brightness control tools (at least one required)
    command -v light >/dev/null && brightness_tools+=("light")
    command -v brightnessctl >/dev/null && brightness_tools+=("brightnessctl") 
    command -v xbacklight >/dev/null && brightness_tools+=("xbacklight")
    
    if [[ ${#brightness_tools[@]} -eq 0 ]]; then
        missing_deps+=("brightness tool (light, brightnessctl, or xbacklight)")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo "Error: Missing required dependencies:" >&2
        printf "  - %s\n" "${missing_deps[@]}" >&2
        echo "Please install the missing packages and try again." >&2
        exit 1
    fi
    
    # Set preferred brightness tool
    if command -v light >/dev/null; then
        BRIGHTNESS_TOOL="light"
    elif command -v brightnessctl >/dev/null; then
        BRIGHTNESS_TOOL="brightnessctl"
    elif command -v xbacklight >/dev/null; then
        BRIGHTNESS_TOOL="xbacklight"
    fi
    
    export BRIGHTNESS_TOOL
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

# Get current brightness level
get_brightness() {
    local brightness=0
    
    case "$BRIGHTNESS_TOOL" in
        "light")
            brightness="$(light -G 2>/dev/null | awk '{print int($1)}')" || brightness=0
            ;;
        "brightnessctl")
            local current max
            current="$(brightnessctl get 2>/dev/null)" || current=0
            max="$(brightnessctl max 2>/dev/null)" || max=1
            brightness="$(awk -v c="$current" -v m="$max" 'BEGIN {print int((c/m)*100)}')" || brightness=0
            ;;
        "xbacklight")
            brightness="$(xbacklight -get 2>/dev/null | awk '{print int($1)}')" || brightness=0
            ;;
    esac
    
    export CURRENT_BRIGHTNESS="$brightness"
}

# Get brightness device info
get_device_info() {
    local device="unknown" level_desc="unknown"
    
    # Get device name
    case "$BRIGHTNESS_TOOL" in
        "light")
            device="$(light -L 2>/dev/null | grep 'backlight' | head -n1 | cut -d'/' -f3)" || device="backlight"
            ;;
        "brightnessctl")
            device="$(brightnessctl -l 2>/dev/null | head -n1 | cut -d"'" -f2)" || device="backlight"
            ;;
        "xbacklight")
            device="xbacklight"
            ;;
    esac
    
    # Categorize brightness level
    get_brightness
    local brightness="$CURRENT_BRIGHTNESS"
    
    if [[ $brightness -ge 0 && $brightness -le 29 ]]; then
        level_desc="Low"
    elif [[ $brightness -ge 30 && $brightness -le 49 ]]; then
        level_desc="Optimal"
    elif [[ $brightness -ge 50 && $brightness -le 69 ]]; then
        level_desc="High"
    elif [[ $brightness -ge 70 && $brightness -le 100 ]]; then
        level_desc="Peak"
    fi
    
    export BRIGHTNESS_DEVICE="$device"
    export BRIGHTNESS_LEVEL="$level_desc"
}

# Get rofi theme configuration
get_theme_config() {
    local theme="${1:-$DEFAULT_ROFI_THEME}"
    
    # Default theme configuration
    local list_col="1"
    local list_row="4"
    local win_width="400px"
    
    # Detect theme type and adjust layout
    if [[ "$theme" == *'type-1'* ]]; then
        list_col='1'; list_row='4'; win_width='400px'
    elif [[ "$theme" == *'type-3'* ]]; then
        list_col='1'; list_row='4'; win_width='120px'
    elif [[ "$theme" == *'type-5'* ]]; then
        list_col='1'; list_row='4'; win_width='425px'
    elif [[ "$theme" == *'type-2'* || "$theme" == *'type-4'* ]]; then
        list_col='4'; list_row='1'; win_width='550px'
    fi
    
    # Check if theme uses icons or text
    local use_icons="YES"
    if [[ -f "$theme" ]]; then
        local layout
        layout=$(grep 'USE_ICON' "$theme" 2>/dev/null | cut -d'=' -f2 || echo "YES")
        use_icons="$layout"
    fi
    
    # Export theme config
    export THEME_FILE="$theme"
    export LIST_COL="$list_col"
    export LIST_ROW="$list_row"
    export WIN_WIDTH="$win_width"
    export USE_ICONS="$use_icons"
}

# Build rofi options
build_rofi_options() {
    get_device_info
    
    # Build option strings based on icon preference
    if [[ "$USE_ICONS" == "NO" ]]; then
        OPTION_1="󰃞 Increase Brightness"
        OPTION_2="󰃝 Optimal (25%)"
        OPTION_3="󰃟 Decrease Brightness" 
        OPTION_4="󰒓 Display Settings"
    else
        OPTION_1="󰃞"  # Increase brightness icon
        OPTION_2="󰃝"  # Optimal brightness icon
        OPTION_3="󰃟"  # Decrease brightness icon
        OPTION_4="󰒓"  # Settings icon
    fi
    
    # Export for rofi command
    export ROFI_PROMPT="${CURRENT_BRIGHTNESS}%"
    export ROFI_MESSAGE="Device: $BRIGHTNESS_DEVICE, Level: $BRIGHTNESS_LEVEL"
}

# Execute rofi command
run_rofi() {
    build_rofi_options
    get_theme_config
    
    local rofi_cmd=(
        rofi
        -theme-str "window {width: $WIN_WIDTH;}"
        -theme-str "listview {columns: $LIST_COL; lines: $LIST_ROW;}"
        -theme-str 'textbox-prompt-colon {str: "";}'
        -dmenu
        -p "$ROFI_PROMPT"
        -mesg "$ROFI_MESSAGE"
        -markup-rows
    )
    
    # Add theme if it exists
    [[ -f "$THEME_FILE" ]] && rofi_cmd+=(-theme "$THEME_FILE")
    
    # Run rofi with options
    echo -e "$OPTION_1\n$OPTION_2\n$OPTION_3\n$OPTION_4" | "${rofi_cmd[@]}"
}

# Execute brightness commands
execute_action() {
    local action="$1"
    local result=0
    
    case "$action" in
        "increase")
            case "$BRIGHTNESS_TOOL" in
                "light")
                    if light -A 5 2>/dev/null; then
                        get_brightness
                        notify "Brightness" "Increased to ${CURRENT_BRIGHTNESS}%"
                        log "Brightness increased to ${CURRENT_BRIGHTNESS}%"
                    else
                        log "Failed to increase brightness"
                        result=1
                    fi
                    ;;
                "brightnessctl")
                    if brightnessctl set +5% 2>/dev/null >/dev/null; then
                        get_brightness
                        notify "Brightness" "Increased to ${CURRENT_BRIGHTNESS}%"
                        log "Brightness increased to ${CURRENT_BRIGHTNESS}%"
                    else
                        log "Failed to increase brightness"
                        result=1
                    fi
                    ;;
                "xbacklight")
                    if xbacklight -inc 5 2>/dev/null; then
                        get_brightness
                        notify "Brightness" "Increased to ${CURRENT_BRIGHTNESS}%"
                        log "Brightness increased to ${CURRENT_BRIGHTNESS}%"
                    else
                        log "Failed to increase brightness"
                        result=1
                    fi
                    ;;
            esac
            ;;
        "decrease")
            case "$BRIGHTNESS_TOOL" in
                "light")
                    if light -U 5 2>/dev/null; then
                        get_brightness
                        notify "Brightness" "Decreased to ${CURRENT_BRIGHTNESS}%"
                        log "Brightness decreased to ${CURRENT_BRIGHTNESS}%"
                    else
                        log "Failed to decrease brightness"
                        result=1
                    fi
                    ;;
                "brightnessctl")
                    if brightnessctl set 5%- 2>/dev/null >/dev/null; then
                        get_brightness
                        notify "Brightness" "Decreased to ${CURRENT_BRIGHTNESS}%"
                        log "Brightness decreased to ${CURRENT_BRIGHTNESS}%"
                    else
                        log "Failed to decrease brightness"
                        result=1
                    fi
                    ;;
                "xbacklight")
                    if xbacklight -dec 5 2>/dev/null; then
                        get_brightness
                        notify "Brightness" "Decreased to ${CURRENT_BRIGHTNESS}%"
                        log "Brightness decreased to ${CURRENT_BRIGHTNESS}%"
                    else
                        log "Failed to decrease brightness"
                        result=1
                    fi
                    ;;
            esac
            ;;
        "optimal")
            case "$BRIGHTNESS_TOOL" in
                "light")
                    if light -S 25 2>/dev/null; then
                        notify "Brightness" "Set to optimal (25%)"
                        log "Brightness set to optimal (25%)"
                    else
                        log "Failed to set optimal brightness"
                        result=1
                    fi
                    ;;
                "brightnessctl")
                    if brightnessctl set 25% 2>/dev/null >/dev/null; then
                        notify "Brightness" "Set to optimal (25%)"
                        log "Brightness set to optimal (25%)"
                    else
                        log "Failed to set optimal brightness"
                        result=1
                    fi
                    ;;
                "xbacklight")
                    if xbacklight -set 25 2>/dev/null; then
                        notify "Brightness" "Set to optimal (25%)"
                        log "Brightness set to optimal (25%)"
                    else
                        log "Failed to set optimal brightness"
                        result=1
                    fi
                    ;;
            esac
            ;;
        "settings")
            # Try different display settings applications
            local display_settings=()
            command -v xfce4-power-manager-settings >/dev/null && display_settings+=(xfce4-power-manager-settings)
            command -v gnome-control-center >/dev/null && display_settings+=("gnome-control-center display")
            command -v systemsettings5 >/dev/null && display_settings+=("systemsettings5 kcm_displayconfiguration")
            command -v arandr >/dev/null && display_settings+=(arandr)
            
            if [[ ${#display_settings[@]} -gt 0 ]]; then
                log "Opening display settings with ${display_settings[0]}"
                ${display_settings[0]} &
            else
                notify "Error" "No display settings application found"
                log "No display settings application found"
                result=1
            fi
            ;;
        *)
            log "Unknown action: $action"
            result=1
            ;;
    esac
    
    return $result
}

# Show usage information
usage() {
    cat << EOF
System Brightness Control Script

Usage: $0 [COMMAND] [VALUE]

Commands:
    gui           Show rofi brightness interface (default)
    increase      Increase brightness by 5%
    decrease      Decrease brightness by 5%
    optimal       Set brightness to 25% (optimal)
    set VALUE     Set brightness to specific percentage (0-100)
    status        Show current brightness status
    settings      Open display settings
    help          Show this help

Examples:
    $0              # Show rofi interface
    $0 increase     # Increase brightness
    $0 set 50       # Set to 50%
    $0 status       # Show brightness info

Dependencies:
    - rofi
    - awk
    - brightness tool (light, brightnessctl, or xbacklight)
EOF
}

# Show current brightness status
show_status() {
    get_device_info
    
    cat << EOF
Brightness Status:
  Current: ${CURRENT_BRIGHTNESS}%
  Level: $BRIGHTNESS_LEVEL
  Device: $BRIGHTNESS_DEVICE
  Tool: $BRIGHTNESS_TOOL
EOF
}

# Set specific brightness value
set_brightness() {
    local value="$1"
    
    # Validate input
    if ! [[ "$value" =~ ^[0-9]+$ ]] || [[ $value -lt 0 || $value -gt 100 ]]; then
        echo "Error: Brightness value must be between 0-100" >&2
        return 1
    fi
    
    case "$BRIGHTNESS_TOOL" in
        "light")
            if light -S "$value" 2>/dev/null; then
                notify "Brightness" "Set to ${value}%"
                log "Brightness set to ${value}%"
            else
                log "Failed to set brightness to ${value}%"
                return 1
            fi
            ;;
        "brightnessctl")
            if brightnessctl set "${value}%" 2>/dev/null >/dev/null; then
                notify "Brightness" "Set to ${value}%"
                log "Brightness set to ${value}%"
            else
                log "Failed to set brightness to ${value}%"
                return 1
            fi
            ;;
        "xbacklight")
            if xbacklight -set "$value" 2>/dev/null; then
                notify "Brightness" "Set to ${value}%"
                log "Brightness set to ${value}%"
            else
                log "Failed to set brightness to ${value}%"
                return 1
            fi
            ;;
    esac
}

# Main function
main() {
    local command="${1:-gui}"
    
    # Handle help first (no dependency check needed)
    if [[ "$command" == "help" || "$command" == "-h" || "$command" == "--help" ]]; then
        usage
        exit 0
    fi
    
    # Check dependencies for all other commands
    check_dependencies
    
    case "$command" in
        "gui"|"")
            local choice
            choice=$(run_rofi)
            
            case "$choice" in
                "$OPTION_1") execute_action "increase" ;;
                "$OPTION_2") execute_action "optimal" ;;
                "$OPTION_3") execute_action "decrease" ;;
                "$OPTION_4") execute_action "settings" ;;
                "") log "No option selected" ;;
                *) log "Unknown option: $choice" ;;
            esac
            ;;
        "increase"|"inc"|"+")
            execute_action "increase"
            ;;
        "decrease"|"dec"|"-")
            execute_action "decrease"
            ;;
        "optimal")
            execute_action "optimal"
            ;;
        "set")
            if [[ -z "${2:-}" ]]; then
                echo "Error: set command requires a value (0-100)" >&2
                exit 1
            fi
            set_brightness "$2"
            ;;
        "settings")
            execute_action "settings"
            ;;
        "status")
            show_status
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
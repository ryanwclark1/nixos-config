#!/usr/bin/env bash

## Battery status rofi applet - Enhanced and made more robust
## Original Author: Aditya Shakya (adi1090x)
## Enhanced with better error handling and icon support

# Set strict error handling
set -euo pipefail

# Find and source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROFI_HELPERS=""
BATTERY_ICONS=""
POWER_MANAGER=""
SYSTEM_TOOLS=""
DESKTOP_DETECTION=""

if [[ -f "$HOME/.local/bin/scripts/system/os-rofi-helpers.sh" ]]; then
    ROFI_HELPERS="$HOME/.local/bin/scripts/system/os-rofi-helpers.sh"
elif [[ -f "$SCRIPT_DIR/../../../../common/scripts/system/os-rofi-helpers.sh" ]]; then
    ROFI_HELPERS="$SCRIPT_DIR/../../../../common/scripts/system/os-rofi-helpers.sh"
fi

if [[ -f "$HOME/.local/bin/scripts/system/os-battery-icons.sh" ]]; then
    BATTERY_ICONS="$HOME/.local/bin/scripts/system/os-battery-icons.sh"
elif [[ -f "$SCRIPT_DIR/../../../../common/scripts/system/os-battery-icons.sh" ]]; then
    BATTERY_ICONS="$SCRIPT_DIR/../../../../common/scripts/system/os-battery-icons.sh"
fi

if [[ -f "$HOME/.local/bin/scripts/system/os-power-manager.sh" ]]; then
    POWER_MANAGER="$HOME/.local/bin/scripts/system/os-power-manager.sh"
elif [[ -f "$SCRIPT_DIR/../../../../common/scripts/system/os-power-manager.sh" ]]; then
    POWER_MANAGER="$SCRIPT_DIR/../../../../common/scripts/system/os-power-manager.sh"
fi

if [[ -f "$HOME/.local/bin/scripts/system/os-system-tools.sh" ]]; then
    SYSTEM_TOOLS="$HOME/.local/bin/scripts/system/os-system-tools.sh"
elif [[ -f "$SCRIPT_DIR/../../../../common/scripts/system/os-system-tools.sh" ]]; then
    SYSTEM_TOOLS="$SCRIPT_DIR/../../../../common/scripts/system/os-system-tools.sh"
fi

if [[ -f "$HOME/.local/bin/scripts/system/os-desktop-detection.sh" ]]; then
    DESKTOP_DETECTION="$HOME/.local/bin/scripts/system/os-desktop-detection.sh"
elif [[ -f "$SCRIPT_DIR/../../../../common/scripts/system/os-desktop-detection.sh" ]]; then
    DESKTOP_DETECTION="$SCRIPT_DIR/../../../../common/scripts/system/os-desktop-detection.sh"
fi

if [[ -n "$ROFI_HELPERS" ]]; then
    # shellcheck source=/dev/null
    source "$ROFI_HELPERS"
fi

if [[ -n "$BATTERY_ICONS" ]]; then
    # shellcheck source=/dev/null
    source "$BATTERY_ICONS"
fi

if [[ -n "$POWER_MANAGER" ]]; then
    # shellcheck source=/dev/null
    source "$POWER_MANAGER"
fi

if [[ -n "$SYSTEM_TOOLS" ]]; then
    # shellcheck source=/dev/null
    source "$SYSTEM_TOOLS"
fi

if [[ -n "$DESKTOP_DETECTION" ]]; then
    # shellcheck source=/dev/null
    source "$DESKTOP_DETECTION"
fi

# Configuration
ROFI_TYPE="${ROFI_TYPE:-$HOME/.config/rofi/applets/type-3}"
ROFI_STYLE="${ROFI_STYLE:-style-3.rasi}"
theme="$ROFI_TYPE/$ROFI_STYLE"

# Fallback theme if file doesn't exist
if [[ ! -f "$theme" ]]; then
    echo "Warning: Rofi theme not found at $theme, using default" >&2
    theme=""
fi

# Source the shared battery library
# Try multiple paths to find the library
BATTERY_LIB_PATHS=(
    "$HOME/.local/bin/scripts/system/os-battery-lib.sh"
    "$SCRIPT_DIR/../../../../common/scripts/system/os-battery-lib.sh"
    "$SCRIPT_DIR/../../../common/scripts/system/os-battery-lib.sh"
)

BATTERY_LIB=""
for lib_path in "${BATTERY_LIB_PATHS[@]}"; do
    if [[ -f "$lib_path" ]]; then
        BATTERY_LIB="$lib_path"
        break
    fi
done

if [[ -n "$BATTERY_LIB" ]]; then
    source "$BATTERY_LIB" 2>/dev/null || {
        echo "Warning: Could not load battery library, using fallback methods" >&2
    }
else
    echo "Warning: Battery library not found, using fallback methods" >&2
fi

# Function to get battery info using shared library with time extraction from acpi
get_battery_info() {
    local battery_info=()
    time=""

    # Try to get time estimate from acpi (most detailed source)
    if command -v acpi >/dev/null 2>&1; then
        local acpi_output
        if acpi_output=$(acpi -b 2>/dev/null) && [[ -n "$acpi_output" ]]; then
            # Extract time from acpi if available
            time=$(echo "$acpi_output" | head -n1 | cut -d',' -f3 | tr -d ' ' || echo "")
            # Extract battery name from acpi
            battery=$(echo "$acpi_output" | head -n1 | cut -d',' -f1 | cut -d':' -f1 | tr -d ' ' || echo "")
        fi
    fi

    # Use shared library for percentage and state (with fallback)
    if command -v get_battery_percentage >/dev/null 2>&1; then
        percentage=$(get_battery_percentage || echo "0")
        status=$(get_battery_state || echo "Unknown")

        # Get battery device name if not set from acpi
        if [[ -z "$battery" || "$battery" == "Battery" ]]; then
            local battery_device
            battery_device=$(get_battery_device || echo "")
            if [[ -n "$battery_device" ]]; then
                battery="$battery_device"
            else
                battery="Battery"
            fi
        fi
    else
        # Fallback to direct methods if library not available
        # Method 1: Try acpi first (most detailed)
        if command -v acpi >/dev/null 2>&1; then
            local acpi_output
            if acpi_output=$(acpi -b 2>/dev/null) && [[ -n "$acpi_output" ]]; then
                battery=$(echo "$acpi_output" | head -n1 | cut -d',' -f1 | cut -d':' -f1 | tr -d ' ')
                status=$(echo "$acpi_output" | head -n1 | cut -d',' -f1 | cut -d':' -f2 | tr -d ' ')
                percentage=$(echo "$acpi_output" | head -n1 | cut -d',' -f2 | tr -d ' %,')
                time=$(echo "$acpi_output" | head -n1 | cut -d',' -f3 | tr -d ' ')

                # Validate percentage is numeric
                if ! [[ "$percentage" =~ ^[0-9]+$ ]]; then
                    percentage="0"
                fi

                return 0
            fi
        fi

        # Method 2: Fallback to /sys/class/power_supply/
        local bat_path="/sys/class/power_supply"
        if [[ -d "$bat_path" ]]; then
            local bat_dir
            for bat_dir in "$bat_path"/BAT*; do
                if [[ -d "$bat_dir" && -f "$bat_dir/capacity" && -f "$bat_dir/status" ]]; then
                    battery="$(basename "$bat_dir")"
                    percentage=$(cat "$bat_dir/capacity" 2>/dev/null || echo "0")
                    status=$(cat "$bat_dir/status" 2>/dev/null || echo "Unknown")
                    time=""

                    # Validate percentage
                    if ! [[ "$percentage" =~ ^[0-9]+$ ]] || [[ "$percentage" -gt 100 ]]; then
                        percentage="0"
                    fi

                    return 0
                fi
            done
        fi

        # Method 3: Try upower as last resort
        if command -v upower >/dev/null 2>&1; then
            local upower_output
            if upower_output=$(upower -i $(upower -e | grep 'BAT') 2>/dev/null); then
                battery="Battery"
                percentage=$(echo "$upower_output" | grep -E "percentage" | awk '{print $2}' | sed 's/%//' || echo "0")
                status=$(echo "$upower_output" | grep -E "state" | awk '{print $2}' || echo "Unknown")
                time=""

                # Validate percentage
                if ! [[ "$percentage" =~ ^[0-9]+$ ]]; then
                    percentage="0"
                fi

                # Convert upower status to acpi-like format
                case "$status" in
                    "charging") status="Charging" ;;
                    "discharging") status="Discharging" ;;
                    "fully-charged"|"full") status="Full" ;;
                    *) status="Unknown" ;;
                esac

                return 0
            fi
        fi

        # No battery found or accessible
        battery="No Battery"
        status="Not Available"
        percentage="0"
        time=""
        return 1
    fi

    # Validate results
    if [[ -z "$percentage" || ! "$percentage" =~ ^[0-9]+$ ]] || [[ "$percentage" -gt 100 ]]; then
        percentage="0"
    fi

    if [[ -z "$status" ]]; then
        status="Unknown"
    fi

    if [[ -z "$battery" ]]; then
        battery="Battery"
    fi

    # Check if we actually have a battery
    if command -v has_battery >/dev/null 2>&1; then
        if ! has_battery; then
            battery="No Battery"
            status="Not Available"
            percentage="0"
            time=""
            return 1
        fi
    elif [[ "$percentage" == "0" && "$status" == "Unknown" ]]; then
        battery="No Battery"
        status="Not Available"
        return 1
    fi

    return 0
}

# Get battery information
if ! get_battery_info; then
    echo "Warning: Could not retrieve battery information" >&2
fi

# Handle desktop systems differently using shared detection
if command -v is_desktop_system >/dev/null 2>&1; then
    if is_desktop_system; then
        desktop_mode=true
        battery="Desktop System"
        status="AC Power"
        percentage="100"
        time="∞"
    else
        desktop_mode=false
    fi
else
    # Fallback detection
    if [[ "$battery" == "No Battery" ]]; then
        desktop_mode=true
        battery="Desktop System"
        status="AC Power"
        percentage="100"
        time="∞"
    else
        desktop_mode=false
    fi
fi

# Set default time message
if [[ -z "$time" ]]; then
    case "$status" in
        "Full"|"fully-charged") time="Fully Charged" ;;
        "Charging") time="Calculating..." ;;
        "Discharging") time="Calculating..." ;;
        *) time="Unknown" ;;
    esac
fi

# Battery Icons - Using shared utilities if available
ICON_POWER_MANAGER="${ICON_POWER_MANAGER:-󰒓}"
ICON_DIAGNOSTIC="${ICON_DIAGNOSTIC:-󱎘}"

# Get battery icons using shared function if available
if command -v get_battery_icon >/dev/null 2>&1; then
    ICON_DISCHRG=$(get_battery_icon "$percentage" "$status")
    ICON_CHRG=$(get_battery_charging_icon "$status")
else
    # Fallback icons
    ICON_BATTERY_FULL="${ICON_BATTERY_FULL:-󰁹}"
    ICON_BATTERY_HIGH="${ICON_BATTERY_HIGH:-󰂂}"
    ICON_BATTERY_MEDIUM="${ICON_BATTERY_MEDIUM:-󰂀}"
    ICON_BATTERY_LOW="${ICON_BATTERY_LOW:-󰁻}"
    ICON_BATTERY_CRITICAL="${ICON_BATTERY_CRITICAL:-󰁺}"
    ICON_BATTERY_CHARGING="${ICON_BATTERY_CHARGING:-󰂄}"
    ICON_BATTERY_AC="${ICON_BATTERY_AC:-󰚥}"
    ICON_CHRG="$ICON_BATTERY_MEDIUM"
fi

# Theme Elements with better defaults
prompt="$status"
mesg="${battery}: ${percentage}%,${time}"

# Theme configuration with error handling
list_col='1'
list_row='4'
win_width='400px'

if [[ -n "$theme" ]]; then
    if [[ "$theme" == *'type-1'* ]]; then
        list_col='1'
        list_row='4'
        win_width='400px'
    elif [[ "$theme" == *'type-3'* ]]; then
        list_col='1'
        list_row='4'
        win_width='120px'
    elif [[ "$theme" == *'type-5'* ]]; then
        list_col='1'
        list_row='4'
        win_width='500px'
    elif [[ ( "$theme" == *'type-2'* ) || ( "$theme" == *'type-4'* ) ]]; then
        list_col='4'
        list_row='1'
        win_width='550px'
    fi
fi

# Charging Status with robust detection using shared utilities
if command -v get_battery_rofi_flags >/dev/null 2>&1; then
    flags=$(get_battery_rofi_flags "$status" "$percentage")
    read -r active urgent <<< "$flags"
else
    # Fallback detection
    active=""
    urgent=""
    case "$status" in
        *"Charging"*)
            active="-a 1"
            ;;
        *"Full"*|*"fully-charged"*)
            urgent="-u 1"
            ;;
        *"Discharging"*|*"Unknown"*)
            if [[ "$percentage" -le 20 ]]; then
                urgent="-u 1"
            fi
            ;;
    esac
fi

# Get battery icons if not already set
if [[ -z "${ICON_DISCHRG:-}" ]]; then
    if command -v get_battery_icon >/dev/null 2>&1; then
        ICON_DISCHRG=$(get_battery_icon "$percentage" "$status")
    else
        # Fallback icon selection
        if [[ "$percentage" -ge 95 ]]; then
            ICON_DISCHRG="$ICON_BATTERY_FULL"
        elif [[ "$percentage" -ge 80 ]]; then
            ICON_DISCHRG="$ICON_BATTERY_HIGH"
        elif [[ "$percentage" -ge 60 ]]; then
            ICON_DISCHRG="$ICON_BATTERY_MEDIUM"
        elif [[ "$percentage" -ge 40 ]]; then
            ICON_DISCHRG="$ICON_BATTERY_MEDIUM"
        elif [[ "$percentage" -ge 20 ]]; then
            ICON_DISCHRG="$ICON_BATTERY_LOW"
        else
            ICON_DISCHRG="$ICON_BATTERY_CRITICAL"
        fi
    fi
fi

if [[ -z "${ICON_CHRG:-}" ]]; then
    if command -v get_battery_charging_icon >/dev/null 2>&1; then
        ICON_CHRG=$(get_battery_charging_icon "$status")
    else
        ICON_CHRG="$ICON_BATTERY_MEDIUM"
    fi
fi

# Options with improved icons and text
layout=""
if [[ -n "$theme" && -f "$theme" ]]; then
    layout=$(grep 'USE_ICON' "$theme" 2>/dev/null | cut -d'=' -f2 || echo "YES")
fi

# Set options based on desktop vs laptop mode
if [[ "$desktop_mode" == true ]]; then
    if [[ "$layout" == 'NO' ]]; then
        option_1="󰍹 System Monitor"
        option_2="󰒓 Power Settings"
        option_3="🔧 System Tools"
        option_4="󱎘 Diagnostics"
    else
        option_1="󰍹"  # System monitor icon
        option_2="󰒓"  # Power settings icon
        option_3="🔧"  # System tools icon
        option_4="󱎘"  # Diagnostics icon
    fi
else
    # Laptop mode - original battery options
    if [[ "$layout" == 'NO' ]]; then
        option_1="󰁹 Remaining ${percentage}%"
        option_2="󰚥 $status"
        option_3="󰒓 Power Manager"
        option_4="󱎘 Diagnose"
    else
        option_1="$ICON_DISCHRG"
        option_2="$ICON_CHRG"
        option_3="$ICON_POWER_MANAGER"
        option_4="$ICON_DIAGNOSTIC"
    fi
fi

# Rofi CMD with better error handling
rofi_cmd() {
    local rofi_args=()

    if [[ -n "$theme" && -f "$theme" ]]; then
        rofi_args+=(-theme "$theme")
    fi

    rofi_args+=(
        -theme-str "window {width: $win_width;}"
        -theme-str "listview {columns: $list_col; lines: $list_row;}"
        -theme-str "textbox-prompt-colon {str: \"$ICON_DISCHRG\";}"
        -dmenu
        -p "$prompt"
        -mesg "$mesg"
        -markup-rows
    )

    # Add active/urgent states if set
    [[ -n "$active" ]] && rofi_args+=($active)
    [[ -n "$urgent" ]] && rofi_args+=($urgent)

    rofi "${rofi_args[@]}"
}

# Pass variables to rofi dmenu
run_rofi() {
    echo -e "$option_1\n$option_2\n$option_3\n$option_4" | rofi_cmd
}

# Execute Command with better application detection
run_cmd() {
    local polkit_cmd="pkexec env PATH=$PATH DISPLAY=${DISPLAY:-} XAUTHORITY=${XAUTHORITY:-}"

    case "$1" in
        '--opt1')
            if [[ "$desktop_mode" == true ]]; then
                # Desktop mode - launch system monitor using shared utility
                if command -v launch_system_monitor >/dev/null 2>&1; then
                    launch_system_monitor "notify-send"
                else
                    # Fallback
                    notify-send -u normal "󰍹 System Monitor" "System monitor launcher not available" -t 5000
                fi
            else
                # Laptop mode - show battery remaining
                notify-send -u low "$ICON_DISCHRG Remaining: ${percentage}%" -t 3000
            fi
            ;;
        '--opt2')
            if [[ "$desktop_mode" == true ]]; then
                # Desktop mode - launch power settings (same as opt3 in laptop mode)
                run_cmd '--opt3'
            else
                # Laptop mode - show battery status
                notify-send -u low "$ICON_CHRG Status: $status" -t 3000
            fi
            ;;
        '--opt3')
            if [[ "$desktop_mode" == true ]]; then
                # Desktop mode - launch system tools using shared utility
                if command -v launch_system_tools >/dev/null 2>&1; then
                    launch_system_tools "notify-send"
                else
                    # Fallback
                    notify-send -u normal "🔧 System Tools" "System tools launcher not available" -t 5000
                fi
            else
                # Laptop mode - power manager functionality using shared utility
                local polkit_cmd="pkexec env PATH=$PATH DISPLAY=${DISPLAY:-} XAUTHORITY=${XAUTHORITY:-}"
                if command -v launch_power_manager >/dev/null 2>&1; then
                    launch_power_manager "notify-send" "$polkit_cmd"
                else
                    # Fallback
                    notify-send -u normal "$ICON_POWER_MANAGER Power Manager" "Power manager launcher not available" -t 5000
                fi
            fi
            ;;
        '--opt4')
            # Launch diagnostic tool using shared utility
            local polkit_cmd="pkexec env PATH=$PATH DISPLAY=${DISPLAY:-} XAUTHORITY=${XAUTHORITY:-}"
            if command -v launch_diagnostic_tool >/dev/null 2>&1; then
                launch_diagnostic_tool "notify-send" "$polkit_cmd"
            else
                # Fallback
                notify-send -u normal "$ICON_DIAGNOSTIC Diagnose" "Diagnostic tool launcher not available" -t 5000
            fi
            ;;
    esac
}

# Actions with better error handling
if chosen="$(run_rofi)"; then
    case ${chosen} in
        "$option_1")
            run_cmd --opt1
            ;;
        "$option_2")
            run_cmd --opt2
            ;;
        "$option_3")
            run_cmd --opt3
            ;;
        "$option_4")
            run_cmd --opt4
            ;;
    esac
else
    echo "Rofi selection cancelled or failed" >&2
    exit 1
fi

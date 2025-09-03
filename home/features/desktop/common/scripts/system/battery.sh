#!/usr/bin/env bash

## Battery status rofi applet - Enhanced and made more robust
## Original Author: Aditya Shakya (adi1090x)
## Enhanced with better error handling and icon support

# Set strict error handling
set -euo pipefail

# Configuration
ROFI_TYPE="${ROFI_TYPE:-$HOME/.config/rofi/applets/type-3}"
ROFI_STYLE="${ROFI_STYLE:-style-3.rasi}"
theme="$ROFI_TYPE/$ROFI_STYLE"

# Fallback theme if file doesn't exist
if [[ ! -f "$theme" ]]; then
    echo "Warning: Rofi theme not found at $theme, using default" >&2
    theme=""
fi

# Function to get battery info using multiple methods
get_battery_info() {
    local battery_info=()
    
    # Method 1: Try acpi first (most detailed)
    if command -v acpi >/dev/null 2>&1; then
        local acpi_output
        if acpi_output=$(acpi -b 2>/dev/null) && [[ -n "$acpi_output" ]]; then
            # Parse acpi output
            battery=$(echo "$acpi_output" | head -n1 | cut -d',' -f1 | cut -d':' -f1)
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
        # Find first battery
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
}

# Get battery information
if ! get_battery_info; then
    echo "Warning: Could not retrieve battery information" >&2
fi

# Handle desktop systems differently
if [[ "$battery" == "No Battery" ]]; then
    # Desktop system - show power management options instead
    battery="Desktop System"
    status="AC Power"
    percentage="100"
    time="∞"
    desktop_mode=true
else
    desktop_mode=false
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

# Battery Icons - Using Nerd Font and Unicode icons with fallbacks
ICON_BATTERY_FULL="${ICON_BATTERY_FULL:-󰁹}"
ICON_BATTERY_HIGH="${ICON_BATTERY_HIGH:-󰂂}" 
ICON_BATTERY_MEDIUM="${ICON_BATTERY_MEDIUM:-󰂀}"
ICON_BATTERY_LOW="${ICON_BATTERY_LOW:-󰁻}"
ICON_BATTERY_CRITICAL="${ICON_BATTERY_CRITICAL:-󰁺}"
ICON_BATTERY_CHARGING="${ICON_BATTERY_CHARGING:-󰂄}"
ICON_BATTERY_AC="${ICON_BATTERY_AC:-󰚥}"
ICON_POWER_MANAGER="${ICON_POWER_MANAGER:-󰒓}"
ICON_DIAGNOSTIC="${ICON_DIAGNOSTIC:-󱎘}"

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

# Charging Status with robust detection
active=""
urgent=""
ICON_CHRG=""

case "$status" in
    *"Charging"*)
        active="-a 1"
        ICON_CHRG="$ICON_BATTERY_CHARGING"
        ;;
    *"Full"*|*"fully-charged"*)
        active="-u 1" 
        ICON_CHRG="$ICON_BATTERY_AC"
        ;;
    *"Discharging"*|*"Unknown"*)
        if [[ "$percentage" -le 20 ]]; then
            urgent="-u 1"
        fi
        ICON_CHRG="$ICON_BATTERY_MEDIUM"
        ;;
    *)
        ICON_CHRG="$ICON_BATTERY_MEDIUM"
        ;;
esac

# Battery level icons with more granular levels
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
elif [[ "$percentage" -ge 5 ]]; then
    ICON_DISCHRG="$ICON_BATTERY_CRITICAL"
else
    ICON_DISCHRG="$ICON_BATTERY_CRITICAL"
    urgent="-u 1"  # Critical battery level
fi

# Use charging icon if currently charging
if [[ "$status" == *"Charging"* ]]; then
    ICON_DISCHRG="$ICON_BATTERY_CHARGING"
elif [[ "$status" == *"Full"* ]]; then
    ICON_DISCHRG="$ICON_BATTERY_FULL"
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
                # Desktop mode - launch system monitor
                local monitor_launched=false
                local monitor_apps=("btop" "htop" "gotop" "bashtop" "bpytop" "top")
                
                for monitor in "${monitor_apps[@]}"; do
                    if command -v "$monitor" >/dev/null 2>&1; then
                        local terminal_candidates=("ghostty" "kitty" "alacritty" "gnome-terminal" "konsole" "xfce4-terminal")
                        for terminal in "${terminal_candidates[@]}"; do
                            if command -v "$terminal" >/dev/null 2>&1; then
                                "$terminal" -e "$monitor" &
                                notify-send -u low "󰍹 System Monitor" "Launched $monitor in $terminal" -t 3000
                                monitor_launched=true
                                break 2
                            fi
                        done
                    fi
                done
                
                if [[ "$monitor_launched" == false ]]; then
                    notify-send -u normal "󰍹 System Monitor" "No suitable system monitor or terminal found. Install btop, htop, or similar." -t 5000
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
                # Desktop mode - launch system tools
                local tools_launched=false
                local system_tools=(
                    "gnome-system-monitor:GNOME System Monitor"
                    "ksysguard:KDE System Guard"  
                    "plasma-systemmonitor:KDE Plasma System Monitor"
                    "xfce4-taskmanager:XFCE Task Manager"
                    "mate-system-monitor:MATE System Monitor"
                    "lxtask:LXDE Task Manager"
                    "qps:Qt Process Manager"
                    "gnome-control-center:GNOME Settings"
                    "systemsettings6:KDE Settings 6"
                    "systemsettings5:KDE Settings 5"
                    "systemsettings:KDE Settings"
                )
                
                for tool_entry in "${system_tools[@]}"; do
                    local tool_cmd="${tool_entry%%:*}"
                    local tool_name="${tool_entry##*:}"
                    
                    if command -v "$tool_cmd" >/dev/null 2>&1; then
                        "$tool_cmd" >/dev/null 2>&1 &
                        if [[ $? -eq 0 ]]; then
                            notify-send -u low "🔧 System Tools" "Launched $tool_name" -t 3000
                            tools_launched=true
                            break
                        else
                            notify-send -u normal "⚠️ Error" "Failed to launch $tool_name" -t 4000
                        fi
                    fi
                done
                
                if [[ "$tools_launched" == false ]]; then
                    notify-send -u normal "🔧 System Tools" "No suitable system management tools found. Install gnome-system-monitor, ksysguard, or similar." -t 5000
                fi
            else
                # Laptop mode - power manager functionality
                # Try different power managers in order of preference
                # Detect desktop environment and session type for better integration
                local desktop_env="${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-unknown}}"
                local session_type="${XDG_SESSION_TYPE:-unknown}"
                local wayland_compositor="${WAYLAND_DISPLAY:+wayland}"
                local power_manager_launched=false
            
            # Detect if we're in a tiling window manager vs traditional DE
            local is_tiling_wm=false
            case "${desktop_env,,}" in
                *hyprland*|*sway*|*river*|*niri*|*qtile*|*i3*|*bspwm*|*awesome*|*xmonad*|*dwm*)
                    is_tiling_wm=true
                    ;;
            esac
            
            # KDE Plasma power management (detect Plasma version)
            if [[ "$desktop_env" == *"KDE"* ]] || [[ "$desktop_env" == *"plasma"* ]] || [[ "$desktop_env" == *"Plasma"* ]]; then
                # Try Plasma 6 first (systemsettings6 or newer systemsettings)
                if command -v systemsettings6 >/dev/null 2>&1; then
                    systemsettings6 kcm_powerdevilprofilesconfig >/dev/null 2>&1 &
                    if [[ $? -eq 0 ]]; then
                        notify-send -u low "󰒓 Power Settings" "Opened KDE Plasma 6 power settings" -t 3000
                        power_manager_launched=true
                    else
                        notify-send -u normal "⚠️ Error" "Failed to launch KDE Plasma 6 power settings" -t 4000
                    fi
                elif command -v systemsettings >/dev/null 2>&1; then
                    # Check if it's Plasma 6 by looking for newer KDE version
                    local kde_version=""
                    if command -v kf6-config >/dev/null 2>&1; then
                        kde_version="6"
                        systemsettings kcm_powerdevilprofilesconfig >/dev/null 2>&1 &
                        if [[ $? -eq 0 ]]; then
                            notify-send -u low "󰒓 Power Settings" "Opened KDE Plasma 6 power settings" -t 3000
                            power_manager_launched=true
                        else
                            notify-send -u normal "⚠️ Error" "Failed to launch KDE Plasma 6 power settings" -t 4000
                        fi
                    elif command -v kf5-config >/dev/null 2>&1; then
                        kde_version="5"
                        systemsettings kcm_powerdevilprofilesconfig >/dev/null 2>&1 &
                        if [[ $? -eq 0 ]]; then
                            notify-send -u low "󰒓 Power Settings" "Opened KDE Plasma 5 power settings" -t 3000
                            power_manager_launched=true
                        else
                            notify-send -u normal "⚠️ Error" "Failed to launch KDE Plasma 5 power settings" -t 4000
                        fi
                    else
                        # Fallback - try modern syntax first
                        systemsettings kcm_powerdevilprofilesconfig >/dev/null 2>&1 &
                        if [[ $? -eq 0 ]]; then
                            notify-send -u low "󰒓 Power Settings" "Opened KDE power settings" -t 3000
                            power_manager_launched=true
                        else
                            notify-send -u normal "⚠️ Error" "Failed to launch KDE power settings" -t 4000
                        fi
                    fi
                elif command -v systemsettings5 >/dev/null 2>&1; then
                    systemsettings5 kcm_powerdevilprofilesconfig >/dev/null 2>&1 &
                    if [[ $? -eq 0 ]]; then
                        notify-send -u low "󰒓 Power Settings" "Opened KDE Plasma 5 power settings" -t 3000
                        power_manager_launched=true
                    else
                        notify-send -u normal "⚠️ Error" "Failed to launch KDE Plasma 5 power settings" -t 4000
                    fi
                fi
            fi
            
            # GNOME power settings
            if [[ "$power_manager_launched" == false ]] && [[ "$desktop_env" == *"GNOME"* ]]; then
                if command -v gnome-control-center >/dev/null 2>&1; then
                    gnome-control-center power >/dev/null 2>&1 &
                    if [[ $? -eq 0 ]]; then
                        notify-send -u low "󰒓 Power Settings" "Opened GNOME power settings" -t 3000
                        power_manager_launched=true
                    else
                        notify-send -u normal "⚠️ Error" "Failed to launch GNOME power settings" -t 4000
                    fi
                fi
            fi
            
            # XFCE power manager
            if [[ "$power_manager_launched" == false ]] && [[ "$desktop_env" == *"XFCE"* ]]; then
                if command -v xfce4-power-manager-settings >/dev/null 2>&1; then
                    xfce4-power-manager-settings
                    power_manager_launched=true
                fi
            fi
            
            # Try universal and fallback power managers if DE-specific ones didn't work
            if [[ "$power_manager_launched" == false ]]; then
                # Handle different scenarios based on session type and window manager type
                if [[ "$session_type" == "wayland" || -n "$wayland_compositor" ]]; then
                    if [[ "$is_tiling_wm" == true ]]; then
                        # Tiling WM on Wayland - prefer universal/CLI tools
                        if command -v powerprofilesctl >/dev/null 2>&1 && systemctl is-active --quiet power-profiles-daemon; then
                            # Show current power profile and allow switching via notifications
                            local current_profile
                            current_profile=$(powerprofilesctl get 2>/dev/null || echo "unknown")
                            notify-send -u normal "$ICON_POWER_MANAGER Power Profile: $current_profile" "Use 'powerprofilesctl set <profile>' to change. Available profiles: balanced, power-saver, performance" -t 8000
                            power_manager_launched=true
                        elif command -v tlp >/dev/null 2>&1; then
                            if command -v tlpui >/dev/null 2>&1; then
                                tlpui
                                power_manager_launched=true
                            else
                                notify-send -u normal "$ICON_POWER_MANAGER TLP" "TLP is available. Use 'sudo tlp-stat' for status or install tlpui for GUI." -t 5000
                                power_manager_launched=true
                            fi
                        elif command -v powertop >/dev/null 2>&1; then
                            ${polkit_cmd} powertop
                            power_manager_launched=true
                        fi
                    else
                        # Traditional DE on Wayland - prefer DE tools first, then universal
                        # Try Plasma 6/5 tools
                        if command -v systemsettings6 >/dev/null 2>&1; then
                            systemsettings6 kcm_powerdevilprofilesconfig
                            power_manager_launched=true
                        elif command -v systemsettings >/dev/null 2>&1; then
                            systemsettings kcm_powerdevilprofilesconfig
                            power_manager_launched=true
                        # GNOME Control Center (excellent Wayland support)
                        elif command -v gnome-control-center >/dev/null 2>&1; then
                            gnome-control-center power
                            power_manager_launched=true
                        # Other DE tools that work on Wayland
                        elif command -v xfce4-power-manager-settings >/dev/null 2>&1; then
                            xfce4-power-manager-settings
                            power_manager_launched=true
                        fi
                    fi
                else
                    # X11 session - traditional approach
                    # KDE Plasma (works on any DE)
                    if command -v systemsettings6 >/dev/null 2>&1; then
                        systemsettings6 kcm_powerdevilprofilesconfig
                        power_manager_launched=true
                    elif command -v systemsettings5 >/dev/null 2>&1; then
                        systemsettings5 kcm_powerdevilprofilesconfig
                        power_manager_launched=true
                    elif command -v systemsettings >/dev/null 2>&1; then
                        systemsettings powerdevilprofilesconfig
                        power_manager_launched=true
                    # GNOME Control Center (works on any DE)
                    elif command -v gnome-control-center >/dev/null 2>&1; then
                        gnome-control-center power
                        power_manager_launched=true
                    # XFCE Power Manager (works on any DE)
                    elif command -v xfce4-power-manager-settings >/dev/null 2>&1; then
                        xfce4-power-manager-settings
                        power_manager_launched=true
                    fi
                fi
                
                # Final fallbacks if nothing worked
                if [[ "$power_manager_launched" == false ]]; then
                    # Universal power management tools (work anywhere)
                    if command -v tlp >/dev/null 2>&1; then
                        if command -v tlpui >/dev/null 2>&1; then
                            tlpui
                        else
                            notify-send -u normal "$ICON_POWER_MANAGER TLP" "TLP is available. Use 'sudo tlp-stat' for status or install tlpui for GUI." -t 5000
                        fi
                    elif command -v powerprofilesctl >/dev/null 2>&1 && systemctl is-active --quiet power-profiles-daemon; then
                        local current_profile
                        current_profile=$(powerprofilesctl get 2>/dev/null || echo "unknown")
                        notify-send -u normal "$ICON_POWER_MANAGER Power Profile: $current_profile" "Use 'powerprofilesctl set <profile>' to change. Available: balanced, power-saver, performance" -t 8000
                    elif command -v powertop >/dev/null 2>&1; then
                        ${polkit_cmd} powertop
                    # MATE and LXQt power managers (X11 focused)
                    elif command -v mate-power-manager >/dev/null 2>&1; then
                        mate-power-manager
                    elif command -v lxqt-powermanagement >/dev/null 2>&1; then
                        lxqt-powermanagement
                    else
                        # No power management found - provide helpful suggestions
                        local suggestions=""
                        if [[ "$is_tiling_wm" == true ]]; then
                            suggestions="For tiling WMs: tlp + tlpui, auto-cpufreq, power-profiles-daemon, powertop, or thermald"
                        elif [[ "$session_type" == "wayland" ]]; then
                            suggestions="For Wayland DEs: systemsettings6 (KDE), gnome-control-center power, pwvucontrol, tlp, auto-cpufreq, or power-profiles-daemon"
                        else
                            suggestions="systemsettings6 (KDE), gnome-control-center power, xfce4-power-manager, auto-cpufreq, tlp, or powertop"
                        fi
                        notify-send -u normal "$ICON_POWER_MANAGER Power Manager Not Found" "Consider installing: $suggestions" -t 8000
                    fi
                fi
            fi
            fi  # Close desktop_mode if statement
            ;;
        '--opt4')
            # Try different terminals and diagnostic tools
            local terminal=""
            local diagnostic_tool=""
            
            # Find available terminal with priority for modern/Wayland-compatible ones
            # Prioritize terminals that work well with Wayland/Hyprland
            local terminal_candidates=(
                "ghostty"           # Modern GPU-accelerated terminal
                "kitty"            # GPU-accelerated, works great with Wayland
                "alacritty"        # GPU-accelerated, cross-platform
                "foot"             # Lightweight Wayland-native terminal
                "wezterm"          # GPU-accelerated with great Wayland support
                "gnome-terminal"   # GNOME's terminal (good Wayland support)
                "konsole"          # KDE's terminal
                "xfce4-terminal"   # XFCE terminal
                "tilix"            # Tiling terminal emulator
                "termite"          # Wayland-compatible terminal
                "sakura"           # Lightweight terminal
                "st"               # Simple terminal from suckless
                "urxvt"            # rxvt-unicode
                "xterm"            # Fallback X11 terminal
            )
            
            # Find the first available terminal
            for term in "${terminal_candidates[@]}"; do
                if command -v "$term" >/dev/null 2>&1; then
                    terminal="$term"
                    break
                fi
            done
            
            # Find available diagnostic tool with priority for power-specific tools
            local diagnostic_candidates=(
                "powertop"         # Intel PowerTOP - best for power analysis
                "auto-cpufreq --stats" # CPU frequency management stats
                "btop"            # Modern system monitor with better UI
                "htop"            # Enhanced top with better interface  
                "gotop"           # Terminal based graphical activity monitor
                "ytop"            # System monitor written in Rust
                "bashtop"         # Resource monitor in bash
                "bpytop"          # Python version of bashtop
                "tlp-stat"        # TLP power management statistics
                "upower --dump"   # UPower detailed battery information
                "top"             # Traditional system monitor (fallback)
            )
            
            # Find the first available diagnostic tool
            for tool in "${diagnostic_candidates[@]}"; do
                if command -v "$tool" >/dev/null 2>&1; then
                    diagnostic_tool="$tool"
                    break
                fi
            done
            
            if [[ -n "$terminal" && -n "$diagnostic_tool" ]]; then
                # Handle different terminal syntaxes for executing commands
                local term_args=()
                case "$terminal" in
                    "ghostty"|"kitty"|"alacritty"|"foot")
                        term_args=("-e" "$diagnostic_tool")
                        ;;
                    "wezterm")
                        term_args=("start" "--" "$diagnostic_tool")
                        ;;
                    "gnome-terminal"|"tilix")
                        term_args=("--" "$diagnostic_tool")
                        ;;
                    "konsole")
                        term_args=("-e" "$diagnostic_tool")
                        ;;
                    "xfce4-terminal")
                        term_args=("-e" "$diagnostic_tool")
                        ;;
                    "termite")
                        term_args=("-e" "$diagnostic_tool")
                        ;;
                    "sakura")
                        term_args=("-e" "$diagnostic_tool")
                        ;;
                    "st"|"urxvt"|"xterm")
                        term_args=("-e" "$diagnostic_tool")
                        ;;
                    *)
                        # Default fallback
                        term_args=("-e" "$diagnostic_tool")
                        ;;
                esac
                
                if [[ "$diagnostic_tool" == "powertop" ]]; then
                    # PowerTOP needs root privileges
                    ${polkit_cmd} "$terminal" "${term_args[@]}"
                else
                    "$terminal" "${term_args[@]}" &
                fi
            else
                local missing=""
                [[ -z "$terminal" ]] && missing="terminal"
                [[ -z "$diagnostic_tool" ]] && missing="${missing:+$missing and }diagnostic tool"
                notify-send -u normal "$ICON_DIAGNOSTIC Diagnose" "No suitable $missing found. Consider installing: ghostty, kitty, alacritty (terminals) or powertop, auto-cpufreq, btop, htop, tlp-stat (power/system monitors)" -t 5000
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
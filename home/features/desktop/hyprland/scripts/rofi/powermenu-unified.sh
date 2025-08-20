#!/usr/bin/env bash

# Unified Power Menu Script
# Consolidates functionality from powermenu.sh, powermenu2.sh, and power-big.sh

# Configuration
CONFIG_DIR="$HOME/.config/rofi"
STYLE_TYPE="${ROFI_POWERMENU_STYLE:-type-3}"  # Allow override via env var
STYLE_NAME="${ROFI_POWERMENU_STYLE_NAME:-style-3}"
THEME_DIR="$CONFIG_DIR/powermenu/$STYLE_TYPE"
THEME="$THEME_DIR/$STYLE_NAME.rasi"

# Fallback themes if primary not found
if [[ ! -f "$THEME" ]]; then
    THEME_DIR="$CONFIG_DIR/applets/$STYLE_TYPE"
    THEME="$THEME_DIR/$STYLE_NAME.rasi"
    if [[ ! -f "$THEME" ]]; then
        THEME_DIR="$CONFIG_DIR/style"
        THEME="$THEME_DIR/power-big.rasi"
    fi
fi

# System Info
HOST=$(hostname)
UPTIME=$(uptime -p | sed -e 's/up //g')
LASTLOGIN=$(last -n 1 "$USER" 2>/dev/null | tr -s ' ' | cut -d' ' -f5-7 || echo "Unknown")

# Messages
PROMPT="$HOST"
MESG="Uptime: $UPTIME"

# Icons (with fallbacks) - Using Nerd Font icons
SHUTDOWN_ICON="${POWERMENU_SHUTDOWN_ICON:-󰐥}"
REBOOT_ICON="${POWERMENU_REBOOT_ICON:-󰜉}"
LOCK_ICON="${POWERMENU_LOCK_ICON:-󰌾}"
SUSPEND_ICON="${POWERMENU_SUSPEND_ICON:-󰏦}"
LOGOUT_ICON="${POWERMENU_LOGOUT_ICON:-󰍃}"
HIBERNATE_ICON="${POWERMENU_HIBERNATE_ICON:-󰤄}"

# Layout detection
layout=$(grep -E '^[[:space:]]*USE_ICON' "$THEME" 2>/dev/null | cut -d'=' -f2 | tr -d ' "'"'" || echo "YES")

if [[ "$layout" == "NO" ]]; then
    # Text layout
    option_shutdown="$SHUTDOWN_ICON Shutdown"
    option_reboot="$REBOOT_ICON Reboot"
    option_lock="$LOCK_ICON Lock"
    option_suspend="$SUSPEND_ICON Suspend"
    option_logout="$LOGOUT_ICON Logout"
    option_hibernate="$HIBERNATE_ICON Hibernate"
else
    # Icon-only layout
    option_shutdown="$SHUTDOWN_ICON"
    option_reboot="$REBOOT_ICON"
    option_lock="$LOCK_ICON"
    option_suspend="$SUSPEND_ICON"
    option_logout="$LOGOUT_ICON"
    option_hibernate="$HIBERNATE_ICON"
fi

# Rofi command with error handling
rofi_cmd() {
    if [[ ! -f "$THEME" ]]; then
        echo "Error: Theme file not found: $THEME" >&2
        # Fallback to basic rofi
        rofi -dmenu -p "$PROMPT" -mesg "$MESG"
    else
        rofi -dmenu -p "$PROMPT" -mesg "$MESG" -theme "$THEME"
    fi
}

# Show menu and get choice
run_rofi() {
    echo -e "$option_lock\n$option_logout\n$option_suspend\n$option_hibernate\n$option_reboot\n$option_shutdown" | rofi_cmd
}

# Confirmation dialog
confirm_action() {
    local action="$1"
    local message="Are you sure you want to $action?"
    
    echo -e "Yes\nNo" | rofi -dmenu -p "Confirm" -mesg "$message" \
        -theme-str 'window {width: 300px;} listview {lines: 2;}'
}

# Execute power actions with error handling
execute_action() {
    local action="$1"
    
    case "$action" in
        "lock")
            if command -v hyprlock >/dev/null; then
                hyprlock
            elif command -v swaylock >/dev/null; then
                swaylock
            else
                notify-send "Error" "No lock screen program found"
                exit 1
            fi
            ;;
        "logout")
            if command -v hyprctl >/dev/null; then
                hyprctl dispatch exit
            elif command -v loginctl >/dev/null; then
                loginctl terminate-user "$USER"
            else
                pkill -KILL -u "$USER"
            fi
            ;;
        "suspend")
            systemctl suspend
            ;;
        "hibernate")
            systemctl hibernate
            ;;
        "reboot")
            systemctl reboot
            ;;
        "shutdown")
            systemctl poweroff
            ;;
        *)
            echo "Unknown action: $action" >&2
            exit 1
            ;;
    esac
}

# Main logic
main() {
    chosen=$(run_rofi)
    
    if [[ -z "$chosen" ]]; then
        exit 0
    fi
    
    # Determine action from chosen option
    case "$chosen" in
        *"$SHUTDOWN_ICON"*|*"Shutdown"*)
            action="shutdown"
            ;;
        *"$REBOOT_ICON"*|*"Reboot"*)
            action="reboot"
            ;;
        *"$LOCK_ICON"*|*"Lock"*)
            action="lock"
            ;;
        *"$SUSPEND_ICON"*|*"Suspend"*)
            action="suspend"
            ;;
        *"$LOGOUT_ICON"*|*"Logout"*)
            action="logout"
            ;;
        *"$HIBERNATE_ICON"*|*"Hibernate"*)
            action="hibernate"
            ;;
        *)
            echo "Unknown option: $chosen" >&2
            exit 1
            ;;
    esac
    
    # Skip confirmation for lock action
    if [[ "$action" == "lock" ]]; then
        execute_action "$action"
    else
        # Show confirmation for destructive actions
        confirmation=$(confirm_action "$action")
        if [[ "$confirmation" == "Yes" ]]; then
            execute_action "$action"
        fi
    fi
}

# Run main function
main "$@"
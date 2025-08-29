#!/usr/bin/env bash

# -----------------------------------------------------
# System Power Management Script
# Unified power actions for any desktop environment
# -----------------------------------------------------
#
# This script provides power management actions that work across
# different window managers and desktop environments.
# Supports lock, logout, suspend, reboot, and shutdown operations.
# -----------------------------------------------------

set -euo pipefail

# Configuration
SCRIPT_NAME="$(basename "$0")"
LOCK_TIMEOUT=5  # Seconds to wait for lock screen

# Dependency check function
check_dependencies() {
    local missing_deps=()
    
    # Core system utilities (should always be available)
    command -v systemctl >/dev/null || missing_deps+=("systemd")
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo "Error: Missing required dependencies:" >&2
        printf "  - %s\n" "${missing_deps[@]}" >&2
        echo "Please install the missing packages and try again." >&2
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

# Detect and execute lock screen
lock_screen() {
    local lock_commands=(
        "hyprlock"           # Hyprland lock screen
        "swaylock"           # Sway/generic Wayland lock
        "gtklock"            # GTK-based lock screen
        "waylock"            # Minimal Wayland lock
        "i3lock"             # i3 lock screen (X11 fallback)
        "xscreensaver-command -lock"  # Xscreensaver (X11 fallback)
    )
    
    for lock_cmd in "${lock_commands[@]}"; do
        local cmd_name="${lock_cmd%% *}"  # Get first word (command name)
        if command -v "$cmd_name" >/dev/null; then
            log "Locking screen with: $lock_cmd"
            notify "System" "Screen locked"
            
            # Execute lock command
            if $lock_cmd; then
                log "Screen locked successfully"
                return 0
            else
                log "Warning: $lock_cmd failed, trying next option"
            fi
        fi
    done
    
    # If no lock screen found
    notify "Error" "No lock screen program found"
    log "Error: No lock screen program available"
    return 1
}

# Detect and execute logout
logout_session() {
    # Try window manager specific logout commands
    if command -v hyprctl >/dev/null; then
        log "Logging out from Hyprland"
        notify "System" "Logging out..."
        hyprctl dispatch exit
        return 0
    elif command -v swaymsg >/dev/null; then
        log "Logging out from Sway"
        notify "System" "Logging out..."
        swaymsg exit
        return 0
    elif command -v i3-msg >/dev/null; then
        log "Logging out from i3"
        notify "System" "Logging out..."
        i3-msg exit
        return 0
    elif command -v bspc >/dev/null; then
        log "Logging out from bspwm"
        notify "System" "Logging out..."
        bspc quit
        return 0
    elif [[ -n "${XDG_CURRENT_DESKTOP:-}" ]]; then
        # Try desktop environment specific commands
        case "${XDG_CURRENT_DESKTOP,,}" in
            "gnome")
                if command -v gnome-session-quit >/dev/null; then
                    log "Logging out from GNOME"
                    notify "System" "Logging out..."
                    gnome-session-quit --logout --no-prompt
                    return 0
                fi
                ;;
            "kde"*)
                if command -v qdbus >/dev/null; then
                    log "Logging out from KDE"
                    notify "System" "Logging out..."
                    qdbus org.kde.ksmserver /KSMServer logout 0 0 0
                    return 0
                fi
                ;;
            "xfce")
                if command -v xfce4-session-logout >/dev/null; then
                    log "Logging out from XFCE"
                    notify "System" "Logging out..."
                    xfce4-session-logout --logout
                    return 0
                fi
                ;;
        esac
    fi
    
    # Fallback: kill user session
    log "Using fallback logout method"
    notify "System" "Terminating session..."
    
    if command -v loginctl >/dev/null; then
        local session_id
        session_id=$(loginctl show-user "$USER" -p Display --value 2>/dev/null || echo "")
        if [[ -n "$session_id" ]]; then
            loginctl terminate-session "$session_id"
            return 0
        fi
    fi
    
    # Last resort: SIGTERM to session
    pkill -TERM -u "$USER" || true
    return 0
}

# System suspend
suspend_system() {
    log "Suspending system"
    notify "System" "Suspending..."
    
    # Optional: Lock screen before suspend
    if [[ "${LOCK_BEFORE_SUSPEND:-true}" == "true" ]]; then
        lock_screen &
        sleep 1  # Give lock screen time to start
    fi
    
    if systemctl suspend; then
        log "System suspended successfully"
    else
        log "Failed to suspend system"
        notify "Error" "Failed to suspend system"
        return 1
    fi
}

# System reboot
reboot_system() {
    log "Rebooting system"
    notify "System" "Rebooting..."
    
    if systemctl reboot; then
        log "System reboot initiated"
    else
        log "Failed to reboot system"
        notify "Error" "Failed to reboot system"
        return 1
    fi
}

# System shutdown
shutdown_system() {
    log "Shutting down system"
    notify "System" "Shutting down..."
    
    if systemctl poweroff; then
        log "System shutdown initiated"
    else
        log "Failed to shutdown system"  
        notify "Error" "Failed to shutdown system"
        return 1
    fi
}

# Hibernate system (if supported)
hibernate_system() {
    # Check if hibernation is supported
    if ! systemctl hibernate --dry-run &>/dev/null; then
        log "Hibernation not supported or not configured"
        notify "Error" "Hibernation not available"
        return 1
    fi
    
    log "Hibernating system"
    notify "System" "Hibernating..."
    
    # Optional: Lock screen before hibernate
    if [[ "${LOCK_BEFORE_HIBERNATE:-true}" == "true" ]]; then
        lock_screen &
        sleep 1  # Give lock screen time to start
    fi
    
    if systemctl hibernate; then
        log "System hibernated successfully"
    else
        log "Failed to hibernate system"
        notify "Error" "Failed to hibernate system"
        return 1
    fi
}

# Show system status
show_status() {
    cat << EOF
System Power Status:
  Uptime: $(uptime -p 2>/dev/null || echo "unknown")
  Load: $(cat /proc/loadavg | cut -d' ' -f1-3)
  
Session Information:
  User: $USER
  Desktop: ${XDG_CURRENT_DESKTOP:-unknown}
  Session Type: ${XDG_SESSION_TYPE:-unknown}
  
Power Management:
  Hibernation: $(systemctl hibernate --dry-run &>/dev/null && echo "supported" || echo "not available")
  Suspend: $(systemctl suspend --dry-run &>/dev/null && echo "supported" || echo "not available")
EOF
}

# Show usage information
usage() {
    cat << EOF
System Power Management Script

Usage: $0 <action>

Actions:
    lock        Lock the screen
    logout      Log out of current session
    suspend     Suspend the system
    hibernate   Hibernate the system (if supported)
    reboot      Restart the system
    shutdown    Power off the system
    status      Show system power status
    help        Show this help

Examples:
    $0 lock       # Lock screen
    $0 suspend    # Suspend system
    $0 reboot     # Restart system

Environment Variables:
    LOCK_BEFORE_SUSPEND    Lock screen before suspend (default: true)
    LOCK_BEFORE_HIBERNATE  Lock screen before hibernate (default: true)

Dependencies:
    - systemd (systemctl)
    - Lock screen program (hyprlock, swaylock, etc.) for lock action
EOF
}

# Confirmation prompt for destructive actions
confirm_action() {
    local action="$1"
    local prompt="Are you sure you want to $action? [y/N]: "
    
    # Skip confirmation if running non-interactively or if SKIP_CONFIRMATION is set
    if [[ ! -t 0 ]] || [[ "${SKIP_CONFIRMATION:-false}" == "true" ]]; then
        return 0
    fi
    
    read -p "$prompt" -n 1 -r
    echo  # Move to next line
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        return 0
    else
        log "Action cancelled by user"
        return 1
    fi
}

# Main function
main() {
    local action="${1:-help}"
    
    # Handle help first (no dependency check needed)
    if [[ "$action" == "help" || "$action" == "-h" || "$action" == "--help" ]]; then
        usage
        exit 0
    fi
    
    # Check dependencies for other commands
    check_dependencies
    
    case "$action" in
        "lock")
            lock_screen
            ;;
        "logout")
            if confirm_action "log out"; then
                logout_session
            fi
            ;;
        "suspend")
            suspend_system
            ;;
        "hibernate")
            hibernate_system
            ;;
        "reboot")
            if confirm_action "reboot"; then
                reboot_system
            fi
            ;;
        "shutdown"|"poweroff")
            if confirm_action "shutdown"; then
                shutdown_system
            fi
            ;;
        "status")
            show_status
            ;;
        *)
            echo "Error: Unknown action '$action'" >&2
            echo "Use '$0 help' for usage information" >&2
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
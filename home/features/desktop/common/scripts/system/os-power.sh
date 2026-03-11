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
    local lock_method=""
    local lock_success=false
    
    # Method 1: Hypridle integration (preferred for Hyprland)
    if command -v hyprctl >/dev/null && pgrep -x hypridle >/dev/null; then
        lock_method="hypridle integration"
        log "Attempting lock via loginctl (hypridle integration)"
        
        # Use loginctl to trigger D-Bus lock event, hypridle will handle hyprlock
        if loginctl lock-session 2>/dev/null; then
            log "Lock command sent via loginctl"
            # Give hypridle/hyprlock time to respond to the D-Bus event
            sleep 0.5
            
            # Verify lock screen actually started (check for hyprlock process)
            if pgrep -x hyprlock >/dev/null; then
                log "Screen locked successfully via hypridle integration"
                notify "System" "Screen locked"
                return 0
            else
                log "Warning: loginctl succeeded but hyprlock not detected, trying fallback"
                # Don't return here - fall through to direct methods
            fi
        else
            log "Warning: loginctl lock-session failed (exit code: $?)"
        fi
    fi
    
    # Method 2: Direct lock screen programs (fallback)
    local lock_commands=(
        "hyprlock"           # Direct hyprlock (if hypridle not running or failed)
        "waylock"            # Minimal Wayland lock with good security
        "swaylock -f"        # Sway/generic Wayland lock (fork to background)
        "gtklock"            # GTK-based lock screen
        "i3lock -n"          # i3 lock screen (X11 fallback, no fork)
        "xscreensaver-command -lock"  # Xscreensaver (X11 fallback)
    )
    
    log "Trying direct lock screen programs as fallback"
    for lock_cmd in "${lock_commands[@]}"; do
        local cmd_name="${lock_cmd%% *}"  # Get first word (command name)
        if command -v "$cmd_name" >/dev/null; then
            log "Attempting lock with: $lock_cmd"
            
            # Execute lock command with timeout and error handling
            if timeout 10 bash -c "eval '$lock_cmd'" 2>/dev/null; then
                log "Screen locked successfully with $cmd_name"
                notify "System" "Screen locked"
                return 0
            else
                log "Warning: $lock_cmd failed or timed out"
            fi
        fi
    done
    
    # Method 3: Emergency fallback - try to at least blank the screen
    log "All lock methods failed, attempting screen blanking as emergency fallback"
    if command -v hyprctl >/dev/null; then
        hyprctl dispatch dpms off 2>/dev/null && log "Screen blanked via hyprctl dpms off"
    elif command -v wlr-randr >/dev/null; then
        wlr-randr --output '*' --off 2>/dev/null && log "Displays turned off via wlr-randr"
    elif command -v xset >/dev/null; then
        xset dpms force off 2>/dev/null && log "Display blanked via xset (X11)"
    fi
    
    # Final failure
    notify "Error" "Screen lock failed - all methods exhausted"
    log "Error: No functional lock screen program found"
    return 1
}

# Detect and execute logout
logout_session() {
    # Check for UWSM (Universal Wayland Session Manager) first
    if command -v uwsm >/dev/null && [[ -n "${UWSM_ID:-}" ]]; then
        log "Logging out via UWSM"
        notify "System" "Logging out..."
        uwsm stop
        return 0
    fi
    
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
        log "Locking screen before suspend"
        # Try to lock synchronously first, but don't block suspend if it fails
        if ! lock_screen; then
            log "Warning: Screen lock failed, proceeding with suspend anyway"
            # Emergency: at least try to blank the screen
            if command -v hyprctl >/dev/null; then
                hyprctl dispatch dpms off 2>/dev/null
            fi
        fi
        
        # Brief pause to ensure lock screen is established
        sleep 0.5
    fi
    
    # Use UWSM if available for better session management
    if command -v uwsm >/dev/null && [[ -n "${UWSM_ID:-}" ]]; then
        log "Suspending via UWSM"
        if uwsm app -- systemctl suspend; then
            log "System suspended successfully"
        else
            log "Failed to suspend system via UWSM"
            notify "Error" "Failed to suspend system"
            return 1
        fi
    elif systemctl suspend; then
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
        log "Locking screen before hibernate"
        # Try to lock synchronously first, but don't block hibernate if it fails
        if ! lock_screen; then
            log "Warning: Screen lock failed, proceeding with hibernate anyway"
            # Emergency: at least try to blank the screen
            if command -v hyprctl >/dev/null; then
                hyprctl dispatch dpms off 2>/dev/null
            fi
        fi
        
        # Brief pause to ensure lock screen is established
        sleep 0.5
    fi
    
    # Use UWSM if available for better session management
    if command -v uwsm >/dev/null && [[ -n "${UWSM_ID:-}" ]]; then
        log "Hibernating via UWSM"
        if uwsm app -- systemctl hibernate; then
            log "System hibernated successfully"
        else
            log "Failed to hibernate system via UWSM"
            notify "Error" "Failed to hibernate system"
            return 1
        fi
    elif systemctl hibernate; then
        log "System hibernated successfully"
    else
        log "Failed to hibernate system"
        notify "Error" "Failed to hibernate system"
        return 1
    fi
}

# Show system status
show_status() {
    local uwsm_status="not detected"
    local lock_screen_available="none"
    local hypridle_status="not running"
    
    # Check UWSM status
    if command -v uwsm >/dev/null; then
        if [[ -n "${UWSM_ID:-}" ]]; then
            uwsm_status="active (ID: ${UWSM_ID})"
        else
            uwsm_status="installed but not active"
        fi
    fi
    
    # Check hypridle status
    if command -v hyprctl >/dev/null && pgrep -x hypridle >/dev/null; then
        hypridle_status="running (integrated)"
    elif command -v hypridle >/dev/null; then
        hypridle_status="available but not running"
    fi
    
    # Check available lock screens (in preference order)
    local lock_screens=()
    for lock_cmd in "hyprlock" "waylock" "swaylock" "gtklock" "i3lock"; do
        if command -v "$lock_cmd" >/dev/null; then
            lock_screens+=("$lock_cmd")
        fi
    done
    
    # Show lock method based on hypridle integration
    if [[ "$hypridle_status" == "running (integrated)" ]]; then
        lock_screen_available="loginctl → hypridle → hyprlock (integrated)"
    elif [[ ${#lock_screens[@]} -gt 1 ]]; then
        lock_screen_available="${lock_screens[0]} (preferred), ${lock_screens[*]:1}"
    else
        lock_screen_available="${lock_screens[*]:-none}"
    fi
    
    cat << EOF
System Power Status:
  Uptime: $(uptime -p 2>/dev/null || echo "unknown")
  Load: $(cat /proc/loadavg | cut -d' ' -f1-3)
  
Session Information:
  User: $USER
  Desktop: ${XDG_CURRENT_DESKTOP:-unknown}
  Session Type: ${XDG_SESSION_TYPE:-unknown}
  UWSM Status: $uwsm_status
  
Screen Lock:
  Hypridle: $hypridle_status
  Method: $lock_screen_available
  
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
    - Lock screen program (hyprlock, waylock, swaylock, etc.) for lock action
    - uwsm (Universal Wayland Session Manager) - optional but recommended for Wayland sessions
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
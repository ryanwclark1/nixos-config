#!/usr/bin/env bash

# Hyprland Utility Functions Script
# Consolidates small utility scripts into one configurable tool

# Configuration
NOTIFICATION_TIMEOUT="${HYPR_NOTIFICATION_TIMEOUT:-3000}"
MPVFLAGS="${HYPR_MPV_FLAGS:---no-terminal --force-window}"

# Error handling
set -euo pipefail

# Logging function
log() {
    local level="$1"
    shift
    echo "[$level] $(date '+%Y-%m-%d %H:%M:%S') $*" >&2
}

# Notification wrapper with error handling
notify() {
    local title="$1"
    local message="$2"
    local urgency="${3:-normal}"
    
    if command -v notify-send >/dev/null; then
        notify-send -t "$NOTIFICATION_TIMEOUT" -u "$urgency" "$title" "$message"
    else
        log "WARNING" "notify-send not available: $title - $message"
    fi
}

# Play clipboard URL in media player
play_clipboard() {
    local url
    url=$(wl-paste 2>/dev/null || xclip -o 2>/dev/null || echo "")
    
    if [[ -z "$url" ]]; then
        notify "Error" "No URL found in clipboard" "critical"
        return 1
    fi
    
    if ! command -v mpv >/dev/null; then
        notify "Error" "mpv not installed" "critical"
        return 1
    fi
    
    notify "Opening Video" "$url"
    log "INFO" "Playing URL: $url"
    
    # Run mpv in background and handle errors
    if ! mpv $MPVFLAGS "$url" &>/dev/null &then
        notify "Error" "Failed to play: $url" "critical"
        return 1
    fi
}

# Restart hypridle daemon
restart_hypridle() {
    if ! command -v hypridle >/dev/null; then
        notify "Error" "hypridle not installed" "critical"
        return 1
    fi
    
    log "INFO" "Restarting hypridle"
    
    # Kill existing instances
    pkill hypridle 2>/dev/null || true
    sleep 1
    
    # Start new instance
    if hypridle &then
        notify "Hypridle" "Service restarted successfully"
        log "INFO" "hypridle restarted successfully"
    else
        notify "Error" "Failed to restart hypridle" "critical"
        log "ERROR" "Failed to restart hypridle"
        return 1
    fi
}

# Toggle rofi launcher
toggle_rofi() {
    if pgrep -x "rofi" >/dev/null; then
        log "INFO" "Closing rofi"
        pkill -x rofi
        return 0
    fi
    
    log "INFO" "Opening rofi launcher"
    rofi -show drun &
}

# Clear wallpaper cache
clear_wallpaper_cache() {
    local cache_dir="$HOME/.cache/hyprland-wallpapers"
    local old_cache_dir="$HOME/.config/hypr/scripts/cache/wallpaper-generated"
    
    local cleared=false
    
    # Clear new cache location
    if [[ -d "$cache_dir" ]]; then
        rm -rf "$cache_dir"/* 2>/dev/null || true
        cleared=true
        log "INFO" "Cleared wallpaper cache: $cache_dir"
    fi
    
    # Clear old cache location (backward compatibility)
    if [[ -d "$old_cache_dir" ]]; then
        rm -rf "$old_cache_dir"/* 2>/dev/null || true
        cleared=true
        log "INFO" "Cleared old wallpaper cache: $old_cache_dir"
    fi
    
    if [[ "$cleared" == "true" ]]; then
        notify "Wallpaper Cache" "Cache cleared successfully"
    else
        notify "Wallpaper Cache" "No cache found to clear"
    fi
}

# Enhanced wlogout with dynamic sizing
launch_wlogout() {
    if ! command -v wlogout >/dev/null; then
        notify "Error" "wlogout not installed" "critical"
        return 1
    fi
    
    if ! command -v hyprctl >/dev/null; then
        log "WARNING" "hyprctl not available, using default wlogout"
        wlogout &
        return 0
    fi
    
    # Get monitor dimensions dynamically
    local monitor_info
    monitor_info=$(hyprctl -j monitors 2>/dev/null || echo "[]")
    
    if [[ "$monitor_info" == "[]" ]]; then
        log "WARNING" "Could not get monitor info, using default wlogout"
        wlogout &
        return 0
    fi
    
    local res_w res_h h_scale w_margin
    res_w=$(echo "$monitor_info" | jq -r '.[] | select(.focused==true) | .width // 1920')
    res_h=$(echo "$monitor_info" | jq -r '.[] | select(.focused==true) | .height // 1080')
    h_scale=$(echo "$monitor_info" | jq -r '.[] | select(.focused==true) | .scale // 1' | sed 's/\.//')
    
    # Calculate margins (fallback to 100 if calculation fails)
    w_margin=$((res_h * 27 / h_scale)) 2>/dev/null || w_margin=100
    
    log "INFO" "Launching wlogout with margins: $w_margin"
    wlogout -b 5 -T "$w_margin" -B "$w_margin" &
}

# System information display
show_system_info() {
    local info
    info="$(uname -sr) | $(whoami) | $(date)"
    
    if command -v notify-send >/dev/null; then
        notify "System Info" "$info"
    else
        echo "$info"
    fi
    
    log "INFO" "System info displayed: $info"
}

# Usage information
usage() {
    cat << EOF
Hyprland Utility Functions

Usage: $0 <command> [options]

Commands:
    play-clipboard      Play URL from clipboard with mpv
    restart-hypridle    Restart the hypridle daemon
    toggle-rofi         Toggle rofi application launcher
    clear-cache         Clear wallpaper cache
    wlogout             Launch wlogout with dynamic sizing
    system-info         Show system information
    help                Show this help message

Environment Variables:
    HYPR_NOTIFICATION_TIMEOUT  Notification duration (default: 3000ms)
    HYPR_MPV_FLAGS             MPV flags (default: --no-terminal --force-window)

Examples:
    $0 play-clipboard
    $0 restart-hypridle
    $0 toggle-rofi
EOF
}

# Main function
main() {
    local command="${1:-help}"
    
    case "$command" in
        "play-clipboard"|"play"|"yt")
            play_clipboard
            ;;
        "restart-hypridle"|"restart-idle")
            restart_hypridle
            ;;
        "toggle-rofi"|"rofi"|"launcher")
            toggle_rofi
            ;;
        "clear-cache"|"clear-wallpaper-cache")
            clear_wallpaper_cache
            ;;
        "wlogout"|"logout-menu")
            launch_wlogout
            ;;
        "system-info"|"info")
            show_system_info
            ;;
        "help"|"-h"|"--help")
            usage
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
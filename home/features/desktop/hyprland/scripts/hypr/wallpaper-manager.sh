#!/usr/bin/env bash

# Enhanced Wallpaper Manager
# Consolidates wallpaper.sh, wallpaper-automation.sh, wallpaper-effects.sh, wallpaper-restore.sh

# Configuration
WALLPAPER_DIR="${HYPR_WALLPAPER_DIR:-$HOME/Pictures/wallpapers}"
CACHE_DIR="$HOME/.cache/hyprland-wallpapers"
CONFIG_DIR="$HOME/.config/hypr/wallpaper"
EFFECTS_DIR="$HOME/.config/hypr/effects/wallpaper"

# Cache files  
CURRENT_WALLPAPER="$CACHE_DIR/current_wallpaper"
BLURRED_WALLPAPER="$CACHE_DIR/blurred_wallpaper.png"
SQUARE_WALLPAPER="$CACHE_DIR/square_wallpaper.png"
RASI_FILE="$CACHE_DIR/current_wallpaper.rasi"
AUTOMATION_PID="$CACHE_DIR/automation.pid"

# Configuration files
CACHE_ENABLED="$CONFIG_DIR/cache_enabled"
AUTOMATION_INTERVAL="$CONFIG_DIR/automation_interval"
CURRENT_EFFECT="$CONFIG_DIR/current_effect"

# Defaults
DEFAULT_WALLPAPER="$HOME/Pictures/wallpaper/default.png"
DEFAULT_AUTOMATION_INTERVAL=60

# Create directories
mkdir -p "$CACHE_DIR" "$CONFIG_DIR" "$EFFECTS_DIR"

# Error handling
set -euo pipefail

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$1] $2" >&2
}

# Notification wrapper
notify() {
    if command -v notify-send >/dev/null; then
        notify-send -t 3000 "$@"
    fi
}

# Check if caching is enabled
is_cache_enabled() {
    [[ -f "$CACHE_ENABLED" ]]
}

# Ensure swww daemon is running
ensure_swww_daemon() {
    if command -v swww >/dev/null; then
        if ! pgrep -x "swww-daemon" > /dev/null; then
            log "INFO" "Starting swww daemon"
            swww-daemon &
            sleep 1
            # Wait for daemon to be ready
            local attempts=0
            while ! swww query >/dev/null 2>&1 && [ $attempts -lt 10 ]; do
                sleep 0.5
                attempts=$((attempts + 1))
            done
        fi
        return 0
    fi
    return 1
}

# Set current wallpaper
set_current_wallpaper() {
    local wallpaper="$1"
    
    if [[ ! -f "$wallpaper" ]]; then
        log "ERROR" "Wallpaper file does not exist: $wallpaper"
        return 1
    fi
    
    # Store current wallpaper
    echo "$wallpaper" > "$CURRENT_WALLPAPER"
    
    # Set wallpaper using available tools (prioritize swww)
    if ensure_swww_daemon; then
        # Add buffer management flags to reduce errors
        swww img "$wallpaper" --transition-fps 30 --transition-type fade --transition-duration 1 --no-resize 2>/dev/null || {
            log "WARNING" "swww failed, retrying with fallback settings"
            sleep 0.5
            swww img "$wallpaper" --no-resize 2>/dev/null || {
                log "ERROR" "swww completely failed, falling back to swaybg"
                pkill swaybg 2>/dev/null || true
                swaybg -i "$wallpaper" &
            }
        }
    elif command -v waypaper >/dev/null; then
        waypaper --wallpaper "$wallpaper"
    elif command -v swaybg >/dev/null; then
        pkill swaybg 2>/dev/null || true
        swaybg -i "$wallpaper" &
    else
        log "ERROR" "No wallpaper tool found (swww, waypaper, swaybg)"
        return 1
    fi
    
    log "INFO" "Wallpaper set: $wallpaper"
    notify "Wallpaper Changed" "$(basename "$wallpaper")"
    
    # Generate cache if enabled
    if is_cache_enabled; then
        generate_cache "$wallpaper" &
    fi
}

# Generate wallpaper cache (blurred, square versions, etc.)
generate_cache() {
    local wallpaper="$1"
    
    log "INFO" "Generating wallpaper cache for $(basename "$wallpaper")"
    
    # Generate blurred version
    if command -v convert >/dev/null; then
        convert "$wallpaper" -blur 0x20 "$BLURRED_WALLPAPER" 2>/dev/null &
    fi
    
    # Generate square version
    if command -v convert >/dev/null; then
        convert "$wallpaper" -resize 400x400^ -gravity center -extent 400x400 "$SQUARE_WALLPAPER" 2>/dev/null &
    fi
    
    # Generate RASI file for rofi themes
    cat > "$RASI_FILE" << EOF
* {
    current-image: url("$wallpaper", height);
}
EOF
}

# Set random wallpaper
set_random_wallpaper() {
    if [[ ! -d "$WALLPAPER_DIR" ]]; then
        log "ERROR" "Wallpaper directory does not exist: $WALLPAPER_DIR"
        return 1
    fi
    
    local wallpapers
    readarray -t wallpapers < <(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.bmp" -o -iname "*.webp" \) 2>/dev/null || true)
    
    if [[ ${#wallpapers[@]} -eq 0 ]]; then
        log "ERROR" "No wallpapers found in $WALLPAPER_DIR"
        return 1
    fi
    
    local random_wallpaper="${wallpapers[RANDOM % ${#wallpapers[@]}]}"
    set_current_wallpaper "$random_wallpaper"
}

# Restore last wallpaper
restore_wallpaper() {
    local wallpaper
    
    if [[ -f "$CURRENT_WALLPAPER" ]]; then
        wallpaper=$(cat "$CURRENT_WALLPAPER")
        # Expand ~ to home directory
        wallpaper="${wallpaper/#\~/$HOME}"
        
        if [[ -f "$wallpaper" ]]; then
            log "INFO" "Restoring wallpaper: $wallpaper"
            set_current_wallpaper "$wallpaper"
            return 0
        else
            log "WARNING" "Cached wallpaper does not exist: $wallpaper"
        fi
    fi
    
    # Fallback to default
    if [[ -f "$DEFAULT_WALLPAPER" ]]; then
        log "INFO" "Using default wallpaper: $DEFAULT_WALLPAPER"
        set_current_wallpaper "$DEFAULT_WALLPAPER"
    else
        log "ERROR" "No default wallpaper found"
        return 1
    fi
}

# Start wallpaper automation
start_automation() {
    local interval="${1:-$DEFAULT_AUTOMATION_INTERVAL}"
    
    if [[ -f "$AUTOMATION_PID" ]] && kill -0 "$(cat "$AUTOMATION_PID")" 2>/dev/null; then
        log "INFO" "Wallpaper automation already running"
        return 0
    fi
    
    echo "$interval" > "$AUTOMATION_INTERVAL"
    
    # Start automation in background
    (
        while true; do
            set_random_wallpaper
            sleep "$interval"
        done
    ) &
    
    local pid=$!
    echo "$pid" > "$AUTOMATION_PID"
    
    log "INFO" "Wallpaper automation started (PID: $pid, interval: ${interval}s)"
    notify "Wallpaper Automation" "Started (every ${interval}s)"
}

# Stop wallpaper automation
stop_automation() {
    if [[ -f "$AUTOMATION_PID" ]]; then
        local pid
        pid=$(cat "$AUTOMATION_PID")
        
        if kill "$pid" 2>/dev/null; then
            log "INFO" "Wallpaper automation stopped (PID: $pid)"
            notify "Wallpaper Automation" "Stopped"
        fi
        
        rm -f "$AUTOMATION_PID"
    else
        log "INFO" "Wallpaper automation not running"
    fi
}

# Toggle wallpaper automation
toggle_automation() {
    if [[ -f "$AUTOMATION_PID" ]] && kill -0 "$(cat "$AUTOMATION_PID")" 2>/dev/null; then
        stop_automation
    else
        local interval
        if [[ -f "$AUTOMATION_INTERVAL" ]]; then
            interval=$(cat "$AUTOMATION_INTERVAL")
        else
            interval="$DEFAULT_AUTOMATION_INTERVAL"
        fi
        start_automation "$interval"
    fi
}

# Set wallpaper effects using hyprshade
set_effect() {
    local effect="$1"
    
    if [[ ! -d "$EFFECTS_DIR" ]]; then
        log "ERROR" "Effects directory not found: $EFFECTS_DIR"
        return 1
    fi
    
    if [[ "$effect" == "off" || "$effect" == "none" ]]; then
        if command -v hyprshade >/dev/null; then
            hyprshade off
        fi
        rm -f "$CURRENT_EFFECT"
        log "INFO" "Wallpaper effects disabled"
        notify "Wallpaper Effects" "Disabled"
        return 0
    fi
    
    local effect_file="$EFFECTS_DIR/$effect"
    if [[ ! -f "$effect_file" ]]; then
        log "ERROR" "Effect file not found: $effect_file"
        return 1
    fi
    
    if command -v hyprshade >/dev/null; then
        hyprshade on "$effect_file"
        echo "$effect" > "$CURRENT_EFFECT"
        log "INFO" "Applied effect: $effect"
        notify "Wallpaper Effects" "Applied: $effect"
    else
        log "ERROR" "hyprshade not available"
        return 1
    fi
}

# Select effect interactively
select_effect() {
    if [[ ! -d "$EFFECTS_DIR" ]]; then
        log "ERROR" "Effects directory not found: $EFFECTS_DIR"
        return 1
    fi
    
    local effects options choice
    readarray -t effects < <(ls "$EFFECTS_DIR" 2>/dev/null || true)
    
    if [[ ${#effects[@]} -eq 0 ]]; then
        log "INFO" "No effects available"
        return 0
    fi
    
    # Add "off" option
    options="$(printf '%s\n' "${effects[@]}")\noff"
    
    if command -v rofi >/dev/null; then
        choice=$(echo -e "$options" | rofi -dmenu -i -p "Select Effect:")
    else
        echo "Available effects:"
        echo -e "$options" | nl
        read -p "Choose effect (name or number): " choice
        
        # Handle numeric input
        if [[ "$choice" =~ ^[0-9]+$ ]]; then
            local effects_array=("${effects[@]}" "off")
            choice="${effects_array[$((choice-1))]}"
        fi
    fi
    
    if [[ -n "$choice" ]]; then
        set_effect "$choice"
        # Reload current wallpaper with new effect
        if [[ -f "$CURRENT_WALLPAPER" ]]; then
            set_current_wallpaper "$(cat "$CURRENT_WALLPAPER")"
        fi
    fi
}

# Clear wallpaper cache
clear_cache() {
    rm -rf "$CACHE_DIR"/* 2>/dev/null || true
    mkdir -p "$CACHE_DIR"
    log "INFO" "Wallpaper cache cleared"
    notify "Cache Cleared" "Wallpaper cache emptied"
}

# Toggle cache
toggle_cache() {
    if is_cache_enabled; then
        rm -f "$CACHE_ENABLED"
        log "INFO" "Wallpaper cache disabled"
        notify "Cache" "Disabled"
    else
        touch "$CACHE_ENABLED"
        log "INFO" "Wallpaper cache enabled"
        notify "Cache" "Enabled"
    fi
}

# Set swww transition options
set_swww_transition() {
    local transition_type="${1:-wipe}"
    local duration="${2:-2}"
    local fps="${3:-60}"
    
    if ! ensure_swww_daemon; then
        log "ERROR" "swww not available"
        return 1
    fi
    
    if [[ -f "$CURRENT_WALLPAPER" ]]; then
        local wallpaper=$(cat "$CURRENT_WALLPAPER")
        wallpaper="${wallpaper/#\~/$HOME}"
        
        log "INFO" "Applying transition: $transition_type (${duration}s, ${fps}fps)"
        swww img "$wallpaper" --transition-type "$transition_type" --transition-duration "$duration" --transition-fps "$fps"
        notify "Transition Applied" "$transition_type transition"
    else
        log "ERROR" "No current wallpaper set"
        return 1
    fi
}

# Usage information
usage() {
    cat << EOF
Enhanced Wallpaper Manager

Usage: $0 <command> [arguments]

Commands:
    set <path>              Set specific wallpaper
    random                  Set random wallpaper
    restore                 Restore last wallpaper
    
    automation start [sec]  Start automatic wallpaper rotation
    automation stop         Stop automatic wallpaper rotation
    automation toggle       Toggle automatic wallpaper rotation
    
    effect <name>           Apply wallpaper effect
    effect select           Select effect interactively
    effect off              Disable effects
    
    transition <type> [dur] [fps]  Set swww transition (types: wipe, fade, center, etc.)
    
    cache clear             Clear wallpaper cache
    cache toggle            Toggle cache generation
    
    help                    Show this help

Environment Variables:
    HYPR_WALLPAPER_DIR     Wallpaper directory (default: ~/Pictures/wallpapers)

Examples:
    $0 random
    $0 set ~/Pictures/nature.jpg
    $0 automation start 30
    $0 effect blur
EOF
}

# Main function
main() {
    local command="${1:-help}"
    
    case "$command" in
        "set")
            if [[ -z "${2:-}" ]]; then
                echo "Error: Please provide wallpaper path" >&2
                exit 1
            fi
            set_current_wallpaper "$2"
            ;;
        "random")
            set_random_wallpaper
            ;;
        "restore")
            restore_wallpaper
            ;;
        "automation")
            case "${2:-}" in
                "start")
                    start_automation "${3:-$DEFAULT_AUTOMATION_INTERVAL}"
                    ;;
                "stop")
                    stop_automation
                    ;;
                "toggle")
                    toggle_automation
                    ;;
                *)
                    echo "Error: automation requires start/stop/toggle" >&2
                    exit 1
                    ;;
            esac
            ;;
        "effect")
            case "${2:-}" in
                "select")
                    select_effect
                    ;;
                "off"|"none")
                    set_effect "off"
                    ;;
                "")
                    echo "Error: effect requires name or 'select'" >&2
                    exit 1
                    ;;
                *)
                    set_effect "$2"
                    ;;
            esac
            ;;
        "transition")
            if [[ -z "${2:-}" ]]; then
                echo "Error: transition requires type" >&2
                exit 1
            fi
            set_swww_transition "$2" "${3:-2}" "${4:-60}"
            ;;
        "cache")
            case "${2:-}" in
                "clear")
                    clear_cache
                    ;;
                "toggle")
                    toggle_cache
                    ;;
                *)
                    echo "Error: cache requires clear/toggle" >&2
                    exit 1
                    ;;
            esac
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

# Run main function
main "$@"
#!/usr/bin/env bash

# Quick bookmark launcher with smart webapp detection
# Supports both rofi and walker menu interfaces with automatic detection

set -euo pipefail

# Configuration
SCRIPT_NAME="$(basename "$0")"

# Logging function
log() {
    echo "[$SCRIPT_NAME] $1" >&2
}

# Detect available menu system
detect_menu_system() {
    local menu_system=""
    local force_menu="${1:-}"
    
    # Check for forced menu system via argument or environment variable
    if [[ -n "$force_menu" ]]; then
        menu_system="$force_menu"
    elif [[ -n "${BOOKMARK_MENU:-}" ]]; then
        menu_system="$BOOKMARK_MENU"
    # Auto-detect with preference order
    elif command -v rofi >/dev/null 2>&1; then
        menu_system="rofi"
    elif command -v walker >/dev/null 2>&1; then
        menu_system="walker"
    else
        echo "Error: No suitable menu system found" >&2
        echo "Please install rofi or walker" >&2
        echo "Available options:" >&2
        echo "  rofi   - Traditional X11/Wayland menu system" >&2
        echo "  walker - Modern Wayland-native menu system" >&2
        exit 1
    fi
    
    # Verify the selected menu system is available
    if ! command -v "$menu_system" >/dev/null 2>&1; then
        echo "Error: Requested menu system '$menu_system' is not available" >&2
        exit 1
    fi
    
    log "Using menu system: $menu_system"
    echo "$menu_system"
}

# Show menu with rofi
show_rofi_menu() {
    local menu_items="$1"
    local selection=""
    
    # Try different rofi themes/configs
    local rofi_args=(-dmenu -p "Open bookmark…" -markup-rows)
    
    # Add theme if available
    if [[ -f "$HOME/.config/rofi/config.rasi" ]]; then
        rofi_args+=(-theme "$HOME/.config/rofi/config.rasi")
    elif [[ -f "$HOME/.config/rofi/applets/type-3/style-3.rasi" ]]; then
        rofi_args+=(-theme "$HOME/.config/rofi/applets/type-3/style-3.rasi")
    fi
    
    # Additional rofi optimizations
    rofi_args+=(-no-custom -auto-select)
    
    log "Launching rofi menu"
    selection=$(echo -e "$menu_items" | rofi "${rofi_args[@]}" 2>/dev/null || echo "")
    echo "$selection"
}

# Show menu with walker
show_walker_menu() {
    local menu_items="$1"
    local selection=""
    
    log "Launching walker menu"
    selection=$(echo -e "$menu_items" | walker --dmenu -p "Open bookmark…" 2>/dev/null || echo "")
    echo "$selection"
}

# Show usage information
show_usage() {
    cat << EOF
Quick Bookmark Launcher

Usage: $0 [OPTIONS]

Options:
    --rofi          Force use of rofi menu system
    --walker        Force use of walker menu system
    -h, --help      Show this help message

Environment Variables:
    BOOKMARK_MENU   Force menu system (rofi|walker)

Examples:
    $0              # Auto-detect menu system
    $0 --rofi       # Force rofi
    $0 --walker     # Force walker
    BOOKMARK_MENU=rofi $0  # Force rofi via environment

Features:
    - Auto-detection with rofi preferred over walker
    - Smart webapp mode for productivity apps
    - Configurable bookmark list
    - Theme support for both menu systems
    - Error handling and user feedback
EOF
}

# Launch selected bookmark
launch_bookmark() {
    local url="$1"
    local name="$2"
    
    # Use webapp mode for known web applications that benefit from it
    case "$url" in
        *"gmail.com"*|*"outlook.live.com"*|*"calendar.google.com"*|*"drive.google.com"*|*"onedrive.live.com"*|*"teams.microsoft.com"*|*"discord.com"*|*"web.whatsapp.com"*)
            log "Launching $name as webapp: $url"
            launch-webapp "$url"
            ;;
        *)
            log "Launching $name in browser: $url"
            launch-browser "$url"
            ;;
    esac
}

# Main function
main() {
    local force_menu=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --rofi)
                force_menu="rofi"
                shift
                ;;
            --walker)
                force_menu="walker"
                shift
                ;;
            -h|--help|help)
                show_usage
                exit 0
                ;;
            *)
                echo "Unknown argument: $1" >&2
                echo "Use --help for usage information" >&2
                exit 1
                ;;
        esac
    done
    
    # Common bookmarks - customize as needed
    local bookmarks=(
        "GitHub|https://github.com"
        "Gmail|https://mail.google.com"
        "Outlook Mail|https://outlook.live.com"
        "Google Calendar|https://calendar.google.com"
        "Outlook Calendar|https://outlook.live.com/calendar"
        "Google Drive|https://drive.google.com"
        "OneDrive|https://onedrive.live.com"
        "YouTube|https://youtube.com"
        "Netflix|https://netflix.com"
        "Discord|https://discord.com/app"
        "WhatsApp Web|https://web.whatsapp.com"
        "Reddit|https://reddit.com"
        "Twitter|https://twitter.com"
        "ChatGPT|https://chatgpt.com"
        "NixOS Manual|https://nixos.org/manual/"
        "Home Manager Manual|https://nix-community.github.io/home-manager/"
        "Arch Wiki|https://wiki.archlinux.org/"
        "MDN Web Docs|https://developer.mozilla.org/"
    )
    
    # Detect menu system
    local menu_system
    menu_system=$(detect_menu_system "$force_menu")
    
    # Format menu items
    local menu_items=""
    for bookmark in "${bookmarks[@]}"; do
        local name="${bookmark%|*}"
        menu_items+="$name\n"
    done
    
    # Show menu and get selection
    local selection=""
    case "$menu_system" in
        "rofi")
            selection=$(show_rofi_menu "$menu_items")
            ;;
        "walker")
            selection=$(show_walker_menu "$menu_items")
            ;;
        *)
            echo "Error: Unknown menu system: $menu_system" >&2
            exit 1
            ;;
    esac
    
    # Handle selection
    if [[ -n "$selection" ]]; then
        # Find the URL for the selected bookmark
        local found=false
        for bookmark in "${bookmarks[@]}"; do
            local name="${bookmark%|*}"
            local url="${bookmark#*|}"
            if [[ "$name" == "$selection" ]]; then
                launch_bookmark "$url" "$name"
                found=true
                break
            fi
        done
        
        if [[ "$found" == false ]]; then
            log "Warning: Selected bookmark '$selection' not found"
        fi
    else
        log "No bookmark selected"
    fi
}

# Run main function with all arguments
main "$@"
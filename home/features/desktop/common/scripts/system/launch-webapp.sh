#!/usr/bin/env bash

# -----------------------------------------------------
# Web Application Launcher Script
# Launch web applications in app mode with UWSM support
# -----------------------------------------------------
#
# This script launches web applications using the default browser
# in application mode, with UWSM session management integration.
# Automatically detects and uses Chrome-based browsers for best app experience.
# -----------------------------------------------------

set -euo pipefail

# Configuration
SCRIPT_NAME="$(basename "$0")"

# Dependency check function
check_dependencies() {
    local missing_deps=()
    
    # Check for basic utilities
    command -v sed >/dev/null || missing_deps+=("sed")
    
    # Check for session manager (optional)
    if ! command -v uwsm >/dev/null && ! command -v systemd-run >/dev/null; then
        log "Warning: No session manager found (uwsm or systemd-run)"
        log "Applications will run without session management"
    fi
    
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

# Get default browser with fallbacks
get_default_browser() {
    local browser=""
    
    # Try xdg-settings first
    if command -v xdg-settings >/dev/null; then
        browser=$(xdg-settings get default-web-browser 2>/dev/null || echo "")
    fi
    
    # If xdg-settings failed or returned empty, try environment variable
    if [[ -z "$browser" && -n "${BROWSER:-}" ]]; then
        browser="$BROWSER"
        # Add .desktop suffix if not present and not a full path
        if [[ "$browser" != *".desktop" && "$browser" != /* ]]; then
            browser="${browser}.desktop"
        fi
    fi
    
    # If still no browser, try to find suitable ones
    if [[ -z "$browser" ]]; then
        local browser_candidates=(
            "google-chrome.desktop"
            "google-chrome-stable.desktop"
            "brave-browser.desktop"
            "microsoft-edge.desktop"
            "chromium.desktop"
            "firefox.desktop"
            "librewolf.desktop"
        )
        
        for candidate in "${browser_candidates[@]}"; do
            local cmd_name="${candidate%%.desktop}"
            cmd_name="${cmd_name##*-}"  # Remove prefix for compound names
            
            # Check common command variations
            local check_commands=("$cmd_name" "${candidate%%.desktop}")
            for check_cmd in "${check_commands[@]}"; do
                if command -v "$check_cmd" >/dev/null 2>&1; then
                    browser="$candidate"
                    break 2
                fi
            done
        done
    fi
    
    echo "$browser"
}

# Find browser executable from desktop file or command name
find_browser_executable() {
    local browser="$1"
    local browser_exec=""
    
    # If browser is already a full path, return it
    if [[ "$browser" == /* ]] && command -v "$browser" >/dev/null; then
        echo "$browser"
        return 0
    fi
    
    # Try to find executable through desktop files
    if [[ "$browser" == *".desktop" ]]; then
        local desktop_dirs=(
            "$HOME/.local/share/applications"
            "$HOME/.nix-profile/share/applications"
            "/usr/local/share/applications"
            "/usr/share/applications"
            "/var/lib/flatpak/exports/share/applications"
            "$HOME/.local/share/flatpak/exports/share/applications"
        )
        
        for dir in "${desktop_dirs[@]}"; do
            if [[ -f "$dir/$browser" ]]; then
                # Extract Exec line from desktop file
                browser_exec=$(sed -n 's/^Exec=\([^ ]*\).*/\1/p' "$dir/$browser" 2>/dev/null | head -1)
                if [[ -n "$browser_exec" ]]; then
                    # Remove %U, %F, etc. placeholders
                    browser_exec="${browser_exec%% %*}"
                    break
                fi
            fi
        done
    fi
    
    # If we couldn't find executable through desktop files, try direct mapping
    if [[ -z "$browser_exec" ]]; then
        case "$browser" in
            "google-chrome"*) 
                local chrome_commands=("google-chrome-stable" "google-chrome" "chrome")
                for cmd in "${chrome_commands[@]}"; do
                    if command -v "$cmd" >/dev/null; then
                        browser_exec="$cmd"
                        break
                    fi
                done
                ;;
            "chromium"*) 
                browser_exec="chromium" 
                ;;
            "brave"*) 
                local brave_commands=("brave" "brave-browser")
                for cmd in "${brave_commands[@]}"; do
                    if command -v "$cmd" >/dev/null; then
                        browser_exec="$cmd"
                        break
                    fi
                done
                ;;
            "microsoft-edge"*) 
                browser_exec="microsoft-edge" 
                ;;
            "firefox"*) 
                browser_exec="firefox" 
                ;;
            "librewolf"*) 
                browser_exec="librewolf" 
                ;;
            *)
                # Try the browser name without .desktop extension
                browser_exec="${browser%%.desktop}"
                ;;
        esac
    fi
    
    echo "$browser_exec"
}

# Check if browser supports app mode
browser_supports_app_mode() {
    local browser="$1"
    
    # Chrome-based browsers support --app mode
    case "$browser" in
        *"chrome"*|*"chromium"*|*"brave"*|*"edge"*|*"opera"*|*"vivaldi"*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Launch application with session management
launch_with_session_manager() {
    local browser_exec="$1"
    local url="$2"
    shift 2
    local additional_args=("$@")
    
    # Try UWSM first (preferred for Wayland)
    if command -v uwsm >/dev/null; then
        log "Launching with UWSM session manager"
        exec setsid uwsm app -- "$browser_exec" "${additional_args[@]}" "$url"
    # Fallback to systemd-run for session management
    elif command -v systemd-run >/dev/null; then
        log "Launching with systemd session manager"
        exec systemd-run --user --scope -- "$browser_exec" "${additional_args[@]}" "$url"
    # Direct launch without session management
    else
        log "Launching without session manager"
        exec setsid "$browser_exec" "${additional_args[@]}" "$url" &>/dev/null &
    fi
}

# Main launch function
launch_webapp() {
    local url="$1"
    shift
    local additional_args=("$@")
    
    # Validate URL
    if [[ ! "$url" =~ ^https?:// ]]; then
        echo "Error: URL must start with http:// or https://" >&2
        return 1
    fi
    
    # Get browser
    local browser
    browser=$(get_default_browser)
    if [[ -z "$browser" ]]; then
        echo "Error: No suitable browser found" >&2
        return 1
    fi
    
    log "Selected browser: $browser"
    
    # Find executable
    local browser_exec
    browser_exec=$(find_browser_executable "$browser")
    if [[ -z "$browser_exec" ]] || ! command -v "$browser_exec" >/dev/null 2>&1; then
        echo "Error: Browser executable '$browser_exec' not found" >&2
        return 1
    fi
    
    log "Browser executable: $browser_exec"
    
    # Build launch arguments
    local launch_args=()
    
    # Add app mode if supported
    if browser_supports_app_mode "$browser"; then
        launch_args+=("--app=$url")
        log "Using app mode for Chrome-based browser"
        
        # Add additional Chrome app mode flags for better experience
        launch_args+=("--no-default-browser-check")
        launch_args+=("--disable-background-timer-throttling")
        launch_args+=("--disable-renderer-backgrounding")
        launch_args+=("--disable-backgrounding-occluded-windows")
        
    else
        # For non-Chrome browsers, add URL as regular argument
        launch_args+=("$url")
        log "Using regular browser mode"
    fi
    
    # Add any additional arguments passed to the script
    launch_args+=("${additional_args[@]}")
    
    # Launch the application
    log "Launching: $browser_exec ${launch_args[*]}"
    notify "Web App" "Launching $(basename "$url")"
    
    launch_with_session_manager "$browser_exec" "${launch_args[@]}"
}

# Show usage information
usage() {
    cat << EOF
Web Application Launcher Script

Usage: $0 <URL> [additional_browser_args...]

Arguments:
    URL                    Web application URL (must start with http:// or https://)
    additional_args...     Additional arguments to pass to the browser

Examples:
    $0 https://web.whatsapp.com
    $0 https://discord.com/app
    $0 https://gmail.com --disable-extensions
    $0 https://music.youtube.com --start-maximized

Features:
    - Automatic browser detection with fallbacks
    - Chrome-based browsers use --app mode for native app experience
    - UWSM/systemd session management integration
    - Supports environment variable BROWSER override

Environment Variables:
    BROWSER               Override default browser (e.g., "firefox", "chromium.desktop")

Dependencies:
    - A web browser (preferably Chrome-based for best experience)
    - sed (for desktop file parsing)
    - Optional: uwsm or systemd-run (for session management)
EOF
}

# Main function
main() {
    local url="${1:-}"
    
    # Handle help and empty arguments
    if [[ -z "$url" ]] || [[ "$url" == "help" || "$url" == "-h" || "$url" == "--help" ]]; then
        usage
        exit 0
    fi
    
    # Check dependencies
    check_dependencies
    
    # Launch web application
    if launch_webapp "$@"; then
        log "Web application launched successfully"
    else
        log "Failed to launch web application"
        exit 1
    fi
}

# Run main function with all arguments  
main "$@"
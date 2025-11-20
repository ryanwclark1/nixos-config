#!/usr/bin/env bash

# -----------------------------------------------------
# Web Application Launcher Script
# Combined best features from multiple implementations
# -----------------------------------------------------
#
# This script launches web applications using the default browser
# in application mode with profile support and session management.
# Features robust browser detection, profile support, and fallbacks.
# -----------------------------------------------------

set -euo pipefail

# Configuration
SCRIPT_NAME="$(basename "$0")"

# Parse command line arguments
parse_arguments() {
    URL=""
    PROFILE=""
    ADDITIONAL_ARGS=()

    while [[ $# -gt 0 ]]; do
        case $1 in
            --profile=*)
                PROFILE="${1#*=}"
                shift
                ;;
            --profile)
                PROFILE="$2"
                shift 2
                ;;
            --help|-h|help)
                show_usage
                exit 0
                ;;
            --*)
                ADDITIONAL_ARGS+=("$1")
                shift
                ;;
            *)
                if [[ -z "$URL" ]]; then
                    URL="$1"
                else
                    ADDITIONAL_ARGS+=("$1")
                fi
                shift
                ;;
        esac
    done

    # Export for use in other functions
    export URL PROFILE
}

# Logging and notification functions
log() {
    echo "[$SCRIPT_NAME] $1" >&2
}

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -t 3000 "$@" 2>/dev/null || true
    fi
}

# Dependency check
check_dependencies() {
    local missing_deps=()

    # Check for basic utilities
    command -v sed >/dev/null || missing_deps+=("sed")

    # Check for session managers (optional)
    if ! command -v uwsm >/dev/null 2>&1 && ! command -v systemd-run >/dev/null 2>&1; then
        log "Info: No session manager found (uwsm/systemd-run), using direct launch"
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo "Error: Missing required dependencies:" >&2
        printf "  - %s\n" "${missing_deps[@]}" >&2
        echo "Please install the missing packages and try again." >&2
        exit 1
    fi
}

# Get default browser with comprehensive fallback chain
# Prioritizes Chrome/Chromium and excludes Firefox
get_default_browser() {
    local browser=""

    # Method 1: Try xdg-settings first, but skip Firefox
    if command -v xdg-settings >/dev/null 2>&1; then
        browser=$(xdg-settings get default-web-browser 2>/dev/null || echo "")
        # Skip Firefox even if it's the system default
        if [[ "$browser" == *"firefox"* ]] || [[ "$browser" == *"librewolf"* ]]; then
            browser=""
        fi
    fi

    # Method 2: Try environment variable, but skip Firefox
    if [[ -z "$browser" && -n "${BROWSER:-}" ]]; then
        browser="$BROWSER"
        # Skip Firefox if specified in environment
        if [[ "$browser" == *"firefox"* ]] || [[ "$browser" == *"librewolf"* ]]; then
            browser=""
        else
            # Add .desktop suffix if not present and not a full path
            if [[ "$browser" != *".desktop" && "$browser" != /* ]]; then
                browser="${browser}.desktop"
            fi
        fi
    fi

    # Method 3: Try to find suitable browsers by checking commands
    # Prioritize Chrome/Chromium, exclude Firefox
    if [[ -z "$browser" ]]; then
        local browser_candidates=(
            "google-chrome-stable:google-chrome.desktop"
            "google-chrome:google-chrome.desktop"
            "chrome:google-chrome.desktop"
            "chromium:chromium.desktop"
            "brave:brave-browser.desktop"
            "brave-browser:brave-browser.desktop"
            "microsoft-edge:microsoft-edge.desktop"
            "edge:microsoft-edge.desktop"
            "vivaldi:vivaldi.desktop"
            "vivaldi-stable:vivaldi.desktop"
            "opera:opera.desktop"
            "opera-stable:opera.desktop"
        )

        for candidate in "${browser_candidates[@]}"; do
            local cmd_name="${candidate%%:*}"
            local desktop_name="${candidate##*:}"

            if command -v "$cmd_name" >/dev/null 2>&1; then
                browser="$desktop_name"
                break
            fi
        done
    fi

    echo "$browser"
}

# Find browser executable from desktop file or command mapping
find_browser_executable() {
    local browser="$1"
    local browser_exec=""

    # If browser is already a full path, return it
    if [[ "$browser" == /* ]] && command -v "$browser" >/dev/null 2>&1; then
        echo "$browser"
        return 0
    fi

    # Try to find executable through desktop files
    if [[ "$browser" == *".desktop" ]]; then
        local desktop_dirs=(
            "$HOME/.local/share/applications"
            "$HOME/.nix-profile/share/applications"
            "/run/current-system/sw/share/applications"
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
                    if command -v "$cmd" >/dev/null 2>&1; then
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
                    if command -v "$cmd" >/dev/null 2>&1; then
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
            "vivaldi"*)
                local vivaldi_commands=("vivaldi" "vivaldi-stable")
                for cmd in "${vivaldi_commands[@]}"; do
                    if command -v "$cmd" >/dev/null 2>&1; then
                        browser_exec="$cmd"
                        break
                    fi
                done
                ;;
            "opera"*)
                local opera_commands=("opera" "opera-stable")
                for cmd in "${opera_commands[@]}"; do
                    if command -v "$cmd" >/dev/null 2>&1; then
                        browser_exec="$cmd"
                        break
                    fi
                done
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

# Check if browser supports profile mode
browser_supports_profiles() {
    local browser="$1"

    # Chrome-based browsers and Firefox support profiles
    case "$browser" in
        *"chrome"*|*"chromium"*|*"brave"*|*"edge"*|*"vivaldi"*|*"opera"*|*"firefox"*|*"librewolf"*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Build browser arguments including profile support
build_browser_arguments() {
    local browser_exec="$1"
    local url="$2"
    local profile="$3"
    shift 3
    local additional_args=("$@")

    local launch_args=()

    # Add profile support if specified and supported
    if [[ -n "$profile" ]] && browser_supports_profiles "$browser_exec"; then
        case "$browser_exec" in
            *"chrome"*|*"chromium"*|*"brave"*|*"edge"*|*"vivaldi"*|*"opera"*)
                launch_args+=("--profile-directory=$profile")
                ;;
            *"firefox"*|*"librewolf"*)
                launch_args+=("-P" "$profile")
                ;;
        esac
        log "Using profile: $profile"
    fi

    # Add app mode if supported
    if browser_supports_app_mode "$browser_exec"; then
        launch_args+=("--app=$url")

        # Add additional Chrome app mode optimizations
        launch_args+=("--no-default-browser-check")
        launch_args+=("--disable-background-timer-throttling")
        launch_args+=("--disable-renderer-backgrounding")
        launch_args+=("--disable-backgrounding-occluded-windows")

        log "Using app mode for Chrome-based browser"
    else
        # For non-Chrome browsers, add URL as regular argument
        launch_args+=("$url")
        log "Using regular browser mode"
    fi

    # Add any additional arguments
    launch_args+=("${additional_args[@]}")

    # Return the arguments
    printf '%s\n' "${launch_args[@]}"
}

# Launch application with session management
launch_with_session_manager() {
    local browser_exec="$1"
    shift
    local launch_args=("$@")

    # Try UWSM first (preferred for Wayland)
    if command -v uwsm >/dev/null 2>&1; then
        log "Launching with UWSM session manager"
        exec setsid uwsm app -- "$browser_exec" "${launch_args[@]}"
    # Fallback to systemd-run for session management
    elif command -v systemd-run >/dev/null 2>&1; then
        log "Launching with systemd session manager"
        exec systemd-run --user --scope -- "$browser_exec" "${launch_args[@]}"
    # Direct launch without session management
    else
        log "Launching without session manager"
        exec setsid "$browser_exec" "${launch_args[@]}" &>/dev/null &
    fi
}

# Validate URL format
validate_url() {
    local url="$1"

    # Check if URL starts with http:// or https://
    if [[ ! "$url" =~ ^https?:// ]]; then
        echo "Error: URL must start with http:// or https://" >&2
        echo "Provided: $url" >&2
        return 1
    fi

    return 0
}

# Main launch function
launch_webapp() {
    # Validate URL
    if ! validate_url "$URL"; then
        exit 1
    fi

    # Get browser
    local browser
    browser=$(get_default_browser)
    if [[ -z "$browser" ]]; then
        echo "Error: No suitable browser found" >&2
        echo "Please install a web browser (Chrome, Firefox, etc.)" >&2
        exit 1
    fi

    log "Selected browser: $browser"

    # Find executable
    local browser_exec
    browser_exec=$(find_browser_executable "$browser")
    if [[ -z "$browser_exec" ]] || ! command -v "$browser_exec" >/dev/null 2>&1; then
        echo "Error: Browser executable '$browser_exec' not found" >&2
        echo "Browser: $browser" >&2
        exit 1
    fi

    log "Browser executable: $browser_exec"

    # Build launch arguments
    local launch_args=()
    readarray -t launch_args < <(build_browser_arguments "$browser_exec" "$URL" "$PROFILE" "${ADDITIONAL_ARGS[@]}")

    # Launch the application
    log "Launching: $browser_exec ${launch_args[*]}"
    notify "Web App" "Launching $(basename "$URL")"

    launch_with_session_manager "$browser_exec" "${launch_args[@]}"
}

# Show usage information
show_usage() {
    cat << EOF
Web Application Launcher Script

Usage: $0 <URL> [OPTIONS] [ADDITIONAL_ARGS...]

Arguments:
    URL                    Web application URL (must start with http:// or https://)

Options:
    --profile=PROFILE      Use specific browser profile (Chrome: Profile 1, Profile 2, etc.)
    --profile PROFILE      Alternative profile syntax
    -h, --help, help       Show this help message

Additional Arguments:
    Any additional arguments are passed directly to the browser

Examples:
    $0 https://web.whatsapp.com
    $0 https://teams.microsoft.com --profile="Profile 2"
    $0 https://gmail.com --profile "Default" --start-maximized
    $0 https://discord.com/app --disable-extensions

Features:
    - Automatic browser detection with comprehensive fallbacks
    - Profile support for Chrome-based browsers and Firefox
    - Chrome-based browsers use --app mode for native app experience
    - UWSM/systemd session management integration
    - Robust error handling and user feedback
    - Support for additional browser arguments

Environment Variables:
    BROWSER               Override default browser (e.g., "firefox", "chromium.desktop")

Dependencies:
    - A web browser (preferably Chrome-based for best experience)
    - sed (for desktop file parsing)
    - Optional: uwsm or systemd-run (for session management)
    - Optional: notify-send (for notifications)
EOF
}

# Main function
main() {
    # Parse command line arguments
    parse_arguments "$@"

    # Check for help or empty URL
    if [[ -z "$URL" ]]; then
        show_usage
        exit 1
    fi

    # Check dependencies
    check_dependencies

    # Launch web application
    if launch_webapp; then
        log "Web application launched successfully"
    else
        log "Failed to launch web application"
        notify "Error" "Failed to launch web application"
        exit 1
    fi
}

# Run main function with all arguments
main "$@"

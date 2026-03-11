#!/usr/bin/env bash

# -----------------------------------------------------
# Rofi Web Search Script
# Quick web search launcher with configurable search engines
# -----------------------------------------------------
#
# This script provides a rofi interface for quickly searching
# various websites and search engines. Easily configurable
# with custom search providers.
# -----------------------------------------------------

set -euo pipefail

# Configuration
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/rofi"
DEFAULT_THEME="config"

# Find and source shared utilities
ROFI_HELPERS=""
WEB_SEARCH=""
URL_HANDLER=""

if [[ -f "$HOME/.local/bin/scripts/system/os-rofi-helpers.sh" ]]; then
    ROFI_HELPERS="$HOME/.local/bin/scripts/system/os-rofi-helpers.sh"
elif [[ -f "$SCRIPT_DIR/../../../../common/scripts/system/os-rofi-helpers.sh" ]]; then
    ROFI_HELPERS="$SCRIPT_DIR/../../../../common/scripts/system/os-rofi-helpers.sh"
fi

if [[ -f "$HOME/.local/bin/scripts/system/os-web-search.sh" ]]; then
    WEB_SEARCH="$HOME/.local/bin/scripts/system/os-web-search.sh"
elif [[ -f "$SCRIPT_DIR/../../../../common/scripts/system/os-web-search.sh" ]]; then
    WEB_SEARCH="$SCRIPT_DIR/../../../../common/scripts/system/os-web-search.sh"
fi

if [[ -f "$HOME/.local/bin/scripts/system/os-url-handler.sh" ]]; then
    URL_HANDLER="$HOME/.local/bin/scripts/system/os-url-handler.sh"
elif [[ -f "$SCRIPT_DIR/../../../../common/scripts/system/os-url-handler.sh" ]]; then
    URL_HANDLER="$SCRIPT_DIR/../../../../common/scripts/system/os-url-handler.sh"
fi

if [[ -n "$ROFI_HELPERS" ]]; then
    # shellcheck source=/dev/null
    source "$ROFI_HELPERS"
fi

if [[ -n "$WEB_SEARCH" ]]; then
    # shellcheck source=/dev/null
    source "$WEB_SEARCH"
fi

if [[ -n "$URL_HANDLER" ]]; then
    # shellcheck source=/dev/null
    source "$URL_HANDLER"
fi

# Search engine configuration
declare -A SEARCH_ENGINES

# Initialize search engines using shared function if available
init_search_engines() {
    if command -v init_search_engines >/dev/null 2>&1; then
        init_search_engines SEARCH_ENGINES
    else
        # Fallback to local implementation
        SEARCH_ENGINES=(
            ["🔍 Search"]="https://search.brave.com/search?q="
            ["🌐 Google"]="https://www.google.com/search?q="
            ["🦆 DuckDuckGo"]="https://duckduckgo.com/?q="
            ["❄️  NixOS Packages"]="https://search.nixos.org/packages?channel=unstable&from=0&size=50&sort=relevance&type=packages&query="
            ["📦 NixOS Options"]="https://search.nixos.org/options?channel=unstable&from=0&size=50&sort=relevance&query="
            ["🎞️  YouTube"]="https://www.youtube.com/results?search_query="
            ["🐙 GitHub"]="https://github.com/search?q="
            ["📚 Wikipedia"]="https://en.wikipedia.org/wiki/Special:Search?search="
            ["🛒 Amazon"]="https://www.amazon.com/s?k="
            ["🗺️  Maps"]="https://www.openstreetmap.org/search?query="
            ["📰 Reddit"]="https://www.reddit.com/search/?q="
            ["🎵 Spotify"]="https://open.spotify.com/search/"
            ["🐧 Arch Wiki"]="https://wiki.archlinux.org/index.php?search="
        )
    fi
}

# Dependency check function
check_dependencies() {
    local missing_deps=()

    # Check rofi using shared helper if available
    if command -v check_rofi >/dev/null 2>&1; then
        if ! check_rofi; then
            exit 1
        fi
    else
        command -v rofi >/dev/null || missing_deps+=("rofi")
    fi

    # xdg-open is handled by open_url function, so we don't need to check it here

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
        notify-send -t 2000 "$@"
    fi
}

# Generate list for rofi
generate_engine_list() {
    if command -v get_search_engine_list >/dev/null 2>&1; then
        get_search_engine_list SEARCH_ENGINES
    else
        # Fallback
        for engine in "${!SEARCH_ENGINES[@]}"; do
            echo "$engine"
        done | sort
    fi
}

# Run rofi with theme
run_rofi() {
    local prompt="$1"
    local message="${2:-}"
    local theme_path

    if command -v get_rofi_theme >/dev/null 2>&1; then
        theme_path=$(get_rofi_theme "$DEFAULT_THEME")
    else
        # Fallback
        theme_path="$CONFIG_DIR/$DEFAULT_THEME.rasi"
        [[ ! -f "$theme_path" ]] && theme_path=""
    fi

    local rofi_args=(
        -dmenu
        -p "$prompt"
        -i  # Case insensitive
        -format "s"  # Return selection
    )

    # Add message if provided
    [[ -n "$message" ]] && rofi_args+=(-mesg "$message")

    # Add theme if available
    [[ -n "$theme_path" ]] && rofi_args+=(-theme "$theme_path")

    rofi "${rofi_args[@]}"
}

# Main search function
perform_search() {
    init_search_engines

    # Select search engine
    log "Showing search engine selection"
    local selected_engine
    selected_engine=$(generate_engine_list | run_rofi "Search Engine" "Select a search engine")

    if [[ -z "$selected_engine" ]]; then
        log "No search engine selected"
        return 0
    fi

    log "Selected engine: $selected_engine"

    # Get search query
    local query
    query=$(echo "" | run_rofi "Search Query" "Enter search terms for $selected_engine")

    if [[ -z "$query" ]]; then
        log "No search query entered"
        return 0
    fi

    # Build and open URL using shared functions if available
    local full_url
    if command -v get_search_url >/dev/null 2>&1; then
        full_url=$(get_search_url SEARCH_ENGINES "$selected_engine" "$query")
    else
        # Fallback: manual URL building
        local encoded_query
        if command -v url_encode >/dev/null 2>&1; then
            encoded_query=$(url_encode "$query")
        else
            # Basic encoding fallback
            encoded_query=$(printf '%s' "$query" | jq -sRr @uri 2>/dev/null || echo "$query")
        fi
        local base_url="${SEARCH_ENGINES[$selected_engine]}"
        full_url="${base_url}${encoded_query}"
    fi

    log "Opening URL: $full_url"
    notify "Web Search" "Searching $selected_engine for: $query"

    # Open URL in default browser using shared function if available
    if command -v open_url >/dev/null 2>&1; then
        if open_url "$full_url"; then
            log "Successfully opened web search"
        else
            log "Failed to open web search"
            notify "Error" "Failed to open web browser"
            return 1
        fi
    else
        # Fallback to xdg-open
        if xdg-open "$full_url" 2>/dev/null; then
            log "Successfully opened web search"
        else
            log "Failed to open web search"
            notify "Error" "Failed to open web browser"
            return 1
        fi
    fi
}

# Create example config file
create_example_config() {
    if command -v create_search_config_example >/dev/null 2>&1; then
        create_search_config_example
    else
        # Fallback implementation
        local config_file="$CONFIG_DIR/web-search-engines.conf"

        if [[ -f "$config_file" ]]; then
            echo "Configuration file already exists: $config_file" >&2
            return 1
        fi

        mkdir -p "$CONFIG_DIR"

        cat > "$config_file" << 'EOF'
# Web Search Engines Configuration
# Format: "Display Name"="Search URL with query placeholder"
# The search query will be URL-encoded and appended to the URL
# Lines starting with # are comments

# Custom search engines (examples)
# "🎨 DeviantArt"="https://www.deviantart.com/search/deviations?q="
# "🎮 Steam"="https://store.steampowered.com/search/?term="
# "📖 Goodreads"="https://www.goodreads.com/search?q="
# "🛡️ CVE Database"="https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword="
# "🏠 My Company Docs"="https://docs.company.com/search?q="

# Override default engines by using the same display name
# "🔍 Search"="https://www.startpage.com/sp/search?query="
EOF

        echo "Example configuration created: $config_file"
        echo "Edit this file to add custom search engines"
    fi
}

# Show usage information
usage() {
    cat << EOF
Rofi Web Search Script

Usage: $0 [COMMAND]

Commands:
    search       Launch search interface (default)
    config       Create example configuration file
    list         List available search engines
    help         Show this help

Configuration:
    Config file: ~/.config/rofi/web-search-engines.conf
    Theme: ~/.config/rofi/config.rasi (or specify with --theme)

Features:
    - Multiple pre-configured search engines
    - Custom search engine support via config file
    - URL encoding of search queries
    - Configurable rofi themes
    - Case-insensitive search engine selection

Examples:
    $0                    # Launch search interface
    $0 search             # Same as above
    $0 config             # Create example config file
    $0 list               # Show available engines

Dependencies:
    - rofi
    - xdg-open
EOF
}

# List available search engines
list_engines() {
    init_search_engines

    echo "Available search engines:"
    echo "========================"

    if command -v get_search_engine_list >/dev/null 2>&1; then
        while IFS= read -r engine; do
            printf "  %-25s %s\n" "$engine" "${SEARCH_ENGINES[$engine]}"
        done < <(get_search_engine_list SEARCH_ENGINES)
    else
        # Fallback
        for engine in "${!SEARCH_ENGINES[@]}"; do
            printf "  %-25s %s\n" "$engine" "${SEARCH_ENGINES[$engine]}"
        done | sort
    fi
}

# Main function
main() {
    local command="${1:-search}"

    case "$command" in
        "search"|"")
            check_dependencies
            perform_search
            ;;
        "config")
            if create_example_config; then
                echo "Configuration file created successfully"
            else
                echo "Configuration file already exists" >&2
                exit 1
            fi
            ;;
        "list")
            list_engines
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

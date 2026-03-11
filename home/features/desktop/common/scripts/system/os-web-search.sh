#!/usr/bin/env bash

# -----------------------------------------------------
# Web Search Utilities
# Shared web search functionality and search engine management
# -----------------------------------------------------
#
# This script provides shared utilities for web search operations,
# including search engine configuration and URL building.
# -----------------------------------------------------

set -euo pipefail

# Source URL handler utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/os-url-handler.sh" ]]; then
    # shellcheck source=os-url-handler.sh
    source "$SCRIPT_DIR/os-url-handler.sh"
fi

# Configuration
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/rofi"
SEARCH_CONFIG_FILE="$CONFIG_DIR/web-search-engines.conf"

# Default search engines
declare -A DEFAULT_SEARCH_ENGINES=(
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

# Initialize search engines (loads defaults + custom config)
init_search_engines() {
    local -n engines_ref="$1"

    # Start with defaults
    for key in "${!DEFAULT_SEARCH_ENGINES[@]}"; do
        engines_ref["$key"]="${DEFAULT_SEARCH_ENGINES[$key]}"
    done

    # Load custom search engines from config file if it exists
    if [[ -f "$SEARCH_CONFIG_FILE" ]]; then
        while IFS='=' read -r key value; do
            # Skip comments and empty lines
            [[ "$key" =~ ^[[:space:]]*# ]] && continue
            [[ -z "$key" ]] && continue

            # Remove quotes from value if present
            value="${value%\"}"
            value="${value#\"}"

            engines_ref["$key"]="$value"
        done < "$SEARCH_CONFIG_FILE"
    fi
}

# Get search engine list (sorted)
get_search_engine_list() {
    local -n engines_ref="$1"

    for engine in "${!engines_ref[@]}"; do
        echo "$engine"
    done | sort
}

# Get search URL for engine and query
get_search_url() {
    local -n engines_ref="$1"
    local engine="$2"
    local query="$3"

    if [[ -z "${engines_ref[$engine]:-}" ]]; then
        echo "Error: Unknown search engine: $engine" >&2
        return 1
    fi

    local base_url="${engines_ref[$engine]}"
    build_search_url "$base_url" "$query"
}

# Create example config file
create_search_config_example() {
    if [[ -f "$SEARCH_CONFIG_FILE" ]]; then
        echo "Configuration file already exists: $SEARCH_CONFIG_FILE" >&2
        return 1
    fi

    mkdir -p "$CONFIG_DIR"

    cat > "$SEARCH_CONFIG_FILE" << 'EOF'
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

    echo "Example configuration created: $SEARCH_CONFIG_FILE"
    echo "Edit this file to add custom search engines"
}

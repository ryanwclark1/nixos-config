#!/usr/bin/env bash

# -----------------------------------------------------
# URL Handler Utilities
# Shared utilities for opening URLs and web resources
# -----------------------------------------------------
#
# This script provides shared utilities for opening URLs
# in the default browser, with proper error handling.
# -----------------------------------------------------

set -euo pipefail

# Open URL in default browser
open_url() {
    local url="$1"

    if [[ -z "$url" ]]; then
        echo "Error: No URL provided" >&2
        return 1
    fi

    # Try xdg-open first (most common)
    if command -v xdg-open >/dev/null 2>&1; then
        if xdg-open "$url" 2>/dev/null; then
            return 0
        fi
    fi

    # Fallback to other methods
    if command -v firefox >/dev/null 2>&1; then
        firefox "$url" 2>/dev/null &
        return 0
    fi

    if command -v google-chrome >/dev/null 2>&1; then
        google-chrome "$url" 2>/dev/null &
        return 0
    fi

    if command -v chromium >/dev/null 2>&1; then
        chromium "$url" 2>/dev/null &
        return 0
    fi

    echo "Error: No suitable browser found to open URL: $url" >&2
    return 1
}

# URL encode function
url_encode() {
    local string="$1"
    local encoded=""

    # Use printf to encode each character
    for (( i=0; i<${#string}; i++ )); do
        local char="${string:$i:1}"
        case "$char" in
            [a-zA-Z0-9.~_-])
                encoded+="$char"
                ;;
            *)
                encoded+=$(printf '%%%02X' "'$char")
                ;;
        esac
    done

    echo "$encoded"
}

# Build search URL
build_search_url() {
    local base_url="$1"
    local query="$2"

    if [[ -z "$base_url" ]] || [[ -z "$query" ]]; then
        echo "Error: Both base_url and query are required" >&2
        return 1
    fi

    local encoded_query
    encoded_query=$(url_encode "$query")

    echo "${base_url}${encoded_query}"
}

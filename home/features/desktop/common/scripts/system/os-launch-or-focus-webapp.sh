#!/usr/bin/env bash

# Launch or focus webapp window
# Wrapper around os-launch-or-focus for web applications
# Dependencies: os-launch-or-focus, os-launch-webapp

set -euo pipefail

# Check dependencies
check_dependencies() {
    local missing=()

    if ! command -v os-launch-or-focus >/dev/null 2>&1; then
        missing+=("os-launch-or-focus")
    fi

    if ! command -v os-launch-webapp >/dev/null 2>&1; then
        missing+=("os-launch-webapp")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Error: Missing required dependencies: ${missing[*]}" >&2
        echo "Please install the missing packages and try again." >&2
        exit 1
    fi
}

# Usage information
usage() {
    cat << EOF
Launch or Focus Webapp Window

Usage: $0 <window-pattern> [url] [flags...]

Arguments:
    window-pattern    Pattern to match existing window (class or title)
    url               URL to open (optional if flags are provided)
    flags             Additional flags for os-launch-webapp

Description:
    If a window matching the pattern exists, focus it. Otherwise, launch
    a new webapp instance with the provided URL and flags.

Examples:
    $0 "Gmail" "https://mail.google.com"
    $0 "Discord" "https://discord.com" "--app"
    $0 "YouTube" "https://youtube.com" "--new-window"

Dependencies:
    - os-launch-or-focus
    - os-launch-webapp
EOF
}

# Main function
main() {
    # Handle help
    if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
        usage
        exit 0
    fi

    # Check for required arguments
    if [[ $# -eq 0 ]]; then
        echo "Error: Window pattern is required" >&2
        usage >&2
        exit 1
    fi

    # Check dependencies
    check_dependencies

    local window_pattern="$1"
    shift

    # Validate window pattern is not empty
    if [[ -z "$window_pattern" ]]; then
        echo "Error: Window pattern cannot be empty" >&2
        usage >&2
        exit 1
    fi

    # Build launch command with proper argument handling
    # Since os-launch-or-focus uses 'bash -c "$LAUNCH_COMMAND"', we need to properly quote
    local launch_command="os-launch-webapp"
    if [[ $# -gt 0 ]]; then
        # Properly quote all arguments so they survive bash -c execution
        for arg in "$@"; do
            # Use printf %q to properly escape each argument
            launch_command="$launch_command $(printf '%q' "$arg")"
        done
    fi

    # Execute os-launch-or-focus
    exec os-launch-or-focus "$window_pattern" "$launch_command"
}

main "$@"

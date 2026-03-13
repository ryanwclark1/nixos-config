#!/usr/bin/env bash
# Pure hostname functions for tmux-forceline
# Source this file — not meant to be executed directly
if [[ -z "${FL_VERSION:-}" ]]; then
    source "${FORCELINE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null && pwd)}/utils/pure_helpers.sh"
fi

# Get hostname using available commands
get_raw_hostname() {
    local hostname=""

    if command_exists hostname; then
        hostname=$(hostname 2>/dev/null)
    elif command_exists hostnamectl; then
        hostname=$(hostnamectl hostname 2>/dev/null)
    elif [ -r /proc/sys/kernel/hostname ]; then
        hostname=$(cat /proc/sys/kernel/hostname 2>/dev/null)
    elif [ -r /etc/hostname ]; then
        hostname=$(cat /etc/hostname 2>/dev/null)
    fi

    # Remove any trailing whitespace or newlines
    echo "$hostname" | tr -d '\n\r' | sed 's/[[:space:]]*$//'
}

# Format hostname according to specified format
format_hostname() {
    local format="$1"
    local custom="$2"
    local raw_hostname

    raw_hostname=$(get_raw_hostname)

    if [ -z "$raw_hostname" ]; then
        echo "unknown"
        return 1
    fi

    case "$format" in
        "short")
            echo "${raw_hostname%%.*}"
            ;;
        "long"|"full")
            echo "$raw_hostname"
            ;;
        "custom")
            if [ -n "$custom" ]; then
                echo "$custom"
            else
                echo "ERROR: Custom hostname not set"
                return 1
            fi
            ;;
        "upper")
            echo "${raw_hostname%%.*}" | tr '[:lower:]' '[:upper:]'
            ;;
        "lower")
            echo "${raw_hostname%%.*}" | tr '[:upper:]' '[:lower:]'
            ;;
        *)
            echo "${raw_hostname%%.*}"
            ;;
    esac
}

# Get hostname with icon based on OS
get_hostname_with_icon() {
    local format="$1"
    local custom="$2"
    local show_icon="$3"
    local hostname
    local icon=""

    hostname=$(format_hostname "$format" "$custom")

    if [ "$show_icon" = "yes" ]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            icon="󰀵 "
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            icon="󰌽 "
        elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
            icon="󰍲 "
        elif [[ "$OSTYPE" == "freebsd"* ]]; then
            icon="󰈸 "
        else
            icon="󰟀 "
        fi
    fi

    echo "${icon}${hostname}"
}

#!/usr/bin/env bash
# Hostname Helper Functions for tmux-forceline v2.0
# Cross-platform hostname detection and formatting

# Default configurations
HOSTNAME_FORMAT="${FORCELINE_HOSTNAME_FORMAT:-short}"
HOSTNAME_CUSTOM="${FORCELINE_HOSTNAME_CUSTOM:-}"

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

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
            # Remove domain part
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
        # Detect OS and set appropriate icon
        if [[ "$OSTYPE" == "darwin"* ]]; then
            icon="󰀵 "  # Apple logo
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            icon="󰌽 "  # Linux logo
        elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
            icon="󰍲 "  # Windows logo
        elif [[ "$OSTYPE" == "freebsd"* ]]; then
            icon="󰈸 "  # BSD logo
        else
            icon="󰟀 "  # Generic server icon
        fi
    fi
    
    echo "${icon}${hostname}"
}
#!/usr/bin/env bash

# Weather information from wttr.in
# Can be sourced to set WTTR_PARAMS or executed directly

set -euo pipefail

# Configuration
WTTR_BASE_URL="${WTTR_BASE_URL:-wttr.in}"
DEFAULT_LOCATION="${WTTR_LOCATION:-(1// /+)}"

# Check dependencies
check_dependencies() {
    if ! command -v curl >/dev/null 2>&1; then
        echo "Error: curl not found. Please install curl." >&2
        return 1
    fi
    return 0
}

# Initialize WTTR_PARAMS if not set
init_wttr_params() {
    if [[ -z "${WTTR_PARAMS:-}" ]]; then
        local params=""

        # Add narrow format if terminal is small
        if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
            local cols
            cols=$(tput cols 2>/dev/null || echo "0")
            if [[ "$cols" -lt 125 ]]; then
                params+='n'
            fi
        fi

        # Add measurement units based on locale
        if command -v locale >/dev/null 2>&1; then
            local measurement
            measurement=$(locale LC_MEASUREMENT 2>/dev/null || echo "")
            for token in $measurement; do
                case "$token" in
                    1) params+='m' ;;  # Metric
                    2) params+='u' ;;  # US/Imperial
                esac
            done
        fi

        export WTTR_PARAMS="$params"
    fi
}

# Get weather information
wttr() {
    local location="${1:-$DEFAULT_LOCATION}"
    shift || true

    # Check dependencies
    if ! check_dependencies; then
        return 1
    fi

    # Initialize params if needed
    init_wttr_params

    # Build curl arguments
    local args=()
    local params_array

    # Split WTTR_PARAMS and additional arguments
    IFS=' ' read -ra params_array <<< "${WTTR_PARAMS:-} $*"

    for param in "${params_array[@]}"; do
        [[ -n "$param" ]] && args+=(--data-urlencode "$param")
    done

    # Set language header
    local lang_header=""
    if [[ -n "${LANG:-}" ]]; then
        lang_header="-H"
        lang_value="Accept-Language: ${LANG%_*}"
    fi

    # Fetch weather
    if [[ -n "$lang_header" ]]; then
        curl -fGsS "$lang_header" "$lang_value" "${args[@]}" --compressed "${WTTR_BASE_URL}/${location}" 2>/dev/null || {
            echo "Error: Failed to fetch weather information" >&2
            echo "Please check your internet connection and try again" >&2
            return 1
        }
    else
        curl -fGsS "${args[@]}" --compressed "${WTTR_BASE_URL}/${location}" 2>/dev/null || {
            echo "Error: Failed to fetch weather information" >&2
            echo "Please check your internet connection and try again" >&2
            return 1
        }
    fi
}

# Usage information
usage() {
    cat << EOF
Weather Information from wttr.in

Usage: $0 [LOCATION] [OPTIONS]

Arguments:
    LOCATION    Location to get weather for (default: auto-detect)
                Examples: "London", "New York", "Paris"

Options:
    -h, --help    Show this help message

Environment Variables:
    WTTR_PARAMS      Additional wttr.in parameters (e.g., "F q m")
    WTTR_LOCATION    Default location (default: auto-detect)
    WTTR_BASE_URL     Base URL (default: wttr.in)
    LANG              Language for weather descriptions

Examples:
    $0                    # Get weather for current location
    $0 "London"           # Get weather for London
    $0 "New York" "F"     # Get weather for New York with format F

Common Parameters:
    F     Full format
    q     Quiet mode (no location name)
    m     Metric units
    u     US/Imperial units
    n     Narrow format
    Q     Quiet mode (no version line)
    1     One line format
    2     Two lines format
    3     Three lines format

Note: This script can also be sourced to set WTTR_PARAMS:
    source $0
    wttr "London"
EOF
}

# Main function (only if not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    local arg="${1:-}"

    if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
        usage
        exit 0
    fi

    wttr "$@"
fi

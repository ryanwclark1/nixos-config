#!/usr/bin/env bash
# Pure weather functions for tmux-forceline
# Source this file — not meant to be executed directly

if [[ -z "${FL_VERSION:-}" ]]; then
    source "${FORCELINE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null && pwd)}/utils/pure_helpers.sh"
fi

# Fetch weather data from wttr.in with caching
# Arguments: location, format, units, interval_minutes
get_weather() {
    local location="${1:-}"
    local format="${2:-1}"
    local units="${3:-u}"
    local interval="${4:-15}"

    local cache_dir
    cache_dir=$(get_module_cache_dir "weather")
    local cache_file="$cache_dir/weather_value.cache"
    local timestamp_file="$cache_dir/weather_timestamp.cache"

    local update_interval=$((60 * interval))
    local current_time
    current_time=$(date "+%s")

    local previous_update=0
    if [ -f "$timestamp_file" ]; then
        previous_update=$(cat "$timestamp_file" 2>/dev/null || echo "0")
    fi

    local delta=$((current_time - ${previous_update:-0}))

    if [ -z "$previous_update" ] || [ "$previous_update" = "0" ] || [ "$delta" -ge "$update_interval" ]; then
        # Need to fetch fresh data
        local fetch_location="$location"

        # Auto-detect location if not specified
        if [ -z "$fetch_location" ]; then
            fetch_location=$(curl -s "https://ipinfo.io/city" 2>/dev/null | tr -d '\n' || echo "")
            if [ -z "$fetch_location" ]; then
                fetch_location="New York"
            fi
        fi

        # Validate units
        if [ "$units" != "m" ] && [ "$units" != "u" ]; then
            units="u"
        fi

        local value
        if value=$(curl -s "https://wttr.in/$fetch_location?$units&format=$format" 2>/dev/null | sed "s/[[:space:]]km/km/g" | tr -d '\n'); then
            echo -n "$current_time" > "$timestamp_file" 2>/dev/null || true
            echo -n "$value" > "$cache_file" 2>/dev/null || true
            echo -n "$value"
        else
            echo -n "N/A"
        fi
    else
        # Return cached data
        if [ -f "$cache_file" ]; then
            cat "$cache_file" 2>/dev/null || echo -n "N/A"
        else
            echo -n "N/A"
        fi
    fi
}

#!/usr/bin/env bash
# Pure uptime functions for tmux-forceline
# Source this file — not meant to be executed directly
if [[ -z "${FL_VERSION:-}" ]]; then
    source "${FORCELINE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null && pwd)}/utils/pure_helpers.sh"
fi

# Get uptime with cross-platform support and format options
get_uptime() {
    local format="$1"
    local uptime_data

    if command -v uptime >/dev/null 2>&1; then
        uptime_data=$(uptime)
    elif [ -r /proc/uptime ]; then
        local seconds
        seconds=$(cut -d. -f1 /proc/uptime)
        local days=$((seconds / 86400))
        local hours=$(((seconds % 86400) / 3600))
        local mins=$(((seconds % 3600) / 60))
        uptime_data="up ${days} days, ${hours}:$(printf "%02d" $mins)"
    else
        echo "N/A"
        return 1
    fi

    case "$format" in
        "short")
            echo "$uptime_data" | sed 's/.*up \([^,]*\),.*/\1/' | sed 's/^ *//'
            ;;
        "compact")
            echo "$uptime_data" | sed 's/.*up \([^,]*\),.*/\1/' | \
                sed 's/ days\?/d/g; s/ hours\?/h/g; s/ minutes\?/m/g; s/:/ /g' | \
                awk '{
                    if (NF == 1 && index($1, ":")) {
                        split($1, time, ":")
                        printf "%sh %sm", time[1], time[2]
                    } else if (NF == 2 && index($2, ":")) {
                        split($2, time, ":")
                        printf "%s %sh %sm", $1, time[1], time[2]
                    } else {
                        print $0
                    }
                }'
            ;;
        "days")
            echo "$uptime_data" | sed 's/.*up \([0-9]*\) day.*/\1/' | grep -E '^[0-9]+$' || echo "0"
            ;;
        "hours")
            local days hours total_hours
            days=$(echo "$uptime_data" | sed 's/.*up \([0-9]*\) day.*/\1/' | grep -E '^[0-9]+$' || echo "0")
            hours=$(echo "$uptime_data" | sed 's/.*up.*[,:]* *\([0-9]*\):.*/\1/' | grep -E '^[0-9]+$' || echo "0")
            total_hours=$((days * 24 + hours))
            echo "${total_hours}h"
            ;;
        *)
            echo "$uptime_data" | sed 's/.*up \([^,]*\),.*/\1/' | sed 's/^ *//'
            ;;
    esac
}

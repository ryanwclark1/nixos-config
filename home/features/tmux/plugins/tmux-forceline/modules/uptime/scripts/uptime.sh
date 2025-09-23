#!/usr/bin/env bash
# Uptime script for tmux-forceline v3.0
# Enhanced uptime display with format options

# Source centralized path management
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../utils" && pwd)"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    source "$UTILS_DIR/common.sh"
else
    # Fallback implementation if common.sh not available
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Get uptime in different formats
get_uptime() {
    local format="$1"
    local uptime_data
    
    # Get raw uptime
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
            # Extract just the time part: "2 days, 3:45"
            echo "$uptime_data" | sed 's/.*up \([^,]*\),.*/\1/' | sed 's/^ *//'
            ;;
        "compact")
            # Very compact: "2d 3h 45m"
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
            # Just the number of days
            echo "$uptime_data" | sed 's/.*up \([0-9]*\) day.*/\1/' | grep -E '^[0-9]+$' || echo "0"
            ;;
        "hours")
            # Convert to total hours
            local days hours total_hours
            days=$(echo "$uptime_data" | sed 's/.*up \([0-9]*\) day.*/\1/' | grep -E '^[0-9]+$' || echo "0")
            hours=$(echo "$uptime_data" | sed 's/.*up.*[,:]* *\([0-9]*\):.*/\1/' | grep -E '^[0-9]+$' || echo "0")
            total_hours=$((days * 24 + hours))
            echo "${total_hours}h"
            ;;
        *)
            # Default short format
            echo "$uptime_data" | sed 's/.*up \([^,]*\),.*/\1/' | sed 's/^ *//'
            ;;
    esac
}

# Main uptime function
main() {
    local uptime_format
    
    uptime_format=$(get_tmux_option "@forceline_uptime_format" "short")
    
    get_uptime "$uptime_format"
}

# Execute if run directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
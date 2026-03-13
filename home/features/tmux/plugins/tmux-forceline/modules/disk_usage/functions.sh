#!/usr/bin/env bash
# Pure disk_usage functions for tmux-forceline
# Source this file — not meant to be executed directly
if [[ -z "${FL_VERSION:-}" ]]; then
    source "${FORCELINE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null && pwd)}/utils/pure_helpers.sh"
fi

# Get disk usage for specified path in requested format
get_disk_usage() {
    local path="$1"
    local format="$2"
    local show_path="$3"

    if [ ! -d "$path" ]; then
        echo "N/A"
        return 1
    fi

    local usage_data
    if command_exists df; then
        usage_data=$(df -h "$path" 2>/dev/null | tail -1)
    else
        echo "N/A"
        return 1
    fi

    if [ -z "$usage_data" ]; then
        echo "N/A"
        return 1
    fi

    # Parse df output — format varies by OS
    local filesystem size used avail percent mountpoint
    if [[ "$usage_data" =~ ([^[:space:]]+)[[:space:]]+([^[:space:]]+)[[:space:]]+([^[:space:]]+)[[:space:]]+([^[:space:]]+)[[:space:]]+([^[:space:]%]+)%[[:space:]]+(.+) ]]; then
        filesystem="${BASH_REMATCH[1]}"
        size="${BASH_REMATCH[2]}"
        used="${BASH_REMATCH[3]}"
        avail="${BASH_REMATCH[4]}"
        percent="${BASH_REMATCH[5]}"
        mountpoint="${BASH_REMATCH[6]}"
    else
        read -r filesystem size used avail percent mountpoint <<< "$usage_data"
    fi

    percent=$(echo "$percent" | tr -d '%')

    case "$format" in
        "percentage")
            echo "${percent}%"
            ;;
        "used")
            echo "$used"
            ;;
        "available")
            echo "$avail"
            ;;
        "size")
            echo "$size"
            ;;
        "compact")
            echo "${used}/${size}"
            ;;
        "full")
            if [ "$show_path" = "yes" ]; then
                echo "${used}/${size} (${percent}%) [$path]"
            else
                echo "${used}/${size} (${percent}%)"
            fi
            ;;
        *)
            echo "${percent}%"
            ;;
    esac
}

# Get disk usage with threshold-based status prefix
get_disk_usage_with_status() {
    local path="$1"
    local format="$2"
    local show_path="$3"
    local show_status="$4"
    local warning_threshold="${5:-80}"
    local critical_threshold="${6:-90}"

    local usage_output
    usage_output=$(get_disk_usage "$path" "percentage" "$show_path")

    if [ "$usage_output" = "N/A" ]; then
        if [ "$show_status" = "yes" ]; then
            echo "ERROR:N/A"
        else
            echo "N/A"
        fi
        return 1
    fi

    local percent
    percent=$(echo "$usage_output" | tr -d '%')

    local status="NORMAL"
    if [ "$percent" -ge "$critical_threshold" ] 2>/dev/null; then
        status="CRITICAL"
    elif [ "$percent" -ge "$warning_threshold" ] 2>/dev/null; then
        status="WARNING"
    fi

    local final_output
    final_output=$(get_disk_usage "$path" "$format" "$show_path")

    if [ "$show_status" = "yes" ]; then
        echo "${status}:${final_output}"
    else
        echo "$final_output"
    fi
}

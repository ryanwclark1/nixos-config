#!/usr/bin/env bash
# Disk usage script for tmux-forceline v2.0
# Enhanced disk monitoring with configurable paths and thresholds

# Get tmux option or use default
get_tmux_option() {
    local option="$1"
    local default="$2"
    tmux show-option -gqv "$option" 2>/dev/null || echo "$default"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Get disk usage for specified path
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
    
    # Parse df output (format varies by system)
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
    
    # Remove % from percentage
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

# Get disk usage with color indication
get_disk_usage_with_status() {
    local path="$1"
    local format="$2"
    local show_path="$3"
    local show_status="$4"
    
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
    
    # Extract percentage for status determination
    local percent
    percent=$(echo "$usage_output" | tr -d '%')
    
    # Get thresholds
    local warning_threshold critical_threshold
    warning_threshold=$(get_tmux_option "@forceline_disk_usage_warning_threshold" "80")
    critical_threshold=$(get_tmux_option "@forceline_disk_usage_critical_threshold" "90")
    
    # Determine status
    local status="NORMAL"
    if [ "$percent" -ge "$critical_threshold" ] 2>/dev/null; then
        status="CRITICAL"
    elif [ "$percent" -ge "$warning_threshold" ] 2>/dev/null; then
        status="WARNING"
    fi
    
    # Get the actual output in requested format
    local final_output
    final_output=$(get_disk_usage "$path" "$format" "$show_path")
    
    if [ "$show_status" = "yes" ]; then
        echo "${status}:${final_output}"
    else
        echo "$final_output"
    fi
}

# Main disk usage function
main() {
    local path format show_path show_status
    
    path=$(get_tmux_option "@forceline_disk_usage_path" "/")
    format=$(get_tmux_option "@forceline_disk_usage_format" "percentage")
    show_path=$(get_tmux_option "@forceline_disk_usage_show_path" "no")
    show_status=$(get_tmux_option "@forceline_disk_usage_show_status" "no")
    
    get_disk_usage_with_status "$path" "$format" "$show_path" "$show_status"
}

# Execute if run directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
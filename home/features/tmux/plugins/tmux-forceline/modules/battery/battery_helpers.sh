#!/usr/bin/env bash
# Battery Helper Functions for tmux-forceline
# Cross-platform battery status and percentage detection

command_exists() {
    local command
    for command; do
        type "$command" >/dev/null 2>&1 || return $?
    done
}

is_wsl() {
    if [ -f /proc/version ]; then
        version=$(</proc/version)
        if [[ "$version" == *"Microsoft"* || "$version" == *"microsoft"* ]]; then
            return 0
        fi
    fi
    return 1
}

# Get battery status (charging, discharging, charged, etc.)
battery_status() {
    if command_exists "pmset"; then
        # macOS
        pmset -g batt | awk -F '; *' 'NR==2 { print $2 }'
    elif command_exists "acpi"; then
        # Linux with acpi
        acpi -b | awk '{gsub(/,/, ""); print tolower($3); exit}'
    elif command_exists "upower"; then
        # Linux with upower
        local battery
        battery=$(upower -e | grep -E 'battery|DisplayDevice' | tail -n1)
        if [ -n "$battery" ]; then
            upower -i "$battery" | awk '/state/ {print $2}'
        fi
    elif command_exists "apm"; then
        # BSD systems
        local battery
        battery=$(apm -a)
        if [ "$battery" -eq 0 ]; then
            echo "discharging"
        elif [ "$battery" -eq 1 ]; then
            echo "charging"
        fi
    elif command_exists "termux-battery-status" "jq"; then
        # Termux (Android)
        termux-battery-status | jq -er '.status | ascii_downcase'
    elif is_wsl; then
        # Windows Subsystem for Linux
        local battery
        battery=$(find /sys/class/power_supply/*/status 2>/dev/null | tail -n1)
        if [ -n "$battery" ]; then
            awk '{print tolower($0);}' "$battery"
        fi
    fi
}

# Get battery percentage
battery_percentage() {
    if command_exists "pmset"; then
        # macOS
        pmset -g batt | grep -o "[0-9]\{1,3\}%"
    elif command_exists "acpi"; then
        # Linux with acpi
        acpi -b | grep -m 1 -Eo "[0-9]+%"
    elif command_exists "upower"; then
        # Linux with upower
        local battery=$(upower -e | grep -E 'battery|DisplayDevice' | tail -n1)
        if [ -z "$battery" ]; then
            return
        fi
        
        # Try to get percentage directly
        local percentage=$(upower -i "$battery" | awk '/percentage:/ {print $2}')
        if [ -n "$percentage" ]; then
            echo "${percentage%.*%}"
            return
        fi
        
        # Fallback to energy calculation
        local energy=$(upower -i "$battery" | awk '/energy:/ {sum+=$2} END {print sum}')
        local energy_full=$(upower -i "$battery" | awk '/energy-full:/ {sum+=$2} END {print sum}')
        if [ -n "$energy" ] && [ -n "$energy_full" ]; then
            echo "$energy $energy_full" | awk '{printf("%d%%", ($1/$2)*100)}'
        fi
    elif command_exists "termux-battery-status" "jq"; then
        # Termux (Android)
        termux-battery-status | jq -r '.percentage' | awk '{printf("%d%%", $1)}'
    elif command_exists "apm"; then
        # BSD systems
        apm -l | awk '{printf("%d%%", $1)}'
    elif is_wsl; then
        # Windows Subsystem for Linux
        local battery=$(find /sys/class/power_supply/*/capacity 2>/dev/null | tail -n1)
        if [ -n "$battery" ]; then
            cat "$battery" | awk '{printf("%d%%", $1)}'
        fi
    fi
}

# Get numerical battery percentage (without % symbol)
battery_percentage_raw() {
    battery_percentage | sed 's/%//'
}
#!/usr/bin/env bash
# tmux-forceline v3.0 Dynamic Theme Engine
# Advanced theme system with real-time switching and intelligent adaptation

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly THEME_DIR="$SCRIPT_DIR"
readonly YAML_THEME_DIR="$THEME_DIR/yaml"
readonly CACHE_DIR="${HOME}/.cache/tmux-forceline/themes"
readonly STATE_FILE="$CACHE_DIR/current_theme_state.json"

# Dynamic theme features
ADAPTIVE_BRIGHTNESS="yes"
TIME_BASED_SWITCHING="no"
SYSTEM_THEME_SYNC="no"
BATTERY_AWARE_THEMES="yes"
LOAD_AWARE_COLORS="yes"

# Color manipulation functions
readonly COLOR_UTILS="$SCRIPT_DIR/../utils/color_utils.sh"

# Function: Initialize theme engine
init_theme_engine() {
    mkdir -p "$CACHE_DIR"
    
    # Create state file if it doesn't exist
    if [[ ! -f "$STATE_FILE" ]]; then
        cat > "$STATE_FILE" << 'EOF'
{
  "current_theme": "catppuccin-frappe",
  "adaptive_mode": true,
  "last_update": 0,
  "brightness_level": "auto",
  "time_variant": "auto",
  "battery_theme": false,
  "load_theme": false,
  "system_sync": false
}
EOF
    fi
}

# Function: Detect system brightness/theme
detect_system_theme() {
    local system_theme="dark"
    
    # macOS detection
    if command -v defaults >/dev/null 2>&1; then
        local macos_theme
        macos_theme=$(defaults read -g AppleInterfaceStyle 2>/dev/null || echo "Light")
        if [[ "$macos_theme" == "Dark" ]]; then
            system_theme="dark"
        else
            system_theme="light"
        fi
    
    # GNOME detection
    elif command -v gsettings >/dev/null 2>&1; then
        local gnome_theme
        gnome_theme=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo "")
        if [[ "$gnome_theme" =~ -dark ]]; then
            system_theme="dark"
        else
            system_theme="light"
        fi
    
    # KDE detection
    elif command -v kreadconfig5 >/dev/null 2>&1; then
        local kde_theme
        kde_theme=$(kreadconfig5 --group General --key ColorScheme 2>/dev/null || echo "")
        if [[ "$kde_theme" =~ Dark ]]; then
            system_theme="dark"
        else
            system_theme="light"
        fi
    
    # Time-based fallback
    else
        local hour
        hour=$(date +%H)
        if [[ $hour -ge 20 || $hour -le 6 ]]; then
            system_theme="dark"
        else
            system_theme="light"
        fi
    fi
    
    echo "$system_theme"
}

# Function: Get battery status for theme adaptation
get_battery_status() {
    local battery_level=100
    local power_source="AC"
    
    # Linux battery detection
    if [[ -d "/sys/class/power_supply" ]]; then
        local battery_dir
        battery_dir=$(find /sys/class/power_supply -name "BAT*" | head -1)
        if [[ -n "$battery_dir" && -f "$battery_dir/capacity" ]]; then
            battery_level=$(cat "$battery_dir/capacity")
            if [[ -f "$battery_dir/status" ]]; then
                local status
                status=$(cat "$battery_dir/status")
                if [[ "$status" == "Discharging" ]]; then
                    power_source="Battery"
                fi
            fi
        fi
    
    # macOS battery detection
    elif command -v pmset >/dev/null 2>&1; then
        local pmset_output
        pmset_output=$(pmset -g batt 2>/dev/null || echo "")
        if [[ "$pmset_output" =~ ([0-9]+)% ]]; then
            battery_level="${BASH_REMATCH[1]}"
        fi
        if [[ "$pmset_output" =~ "discharging" ]]; then
            power_source="Battery"
        fi
    fi
    
    echo "$battery_level:$power_source"
}

# Function: Get system load for color adaptation
get_system_load() {
    local load_avg="0.0"
    local cpu_count=1
    
    # Get load average
    if [[ -f "/proc/loadavg" ]]; then
        load_avg=$(cut -d' ' -f1 /proc/loadavg)
    elif command -v uptime >/dev/null 2>&1; then
        load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | xargs)
    fi
    
    # Get CPU count
    if [[ -f "/proc/cpuinfo" ]]; then
        cpu_count=$(grep -c "^processor" /proc/cpuinfo)
    elif command -v sysctl >/dev/null 2>&1; then
        cpu_count=$(sysctl -n hw.ncpu 2>/dev/null || echo 1)
    fi
    
    # Calculate load percentage
    local load_percentage
    load_percentage=$(echo "$load_avg * 100 / $cpu_count" | bc -l 2>/dev/null || echo "0")
    
    echo "${load_percentage%%.*}"
}

# Function: Determine optimal theme variant
determine_theme_variant() {
    local base_theme="$1"
    local system_theme
    local battery_info
    local load_level
    local hour
    
    system_theme=$(detect_system_theme)
    battery_info=$(get_battery_status)
    load_level=$(get_system_load)
    hour=$(date +%H)
    
    local battery_level="${battery_info%:*}"
    local power_source="${battery_info#*:}"
    
    # Determine variant based on conditions
    local variant="$base_theme"
    
    # Time-based adaptation
    if [[ "$TIME_BASED_SWITCHING" == "yes" ]]; then
        if [[ $hour -ge 20 || $hour -le 6 ]]; then
            variant="${base_theme}-night"
        elif [[ $hour -ge 6 && $hour -le 10 ]]; then
            variant="${base_theme}-morning"
        elif [[ $hour -ge 18 && $hour -le 20 ]]; then
            variant="${base_theme}-evening"
        fi
    fi
    
    # Battery-aware themes
    if [[ "$BATTERY_AWARE_THEMES" == "yes" && "$power_source" == "Battery" ]]; then
        if [[ $battery_level -le 20 ]]; then
            variant="${base_theme}-power-save"
        elif [[ $battery_level -le 50 ]]; then
            variant="${base_theme}-battery"
        fi
    fi
    
    # Load-aware themes
    if [[ "$LOAD_AWARE_COLORS" == "yes" ]]; then
        if [[ $load_level -ge 80 ]]; then
            variant="${base_theme}-high-load"
        elif [[ $load_level -ge 50 ]]; then
            variant="${base_theme}-medium-load"
        fi
    fi
    
    # System theme sync
    if [[ "$SYSTEM_THEME_SYNC" == "yes" ]]; then
        if [[ "$system_theme" == "dark" ]]; then
            variant="${base_theme}-dark"
        else
            variant="${base_theme}-light"
        fi
    fi
    
    # Fallback to base theme if variant doesn't exist
    if [[ ! -f "$YAML_THEME_DIR/${variant}.yaml" ]]; then
        variant="$base_theme"
    fi
    
    echo "$variant"
}

# Function: Generate dynamic color variations
generate_color_variations() {
    local theme_file="$1"
    local battery_level="$2"
    local load_level="$3"
    
    if [[ ! -f "$COLOR_UTILS" ]]; then
        # Create basic color utilities if not available
        create_color_utils
    fi
    
    # Source color utilities
    source "$COLOR_UTILS"
    
    # Read base colors from theme
    local base_colors
    base_colors=$(yq eval '.palette' "$theme_file" 2>/dev/null || echo "{}")
    
    # Generate battery-aware variations
    if [[ $battery_level -le 20 ]]; then
        # Dim colors for power saving
        echo "$base_colors" | yq eval 'with_entries(.value |= darken_color(., 20))'
    elif [[ $load_level -ge 80 ]]; then
        # Intensify warning colors for high load
        echo "$base_colors" | yq eval '.base08 |= brighten_color(., 30) | .base09 |= brighten_color(., 20)'
    else
        echo "$base_colors"
    fi
}

# Function: Create color manipulation utilities
create_color_utils() {
    cat > "$COLOR_UTILS" << 'EOF'
#!/usr/bin/env bash
# Color manipulation utilities for dynamic theming

# Function: Convert hex to RGB
hex_to_rgb() {
    local hex="$1"
    hex="${hex#'#'}"
    
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    
    echo "$r $g $b"
}

# Function: Convert RGB to hex
rgb_to_hex() {
    local r="$1" g="$2" b="$3"
    printf "#%02x%02x%02x" "$r" "$g" "$b"
}

# Function: Darken color by percentage
darken_color() {
    local hex="$1"
    local percentage="$2"
    
    local rgb
    rgb=$(hex_to_rgb "$hex")
    read -r r g b <<< "$rgb"
    
    local factor=$((100 - percentage))
    r=$((r * factor / 100))
    g=$((g * factor / 100))
    b=$((b * factor / 100))
    
    rgb_to_hex "$r" "$g" "$b"
}

# Function: Brighten color by percentage
brighten_color() {
    local hex="$1"
    local percentage="$2"
    
    local rgb
    rgb=$(hex_to_rgb "$hex")
    read -r r g b <<< "$rgb"
    
    local factor=$((percentage))
    r=$(((255 - r) * factor / 100 + r))
    g=$(((255 - g) * factor / 100 + g))
    b=$(((255 - b) * factor / 100 + b))
    
    # Clamp to 255
    r=$((r > 255 ? 255 : r))
    g=$((g > 255 ? 255 : g))
    b=$((b > 255 ? 255 : b))
    
    rgb_to_hex "$r" "$g" "$b"
}

# Function: Calculate color contrast ratio
contrast_ratio() {
    local color1="$1"
    local color2="$2"
    
    # Simplified contrast calculation
    local rgb1 rgb2
    rgb1=$(hex_to_rgb "$color1")
    rgb2=$(hex_to_rgb "$color2")
    
    read -r r1 g1 b1 <<< "$rgb1"
    read -r r2 g2 b2 <<< "$rgb2"
    
    # Calculate relative luminance (simplified)
    local lum1=$((r1 * 299 + g1 * 587 + b1 * 114))
    local lum2=$((r2 * 299 + g2 * 587 + b2 * 114))
    
    if [[ $lum1 -gt $lum2 ]]; then
        echo $((lum1 / (lum2 + 1)))
    else
        echo $((lum2 / (lum1 + 1)))
    fi
}
EOF
    
    chmod +x "$COLOR_UTILS"
}

# Function: Apply theme with dynamic adaptations
apply_dynamic_theme() {
    local theme_name="$1"
    local force_update="${2:-no}"
    
    # Get current system state
    local battery_info load_level current_time
    battery_info=$(get_battery_status)
    load_level=$(get_system_load)
    current_time=$(date +%s)
    
    local battery_level="${battery_info%:*}"
    
    # Check if update is needed
    local last_update
    last_update=$(jq -r '.last_update' "$STATE_FILE" 2>/dev/null || echo "0")
    local time_diff=$((current_time - last_update))
    
    if [[ "$force_update" != "yes" && $time_diff -lt 30 ]]; then
        # Skip update if less than 30 seconds since last update
        return 0
    fi
    
    # Determine optimal theme variant
    local theme_variant
    theme_variant=$(determine_theme_variant "$theme_name")
    
    # Load base theme
    local theme_file="$YAML_THEME_DIR/${theme_variant}.yaml"
    if [[ ! -f "$theme_file" ]]; then
        theme_file="$YAML_THEME_DIR/${theme_name}.yaml"
        if [[ ! -f "$theme_file" ]]; then
            echo "Error: Theme file not found: $theme_name" >&2
            return 1
        fi
    fi
    
    # Generate dynamic colors
    local dynamic_colors
    dynamic_colors=$(generate_color_variations "$theme_file" "$battery_level" "$load_level")
    
    # Apply theme through existing theme loader
    if [[ -f "$THEME_DIR/theme_loader.conf" ]]; then
        FORCELINE_THEME="$theme_variant" source "$THEME_DIR/theme_loader.conf"
    fi
    
    # Update state file
    jq --arg theme "$theme_variant" \
       --arg time "$current_time" \
       --arg battery "$battery_level" \
       --arg load "$load_level" \
       '.current_theme = $theme | .last_update = ($time | tonumber) | .battery_level = ($battery | tonumber) | .load_level = ($load | tonumber)' \
       "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
}

# Function: Start theme monitoring daemon
start_theme_daemon() {
    local daemon_pid_file="$CACHE_DIR/theme_daemon.pid"
    
    # Check if daemon is already running
    if [[ -f "$daemon_pid_file" ]]; then
        local pid
        pid=$(cat "$daemon_pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            echo "Theme daemon already running (PID: $pid)"
            return 0
        else
            rm -f "$daemon_pid_file"
        fi
    fi
    
    # Start daemon in background
    (
        echo $$ > "$daemon_pid_file"
        
        while true; do
            # Get current theme from state
            local current_theme
            current_theme=$(jq -r '.current_theme' "$STATE_FILE" 2>/dev/null || echo "catppuccin-frappe")
            
            # Apply dynamic theme adaptations
            apply_dynamic_theme "$current_theme" "no"
            
            # Sleep for 30 seconds
            sleep 30
        done
    ) &
    
    echo "Theme daemon started (PID: $!)"
}

# Function: Stop theme monitoring daemon
stop_theme_daemon() {
    local daemon_pid_file="$CACHE_DIR/theme_daemon.pid"
    
    if [[ -f "$daemon_pid_file" ]]; then
        local pid
        pid=$(cat "$daemon_pid_file")
        if kill "$pid" 2>/dev/null; then
            echo "Theme daemon stopped (PID: $pid)"
            rm -f "$daemon_pid_file"
        else
            echo "Theme daemon not running or already stopped"
            rm -f "$daemon_pid_file"
        fi
    else
        echo "Theme daemon PID file not found"
    fi
}

# Function: List available themes with variants
list_themes_with_variants() {
    echo "Available themes and variants:"
    echo
    
    for theme_file in "$YAML_THEME_DIR"/*.yaml; do
        if [[ -f "$theme_file" ]]; then
            local theme_name
            theme_name=$(basename "$theme_file" .yaml)
            local theme_desc
            theme_desc=$(yq eval '.name // "No description"' "$theme_file" 2>/dev/null)
            local theme_variant
            theme_variant=$(yq eval '.variant // "unknown"' "$theme_file" 2>/dev/null)
            
            echo "  $theme_name ($theme_variant): $theme_desc"
        fi
    done
    
    echo
    echo "Dynamic variants (auto-generated):"
    echo "  *-night: Darker variant for nighttime"
    echo "  *-morning: Brighter variant for morning"
    echo "  *-evening: Warm variant for evening"
    echo "  *-battery: Power-saving variant"
    echo "  *-power-save: Low battery variant"
    echo "  *-high-load: High system load variant"
    echo "  *-medium-load: Medium system load variant"
}

# Function: Show current theme status
show_theme_status() {
    if [[ ! -f "$STATE_FILE" ]]; then
        echo "Theme engine not initialized"
        return 1
    fi
    
    echo "Dynamic Theme Engine Status:"
    echo
    
    local current_theme battery_level load_level last_update
    current_theme=$(jq -r '.current_theme' "$STATE_FILE")
    battery_level=$(jq -r '.battery_level // "unknown"' "$STATE_FILE")
    load_level=$(jq -r '.load_level // "unknown"' "$STATE_FILE")
    last_update=$(jq -r '.last_update' "$STATE_FILE")
    
    echo "  Current Theme: $current_theme"
    echo "  Battery Level: ${battery_level}%"
    echo "  System Load: ${load_level}%"
    echo "  Last Update: $(date -d "@$last_update" 2>/dev/null || echo "Unknown")"
    echo
    
    echo "Adaptive Features:"
    echo "  Brightness Adaptation: $ADAPTIVE_BRIGHTNESS"
    echo "  Time-based Switching: $TIME_BASED_SWITCHING"
    echo "  System Theme Sync: $SYSTEM_THEME_SYNC"
    echo "  Battery-aware Themes: $BATTERY_AWARE_THEMES"
    echo "  Load-aware Colors: $LOAD_AWARE_COLORS"
    echo
    
    # Check daemon status
    local daemon_pid_file="$CACHE_DIR/theme_daemon.pid"
    if [[ -f "$daemon_pid_file" ]]; then
        local pid
        pid=$(cat "$daemon_pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            echo "  Theme Daemon: Running (PID: $pid)"
        else
            echo "  Theme Daemon: Stopped (stale PID file)"
        fi
    else
        echo "  Theme Daemon: Stopped"
    fi
}

# Function: Configure dynamic features
configure_features() {
    local feature="$1"
    local value="$2"
    
    case "$feature" in
        "adaptive-brightness")
            ADAPTIVE_BRIGHTNESS="$value"
            ;;
        "time-based")
            TIME_BASED_SWITCHING="$value"
            ;;
        "system-sync")
            SYSTEM_THEME_SYNC="$value"
            ;;
        "battery-aware")
            BATTERY_AWARE_THEMES="$value"
            ;;
        "load-aware")
            LOAD_AWARE_COLORS="$value"
            ;;
        *)
            echo "Unknown feature: $feature" >&2
            echo "Available features: adaptive-brightness, time-based, system-sync, battery-aware, load-aware" >&2
            return 1
            ;;
    esac
    
    echo "Feature '$feature' set to: $value"
}

# Function: Main command dispatcher
main() {
    local command="${1:-status}"
    
    # Initialize theme engine
    init_theme_engine
    
    case "$command" in
        "apply")
            local theme_name="${2:-catppuccin-frappe}"
            apply_dynamic_theme "$theme_name" "yes"
            ;;
        "start-daemon")
            start_theme_daemon
            ;;
        "stop-daemon")
            stop_theme_daemon
            ;;
        "list")
            list_themes_with_variants
            ;;
        "status")
            show_theme_status
            ;;
        "configure")
            local feature="$2"
            local value="$3"
            configure_features "$feature" "$value"
            ;;
        "detect")
            echo "System theme: $(detect_system_theme)"
            echo "Battery status: $(get_battery_status)"
            echo "System load: $(get_system_load)%"
            ;;
        *)
            echo "Usage: $0 {apply|start-daemon|stop-daemon|list|status|configure|detect}"
            echo
            echo "Commands:"
            echo "  apply <theme>     Apply theme with dynamic adaptations"
            echo "  start-daemon      Start background theme monitoring"
            echo "  stop-daemon       Stop background theme monitoring"
            echo "  list              List available themes and variants"
            echo "  status            Show current theme status"
            echo "  configure <feature> <value>  Configure dynamic features"
            echo "  detect            Detect current system state"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
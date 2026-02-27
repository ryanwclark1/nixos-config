#!/usr/bin/env bash

# Hyprland keybindings display with auto-generated descriptions
# Dependencies: hyprctl, jq, rofi or walker
# Supports both rofi (default) and walker interfaces
# Usage: hyprland-keybindings.sh [--walker|-w] [--help|-h]

set -euo pipefail

# Configuration
NOTIFICATION_TIMEOUT="${HYPR_NOTIFICATION_TIMEOUT:-2000}"

# Check for required dependencies
check_dependencies() {
    local missing=()

    if ! command -v hyprctl >/dev/null 2>&1; then
        missing+=("hyprctl")
    fi

    if ! command -v jq >/dev/null 2>&1; then
        missing+=("jq")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Error: Missing required dependencies: ${missing[*]}" >&2
        echo "Please install: ${missing[*]}" >&2
        exit 1
    fi
}

# Detect available launcher
detect_launcher() {
    local requested="${1:-}"

    # Check for explicit walker request
    if [[ "$requested" == "--walker" || "$requested" == "-w" ]]; then
        if command -v walker >/dev/null 2>&1; then
            echo "walker"
            return 0
        else
            echo "Error: walker not found but requested via parameter." >&2
            exit 1
        fi
    fi

    # Auto-detect: prioritize rofi, fallback to walker
    if command -v rofi >/dev/null 2>&1; then
        echo "rofi"
        return 0
    elif command -v walker >/dev/null 2>&1; then
        echo "walker"
        return 0
    else
        echo "Error: Neither rofi nor walker found. Please install one of them." >&2
        exit 1
    fi
}

# Notification wrapper
notify() {
    local title="$1"
    local message="$2"
    local urgency="${3:-normal}"

    if command -v notify-send >/dev/null 2>&1; then
        notify-send -t "$NOTIFICATION_TIMEOUT" -u "$urgency" "$title" "$message" 2>/dev/null || true
    fi
}

# Get keybindings with auto-generated descriptions
get_keybindings() {
    local binds_json
    binds_json=$(hyprctl binds -j 2>/dev/null || echo "[]")

    if [[ -z "$binds_json" || "$binds_json" == "[]" ]]; then
        echo "Error: Failed to get keybindings from hyprctl" >&2
        return 1
    fi

    echo "$binds_json" | jq -r '
      def clean_nix_path: gsub("/nix/store/[^/]+/bin/"; "");

      def autogenerate_comment(dispatcher; params):
        if dispatcher == "killactive" then "Close window"
        elif dispatcher == "togglefloating" then "Float/unfloat window"
        elif dispatcher == "fullscreen" then
          if params == "0" then "Toggle fullscreen"
          elif params == "1" then "Toggle maximization"
          else "Toggle fullscreen" end
        elif dispatcher == "movefocus" then
          if params == "l" then "Focus window left"
          elif params == "r" then "Focus window right"
          elif params == "u" then "Focus window up"
          elif params == "d" then "Focus window down"
          else "Move focus " + params end
        elif dispatcher == "movewindow" then
          if params == "l" then "Move window left"
          elif params == "r" then "Move window right"
          elif params == "u" then "Move window up"
          elif params == "d" then "Move window down"
          else "Move window " + params end
        elif dispatcher == "resizeactive" then "Resize window by " + params
        elif dispatcher == "splitratio" then "Window split ratio " + params
        elif dispatcher == "workspace" then
          if params == "e+1" then "Next workspace"
          elif params == "e-1" then "Previous workspace"
          elif params == "previous" then "Previous workspace"
          else "Go to workspace " + params end
        elif dispatcher == "movetoworkspace" then
          if params == "e+1" then "Move window to next workspace"
          elif params == "e-1" then "Move window to previous workspace"
          else "Move window to workspace " + params end
        elif dispatcher == "togglespecialworkspace" then "Toggle special workspace"
        elif dispatcher == "swapsplit" then "Swap window split"
        elif dispatcher == "pseudo" then "Toggle pseudo tiling"
        elif dispatcher == "togglegroup" then "Toggle window group"
        elif dispatcher == "lockactivegroup" then "Lock/unlock active group"
        elif dispatcher == "exec" then
          if (params | test("rofi.*drun")) then "App launcher"
          elif (params | test("rofi.*show calc")) then "Calculator"
          elif (params | test("rofi.*emoji")) then "Emoji picker"
          elif (params | test("cliphist")) then "Clipboard history"
          elif (params | test("screenshot")) then "Screenshot menu"
          elif (params | test("powermenu")) then "Power menu"
          elif (params | test("keybindings")) then "Show keybindings"
          elif (params | test("web-search")) then "Web search"
          elif (params | test("kitty")) then "Open terminal"
          elif (params | test("google-chrome|chrome")) then "Open browser"
          elif (params | test("code")) then "Open VS Code"
          elif (params | test("nautilus")) then "Open file manager"
          elif (params | test("hyprlock")) then "Lock screen"
          elif (params | test("wlogout")) then "Logout menu"
          elif (params | test("swayosd-client.*volume")) then "Volume control"
          elif (params | test("swayosd-client.*brightness")) then "Brightness control"
          elif (params | test("playerctl")) then "Media control"
          elif (params | test("waybar")) then "Restart status bar"
          elif (params | test("hyprctl reload")) then "Reload Hyprland config"
          else "Execute: " + (params | clean_nix_path) end
        else dispatcher + " " + params
        end;

      def get_category(dispatcher; params):
        if dispatcher == "exec" then
          if (params | test("rofi|dmenu|cliphist|emoji|calc|web-search")) then "🔍 Menus & Search"
          elif (params | test("kitty|terminal")) then "💻 Terminal"
          elif (params | test("chrome|firefox|browser")) then "🌐 Browser"
          elif (params | test("code|cursor|editor")) then "📝 Editor"
          elif (params | test("screenshot|grimblast")) then "📸 Screenshot"
          elif (params | test("swayosd-client|playerctl|wpctl")) then "🔊 Media & Volume"
          elif (params | test("brightnessctl")) then "🔆 Brightness"
          elif (params | test("hyprlock|wlogout|powermenu")) then "🔐 System Control"
          elif (params | test("nautilus|file")) then "📁 File Manager"
          elif (params | test("waybar|hyprctl")) then "⚙️ System Management"
          else "🚀 Applications" end
        elif dispatcher == "killactive" then "❌ Window Control"
        elif (dispatcher | test("movewindow|resizeactive|movefocus|swapsplit|splitratio")) then "🪟 Window Management"
        elif (dispatcher | test("togglefloating|fullscreen|pseudo|togglegroup|lockactivegroup")) then "🪟 Window Management"
        elif (dispatcher | test("workspace|movetoworkspace|togglespecialworkspace")) then "🏠 Workspaces"
        else "⚙️ System Management"
        end;

      .[] |
      {
        dispatcher: .dispatcher,
        arg: .arg,
        key: .key,
        modmask: .modmask,
        combo: (if .modmask == 64 then "SUPER"
               elif .modmask == 8 then "ALT"
               elif .modmask == 4 then "CTRL"
               elif .modmask == 1 then "SHIFT"
               elif .modmask == 72 then "SUPER + ALT"
               elif .modmask == 68 then "SUPER + CTRL"
               elif .modmask == 65 then "SUPER + SHIFT"
               elif .modmask == 12 then "CTRL + ALT"
               elif .modmask == 9 then "SHIFT + ALT"
               elif .modmask == 5 then "SHIFT + CTRL"
               else (.modmask | tostring)
               end) + " + " + .key,
        description: autogenerate_comment(.dispatcher; .arg),
        category: get_category(.dispatcher; .arg)
      } | select(.description != "") |
      .combo + "\t" + .description + "\t" + .category
    ' 2>/dev/null | sort -k3,3 -k1,1 | awk -F'\t' '
      BEGIN { current_category = "" }
      {
        if ($3 != current_category) {
          if (current_category != "") print ""
          print "--- " $3 " ---"
          current_category = $3
        }
        print $1 "\r" $2
      }
    ' || return 1
}

# Create keybinding lookup table
create_lookup_table() {
    hyprctl binds -j 2>/dev/null | jq -r '.[] | .key + "\t" + (.modmask | tostring) + "\t" + .dispatcher + "\t" + (.arg // "null")' 2>/dev/null || echo ""
}

# Parse key combo to modmask and key
parse_key_combo() {
    local combo="$1"
    local modmask key

    # Remove leading/trailing whitespace
    combo=$(echo "$combo" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    # Parse modifier combinations (order matters - check longer combinations first)
    case "$combo" in
        "SUPER + ALT + "*)
            modmask="72"
            key=$(echo "$combo" | sed 's/SUPER + ALT + //' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            ;;
        "SUPER + CTRL + "*)
            modmask="68"
            key=$(echo "$combo" | sed 's/SUPER + CTRL + //' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            ;;
        "SUPER + SHIFT + "*)
            modmask="65"
            key=$(echo "$combo" | sed 's/SUPER + SHIFT + //' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            ;;
        "CTRL + ALT + "*)
            modmask="12"
            key=$(echo "$combo" | sed 's/CTRL + ALT + //' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            ;;
        "SHIFT + ALT + "*)
            modmask="9"
            key=$(echo "$combo" | sed 's/SHIFT + ALT + //' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            ;;
        "SHIFT + CTRL + "*)
            modmask="5"
            key=$(echo "$combo" | sed 's/SHIFT + CTRL + //' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            ;;
        "SUPER + "*)
            modmask="64"
            key=$(echo "$combo" | sed 's/SUPER + //' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            ;;
        "ALT + "*)
            modmask="8"
            key=$(echo "$combo" | sed 's/ALT + //' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            ;;
        "CTRL + "*)
            modmask="4"
            key=$(echo "$combo" | sed 's/CTRL + //' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            ;;
        "SHIFT + "*)
            modmask="1"
            key=$(echo "$combo" | sed 's/SHIFT + //' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            ;;
        *)
            modmask="0"
            key="$combo"
            ;;
    esac

    echo "$modmask|$key"
}

# Execute keybinding
execute_keybinding() {
    local key_combo="$1"
    local lookup_table="$2"

    # Parse the key combo
    local parsed
    parsed=$(parse_key_combo "$key_combo")
    local modmask key
    modmask=$(echo "$parsed" | cut -d'|' -f1)
    key=$(echo "$parsed" | cut -d'|' -f2)

    if [[ -z "$modmask" || -z "$key" ]]; then
        notify "Keybinding" "Failed to parse key combination: $key_combo" "critical"
        return 1
    fi

    # Find matching binding
    local binding_info
    binding_info=$(echo "$lookup_table" | awk -F'\t' -v key="$key" -v mask="$modmask" '$1 == key && $2 == mask {print $3 "\t" $4}' | head -n1)

    if [[ -z "$binding_info" ]]; then
        notify "Keybinding" "Could not find binding for: $key_combo" "normal"
        return 1
    fi

    local dispatcher arg
    dispatcher=$(echo "$binding_info" | cut -f1)
    arg=$(echo "$binding_info" | cut -f2)

    # Execute the binding
    if [[ -n "$arg" && "$arg" != "null" && "$arg" != "" ]]; then
        if hyprctl dispatch "$dispatcher" "$arg" &>/dev/null; then
            return 0
        else
            notify "Keybinding" "Failed to execute: $dispatcher $arg" "critical"
            return 1
        fi
    else
        if hyprctl dispatch "$dispatcher" &>/dev/null; then
            return 0
        else
            notify "Keybinding" "Failed to execute: $dispatcher" "critical"
            return 1
        fi
    fi
}

# Display keybindings with rofi
display_rofi() {
    local keybinds="$1"
    local formatted

    formatted=$(echo "$keybinds" | sed -E \
        -e 's/\t/ → /' \
        -e 's/\r/ /')

    rofi -dmenu -i -markup -eh 2 -replace -p "Keybinds" <<< "$formatted" || echo ""
}

# Display keybindings with walker
display_walker() {
    local keybinds="$1"
    local formatted

    formatted=$(echo "$keybinds" | sed -E \
        -e 's/\t/ → /' \
        -e 's/--- (.+) ---/\n# \1:/' \
        -e '/^$/d')

    walker --dmenu -p 'Hyprland Keybindings' <<< "$formatted" || echo ""
}

# Usage information
usage() {
    cat << EOF
Hyprland Keybindings Display

Usage: $0 [OPTIONS]

Options:
    -w, --walker    Use walker instead of rofi
    -h, --help      Show this help message

Environment Variables:
    HYPR_NOTIFICATION_TIMEOUT    Notification duration (default: 2000ms)

Description:
    Displays all Hyprland keybindings in a searchable menu. Selecting a
    keybinding will execute it. Keybindings are automatically categorized
    and include human-readable descriptions.

Examples:
    $0
    $0 --walker
    $0 -w
EOF
}

# Main function
main() {
    local launcher_arg="${1:-}"

    # Handle help
    if [[ "$launcher_arg" == "-h" || "$launcher_arg" == "--help" ]]; then
        usage
        exit 0
    fi

    # Check dependencies
    check_dependencies

    # Detect launcher
    local launcher
    launcher=$(detect_launcher "$launcher_arg")

    # Get keybindings
    local organized_keybinds
    organized_keybinds=$(get_keybindings)

    if [[ -z "$organized_keybinds" ]]; then
        echo "Error: No keybindings found or failed to process keybindings." >&2
        exit 1
    fi

    # Create lookup table for execution
    local keybind_lookup
    keybind_lookup=$(create_lookup_table)

    # Display and get selection
    local selected=""
    if [[ "$launcher" == "walker" ]]; then
        selected=$(display_walker "$organized_keybinds")
    else
        selected=$(display_rofi "$organized_keybinds")
    fi

    # Execute selected keybinding
    if [[ -n "$selected" && ! "$selected" =~ ^(---|#) ]]; then
        # Extract the key combination from the selected line
        local key_combo
        key_combo=$(echo "$selected" | sed 's/ →.*//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

        if [[ -n "$key_combo" ]]; then
            execute_keybinding "$key_combo" "$keybind_lookup"
        fi
    fi
}

main "$@"

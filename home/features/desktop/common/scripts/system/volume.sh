#!/usr/bin/env bash

# -----------------------------------------------------
# System Volume Control Script
# PipeWire/WirePlumber volume management with rofi interface
# -----------------------------------------------------
#
# This script provides volume control using wpctl by default
# SwayOSD is used for display notifications when available
# Compatible with any window manager that supports rofi
# Uses PipeWire/WirePlumber for audio management
# -----------------------------------------------------

set -euo pipefail

# Configuration
SCRIPT_NAME="$(basename "$0")"
DEFAULT_ROFI_THEME="${HOME}/.config/rofi/applets/type-3/style-3.rasi"
PATH="/run/current-system/sw/bin:/usr/bin:$PATH"

# Dependency check function
check_dependencies() {
    local missing_deps=()

    # Core dependencies
    command -v wpctl >/dev/null || missing_deps+=("wpctl (wireplumber)")

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo "Error: Missing required dependencies:" >&2
        printf "  - %s\n" "${missing_deps[@]}" >&2
        echo "Please install the missing packages and try again." >&2
        exit 1
    fi
}

# Logging function
log() {
    echo "[$SCRIPT_NAME] $1" >&2
}

# Notification function using notify-send with nerd font icons
notify_volume() {
    local title="$1"
    local message="$2"
    local icon="$3"

    if command -v notify-send >/dev/null; then
        notify-send "$icon $title" "$message" -t 1000
    fi

    # Also send to SwayOSD if available for consistent display
    if command -v swayosd-client >/dev/null; then
        case "$icon" in
            "󰝝") swayosd-client --output-volume raise --max-volume 100 >/dev/null 2>&1 || true ;;
            "󰝞") swayosd-client --output-volume lower --max-volume 100 >/dev/null 2>&1 || true ;;
            "󰝟") swayosd-client --output-volume mute-toggle >/dev/null 2>&1 || true ;;
        esac
    fi
}

# Get audio device volumes and mute status
get_audio_info() {
    # Get volumes (convert decimal to percentage)
    local speaker_vol mic_vol speaker_mute mic_mute

    speaker_vol="$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print int($2 * 100)}')" || speaker_vol="0"
    mic_vol="$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | awk '{print int($2 * 100)}')" || mic_vol="0"

    speaker_mute="$(wpctl get-mute @DEFAULT_AUDIO_SINK@ 2>/dev/null)" || speaker_mute="[Muted: no]"
    mic_mute="$(wpctl get-mute @DEFAULT_AUDIO_SOURCE@ 2>/dev/null)" || mic_mute="[Muted: no]"

    # Export variables for use in other functions
    export SPEAKER_VOL="$speaker_vol"
    export MIC_VOL="$mic_vol"
    export SPEAKER_MUTE="$speaker_mute"
    export MIC_MUTE="$mic_mute"
}

# Get rofi theme configuration
get_theme_config() {
    local theme="${1:-$DEFAULT_ROFI_THEME}"

    # Default theme configuration
    local list_col="1"
    local list_row="5"
    local win_width="400px"

    # Detect theme type and adjust layout
    if [[ "$theme" == *'type-1'* ]]; then
        list_col='1'; list_row='5'; win_width='400px'
    elif [[ "$theme" == *'type-3'* ]]; then
        list_col='1'; list_row='5'; win_width='120px'
    elif [[ "$theme" == *'type-5'* ]]; then
        list_col='1'; list_row='5'; win_width='520px'
    elif [[ "$theme" == *'type-2'* || "$theme" == *'type-4'* ]]; then
        list_col='5'; list_row='1'; win_width='670px'
    fi

    # Check if theme uses icons or text
    local use_icons="YES"
    if [[ -f "$theme" ]]; then
        local layout
        layout=$(grep 'USE_ICON' "$theme" 2>/dev/null | cut -d'=' -f2 || echo "YES")
        use_icons="$layout"
    fi

    # Export theme config
    export THEME_FILE="$theme"
    export LIST_COL="$list_col"
    export LIST_ROW="$list_row"
    export WIN_WIDTH="$win_width"
    export USE_ICONS="$use_icons"
}

# Build rofi options based on current state
build_rofi_options() {
    get_audio_info
    get_theme_config  # Initialize theme config including USE_ICONS

    # Clear status indicators - green for active/good, red for muted/bad
    local active_args="" urgent_args=""

    # Simple clean options - just show volume levels
    if [[ "$USE_ICONS" == "NO" ]]; then
        OPTION_1="󰝝 Volume Up"
        OPTION_2="󰝞 Volume Down"
        OPTION_3="$([ "$SPEAKER_MUTE" == *"Muted"* ] && echo "󰖁 Unmute" || echo "󰕿 Mute")"
        OPTION_4="󰍬 Mic Toggle"
        OPTION_5="󰍃 Settings"
    else
        OPTION_1="󰝝"
        OPTION_2="󰝞"
        OPTION_3="$([ "$SPEAKER_MUTE" == *"Muted"* ] && echo "󰖁" || echo "󰕿")"
        OPTION_4="󰍬"
        OPTION_5="󰍃"
    fi

    # Simple highlighting
    if [[ "$SPEAKER_MUTE" == *"Muted"* ]]; then
        urgent_args="-u 2"
    fi

    # Export options for use in main function
    export OPTION_1 OPTION_2 OPTION_3 OPTION_4 OPTION_5

    # Export for rofi command
    export ROFI_PROMPT="Audio Control"
    export ROFI_MESSAGE="Speaker: ${SPEAKER_VOL}% • Mic: ${MIC_VOL}%"
    export ROFI_ACTIVE="$active_args"
    export ROFI_URGENT="$urgent_args"
}

# Execute rofi command
run_rofi() {
    # Check rofi dependency for GUI mode
    command -v rofi >/dev/null || {
        echo "Error: rofi is required for GUI mode" >&2
        exit 1
    }

    build_rofi_options  # This now calls get_theme_config internally

    local rofi_cmd=(
        rofi
        -theme-str "window {width: $WIN_WIDTH;}"
        -theme-str "listview {columns: $LIST_COL; lines: $LIST_ROW;}"
        -theme-str 'textbox-prompt-colon {str: "";}'
        -dmenu
        -p "$ROFI_PROMPT"
        -mesg "$ROFI_MESSAGE"
        -markup-rows
    )

    # Add active/urgent flags if they exist
    [[ -n "$ROFI_ACTIVE" ]] && rofi_cmd+=($ROFI_ACTIVE)
    [[ -n "$ROFI_URGENT" ]] && rofi_cmd+=($ROFI_URGENT)

    # Add theme if it exists
    [[ -f "$THEME_FILE" ]] && rofi_cmd+=(-theme "$THEME_FILE")

    # Run rofi with options
    echo -e "$OPTION_1\n$OPTION_2\n$OPTION_3\n$OPTION_4\n$OPTION_5" | "${rofi_cmd[@]}"
}

# Execute volume commands with wpctl as default
execute_action() {
    local action="$1"
    local result=0

    case "$action" in
        "increase")
            log "Increasing volume via wpctl"
            # Ensure unmuted and increase volume
            if wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 && wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+ 2>/dev/null; then
                get_audio_info
                notify_volume "Volume" "$(wpctl get-volume @DEFAULT_AUDIO_SINK@)" ""
                log "Volume increased to ${SPEAKER_VOL}%"
            else
                log "Failed to increase volume"
                result=1
            fi
            ;;
        "decrease")
            log "Decreasing volume via wpctl"
            if wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- 2>/dev/null; then
                get_audio_info
                notify_volume "Volume" "$(wpctl get-volume @DEFAULT_AUDIO_SINK@)" ""
                log "Volume decreased to ${SPEAKER_VOL}%"
            else
                log "Failed to decrease volume"
                result=1
            fi
            ;;
        "toggle_speaker")
            log "Toggling speaker mute via wpctl"
            if wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle 2>/dev/null; then
                get_audio_info
                if [[ "$SPEAKER_MUTE" == *"Muted"* ]]; then
                    notify_volume "Audio" "Muted" "󰝟"
                    log "Speaker muted"
                else
                    notify_volume "Audio" "Unmuted" ""
                    log "Speaker unmuted"
                fi
            else
                log "Failed to toggle speaker mute"
                result=1
            fi
            ;;
        "toggle_mic")
            log "Toggling microphone mute via wpctl"
            if wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle 2>/dev/null; then
                get_audio_info
                if [[ "$MIC_MUTE" == *"Muted"* ]]; then
                    notify_volume "Audio" "Microphone muted" "󰍭"
                    log "Microphone muted"
                else
                    notify_volume "Audio" "Microphone unmuted" "󰍬"
                    log "Microphone unmuted"
                fi
            else
                log "Failed to toggle microphone mute"
                result=1
            fi
            ;;
        "mic_increase")
            log "Increasing microphone volume via wpctl"
            if wpctl set-volume -l 1 @DEFAULT_AUDIO_SOURCE@ 5%+ 2>/dev/null; then
                get_audio_info
                notify_volume "Microphone" "$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@)" "󰍬"
                log "Microphone volume increased to ${MIC_VOL}%"
            else
                log "Failed to increase microphone volume"
                result=1
            fi
            ;;
        "mic_decrease")
            log "Decreasing microphone volume via wpctl"
            if wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 5%- 2>/dev/null; then
                get_audio_info
                notify_volume "Microphone" "$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@)" "󰍬"
                log "Microphone volume decreased to ${MIC_VOL}%"
            else
                log "Failed to decrease microphone volume"
                result=1
            fi
            ;;
        "settings")
            # Try different audio control applications
            local audio_settings=()
            command -v pwvucontrol >/dev/null && audio_settings+=(pwvucontrol)
            command -v pavucontrol >/dev/null && audio_settings+=(pavucontrol)
            command -v qpwgraph >/dev/null && audio_settings+=(qpwgraph)

            if [[ ${#audio_settings[@]} -gt 0 ]]; then
                log "Opening audio settings with ${audio_settings[0]}"
                "${audio_settings[0]}" &
            else
                notify_volume "Error" "No audio settings application found" ""
                log "No audio settings application found"
                result=1
            fi
            ;;
        *)
            log "Unknown action: $action"
            result=1
            ;;
    esac

    return $result
}

# Show usage information
usage() {
    cat << EOF
System Volume Control Script

Usage: $0 [COMMAND]

Commands:
    increase      Increase speaker volume by 5% (default)
    decrease      Decrease speaker volume by 5%
    toggle        Toggle speaker mute
    toggle-mic    Toggle microphone mute
    mic-up        Increase microphone volume by 5%
    mic-down      Decrease microphone volume by 5%
    gui           Show rofi volume interface
    status        Show current audio status
    settings      Open audio settings
    help          Show this help

Examples:
    $0              # Increase volume (default)
    $0 decrease     # Decrease volume
    $0 toggle       # Toggle mute
    $0 gui          # Show rofi interface
    $0 status       # Show volume info

Dependencies:
    - wpctl (wireplumber)
    - notify-send (optional, for notifications)
    - rofi (optional, for GUI mode)
    - swayosd-client (optional, for display notifications)
EOF
}

# Show current audio status
show_status() {
    get_audio_info

    local speaker_status="unmuted" mic_status="unmuted"
    [[ "$SPEAKER_MUTE" == *"Muted"* ]] && speaker_status="muted"
    [[ "$MIC_MUTE" == *"Muted"* ]] && mic_status="muted"

    cat << EOF
Audio Status:
  Speaker: ${SPEAKER_VOL}% ($speaker_status)
  Microphone: ${MIC_VOL}% ($mic_status)
EOF
}

# Main function
main() {
    local command="${1:-increase}"  # Default to increase instead of gui

    # Handle help first (no dependency check needed)
    if [[ "$command" == "help" || "$command" == "-h" || "$command" == "--help" ]]; then
        usage
        exit 0
    fi

    # Check dependencies for all other commands
    check_dependencies

    case "$command" in
        "gui")
            local choice
            choice=$(run_rofi)

            # Build options to ensure they're available for comparison
            build_rofi_options

            case "$choice" in
                "$OPTION_1") execute_action "increase" ;;
                "$OPTION_2") execute_action "decrease" ;;
                "$OPTION_3") execute_action "toggle_speaker" ;;
                "$OPTION_4") execute_action "toggle_mic" ;;
                "$OPTION_5") execute_action "settings" ;;
                "") log "No option selected" ;;
                *) log "Unknown option: $choice" ;;
            esac
            ;;
        "increase"|"inc"|"+")
            execute_action "increase"
            ;;
        "decrease"|"dec"|"-")
            execute_action "decrease"
            ;;
        "toggle"|"mute")
            execute_action "toggle_speaker"
            ;;
        "toggle-mic"|"mic")
            execute_action "toggle_mic"
            ;;
        "mic-up"|"mic-increase"|"mic+")
            execute_action "mic_increase"
            ;;
        "mic-down"|"mic-decrease"|"mic-")
            execute_action "mic_decrease"
            ;;
        "settings")
            execute_action "settings"
            ;;
        "status")
            show_status
            ;;
        *)
            echo "Error: Unknown command '$command'" >&2
            echo "Use '$0 help' for usage information" >&2
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"

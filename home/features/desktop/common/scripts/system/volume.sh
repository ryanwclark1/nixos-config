#!/usr/bin/env bash

# -----------------------------------------------------
# System Volume Control Script  
# PipeWire/WirePlumber volume management with rofi interface
# -----------------------------------------------------
# 
# This script provides a rofi-based interface for volume control
# Compatible with any window manager that supports rofi
# Uses PipeWire/WirePlumber for audio management
# -----------------------------------------------------

set -euo pipefail

# Configuration
SCRIPT_NAME="$(basename "$0")"
DEFAULT_ROFI_THEME="${HOME}/.config/rofi/applets/type-3/style-3.rasi"

# Dependency check function
check_dependencies() {
    local missing_deps=()
    
    # Core dependencies
    command -v wpctl >/dev/null || missing_deps+=("wpctl (wireplumber)")
    command -v rofi >/dev/null || missing_deps+=("rofi")
    command -v awk >/dev/null || missing_deps+=("awk")
    
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

# Notification wrapper
notify() {
    if command -v notify-send >/dev/null; then
        notify-send -t 2000 "$@"
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
    
    local active_args="" urgent_args=""
    local speaker_text speaker_icon mic_text mic_icon
    
    # Speaker status
    if [[ "$SPEAKER_MUTE" == *"Muted"* ]]; then
        urgent_args="-u 1"
        speaker_text="Mute"
        speaker_icon="󰖁"  # Muted speaker icon
    else
        active_args="-a 1"
        speaker_text="Unmute" 
        speaker_icon="󰕿"  # Speaker icon
    fi
    
    # Microphone status
    if [[ "$MIC_MUTE" == *"Muted"* ]]; then
        [[ -n "$urgent_args" ]] && urgent_args+=",3" || urgent_args="-u 3"
        mic_text="Mute"
        mic_icon="󰍭"  # Muted mic icon
    else
        [[ -n "$active_args" ]] && active_args+=",3" || active_args="-a 3"
        mic_text="Unmute"
        mic_icon="󰍬"  # Mic icon
    fi
    
    # Build option strings
    if [[ "$USE_ICONS" == "NO" ]]; then
        OPTION_1="󰝝 Increase Volume"
        OPTION_2="$speaker_icon $speaker_text Speaker" 
        OPTION_3="󰝞 Decrease Volume"
        OPTION_4="$mic_icon $mic_text Microphone"
        OPTION_5="󰍃 Audio Settings"
    else
        OPTION_1="󰝝"
        OPTION_2="$speaker_icon"
        OPTION_3="󰝞" 
        OPTION_4="$mic_icon"
        OPTION_5="󰍃"
    fi
    
    # Export for rofi command
    export ROFI_PROMPT="Speaker: $speaker_text, Mic: $mic_text"
    export ROFI_MESSAGE="Volume - Speaker: ${SPEAKER_VOL}%, Microphone: ${MIC_VOL}%"
    export ROFI_ACTIVE="$active_args"
    export ROFI_URGENT="$urgent_args"
}

# Execute rofi command  
run_rofi() {
    build_rofi_options
    get_theme_config
    
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

# Execute volume commands
execute_action() {
    local action="$1"
    local result=0
    
    case "$action" in
        "increase")
            if wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ 2>/dev/null; then
                get_audio_info
                notify "Volume" "Increased to ${SPEAKER_VOL}%"
                log "Volume increased to ${SPEAKER_VOL}%"
            else
                log "Failed to increase volume"
                result=1
            fi
            ;;
        "decrease")
            if wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- 2>/dev/null; then
                get_audio_info
                notify "Volume" "Decreased to ${SPEAKER_VOL}%"
                log "Volume decreased to ${SPEAKER_VOL}%"
            else
                log "Failed to decrease volume" 
                result=1
            fi
            ;;
        "toggle_speaker")
            if wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle 2>/dev/null; then
                get_audio_info
                if [[ "$SPEAKER_MUTE" == *"Muted"* ]]; then
                    notify "Audio" "Speaker muted"
                    log "Speaker muted"
                else
                    notify "Audio" "Speaker unmuted (${SPEAKER_VOL}%)"
                    log "Speaker unmuted"
                fi
            else
                log "Failed to toggle speaker mute"
                result=1
            fi
            ;;
        "toggle_mic")
            if wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle 2>/dev/null; then
                get_audio_info
                if [[ "$MIC_MUTE" == *"Muted"* ]]; then
                    notify "Audio" "Microphone muted"
                    log "Microphone muted"
                else
                    notify "Audio" "Microphone unmuted (${MIC_VOL}%)"
                    log "Microphone unmuted"
                fi
            else
                log "Failed to toggle microphone mute"
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
                notify "Error" "No audio settings application found"
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
    gui           Show rofi volume interface (default)
    increase      Increase volume by 5%
    decrease      Decrease volume by 5%
    toggle        Toggle speaker mute
    toggle-mic    Toggle microphone mute
    status        Show current audio status
    settings      Open audio settings
    help          Show this help

Examples:
    $0              # Show rofi interface
    $0 increase     # Increase volume
    $0 toggle       # Toggle mute
    $0 status       # Show volume info

Dependencies:
    - wpctl (wireplumber)
    - rofi
    - awk
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
    local command="${1:-gui}"
    
    # Handle help first (no dependency check needed)
    if [[ "$command" == "help" || "$command" == "-h" || "$command" == "--help" ]]; then
        usage
        exit 0
    fi
    
    # Check dependencies for all other commands
    check_dependencies
    
    case "$command" in
        "gui"|"")
            local choice
            choice=$(run_rofi)
            
            case "$choice" in
                "$OPTION_1") execute_action "increase" ;;
                "$OPTION_2") execute_action "toggle_speaker" ;;
                "$OPTION_3") execute_action "decrease" ;;
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
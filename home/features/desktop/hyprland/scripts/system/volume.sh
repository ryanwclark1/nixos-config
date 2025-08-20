#!/usr/bin/env bash

## Applets : Volume (PipeWire)

# Import Current Theme
# source "$HOME"/.config/rofi/applets/shared/theme.bash
type="$HOME/.config/rofi/applets/type-3"
style='style-3.rasi'
theme="$type/$style"

# Volume Info (Using PipeWire)
speaker_vol="$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}')"
mic_vol="$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | awk '{print int($2 * 100)}')"

speaker_mute="$(wpctl get-mute @DEFAULT_AUDIO_SINK@)"
mic_mute="$(wpctl get-mute @DEFAULT_AUDIO_SOURCE@)"

active=""
urgent=""

# Speaker Info
if [[ "$speaker_mute" == "Muted" ]]; then
    urgent="-u 1"
    stext="Mute"
    sicon="󰖁 "
else
    active="-a 1"
    stext="Unmute"
    sicon="󰕿 "
fi

# Microphone Info
if [[ "$mic_mute" == "Muted" ]]; then
    [ -n "$urgent" ] && urgent+=",3" || urgent="-u 3"
    mtext="Mute"
    micon="󰍭 "
else
    [ -n "$active" ] && active+=",3" || active="-a 3"
    mtext="Unmute"
    micon="󰍬 "
fi

# Theme Elements
prompt="S:$stext, M:$mtext"
mesg="Speaker: ${speaker_vol}%, Mic: ${mic_vol}%"

# Theme Configurations
if [[ "$theme" == *'type-1'* ]]; then
    list_col='1'
    list_row='5'
    win_width='400px'
elif [[ "$theme" == *'type-3'* ]]; then
    list_col='1'
    list_row='5'
    win_width='120px'
elif [[ "$theme" == *'type-5'* ]]; then
    list_col='1'
    list_row='5'
    win_width='520px'
elif [[ "$theme" == *'type-2'* || "$theme" == *'type-4'* ]]; then
    list_col='5'
    list_row='1'
    win_width='670px'
fi

# Options
layout=$(grep 'USE_ICON' "$theme" | cut -d'=' -f2)
if [[ "$layout" == "NO" ]]; then
    option_1="󰝝  Increase"
    option_2="$sicon $stext"
    option_3="󰝞  Decrease"
    option_4="$micon $mtext"
    option_5="  Settings"
else
    option_1="󰝝 "
    option_2="$sicon"
    option_3="󰝞 "
    option_4="$micon"
    option_5=" "
fi

# Rofi CMD
rofi_cmd() {
    rofi -theme-str "window {width: $win_width;}" \
        -theme-str "listview {columns: $list_col; lines: $list_row;}" \
        -theme-str 'textbox-prompt-colon {str: "";}' \
        -dmenu \
        -p "$prompt" \
        -mesg "$mesg" \
        $active $urgent \
        -markup-rows \
        -theme "$theme"
}

# Run Rofi
run_rofi() {
    echo -e "$option_1\n$option_2\n$option_3\n$option_4\n$option_5" | rofi_cmd
}

# Execute Command
run_cmd() {
    case "$1" in
        "--opt1")
            wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
            ;;
        "--opt2")
            wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
            ;;
        "--opt3")
            wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
            ;;
        "--opt4")
            wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
            ;;
        "--opt5")
            pwvucontrol
            ;;
    esac
}

# Handle Actions
chosen="$(run_rofi)"
case $chosen in
    "$option_1") run_cmd --opt1 ;;
    "$option_2") run_cmd --opt2 ;;
    "$option_3") run_cmd --opt3 ;;
    "$option_4") run_cmd --opt4 ;;
    "$option_5") run_cmd --opt5 ;;
esac

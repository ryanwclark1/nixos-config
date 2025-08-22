#!/usr/bin/env bash

## MPD Control Menu

# Check MPD status
status="$(mpc status 2>/dev/null)"
if [[ -z "$status" ]]; then
	prompt='MPD Offline'
	mesg="MPD is not running"
	OFFLINE=true
else
	current_song="$(mpc -f "%artist% - %title%" current 2>/dev/null)"
	if [[ -n "$current_song" ]]; then
		prompt="$current_song"
	else
		prompt="MPD2"
	fi
	position="$(mpc status | grep "#" | awk '{print $3}' 2>/dev/null)"
	if [[ -n "$position" ]]; then
		mesg="Position: $position"
	else
		mesg="Ready"
	fi
	OFFLINE=false
fi

# Icons using Nerd Font symbols
PLAY_ICON="󰐊"
PAUSE_ICON="󰏤"
STOP_ICON="󰓛"
PREV_ICON="󰒮"
NEXT_ICON="󰒭"
REPEAT_ICON="󰑖"
RANDOM_ICON="󰒝"

# Options with icons
if [[ "$OFFLINE" == true ]]; then
	option_1="$PLAY_ICON Start MPD"
	option_2=""
	option_3=""
	option_4=""
	option_5=""
	option_6=""
else
	if [[ $status == *"[playing]"* ]]; then
		option_1="$PAUSE_ICON Pause"
	else
		option_1="$PLAY_ICON Play"
	fi
	option_2="$STOP_ICON Stop"
	option_3="$PREV_ICON Previous"
	option_4="$NEXT_ICON Next"
	option_5="$REPEAT_ICON Repeat"
	option_6="$RANDOM_ICON Random"
fi

# Toggle Actions for visual feedback
active=""
urgent=""

# Only check repeat/random if MPD is online
if [[ "$OFFLINE" == false ]]; then
	# Repeat
	if [[ $status == *"repeat: on"* ]]; then
		active="-a 4"
	elif [[ $status == *"repeat: off"* ]]; then
		urgent="-u 4"
	fi

	# Random
	if [[ $status == *"random: on"* ]]; then
		[ -n "$active" ] && active+=",5" || active="-a 5"
	elif [[ $status == *"random: off"* ]]; then
		[ -n "$urgent" ] && urgent+=",5" || urgent="-u 5"
	fi
fi

# Rofi CMD with consistent styling
rofi_cmd() {
	rofi -dmenu -i -p "$prompt" -mesg "$mesg" \
		$active $urgent \
		-theme-str 'listview { lines: 6; spacing: 5px; }' \
		-theme-str 'inputbar { children: [prompt,textbox-prompt-colon,entry]; margin: 0px 0px 2px 0px; border: 0px 0px 2px 0px; border-color: @selected-normal-foreground; }' \
		-theme-str 'window { width: 400px; }' \
		-theme-str 'element { padding: 8px; border-radius: 4px; }'
}

# Pass variables to rofi dmenu
run_rofi() {
	if [[ "$OFFLINE" == true ]]; then
		echo -e "$option_1" | rofi_cmd
	else
		echo -e "$option_1\n$option_2\n$option_3\n$option_4\n$option_5\n$option_6" | rofi_cmd
	fi
}

# Execute Command
run_cmd() {
	case "$1" in
		'play_pause')
			if [[ "$OFFLINE" == true ]]; then
				# Try to start MPD
				systemctl --user start mpd 2>/dev/null || mpd 2>/dev/null
				notify-send -u low -t 2000 "󰝚 MPD" "Starting MPD..."
			else
				mpc -q toggle && notify-send -u low -t 1000 "󰝚 $(mpc current 2>/dev/null || echo 'MPD')"
			fi
			;;
		'stop')
			mpc -q stop
			notify-send -u low -t 1000 "󰓛 MPD" "Stopped"
			;;
		'prev')
			mpc -q prev && notify-send -u low -t 1000 "󰒮 $(mpc current 2>/dev/null || echo 'MPD')"
			;;
		'next')
			mpc -q next && notify-send -u low -t 1000 "󰒭 $(mpc current 2>/dev/null || echo 'MPD')"
			;;
		'repeat')
			mpc -q repeat
			if mpc status | grep -q "repeat: on"; then
				notify-send -u low -t 1000 "󰑖 MPD" "Repeat: ON"
			else
				notify-send -u low -t 1000 "󰑖 MPD" "Repeat: OFF"
			fi
			;;
		'random')
			mpc -q random
			if mpc status | grep -q "random: on"; then
				notify-send -u low -t 1000 "󰒝 MPD" "Random: ON"
			else
				notify-send -u low -t 1000 "󰒝 MPD" "Random: OFF"
			fi
			;;
	esac
}

# Actions
chosen="$(run_rofi)"
case $chosen in
	*"$PLAY_ICON"*|*"$PAUSE_ICON"*)
		run_cmd 'play_pause'
		;;
	*"$STOP_ICON"*)
		run_cmd 'stop'
		;;
	*"$PREV_ICON"*)
		run_cmd 'prev'
		;;
	*"$NEXT_ICON"*)
		run_cmd 'next'
		;;
	*"$REPEAT_ICON"*)
		run_cmd 'repeat'
		;;
	*"$RANDOM_ICON"*)
		run_cmd 'random'
		;;
esac

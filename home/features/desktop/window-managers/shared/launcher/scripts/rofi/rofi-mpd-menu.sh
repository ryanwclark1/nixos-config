#!/usr/bin/env bash
set -eu

## MPD Control Menu

# Find and source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROFI_HELPERS=""
MPD_CONTROL=""

if [[ -f "$HOME/.local/bin/scripts/system/os-rofi-helpers.sh" ]]; then
    ROFI_HELPERS="$HOME/.local/bin/scripts/system/os-rofi-helpers.sh"
elif [[ -f "$SCRIPT_DIR/../../../../common/scripts/system/os-rofi-helpers.sh" ]]; then
    ROFI_HELPERS="$SCRIPT_DIR/../../../../common/scripts/system/os-rofi-helpers.sh"
fi

if [[ -f "$HOME/.local/bin/scripts/system/os-mpd-control.sh" ]]; then
    MPD_CONTROL="$HOME/.local/bin/scripts/system/os-mpd-control.sh"
elif [[ -f "$SCRIPT_DIR/../../../../common/scripts/system/os-mpd-control.sh" ]]; then
    MPD_CONTROL="$SCRIPT_DIR/../../../../common/scripts/system/os-mpd-control.sh"
fi

if [[ -n "$ROFI_HELPERS" ]]; then
    # shellcheck source=/dev/null
    source "$ROFI_HELPERS"
fi

if [[ -n "$MPD_CONTROL" ]]; then
    # shellcheck source=/dev/null
    source "$MPD_CONTROL"
fi

# Check dependencies
if command -v check_rofi >/dev/null 2>&1; then
    check_rofi || exit 1
else
    if ! command -v rofi >/dev/null 2>&1; then
        echo "Error: rofi not found" >&2
        exit 1
    fi
fi

if command -v check_mpd >/dev/null 2>&1; then
    check_mpd || exit 1
else
    if ! command -v mpc >/dev/null 2>&1; then
        echo "Error: mpc (MPD client) not found" >&2
        exit 1
    fi
fi

# Check MPD status using shared functions if available
if command -v is_mpd_running >/dev/null 2>&1; then
    if is_mpd_running; then
        OFFLINE=false
        status=$(get_mpd_status)
        current_song=$(get_mpd_current_song)
        position=$(get_mpd_position)
    else
        OFFLINE=true
        status=""
        current_song=""
        position=""
    fi
else
    # Fallback to direct mpc calls
    status="$(mpc status 2>/dev/null)"
    if [[ -z "$status" ]]; then
        OFFLINE=true
    else
        OFFLINE=false
        current_song="$(mpc -f "%artist% - %title%" current 2>/dev/null)"
        position="$(mpc status | grep "#" | awk '{print $3}' 2>/dev/null)"
    fi
fi

if [[ "$OFFLINE" == true ]]; then
	prompt='MPD Offline'
	mesg="MPD is not running"
else
	if [[ -n "$current_song" ]]; then
		prompt="$current_song"
	else
		prompt="MPD2"
	fi
	if [[ -n "$position" ]]; then
		mesg="Position: $position"
	else
		mesg="Ready"
	fi
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
	if command -v is_mpd_repeat_on >/dev/null 2>&1; then
		if is_mpd_repeat_on; then
			active="-a 4"
		else
			urgent="-u 4"
		fi
	else
		# Fallback
		if [[ $status == *"repeat: on"* ]]; then
			active="-a 4"
		elif [[ $status == *"repeat: off"* ]]; then
			urgent="-u 4"
		fi
	fi

	# Random
	if command -v is_mpd_random_on >/dev/null 2>&1; then
		if is_mpd_random_on; then
			[ -n "$active" ] && active+=",5" || active="-a 5"
		else
			[ -n "$urgent" ] && urgent+=",5" || urgent="-u 5"
		fi
	else
		# Fallback
		if [[ $status == *"random: on"* ]]; then
			[ -n "$active" ] && active+=",5" || active="-a 5"
		elif [[ $status == *"random: off"* ]]; then
			[ -n "$urgent" ] && urgent+=",5" || urgent="-u 5"
		fi
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
				# Try to start MPD using shared function if available
				if command -v start_mpd >/dev/null 2>&1; then
					start_mpd
				else
					systemctl --user start mpd 2>/dev/null || mpd 2>/dev/null
				fi
				notify-send -u low -t 2000 "󰝚 MPD" "Starting MPD..."
			else
				if command -v mpd_toggle >/dev/null 2>&1; then
					mpd_toggle
				else
					mpc -q toggle
				fi
				local current
				if command -v get_mpd_current_song >/dev/null 2>&1; then
					current=$(get_mpd_current_song || echo "MPD")
				else
					current=$(mpc current 2>/dev/null || echo "MPD")
				fi
				notify-send -u low -t 1000 "󰝚 $current"
			fi
			;;
		'stop')
			if command -v mpd_stop >/dev/null 2>&1; then
				mpd_stop
			else
				mpc -q stop
			fi
			notify-send -u low -t 1000 "󰓛 MPD" "Stopped"
			;;
		'prev')
			if command -v mpd_prev >/dev/null 2>&1; then
				mpd_prev
			else
				mpc -q prev
			fi
			local current
			if command -v get_mpd_current_song >/dev/null 2>&1; then
				current=$(get_mpd_current_song || echo "MPD")
			else
				current=$(mpc current 2>/dev/null || echo "MPD")
			fi
			notify-send -u low -t 1000 "󰒮 $current"
			;;
		'next')
			if command -v mpd_next >/dev/null 2>&1; then
				mpd_next
			else
				mpc -q next
			fi
			local current
			if command -v get_mpd_current_song >/dev/null 2>&1; then
				current=$(get_mpd_current_song || echo "MPD")
			else
				current=$(mpc current 2>/dev/null || echo "MPD")
			fi
			notify-send -u low -t 1000 "󰒭 $current"
			;;
		'repeat')
			if command -v mpd_repeat >/dev/null 2>&1; then
				mpd_repeat
			else
				mpc -q repeat
			fi
			local repeat_status
			if command -v is_mpd_repeat_on >/dev/null 2>&1; then
				if is_mpd_repeat_on; then
					repeat_status="ON"
				else
					repeat_status="OFF"
				fi
			else
				if mpc status | grep -q "repeat: on"; then
					repeat_status="ON"
				else
					repeat_status="OFF"
				fi
			fi
			notify-send -u low -t 1000 "󰑖 MPD" "Repeat: $repeat_status"
			;;
		'random')
			if command -v mpd_random >/dev/null 2>&1; then
				mpd_random
			else
				mpc -q random
			fi
			local random_status
			if command -v is_mpd_random_on >/dev/null 2>&1; then
				if is_mpd_random_on; then
					random_status="ON"
				else
					random_status="OFF"
				fi
			else
				if mpc status | grep -q "random: on"; then
					random_status="ON"
				else
					random_status="OFF"
				fi
			fi
			notify-send -u low -t 1000 "󰒝 MPD" "Random: $random_status"
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

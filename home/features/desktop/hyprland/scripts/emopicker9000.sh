#!/usr/bin/env bash

# Get user selection via rofi from emoji file.
dir="$HOME/.config/rofi/style"
theme='config-emoji'

chosen=$(cat $HOME/.config/.emoji | rofi -dmenu  -theme "$dir/$theme.rasi" | awk '{print $1}')

# Exit if none chosen.
[ -z "$chosen" ] && exit

# If you run this command with an argument, it will automatically insert the
# character. Otherwise, show a message that the emoji has been copied.
if [ -n "$1" ]; then
      ydotool type "$chosen"
else
      printf "$chosen" | wl-copy
      notify-send "'$chosen' copied to clipboard." &
fi


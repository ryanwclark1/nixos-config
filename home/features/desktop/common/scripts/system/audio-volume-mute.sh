#!/usr/bin/env bash

PATH="/run/current-system/sw/bin:/usr/bin:$PATH"
wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
if wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q "MUTED"; then
  notify-send "󰝟 Audio" "Muted" -t 1000
else
  notify-send " Audio" "Unmuted" -t 1000
fi
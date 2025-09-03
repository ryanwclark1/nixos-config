#!/usr/bin/env bash

PATH="/run/current-system/sw/bin:/usr/bin:$PATH"
wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
notify-send " Volume" "$(wpctl get-volume @DEFAULT_AUDIO_SINK@)" -t 1000
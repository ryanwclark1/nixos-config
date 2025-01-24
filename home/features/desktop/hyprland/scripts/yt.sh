#!/usr/bin/env bash

notify-send "Opening video" "$(wl-paste)"
mpv "$(wl-paste)"


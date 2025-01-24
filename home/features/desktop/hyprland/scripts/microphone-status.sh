#!/usr/bin/env bash

WP_OUTPUT=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@)

if [[ "$WP_OUTPUT" == *"[MUTED]" ]]; then
  printf ""
else
  printf ""
fi

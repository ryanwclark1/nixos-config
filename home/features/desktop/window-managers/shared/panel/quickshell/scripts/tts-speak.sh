#!/usr/bin/env bash
# Usage: qs-tts-speak [--rate=N] [--volume=N] [--engine=ENGINE] TEXT
# Speaks the given text using the configured TTS engine.
# Kills any previous qs-tts-speak instance to avoid overlapping speech.

# Kill previous instance (same script name)
pkill -f "qs-tts-speak" -o 2>/dev/null || true

RATE=175
VOLUME=100
ENGINE="espeak-ng"

while [[ "$1" == --* ]]; do
  case "$1" in
    --rate=*) RATE="${1#*=}" ;;
    --volume=*) VOLUME="${1#*=}" ;;
    --engine=*) ENGINE="${1#*=}" ;;
  esac
  shift
done

TEXT="$*"
[[ -z "$TEXT" ]] && exit 0

case "$ENGINE" in
  espeak-ng|espeak) espeak-ng -s "$RATE" -a "$VOLUME" -- "$TEXT" ;;
  piper) echo "$TEXT" | piper --output_raw | aplay -r 22050 -f S16_LE -t raw ;;
  *) espeak-ng -s "$RATE" -a "$VOLUME" -- "$TEXT" ;;
esac

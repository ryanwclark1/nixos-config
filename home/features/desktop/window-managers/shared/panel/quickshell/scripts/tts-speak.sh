#!/usr/bin/env bash
# Usage: qs-tts-speak [--rate=N] [--volume=N] [--engine=ENGINE] TEXT
# Speaks the given text using the configured TTS engine.
# Kills any previous instance via PID file to avoid overlapping speech.

PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/qs-tts-speak.pid"

# Kill previous instance if still running
if [[ -f "$PIDFILE" ]]; then
  old_pid=$(<"$PIDFILE")
  if [[ -n "$old_pid" ]] && kill -0 "$old_pid" 2>/dev/null; then
    kill "$old_pid" 2>/dev/null
    wait "$old_pid" 2>/dev/null
  fi
fi

# Write our PID
echo $$ > "$PIDFILE"
trap 'rm -f "$PIDFILE"' EXIT

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

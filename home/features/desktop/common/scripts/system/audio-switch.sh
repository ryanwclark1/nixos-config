#!/usr/bin/env bash

PATH="/run/current-system/sw/bin:/usr/bin:$PATH"

# Find all audio sinks, exit if none found
sinks=($(wpctl status | sed -n '/Sinks:/,/Sources:/p' | grep -E '^\s*│\s+\*?\s*[0-9]+\.' | sed -E 's/^[^0-9]*([0-9]+)\..*/\1/'))
if [[ ${#sinks[@]} -eq 0 ]]; then
  echo "No audio sinks found"
  exit 1
fi

# Find current active audio sink
current=$(wpctl status | sed -n '/Sinks:/,/Sources:/p' | grep '^\s*│\s*\*' | sed -E 's/^[^0-9]*([0-9]+)\..*/\1/')

# Find the next sink (cycling through available sinks)
next=""
for i in "${!sinks[@]}"; do
  if [[ "${sinks[$i]}" = "$current" ]]; then
    next="${sinks[$(((i + 1) % ${#sinks[@]}))]}"
    break
  fi
done

# Fallback to first sink if current not found
next="${next:-${sinks[0]}}"

# Get sink name for notification
sink_name=$(wpctl status | sed -n '/Sinks:/,/Sources:/p' | grep "^\s*│\s*\*\?\s*$next\." | sed -E 's/^[^.]*\.\s*//')

# Switch to next sink and unmute it
wpctl set-default "$next"
wpctl set-mute "$next" 0

# Send notification about the switch
notify-send " Audio Output" "Switched to: $sink_name" -t 2000
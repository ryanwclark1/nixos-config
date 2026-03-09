#!/usr/bin/env bash
# run.sh - List all executable commands in PATH

IFS=':' read -ra DIRS <<< "$PATH"

# Use jq to build the final JSON array
output=$(for dir in "${DIRS[@]}"; do
  if [ -d "$dir" ]; then
    find -L "$dir" -maxdepth 1 -executable -type f -printf "%f\n" 2>/dev/null
  fi
done | sort -u | while read -r cmd; do
  if [[ -n "$cmd" ]]; then
    # Escape quotes for JSON
    name_esc=$(echo "$cmd" | jq -R .)
    echo "{\"name\":$name_esc,\"exec\":$name_esc}"
  fi
done | jq -s '.')

echo "$output"

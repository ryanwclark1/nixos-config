#!/usr/bin/env bash
# cliphist.sh - Provide clipboard history for the launcher

# Fetch clipboard history using cliphist
# Format: "ID: Content"
# We'll use jq to format it as JSON objects
cliphist list | while read -r line; do
  id=$(echo "$line" | cut -f1)
  content=$(echo "$line" | cut -f2-)
  
  if [[ -n "$id" && -n "$content" ]]; then
    # Escape for JSON
    id_esc=$(echo "$id" | jq -R .)
    content_esc=$(echo "$content" | jq -R .)
    echo "{\"id\":$id_esc,\"content\":$content_esc}"
  fi
done | jq -s '.'

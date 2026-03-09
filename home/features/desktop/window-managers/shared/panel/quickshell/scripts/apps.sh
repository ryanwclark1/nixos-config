#!/usr/bin/env bash
# apps.sh - List all installed applications from .desktop files with icon resolution

dirs=(
  "/usr/share/applications"
  "/usr/local/share/applications"
  "$HOME/.local/share/applications"
  "$HOME/.nix-profile/share/applications"
  "/run/current-system/sw/share/applications"
)

# Icon search paths
icon_dirs=(
  "$HOME/.nix-profile/share/icons"
  "$HOME/.local/share/icons"
  "/run/current-system/sw/share/icons"
  "/usr/share/icons"
  "/usr/share/pixmaps"
)

# Cache for resolved icons to speed up
declare -A icon_cache

resolve_icon() {
  local icon_name="$1"
  if [[ -z "$icon_name" ]]; then echo ""; return; fi
  if [[ "$icon_name" == /* ]]; then echo "$icon_name"; return; fi
  if [[ -n "${icon_cache[$icon_name]}" ]]; then echo "${icon_cache[$icon_name]}"; return; fi

  # Try to find the icon file
  for dir in "${icon_dirs[@]}"; do
    if [ -d "$dir" ]; then
      # Look for svg, then png
      match=$(find "$dir" -name "${icon_name}.svg" -o -name "${icon_name}.png" | head -n 1)
      if [[ -n "$match" ]]; then
        icon_cache["$icon_name"]="$match"
        echo "$match"
        return
      fi
    fi
  done
  
  icon_cache["$icon_name"]=""
  echo ""
}

# Use jq to build the final JSON array
output=$(for dir in "${dirs[@]}"; do
  if [ -d "$dir" ]; then
    find "$dir" -name "*.desktop"
  fi
done | while read -r file; do
  name=$(grep -m1 "^Name=" "$file" | cut -d'=' -f2)
  exec=$(grep -m1 "^Exec=" "$file" | cut -d'=' -f2 | sed 's/ %[fFuU]//g' | sed 's/"//g')
  icon_name=$(grep -m1 "^Icon=" "$file" | cut -d'=' -f2)
  no_display=$(grep -m1 "^NoDisplay=" "$file" | cut -d'=' -f2)
  terminal=$(grep -m1 "^Terminal=" "$file" | cut -d'=' -f2)
  
  if [[ -n "$name" && -n "$exec" && "$no_display" != "true" ]]; then
    icon_path=$(resolve_icon "$icon_name")
    
    # Escape for JSON
    name_esc=$(echo "$name" | jq -R .)
    exec_esc=$(echo "$exec" | jq -R .)
    icon_esc=$(echo "$icon_path" | jq -R .)
    term_esc=$(echo "${terminal:-false}" | jq -R .)
    echo "{\"name\":$name_esc,\"exec\":$exec_esc,\"icon\":$icon_esc,\"terminal\":$term_esc}"
  fi
done | jq -s 'unique_by(.exec)')

echo "$output"

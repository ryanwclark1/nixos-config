#!/usr/bin/env bash
# icon-resolver.sh - Build a JSON map of WMClass/exec -> icon path from .desktop files
# Used by the taskbar to resolve app icons without hardcoded aliases.

app_dirs=(
  "$HOME/.nix-profile/share/applications"
  "$HOME/.local/share/applications"
  "/run/current-system/sw/share/applications"
  "/usr/share/applications"
  "/usr/local/share/applications"
)

icon_dirs=(
  "$HOME/.nix-profile/share/icons"
  "$HOME/.local/share/icons"
  "/run/current-system/sw/share/icons"
  "/usr/share/icons"
  "/usr/share/pixmaps"
)

declare -A icon_cache

resolve_icon() {
  local icon_name="$1"
  [[ -z "$icon_name" ]] && return
  # Already an absolute path
  [[ "$icon_name" == /* ]] && { echo "$icon_name"; return; }
  # Check cache
  [[ -n "${icon_cache[$icon_name]+set}" ]] && { echo "${icon_cache[$icon_name]}"; return; }

  for dir in "${icon_dirs[@]}"; do
    [[ -d "$dir" ]] || continue
    # Prefer scalable SVGs, then large PNGs
    local match
    match=$(find "$dir" -name "${icon_name}.svg" 2>/dev/null | head -n 1)
    if [[ -z "$match" ]]; then
      match=$(find "$dir" -name "${icon_name}.png" 2>/dev/null | sort -t/ -k8 -rn | head -n 1)
    fi
    if [[ -n "$match" ]]; then
      icon_cache["$icon_name"]="$match"
      echo "$match"
      return
    fi
  done

  icon_cache["$icon_name"]=""
}

# Collect all entries: map wmclass -> icon_path and exec_basename -> icon_path
declare -A result

for dir in "${app_dirs[@]}"; do
  [[ -d "$dir" ]] || continue
  while IFS= read -r file; do
    icon_name=$(grep -m1 "^Icon=" "$file" 2>/dev/null | cut -d'=' -f2)
    [[ -z "$icon_name" ]] && continue

    icon_path=$(resolve_icon "$icon_name")
    [[ -z "$icon_path" ]] && continue

    # Map by StartupWMClass (most reliable for matching running windows)
    wmclass=$(grep -m1 "^StartupWMClass=" "$file" 2>/dev/null | cut -d'=' -f2)
    if [[ -n "$wmclass" ]]; then
      result["${wmclass,,}"]="$icon_path"
    fi

    # Map by desktop file basename (without .desktop)
    basename=$(basename "$file" .desktop)
    result["${basename,,}"]="$icon_path"

    # Map by Exec basename
    exec_line=$(grep -m1 "^Exec=" "$file" 2>/dev/null | cut -d'=' -f2 | awk '{print $1}')
    if [[ -n "$exec_line" ]]; then
      exec_base=$(basename "$exec_line")
      result["${exec_base,,}"]="$icon_path"
    fi
  done < <(find "$dir" -maxdepth 1 -name "*.desktop" 2>/dev/null)
done

# Output as JSON object
echo -n "{"
first=true
for key in "${!result[@]}"; do
  val="${result[$key]}"
  # JSON escape
  key_esc=$(printf '%s' "$key" | jq -R .)
  val_esc=$(printf '%s' "$val" | jq -R .)
  if $first; then first=false; else echo -n ","; fi
  echo -n "${key_esc}:${val_esc}"
done
echo "}"

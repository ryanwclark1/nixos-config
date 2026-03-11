#!/usr/bin/env bash

FLAKE_PATH="${FLAKE:-$HOME/nixos-config}"
HOSTNAME="${HOSTNAME:-$(hostname)}"
UPDATES_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/updates"
ICON="󰮯"
INTERVAL_MINUTES=10

mkdir -p "$UPDATES_DIR"

check_and_write_updates() {
  # NixOS system updates (flake inputs)
  # Check for available updates without building
  nixos_updates=0
  nixos_list=""

  if [ -f "$FLAKE_PATH/flake.nix" ]; then
    cd "$FLAKE_PATH" 2>/dev/null || return

    # Run dry-run update check once and capture output
    update_output=$(nix flake update --dry-run 2>&1)

    if echo "$update_output" | grep -q "would update"; then
      # Extract all inputs that would update
      update_lines=$(echo "$update_output" | grep "would update")

      # Count total updates
      nixos_updates=$(echo "$update_lines" | wc -l)

      # Extract input names that would update (e.g., nixpkgs, home-manager, etc.)
      nixos_list=$(echo "$update_lines" | sed -n 's/.*would update \(.*\)/\1/p' | head -20)
    fi
  fi

  echo "$nixos_updates" > "$UPDATES_DIR/nixos"
  echo "$nixos_list" > "$UPDATES_DIR/nixos_list"

  # Flatpak
  if command -v flatpak >/dev/null 2>&1; then
    flatpak remote-ls --updates 2>/dev/null \
      | tee "$UPDATES_DIR/flatpak_list" >/dev/null
    fpk=$(wc -l < "$UPDATES_DIR/flatpak_list" 2>/dev/null || echo 0)
  else
    fpk=0
    : > "$UPDATES_DIR/flatpak_list"
  fi
  echo "$fpk" > "$UPDATES_DIR/flatpak"
}

boldify_ascii() {
  INPUT="$1"
  echo "$INPUT" | perl -CS -pe '
    s/([A-Z])/chr(ord($1) + 0x1D400 - ord("A"))/ge;
    s/([a-z])/chr(ord($1) + 0x1D41A - ord("a"))/ge;
  '
}

generate_json_output() {
  # Read counts with defaults
  nixos=$(cat "$UPDATES_DIR/nixos" 2>/dev/null || echo 0)
  fpk=$(cat "$UPDATES_DIR/flatpak" 2>/dev/null || echo 0)
  total=$((nixos + fpk))

  if (( total == 0 )); then
    jq -n '{icon: "", count: "", tooltip: ""}'
    return
  fi

  tooltip=""

  # NixOS updates (flake inputs like nixpkgs, home-manager, etc.)
  if [ -s "$UPDATES_DIR/nixos_list" ]; then
    while IFS= read -r line; do
      [ -z "$line" ] && continue
      boldpkg=$(boldify_ascii "$line")
      tooltip="${tooltip}󰏕 ${boldpkg} (flake input)\\n"
    done < "$UPDATES_DIR/nixos_list"
  fi

  # Flatpak updates
  if [ -s "$UPDATES_DIR/flatpak_list" ]; then
    while IFS= read -r line; do
      [ -z "$line" ] && continue
      pkg="${line%% *}"
      rest="${line#* }"
      boldpkg=$(boldify_ascii "$pkg")
      tooltip="${tooltip}󰏕 ${boldpkg} ${rest}\\n"
    done < "$UPDATES_DIR/flatpak_list"
  fi

  # Remove trailing \n at end if any
  tooltip="${tooltip%\\n}"

  jq -n --arg icon "$ICON" --arg count "$total" --arg tooltip "$tooltip" \
    '{icon: $icon, count: $count, tooltip: $tooltip}'
}

check_and_write_updates
generate_json_output

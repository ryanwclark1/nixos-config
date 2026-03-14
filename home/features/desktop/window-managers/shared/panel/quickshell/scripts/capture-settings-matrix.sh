#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"

viewport_preset="portrait"
output_dir="/tmp/settings-matrix"
delay_seconds="4"
scroll_y="0"
workspace_target="auto"
tabs=(
  "wallpaper"
  "bar-widgets"
  "bars"
  "system"
  "plugins"
  "theme"
  "hotkeys"
  "time-weather"
)

usage() {
  cat <<'EOF'
Usage: capture-settings-matrix.sh [--preset portrait|laptop|wide] [--output-dir DIR] [--delay SECONDS] [--scroll-y PX] [--workspace current|auto|NAME]

Capture the high-risk settings tabs for a standard viewport preset.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --preset)
      viewport_preset="${2:-}"
      shift 2
      ;;
    --output-dir)
      output_dir="${2:-}"
      shift 2
      ;;
    --delay)
      delay_seconds="${2:-}"
      shift 2
      ;;
    --scroll-y)
      scroll_y="${2:-}"
      shift 2
      ;;
    --workspace)
      workspace_target="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

case "${viewport_preset}" in
  portrait)
    width=430
    height=932
    ;;
  laptop)
    width=1280
    height=800
    ;;
  wide)
    width=1600
    height=900
    ;;
  *)
    printf 'Unknown preset: %s\n' "${viewport_preset}" >&2
    exit 2
    ;;
esac

mkdir -p "${output_dir}"

for tab in "${tabs[@]}"; do
  bash "${script_dir}/capture-settings-viewport.sh" \
    --width "${width}" \
    --height "${height}" \
    --delay "${delay_seconds}" \
    --scroll-y "${scroll_y}" \
    --workspace "${workspace_target}" \
    --tab "${tab}" \
    --output "${output_dir}/${viewport_preset}-${tab}.png"
done

printf '[INFO] Captured %s matrix to %s\n' "${viewport_preset}" "${output_dir}"

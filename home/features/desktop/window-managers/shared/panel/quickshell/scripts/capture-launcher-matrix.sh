#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"

instance_id=""
viewport_preset=""
output_dir="/tmp/launcher-matrix"
delay_seconds="1.2"
crop_mode="usable"
workspace_target="auto"
query_term="firefox"
empty_query="__launcher_empty_probe__"

source "${script_dir}/gallery-lib.sh"

write_gallery() {
  write_gallery_v2 "${output_dir}" "Launcher Matrix" "capture-launcher-matrix.sh"
}


usage() {
  cat <<'EOF'
Usage: capture-launcher-matrix.sh [--id INSTANCE_ID] [--preset portrait|laptop|wide] [--output-dir DIR] [--delay SECONDS] [--crop monitor|usable] [--workspace current|auto|NAME] [--query TERM] [--empty-query TERM]

Capture a focused launcher artifact set for manual review.
This produces review artifacts for key launcher states, not PASS/WARN/FAIL results.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --id)
      instance_id="${2:-}"
      shift 2
      ;;
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
    --crop)
      crop_mode="${2:-}"
      shift 2
      ;;
    --workspace)
      workspace_target="${2:-}"
      shift 2
      ;;
    --query)
      query_term="${2:-}"
      shift 2
      ;;
    --empty-query)
      empty_query="${2:-}"
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

viewport_args=()
if [[ -n "${viewport_preset}" ]]; then
  case "${viewport_preset}" in
    portrait)
      viewport_args+=(--width 430 --height 932)
      ;;
    laptop)
      viewport_args+=(--width 1280 --height 800)
      ;;
    wide)
      viewport_args+=(--width 1600 --height 900)
      ;;
    *)
      printf 'Unknown preset: %s\n' "${viewport_preset}" >&2
      exit 2
      ;;
  esac
fi

mkdir -p "${output_dir}"

launcher_args=()
if [[ -n "${instance_id}" ]]; then
  launcher_args+=(--id "${instance_id}")
fi
launcher_args+=("${viewport_args[@]}")

bash "${script_dir}/capture-launcher-viewport.sh" \
  "${launcher_args[@]}" \
  --mode drun \
  --state home \
  --delay "${delay_seconds}" \
  --crop "${crop_mode}" \
  --workspace "${workspace_target}" \
  --output "${output_dir}/drun-home.png"

bash "${script_dir}/capture-launcher-viewport.sh" \
  "${launcher_args[@]}" \
  --mode drun \
  --state query \
  --query "${query_term}" \
  --delay "${delay_seconds}" \
  --crop "${crop_mode}" \
  --workspace "${workspace_target}" \
  --output "${output_dir}/drun-query.png"

bash "${script_dir}/capture-launcher-viewport.sh" \
  "${launcher_args[@]}" \
  --mode drun \
  --state category \
  --delay "${delay_seconds}" \
  --crop "${crop_mode}" \
  --workspace "${workspace_target}" \
  --output "${output_dir}/drun-category.png"

bash "${script_dir}/capture-launcher-viewport.sh" \
  "${launcher_args[@]}" \
  --mode files \
  --state empty \
  --query "${empty_query}" \
  --delay "${delay_seconds}" \
  --crop "${crop_mode}" \
  --workspace "${workspace_target}" \
  --output "${output_dir}/files-empty.png"

bash "${script_dir}/capture-launcher-viewport.sh" \
  "${launcher_args[@]}" \
  --mode system \
  --state home \
  --delay "${delay_seconds}" \
  --crop "${crop_mode}" \
  --workspace "${workspace_target}" \
  --output "${output_dir}/system-home.png"

write_gallery "${output_dir}/index.html"

if [[ -n "${viewport_preset}" ]]; then
  printf '[INFO] Saved launcher review artifacts for the %s preset to %s\n' "${viewport_preset}" "${output_dir}"
else
  printf '[INFO] Saved launcher review artifacts to %s\n' "${output_dir}"
fi

#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
instance_id=""
output_dir="/tmp/surface-matrix"
delay_seconds="1.6"
crop_mode="monitor"
workspace_target="auto"
surfaces=(
  "notifCenter"
  "controlCenter"
  "networkMenu"
  "audioMenu"
  "weatherMenu"
  "dateTimeMenu"
)

usage() {
  cat <<'EOF'
Usage: capture-surface-matrix.sh [--output-dir DIR] [--delay SECONDS] [--crop monitor|usable] [--workspace current|auto|NAME]

Capture the high-risk popup/panel surfaces on the currently focused monitor.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --id)
      instance_id="${2:-}"
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

mkdir -p "${output_dir}"
surface_args=()
if [[ -n "${instance_id}" ]]; then
  surface_args+=(--id "${instance_id}")
fi

for surface in "${surfaces[@]}"; do
  "${script_dir}/capture-surface-viewport.sh" \
    "${surface_args[@]}" \
    --surface "${surface}" \
    --delay "${delay_seconds}" \
    --crop "${crop_mode}" \
    --workspace "${workspace_target}" \
    --output "${output_dir}/${surface}-${crop_mode}.png"
done

printf '[INFO] Captured surface matrix (%s) to %s\n' "${crop_mode}" "${output_dir}"

#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
instance_id=""
settings_delay="2"
surface_delay="1.8"
run_settings=1
run_surfaces=1

usage() {
  cat <<'EOF'
Usage: preview-panel-qa.sh [--id INSTANCE_ID] [--settings-delay SECONDS] [--surface-delay SECONDS] [--skip-settings] [--skip-surfaces]

Run the manual QA preview sequence:
  1. walk high-risk settings tabs
  2. walk popup/panel surfaces
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --id)
      instance_id="${2:-}"
      shift 2
      ;;
    --settings-delay)
      settings_delay="${2:-}"
      shift 2
      ;;
    --surface-delay)
      surface_delay="${2:-}"
      shift 2
      ;;
    --skip-settings)
      run_settings=0
      shift
      ;;
    --skip-surfaces)
      run_surfaces=0
      shift
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

main() {
  local args=()
  if [[ -n "${instance_id}" ]]; then
    args+=(--id "${instance_id}")
  fi

  if (( run_settings == 0 && run_surfaces == 0 )); then
    printf 'Nothing to preview. Remove at least one --skip-* flag.\n' >&2
    exit 2
  fi

  if (( run_settings == 1 )); then
    printf '[INFO] Previewing settings tabs...\n'
    "${script_dir}/preview-settings-responsive.sh" "${args[@]}" --delay "${settings_delay}"
  fi

  if (( run_surfaces == 1 )); then
    printf '[INFO] Previewing popup/panel surfaces...\n'
    "${script_dir}/preview-surface-responsive.sh" "${args[@]}" --delay "${surface_delay}"
  fi

  printf '[INFO] Preview sequence complete. Continue manual viewport and multi-monitor QA.\n'
}

main "$@"

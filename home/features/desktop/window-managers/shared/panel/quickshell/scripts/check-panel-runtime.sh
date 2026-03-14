#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
instance_id=""
run_settings=1
run_surfaces=1
run_multibar=1

usage() {
  cat <<'EOF'
Usage: check-panel-runtime.sh [--id INSTANCE_ID] [--skip-settings] [--skip-surfaces] [--skip-multibar]

Run the shared panel runtime verification stack:
  1. panel config contract checks
  2. settings responsive smoke
  3. live popup/panel surface smoke
  4. synthetic multibar shell matrix and management harnesses

If more than one QuickShell instance is running, pass --id INSTANCE_ID.
In headless/offscreen environments, the multibar phase can end in [SKIP] results when
PanelWindow backends are unavailable; treat that as an environment limit, not a widget failure.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --id)
      instance_id="${2:-}"
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
    --skip-multibar)
      run_multibar=0
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

run_step() {
  local label="$1"
  shift
  printf '[INFO] %s...\n' "$label"
  if [[ $# -gt 0 && -f "$1" && ! -x "$1" ]]; then
    bash "$@"
  else
    "$@"
  fi
}

main() {
  local args=()
  if [[ -n "${instance_id}" ]]; then
    args+=(--id "${instance_id}")
  fi

  if (( run_settings == 0 && run_surfaces == 0 && run_multibar == 0 )); then
    printf 'Nothing to run. Remove at least one --skip-* flag.\n' >&2
    exit 2
  fi

  run_step "Running panel config contract checks" "${script_dir}/check-panel-config-contracts.sh"

  if (( run_settings == 1 )); then
    run_step "Running settings responsive smoke" "${script_dir}/check-settings-responsive.sh" "${args[@]}"
  fi

  if (( run_surfaces == 1 )); then
    run_step "Running live surface responsive smoke" "${script_dir}/check-surface-responsive.sh" "${args[@]}"
  fi

  if (( run_multibar == 1 )); then
    run_step "Running synthetic multibar smoke" "${script_dir}/check-multibar-smoke.sh"
  fi

  printf '[INFO] Panel runtime verification completed. In headless/offscreen environments, multibar [SKIP] results can be expected. Manual visual QA is still required for final signoff.\n'
}

main "$@"

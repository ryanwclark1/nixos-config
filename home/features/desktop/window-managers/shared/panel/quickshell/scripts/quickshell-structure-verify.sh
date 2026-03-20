#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
quickshell_root="$(CDPATH= cd -- "${script_dir}/.." && pwd -P)"
nixos_repo_root="$(CDPATH= cd -- "${script_dir}/../../../../../../../../" && pwd -P)"
src_root="${quickshell_root}/src"
quiet=0
use_vm=0
vm_selector="${QS_VERIFY_VM_SELECTOR:-both}"
startup_timeout_seconds="${QS_VERIFY_STARTUP_TIMEOUT_SECONDS:-60}"
launcher_timeout_seconds="${QS_VERIFY_LAUNCHER_SMOKE_TIMEOUT_SECONDS:-180}"
journal_timeout_seconds="${QS_VERIFY_JOURNAL_GATE_TIMEOUT_SECONDS:-180}"
vm_timeout_seconds="${QS_VERIFY_VM_TIMEOUT_SECONDS:-5400}"
stage_names=()
stage_durations=()
stage_exits=()

usage() {
  cat <<'EOF'
Usage: quickshell-structure-verify.sh [--quiet] [--vm [niri|hyprland|both]]

Default fast host path:
  1. structural import-boundary checks
  2. qmldir target validation
  3. clipboard contract checks
  4. startup smoke
  5. transient repo-shell journal warning gate when a live session is available
  6. launcher smoke

Optional exhaustive path:
  --vm [selector]  Run the fast host preflight first, then delegate exhaustive
                   runtime/settings coverage to scripts/vm/run-panel-vm-qa.sh.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --quiet)
      quiet=1
      ;;
    --vm)
      use_vm=1
      if [[ $# -gt 1 && ! "${2}" =~ ^- ]]; then
        vm_selector="${2}"
        shift
      fi
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
  shift
done

step_info() {
  if (( quiet == 0 )); then
    printf '[INFO] %s...\n' "$1"
  fi
}

step_skip() {
  printf '[SKIP] %s\n' "$1"
}

record_stage() {
  stage_names+=("$1")
  stage_durations+=("$2")
  stage_exits+=("$3")
}

run_step() {
  local label="$1"
  shift
  local start_ts end_ts duration exit_code
  step_info "$label"
  start_ts=$SECONDS
  set +e
  "$@"
  exit_code=$?
  set -e
  end_ts=$SECONDS
  duration=$((end_ts - start_ts))
  record_stage "$label" "$duration" "$exit_code"
  return "$exit_code"
}

run_step_timeout() {
  local label="$1"
  local timeout_seconds="$2"
  shift 2
  local start_ts end_ts duration exit_code
  step_info "$label"
  start_ts=$SECONDS
  set +e
  if command -v timeout >/dev/null 2>&1; then
    timeout --foreground --signal=TERM --kill-after=10s "${timeout_seconds}s" "$@"
  else
    "$@"
  fi
  exit_code=$?
  set -e
  end_ts=$SECONDS
  duration=$((end_ts - start_ts))
  record_stage "$label" "$duration" "$exit_code"
  return "$exit_code"
}

print_stage_summary() {
  local i
  printf '[INFO] Stage timing summary:\n'
  for i in "${!stage_names[@]}"; do
    printf '[INFO]   %s: %ss (exit %s)\n' \
      "${stage_names[$i]}" \
      "${stage_durations[$i]}" \
      "${stage_exits[$i]}"
  done
}

run_qmldir_validation() {
  python - <<'PY' "${src_root}"
from pathlib import Path
import sys

root = Path(sys.argv[1])
problems = []

for qmldir in root.rglob('qmldir'):
    for raw_line in qmldir.read_text().splitlines():
        line = raw_line.strip()
        if not line:
            continue
        parts = line.split()
        if line.startswith('singleton ') and len(parts) >= 4:
            target = (qmldir.parent / parts[3]).resolve()
            if not target.exists():
                problems.append(f'{qmldir}: missing {parts[3]}')
        elif not line.startswith('#') and not line.startswith('module ') and len(parts) >= 3 and parts[1][0].isdigit():
            target = (qmldir.parent / parts[2]).resolve()
            if not target.exists():
                problems.append(f'{qmldir}: missing {parts[2]}')

if problems:
    print('\n'.join(problems), file=sys.stderr)
    raise SystemExit(1)

print('qmldir targets OK')
PY
}

has_live_session() {
  [[ -n "${WAYLAND_DISPLAY:-}" || -n "${DISPLAY:-}" ]]
}

trap print_stage_summary EXIT

run_step "Checking import boundaries" bash "${quickshell_root}/tools/checks/check-import-boundaries.sh"
run_step "Validating qmldir targets" run_qmldir_validation
run_step "Running clipboard contract checks" bash "${script_dir}/check-clipboard-contracts.sh"
run_step_timeout "Running startup smoke" "${startup_timeout_seconds}" bash "${script_dir}/check-quickshell-startup.sh"

if has_live_session; then
  run_step_timeout "Running transient repo-shell journal warning gate" "${journal_timeout_seconds}" bash "${script_dir}/check-runtime-journal-gate.sh"
  run_step_timeout "Running launcher smoke" "${launcher_timeout_seconds}" bash "${script_dir}/check-launcher-smoke.sh" --ci
else
  step_skip "transient repo-shell journal warning gate: no live compositor session detected"
  run_step_timeout "Running launcher smoke" "${launcher_timeout_seconds}" bash "${script_dir}/check-launcher-smoke.sh" --ci
fi

if (( use_vm == 1 )); then
  run_step_timeout \
    "Running VM-backed runtime/settings gate (${vm_selector})" \
    "${vm_timeout_seconds}" \
    bash "${nixos_repo_root}/scripts/vm/run-panel-vm-qa.sh" --vm "${vm_selector}"
fi

if (( quiet == 0 )); then
  printf '[INFO] Quickshell structure verification completed.\n'
fi

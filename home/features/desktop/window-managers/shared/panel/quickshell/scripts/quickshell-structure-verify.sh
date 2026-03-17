#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(CDPATH= cd -- "${script_dir}/.." && pwd -P)"
src_root="${repo_root}/src"
quiet=0
startup_timeout_seconds="${QS_VERIFY_STARTUP_TIMEOUT_SECONDS:-60}"

usage() {
  cat <<'EOF'
Usage: quickshell-structure-verify.sh [--quiet]

Run the automated post-migration verification stack:
  1. structural import-boundary checks
  2. qmldir target validation
  3. clipboard contract checks
  4. repo-shell startup smoke
  5. repo-shell launcher smoke
  6. repo-shell panel runtime aggregate
  7. live surface responsive smoke when a compositor session is available
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --quiet)
      quiet=1
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

run_step() {
  local label="$1"
  shift
  step_info "$label"
  "$@"
}

run_step_timeout() {
  local label="$1"
  local timeout_seconds="$2"
  shift 2
  step_info "$label"
  if command -v timeout >/dev/null 2>&1; then
    timeout --foreground --signal=TERM --kill-after=10s "${timeout_seconds}s" "$@"
  else
    "$@"
  fi
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

run_step "Checking import boundaries" bash "${repo_root}/tools/checks/check-import-boundaries.sh"
run_step "Validating qmldir targets" run_qmldir_validation
run_step "Running clipboard contract checks" bash "${script_dir}/check-clipboard-contracts.sh"
run_step_timeout "Running startup smoke" "${startup_timeout_seconds}" bash "${script_dir}/check-quickshell-startup.sh"
run_step "Running launcher smoke" bash "${script_dir}/check-launcher-smoke.sh" --repo-shell
run_step "Running panel runtime aggregate" bash "${script_dir}/check-panel-runtime.sh" --repo-shell

if has_live_session; then
  run_step "Running live surface responsive smoke" bash "${script_dir}/check-surface-responsive.sh" --repo-shell
else
  step_skip "live surface responsive smoke: no live compositor session detected"
fi

if (( quiet == 0 )); then
  printf '[INFO] Quickshell structure verification completed.\n'
fi

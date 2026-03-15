#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
repo_root="$(cd -- "${script_dir}/../../../../../../../.." >/dev/null 2>&1 && pwd -P)"

flake_target=".#administrator@woody"
output_dir="${TMPDIR:-/tmp}/bar-widgets-first-open"
skip_switch=0
instance_id=""

usage() {
  cat <<'EOF'
Usage: check-bar-widgets-first-open.sh [--skip-switch] [--output-dir PATH] [--flake TARGET] [--id INSTANCE_ID]

Deploy the current Home Manager configuration, restart quickshell.service, capture the
Bar Widgets tab in the broken first-open path and the known-good re-entry path, then
OCR both screenshots and fail if first-open is still missing widget controls.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-switch)
      skip_switch=1
      shift
      ;;
    --output-dir)
      output_dir="${2:-}"
      shift 2
      ;;
    --flake)
      flake_target="${2:-}"
      shift 2
      ;;
    --id)
      instance_id="${2:-}"
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

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$1" >&2
    exit 2
  fi
}

discover_instance() {
  local runtime_root="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell/by-id"
  local candidate attempt

  [[ -d "${runtime_root}" ]] || return 1

  for attempt in $(seq 1 20); do
    while IFS= read -r candidate; do
      [[ -n "${candidate}" ]] || continue
      if quickshell ipc --id "${candidate}" call SettingsHub close >/dev/null 2>&1; then
        printf '%s\n' "${candidate}"
        return 0
      fi
    done < <(find "${runtime_root}" -mindepth 1 -maxdepth 1 -type d -exec test -S '{}/ipc.sock' ';' -print 2>/dev/null | sed 's#.*/##')
    sleep 0.5
  done

  return 1
}

load_quickshell_env() {
  local env_dump
  env_dump="$(systemctl --user show-environment)"
  export XDG_RUNTIME_DIR="$(printf '%s\n' "${env_dump}" | sed -n 's/^XDG_RUNTIME_DIR=//p' | head -n1)"
  export DBUS_SESSION_BUS_ADDRESS="$(printf '%s\n' "${env_dump}" | sed -n 's/^DBUS_SESSION_BUS_ADDRESS=//p' | head -n1)"
  export DISPLAY="$(printf '%s\n' "${env_dump}" | sed -n 's/^DISPLAY=//p' | head -n1)"
  export HYPRLAND_INSTANCE_SIGNATURE="$(printf '%s\n' "${env_dump}" | sed -n 's/^HYPRLAND_INSTANCE_SIGNATURE=//p' | head -n1)"
  export WAYLAND_DISPLAY="$(printf '%s\n' "${env_dump}" | sed -n 's/^WAYLAND_DISPLAY=//p' | head -n1)"

  [[ -n "${XDG_RUNTIME_DIR:-}" ]] || {
    printf 'quickshell environment is missing XDG_RUNTIME_DIR.\n' >&2
    exit 1
  }
  [[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]] || {
    printf 'quickshell environment is missing DBUS_SESSION_BUS_ADDRESS.\n' >&2
    exit 1
  }
}

ocr_text() {
  local image_path="$1"
  tesseract "${image_path}" stdout 2>/dev/null | tr '\n' ' '
}

population_score() {
  local text="$1"
  python - "$text" <<'PY'
import re
import sys

text = sys.argv[1]
patterns = [
    r'App Launcher',
    r'Workspace Switcher',
    r'Window Title',
    r'Running Apps',
    r'CPU',
    r'Visible',
    r'Settings',
    r'Remove',
    r'Current widgets',
]
score = sum(1 for pattern in patterns if re.search(pattern, text, flags=re.I))
print(score)
PY
}

require_cmd home-manager
require_cmd quickshell
require_cmd systemctl
require_cmd tesseract
require_cmd compare

mkdir -p "${output_dir}"
first_open_png="${output_dir}/bar-widgets-first-open.png"
reenter_png="${output_dir}/bar-widgets-reenter.png"
first_open_txt="${output_dir}/bar-widgets-first-open.txt"
reenter_txt="${output_dir}/bar-widgets-reenter.txt"

if (( skip_switch == 0 )); then
  printf '[INFO] Running Home Manager switch: home-manager switch --flake %s --show-trace --verbose\n' "${flake_target}"
  (
    cd "${repo_root}"
    home-manager switch --flake "${flake_target}" --show-trace --verbose
  )
fi

printf '[INFO] Restarting quickshell.service\n'
systemctl --user restart quickshell.service
systemctl --user is-active --quiet quickshell.service

load_quickshell_env

if [[ -z "${instance_id}" ]]; then
  instance_id="$(discover_instance)" || {
    printf 'Could not discover a reachable quickshell instance.\n' >&2
    exit 1
  }
fi

printf '[INFO] Running settings smoke against instance %s\n' "${instance_id}"
bash "${script_dir}/check-settings-responsive.sh" --id "${instance_id}"

printf '[INFO] Capturing first-open Bar Widgets state\n'
bash "${script_dir}/capture-settings-viewport.sh" --id "${instance_id}" --tab bar-widgets --output "${first_open_png}"

printf '[INFO] Reproducing close/reenter path for control capture\n'
quickshell ipc --id "${instance_id}" call SettingsHub close >/dev/null 2>&1 || true
quickshell ipc --id "${instance_id}" call SettingsHub openTab bar-widgets >/dev/null
sleep 1
quickshell ipc --id "${instance_id}" call SettingsHub close >/dev/null
sleep 0.5
bash "${script_dir}/capture-settings-viewport.sh" --id "${instance_id}" --tab bar-widgets --output "${reenter_png}"

first_text="$(ocr_text "${first_open_png}")"
reenter_text="$(ocr_text "${reenter_png}")"
printf '%s\n' "${first_text}" > "${first_open_txt}"
printf '%s\n' "${reenter_text}" > "${reenter_txt}"

first_score="$(population_score "${first_text}")"
reenter_score="$(population_score "${reenter_text}")"
rmse="$(compare -metric RMSE "${first_open_png}" "${reenter_png}" null: 2>&1 || true)"

printf '[INFO] First-open population score: %s\n' "${first_score}"
printf '[INFO] Re-enter population score: %s\n' "${reenter_score}"
printf '[INFO] Screenshot RMSE: %s\n' "${rmse}"
printf '[INFO] Artifacts:\n'
printf '  %s\n' "${first_open_png}"
printf '  %s\n' "${reenter_png}"
printf '  %s\n' "${first_open_txt}"
printf '  %s\n' "${reenter_txt}"

if (( reenter_score < 4 )); then
  printf '[FAIL] Re-entry capture did not expose enough widget content, so this run cannot determine pass/fail.\n' >&2
  exit 1
fi

if (( first_score < 3 )); then
  printf '[FAIL] First-open Bar Widgets still looks under-populated.\n' >&2
  exit 1
fi

printf '[PASS] First-open Bar Widgets shows populated widget content.\n'

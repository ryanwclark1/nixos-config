#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
repo_root="$(cd -- "${script_dir}/../../../../../../../.." >/dev/null 2>&1 && pwd -P)"

flake_target=".#administrator@woody"
output_dir="${TMPDIR:-/tmp}/bar-widgets-first-open"
capture_scroll_y="520"
skip_switch=0
instance_id=""
repo_shell_mode=0
repo_shell_pid=""
repo_shell_service_was_active=0
repo_shell_env=()

usage() {
  cat <<'EOF'
Usage: check-bar-widgets-first-open.sh [--skip-switch] [--repo-shell] [--output-dir PATH] [--flake TARGET] [--id INSTANCE_ID]

Deploy the current Home Manager configuration, restart quickshell.service, capture the
Bar Widgets tab in the broken first-open path and the known-good re-entry path, then
OCR both screenshots and fail if first-open is still missing widget controls.
Use --repo-shell to run against a repo-shell instance without deploying Home Manager.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-switch)
      skip_switch=1
      shift
      ;;
    --repo-shell)
      repo_shell_mode=1
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

cleanup_repo_shell() {
  if [[ -n "${repo_shell_pid}" ]]; then
    kill "${repo_shell_pid}" >/dev/null 2>&1 || true
    wait "${repo_shell_pid}" >/dev/null 2>&1 || true
  fi
  if (( repo_shell_service_was_active == 1 )); then
    systemctl --user start quickshell.service >/dev/null 2>&1 || true
  fi
}

handle_termination() {
  trap - EXIT TERM INT
  cleanup_repo_shell
  exit 124
}

populate_repo_shell_env() {
  local line=""
  local key=""
  local value=""
  local has_wayland_session=0
  local found_graphics_env=0

  repo_shell_env=()
  repo_shell_env+=("QS_DISABLE_NOTIFICATION_SERVER=1")
  for key in HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY NIRI_SOCKET XDG_CURRENT_DESKTOP DESKTOP_SESSION XDG_SESSION_TYPE DISPLAY; do
    value="${!key:-}"
    if [[ -n "${value}" ]]; then
      repo_shell_env+=("${key}=${value}")
      case "${key}" in
        HYPRLAND_INSTANCE_SIGNATURE|WAYLAND_DISPLAY|NIRI_SOCKET|DISPLAY)
          found_graphics_env=1
          ;;&
        WAYLAND_DISPLAY|NIRI_SOCKET)
          has_wayland_session=1
          ;;
      esac
    fi
  done

  if (( found_graphics_env == 1 )); then
    if (( has_wayland_session == 1 )); then
      repo_shell_env+=("QT_QPA_PLATFORM=wayland")
    fi
    return 0
  fi

  while IFS= read -r line; do
    [[ "${line}" == *=* ]] || continue
    key="${line%%=*}"
    value="${line#*=}"
    case "${key}" in
      HYPRLAND_INSTANCE_SIGNATURE|WAYLAND_DISPLAY|NIRI_SOCKET|XDG_CURRENT_DESKTOP|DESKTOP_SESSION|XDG_SESSION_TYPE|DISPLAY)
        if [[ -n "${value}" ]]; then
          repo_shell_env+=("${key}=${value}")
          case "${key}" in
            HYPRLAND_INSTANCE_SIGNATURE|WAYLAND_DISPLAY|NIRI_SOCKET|DISPLAY)
              found_graphics_env=1
              ;;&
            WAYLAND_DISPLAY|NIRI_SOCKET)
              has_wayland_session=1
              ;;
          esac
        fi
        ;;
    esac
  done < <(systemctl --user show-environment 2>/dev/null || true)

  if (( has_wayland_session == 1 )); then
    repo_shell_env+=("QT_QPA_PLATFORM=wayland")
  fi
}

start_repo_shell() {
  local runtime_root="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell/by-pid"
  local runtime_dir=""
  local deadline

  if systemctl --user is-active --quiet quickshell.service; then
    repo_shell_service_was_active=1
    systemctl --user stop quickshell.service >/dev/null 2>&1 || true
    sleep 1
  fi

  populate_repo_shell_env
  env "${repo_shell_env[@]}" quickshell -p "${script_dir}/../src/shell.qml" >/tmp/quickshell-repo-bar-widgets-first-open.log 2>&1 &
  repo_shell_pid="$!"

  deadline=$((SECONDS + 20))
  while (( SECONDS < deadline )); do
    runtime_dir="$(readlink -f "${runtime_root}/${repo_shell_pid}" 2>/dev/null || true)"
    if [[ -n "${runtime_dir}" && -S "${runtime_dir}/ipc.sock" ]]; then
      instance_id="$(basename "${runtime_dir}")"
      printf '[INFO] Repo shell instance ready: pid %s id %s\n' "${repo_shell_pid}" "${instance_id}"
      return 0
    fi
    sleep 0.5
  done

  printf 'Repo shell did not become IPC-ready in time. See /tmp/quickshell-repo-bar-widgets-first-open.log\n' >&2
  exit 1
}

discover_instance() {
  local runtime_root="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell/by-id"
  local candidate attempt
  local resolved
  local log_path
  local first_line
  local preferred=()
  local fallback=()

  [[ -d "${runtime_root}" ]] || return 1

  if [[ -n "${instance_id}" ]]; then
    for attempt in $(seq 1 20); do
      if quickshell ipc --id "${instance_id}" show >/dev/null 2>&1; then
        printf '%s\n' "${instance_id}"
        return 0
      fi
      sleep 0.5
    done
  fi

  if (( repo_shell_mode == 1 )) && [[ -n "${repo_shell_pid}" ]]; then
    resolved="$(readlink -f "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell/by-pid/${repo_shell_pid}" 2>/dev/null || true)"
    if [[ -n "${resolved}" && -S "${resolved}/ipc.sock" ]]; then
      candidate="$(basename "${resolved}")"
      for attempt in $(seq 1 20); do
        if quickshell ipc --id "${candidate}" show >/dev/null 2>&1; then
          printf '%s\n' "${candidate}"
          return 0
        fi
        sleep 0.5
      done
    fi
  fi

  while IFS= read -r candidate; do
    [[ -n "${candidate}" ]] || continue
    resolved="$(readlink -f "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell/by-pid/${candidate}" 2>/dev/null || true)"
    if [[ -n "${resolved}" && -S "${resolved}/ipc.sock" ]]; then
      log_path="${resolved}/log.log"
      first_line="$(sed -n '1p' "${log_path}" 2>/dev/null || true)"
      if [[ "${first_line}" == *'Launching config:'*'shell.qml"'* ]]; then
        preferred+=("$(basename "${resolved}")")
      else
        fallback+=("$(basename "${resolved}")")
      fi
    fi
  done < <(ps -eo pid=,comm=,args= | awk '$2 ~ /quickshell/ || $3 ~ /quickshell/ { print $1 }')

  for attempt in $(seq 1 20); do
    while IFS= read -r candidate; do
      [[ -n "${candidate}" ]] || continue
      if quickshell ipc --id "${candidate}" show >/dev/null 2>&1; then
        printf '%s\n' "${candidate}"
        return 0
      fi
    done < <(
      if (( ${#preferred[@]} > 0 )); then
        printf '%s\n' "${preferred[@]}"
      else
        printf '%s\n' "${fallback[@]}"
        find "${runtime_root}" -mindepth 1 -maxdepth 1 -type d -exec test -S '{}/ipc.sock' ';' -print 2>/dev/null | sed 's#.*/##'
      fi | awk 'NF && !seen[$0]++'
    )
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
  export NIRI_SOCKET="$(printf '%s\n' "${env_dump}" | sed -n 's/^NIRI_SOCKET=//p' | head -n1)"
  export XDG_CURRENT_DESKTOP="$(printf '%s\n' "${env_dump}" | sed -n 's/^XDG_CURRENT_DESKTOP=//p' | head -n1)"
  export DESKTOP_SESSION="$(printf '%s\n' "${env_dump}" | sed -n 's/^DESKTOP_SESSION=//p' | head -n1)"
  export XDG_SESSION_TYPE="$(printf '%s\n' "${env_dump}" | sed -n 's/^XDG_SESSION_TYPE=//p' | head -n1)"

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
  local processed_image
  processed_image="$(mktemp /tmp/bar-widgets-ocr-XXXXXX.png)"
  magick "${image_path}" \
    -colorspace Gray \
    -negate \
    -contrast-stretch 0x10% \
    -resize 250% \
    -threshold 35% \
    "${processed_image}"
  tesseract "${processed_image}" stdout --psm 11 2>/dev/null | tr '\n' ' '
  rm -f "${processed_image}"
}

image_mean() {
  local image_path="$1"
  magick "${image_path}" -colorspace Gray -format '%[fx:mean]' info:
}

niri_headless_without_outputs() {
  local outputs_json=""

  [[ -n "${NIRI_SOCKET:-}" ]] || return 1
  command -v niri >/dev/null 2>&1 || return 1
  outputs_json="$(niri msg -j outputs 2>/dev/null || true)"
  [[ -n "${outputs_json}" ]] || return 1

  if printf '%s' "${outputs_json}" | jq -e '
    if type == "array" then
      length == 0
    elif type == "object" then
      length == 0 or (((.outputs // []) | length) == 0)
    else
      true
    end
  ' >/dev/null 2>&1; then
    return 0
  fi

  return 1
}

capture_until_visible() {
  local label="$1"
  local output_path="$2"
  local attempt
  local mean

  for attempt in 1 2 3 4; do
    bash "${script_dir}/capture-settings-viewport.sh" \
      --id "${instance_id}" \
      --tab bar-widgets \
      --scroll-y "${capture_scroll_y}" \
      --workspace current \
      --output "${output_path}"
    mean="$(image_mean "${output_path}")"
    if awk "BEGIN { exit !(${mean} > 0.02) }"; then
      return 0
    fi
    printf '[INFO] %s capture was too dark (mean=%s), retrying.\n' "${label}" "${mean}"
    sleep 1
  done

  return 1
}

population_score() {
  local text="$1"
  local score=0
  local visible_hits=0
  local pattern=""
  local patterns=(
    'Bar[[:space:].]+Widgets'
    'Manage the widget composition'
    '(Main|Mlan)[[:space:]]+Bar'
    'Active[[:space:]]+Bar'
    'Top[[:space:]]+Section'
    'Current widgets'
    'Rem(aove|ove)'
    'Sett(irgs|ings)'
    'App[[:space:]]+L[a-z;]{0,3}uncher'
    'W.{0,4}ks?.{0,4}pace[[:space:]]+Switcher'
    'L.{0,2}ft[[:space:]]+Section'
    'Window[[:space:]]+Title'
    'Act.{0,4}ve[[:space:]]+App[[:space:]]+.{0,8}text'
    'Runn.{0,2}ing[[:space:]]+Apps'
  )

  for pattern in "${patterns[@]}"; do
    if printf '%s\n' "${text}" | grep -Eqi "${pattern}"; then
      score=$((score + 1))
    fi
  done

  visible_hits="$(printf '%s\n' "${text}" | grep -Eio 'Visible' | wc -l | tr -d '[:space:]')"
  if [[ -z "${visible_hits}" ]]; then
    visible_hits=0
  fi
  if (( visible_hits > 6 )); then
    visible_hits=6
  fi
  score=$((score + visible_hits))

  printf '%s\n' "${score}"
}

require_cmd quickshell
require_cmd systemctl
require_cmd tesseract
require_cmd compare
require_cmd ps

if (( repo_shell_mode == 0 )); then
  require_cmd home-manager
fi

mkdir -p "${output_dir}"
first_open_png="${output_dir}/bar-widgets-first-open.png"
reenter_png="${output_dir}/bar-widgets-reenter.png"
first_open_txt="${output_dir}/bar-widgets-first-open.txt"
reenter_txt="${output_dir}/bar-widgets-reenter.txt"

if (( repo_shell_mode == 1 )); then
  trap cleanup_repo_shell EXIT
  trap handle_termination TERM INT
  load_quickshell_env
  start_repo_shell
elif (( skip_switch == 0 )); then
  printf '[INFO] Running Home Manager switch: home-manager switch --flake %s --show-trace --verbose\n' "${flake_target}"
  (
    cd "${repo_root}"
    home-manager switch --flake "${flake_target}" --show-trace --verbose
  )
  printf '[INFO] Restarting quickshell.service\n'
  systemctl --user restart quickshell.service
  systemctl --user is-active --quiet quickshell.service
  load_quickshell_env
else
  printf '[INFO] Restarting quickshell.service\n'
  systemctl --user restart quickshell.service
  systemctl --user is-active --quiet quickshell.service
  load_quickshell_env
fi

if [[ -z "${instance_id}" ]]; then
  instance_id="$(discover_instance)" || {
    printf 'Could not discover a reachable quickshell instance.\n' >&2
    exit 1
  }
fi

printf '[INFO] Running settings smoke against instance %s\n' "${instance_id}"
bash "${script_dir}/check-settings-responsive.sh" --pid "${repo_shell_pid}" --skip-reload
instance_id="$(discover_instance)" || {
  printf 'Could not rediscover a reachable quickshell instance after settings smoke.\n' >&2
  exit 1
}

if niri_headless_without_outputs; then
  printf '[SKIP] Bar Widgets first-open visual capture skipped: Niri session exposes no wl_output in this headless VM.\n'
  printf 'Niri session exposes no wl_output in this headless VM, so grim-based Bar Widgets capture is unavailable.\n' \
    > "${output_dir}/bar-widgets-first-open.skip.txt"
  exit 0
fi

printf '[INFO] Capturing first-open Bar Widgets state\n'
capture_until_visible "First-open" "${first_open_png}"

printf '[INFO] Reproducing close/reenter path for control capture\n'
quickshell ipc --id "${instance_id}" call SettingsHub close >/dev/null 2>&1 || true
sleep 0.5
if ! quickshell ipc --id "${instance_id}" show >/dev/null 2>&1; then
  instance_id="$(discover_instance)" || {
    printf 'Could not rediscover a reachable quickshell instance before re-entry capture.\n' >&2
    exit 1
  }
fi
capture_until_visible "Re-entry" "${reenter_png}"

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

if (( reenter_score < 5 )); then
  printf '[FAIL] Re-entry capture did not expose enough widget content, so this run cannot determine pass/fail.\n' >&2
  exit 1
fi

if (( first_score < 5 )); then
  printf '[FAIL] First-open Bar Widgets still looks under-populated.\n' >&2
  exit 1
fi

printf '[PASS] First-open Bar Widgets shows populated widget content.\n'

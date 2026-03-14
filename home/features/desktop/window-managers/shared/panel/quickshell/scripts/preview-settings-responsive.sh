#!/usr/bin/env bash
set -euo pipefail

runtime_root="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell/by-id"

tab_ids=(
  "wallpaper"
  "bar-widgets"
  "bars"
  "system"
  "plugins"
  "theme"
  "hotkeys"
  "time-weather"
)

instance_id=""
delay_seconds="2"

usage() {
  cat <<'EOF'
Usage: preview-settings-responsive.sh [--id INSTANCE_ID] [--delay SECONDS]

Open SettingsHub and walk the high-risk tabs in sequence for manual visual QA.
This is a live-session manual walkthrough, not a PASS/WARN/FAIL gate.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --id)
      instance_id="${2:-}"
      shift 2
      ;;
    --delay)
      delay_seconds="${2:-}"
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

discover_instances_from_pid() {
  local pid
  local resolved
  local preferred=()
  local fallback=()
  local log_path
  local first_line

  while IFS= read -r pid; do
    [[ -n "${pid}" ]] || continue
    resolved="$(readlink -f "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell/by-pid/${pid}" 2>/dev/null || true)"
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

  if (( ${#preferred[@]} > 0 )); then
    printf '%s\n' "${preferred[@]}" | awk 'NF && !seen[$0]++'
  else
    printf '%s\n' "${fallback[@]}" | awk 'NF && !seen[$0]++'
  fi
}

discover_instances() {
  local dirs=()
  local dir

  mapfile -t dirs < <(discover_instances_from_pid)
  if (( ${#dirs[@]} > 0 )); then
    printf '%s\n' "${dirs[@]}"
    return 0
  fi

  if [[ -d "${runtime_root}" ]]; then
    while IFS= read -r dir; do
      dirs+=("$(basename "${dir}")")
    done < <(find "${runtime_root}" -mindepth 1 -maxdepth 1 -type d -exec test -S '{}/ipc.sock' ';' -print 2>/dev/null | sort)
  fi

  printf '%s\n' "${dirs[@]}"
}

call_ipc() {
  local target="$1"
  shift
  quickshell ipc --id "${instance_id}" call "${target}" "$@"
}

main() {
  require_cmd quickshell
  require_cmd sleep

  if ! [[ "${delay_seconds}" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    printf 'Delay must be numeric, got: %s\n' "${delay_seconds}" >&2
    exit 2
  fi

  if [[ -z "${instance_id}" ]]; then
    mapfile -t live_instances < <(discover_instances)

    if (( ${#live_instances[@]} == 0 )); then
      printf 'No live QuickShell instances found under %s\n' "${runtime_root}" >&2
      exit 1
    elif (( ${#live_instances[@]} > 1 )); then
      printf 'Multiple QuickShell instances found:\n' >&2
      printf '  %s\n' "${live_instances[@]}" >&2
      printf 'Re-run with --id INSTANCE_ID\n' >&2
      exit 1
    fi

    instance_id="${live_instances[0]}"
  fi

  quickshell ipc --id "${instance_id}" show >/dev/null
  call_ipc Shell reloadConfig
  call_ipc SettingsHub open
  printf '[INFO] Opened SettingsHub on instance %s\n' "${instance_id}"

  for tab_id in "${tab_ids[@]}"; do
    call_ipc SettingsHub openTab "${tab_id}"
    printf '[INFO] Showing tab: %s\n' "${tab_id}"
    sleep "${delay_seconds}"
  done

  printf '[INFO] Tab preview complete. Continue manual viewport QA using the runbook.\n'
}

main "$@"

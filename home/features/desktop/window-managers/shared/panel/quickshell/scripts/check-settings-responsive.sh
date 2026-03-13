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

pass_count=0
warn_count=0
fail_count=0

pass() {
  printf '[PASS] %s\n' "$1"
  pass_count=$((pass_count + 1))
}

warn() {
  printf '[WARN] %s\n' "$1"
  warn_count=$((warn_count + 1))
}

fail() {
  printf '[FAIL] %s\n' "$1" >&2
  fail_count=$((fail_count + 1))
}

usage() {
  cat <<'EOF'
Usage: check-settings-responsive.sh [--id INSTANCE_ID]

Smoke-check the live QuickShell settings surface by:
  1. locating a running QuickShell instance,
  2. reloading the config,
  3. opening SettingsHub,
  4. cycling the highest-risk settings tabs,
  5. scanning new runtime log output for warnings/errors.

If more than one live instance is present, pass --id INSTANCE_ID explicitly.
EOF
}

instance_id=""

while [[ $# -gt 0 ]]; do
  case "$1" in
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

discover_instances() {
  local dirs=()
  local dir

  if [[ ! -d "${runtime_root}" ]]; then
    return 0
  fi

  while IFS= read -r dir; do
    dirs+=("$(basename "${dir}")")
  done < <(find "${runtime_root}" -mindepth 1 -maxdepth 1 -type d -exec test -S '{}/ipc.sock' ';' -print 2>/dev/null | sort)

  printf '%s\n' "${dirs[@]}"
}

call_ipc() {
  local target="$1"
  shift
  quickshell ipc --id "${instance_id}" call "${target}" "$@"
}

main() {
  require_cmd quickshell
  require_cmd sed
  require_cmd tail
  require_cmd grep

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

  local instance_dir="${runtime_root}/${instance_id}"
  local log_file="${instance_dir}/log.log"
  local start_bytes=0
  local delta_file
  delta_file="$(mktemp)"
  trap "rm -f '${delta_file}'" EXIT

  if [[ ! -S "${instance_dir}/ipc.sock" ]]; then
    printf 'Instance %s does not expose ipc.sock at %s\n' "${instance_id}" "${instance_dir}/ipc.sock" >&2
    exit 1
  fi

  if [[ -f "${log_file}" ]]; then
    start_bytes="$(wc -c < "${log_file}")"
  fi

  if quickshell ipc --id "${instance_id}" show >/dev/null; then
    pass "IPC reachable for instance ${instance_id}"
  else
    fail "IPC unreachable for instance ${instance_id}"
    printf '[INFO] Summary: %d pass, %d warn, %d fail\n' "${pass_count}" "${warn_count}" "${fail_count}"
    exit 1
  fi

  if call_ipc Shell reloadConfig; then
    pass "Shell.reloadConfig"
  else
    fail "Shell.reloadConfig"
  fi

  if call_ipc SettingsHub open; then
    pass "SettingsHub.open"
  else
    fail "SettingsHub.open"
  fi

  for tab_id in "${tab_ids[@]}"; do
    if call_ipc SettingsHub openTab "${tab_id}"; then
      pass "SettingsHub.openTab ${tab_id}"
    else
      fail "SettingsHub.openTab ${tab_id}"
    fi
  done

  sleep 1

  if [[ -f "${log_file}" ]]; then
    local start_byte=1
    if (( start_bytes > 0 )); then
      start_byte=$((start_bytes + 1))
    fi
    tail -c +"${start_byte}" "${log_file}" > "${delta_file}" || true
  fi

  if [[ -s "${delta_file}" ]]; then
    local filtered
    filtered="$(grep -Evi 'qt\.qpa\.wayland\.textinput|qt\.svg: .*Could not resolve property' "${delta_file}" || true)"
    if [[ -n "${filtered}" ]] && printf '%s' "${filtered}" | grep -Eqi 'warn|error|exception|binding loop|ReferenceError|TypeError|failed'; then
      fail "New runtime warnings/errors detected"
      printf '%s\n' "${filtered}" >&2
    else
      warn "New log output observed, but only known non-blocking warnings were present"
    fi
  else
    pass "No new runtime warnings/errors in QuickShell log"
  fi

  printf '[INFO] Manual visual QA still required for wide, laptop, and narrow/portrait layouts.\n'
  printf '[INFO] Summary: %d pass, %d warn, %d fail\n' "${pass_count}" "${warn_count}" "${fail_count}"
  (( fail_count == 0 ))
}

main "$@"

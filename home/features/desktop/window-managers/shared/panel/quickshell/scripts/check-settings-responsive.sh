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
This is a live-session check and reports PASS/WARN/FAIL outcomes only; it does not use
the headless multibar [SKIP] classification.
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

run_ipc() {
  local output=""
  local status=0
  local attempt

  for attempt in 1 2 3 4 5; do
    output="$(timeout 5s "$@" 2>&1)"
    status=$?
    if [[ "${output}" == *"Not ready to accept queries yet."* ]]; then
      sleep 0.2
      continue
    fi
    if [[ ${status} -eq 0 ]]; then
      return 0
    fi
    [[ -n "${output}" ]] && printf '%s\n' "${output}" >&2
    return "${status}"
  done

  [[ -n "${output}" ]] && printf '%s\n' "${output}" >&2
  return "${status}"
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

discover_reachable_instance() {
  local candidate
  while IFS= read -r candidate; do
    [[ -n "${candidate}" ]] || continue
    if run_ipc quickshell ipc --id "${candidate}" show >/dev/null; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done < <(discover_instances)

  return 1
}

resolve_instance_dir() {
  local requested_id="$1"
  local direct_dir="${runtime_root}/${requested_id}"
  local resolved_dir=""

  if [[ -S "${direct_dir}/ipc.sock" ]]; then
    printf '%s\n' "${direct_dir}"
    return 0
  fi

  resolved_dir="$(
    rg -l --fixed-strings "Shell ID: \"${requested_id}\"" "${runtime_root}"/*/log.log 2>/dev/null \
      | xargs -r stat -c '%Y %n' 2>/dev/null \
      | sort -nr \
      | head -n1 \
      | cut -d' ' -f2- \
      | xargs -r dirname
  )"

  if [[ -n "${resolved_dir}" && -S "${resolved_dir}/ipc.sock" ]]; then
    printf '%s\n' "${resolved_dir}"
    return 0
  fi

  return 1
}

call_ipc() {
  local target="$1"
  shift
  run_ipc quickshell ipc --id "${instance_id}" call "${target}" "$@"
}

main() {
  require_cmd quickshell
  require_cmd timeout
  require_cmd sed
  require_cmd tail
  require_cmd grep

  if [[ -z "${instance_id}" ]]; then
    instance_id="$(discover_reachable_instance || true)"
    if [[ -z "${instance_id}" ]]; then
      printf 'No live QuickShell instances found under %s\n' "${runtime_root}" >&2
      exit 1
    fi
  fi

  local instance_dir=""
  local log_file="${instance_dir}/log.log"
  local start_bytes=0
  local delta_file
  delta_file="$(mktemp)"
  trap "rm -f '${delta_file}'" EXIT

  instance_dir="$(resolve_instance_dir "${instance_id}" || true)"
  if [[ -z "${instance_dir}" || ! -S "${instance_dir}/ipc.sock" ]]; then
    printf 'Unable to resolve a live runtime directory for instance %s under %s\n' "${instance_id}" "${runtime_root}" >&2
    exit 1
  fi
  instance_id="$(basename "${instance_dir}")"
  log_file="${instance_dir}/log.log"

  if [[ -f "${log_file}" ]]; then
    start_bytes="$(wc -c < "${log_file}")"
  fi

  if run_ipc quickshell ipc --id "${instance_id}" show >/dev/null; then
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

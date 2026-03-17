#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
runtime_root="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell/by-id"
config_root="$(CDPATH= cd -- "${script_dir}/../config" >/dev/null && pwd)"
instance_id=""
repo_shell_mode=0
repo_shell_pid=""
repo_shell_service_was_active=0
repo_shell_env=()
settings_preset="portrait"
surface_crop="surface"
workspace_target="auto"
output_dir="/tmp/panel-qa-matrix"
settings_delay="2.5"
surface_delay="1.6"
settings_deep_scroll_y=""
run_settings=1
run_surfaces=1
run_launcher=1

source "${script_dir}/gallery-lib.sh"

write_gallery() {
  write_gallery_v2 "$1" "Panel QA Matrix" "capture-panel-matrix.sh"
}


usage() {
  cat <<'EOF'
Usage: capture-panel-matrix.sh [--id INSTANCE_ID] [--repo-shell] [--output-dir DIR] [--settings-preset portrait|laptop|wide] [--surface-crop surface|monitor|usable] [--workspace current|auto|NAME] [--settings-delay SECONDS] [--surface-delay SECONDS] [--settings-deep-scroll-y PX] [--skip-settings] [--skip-surfaces] [--skip-launcher]

Capture the shared panel QA artifact set:
  - launcher screenshots for portrait, laptop, and wide presets
  - high-risk settings tab screenshots
  - high-risk popup/panel surface screenshots

This produces review artifacts for manual inspection, not PASS/WARN/FAIL results.
`--repo-shell` temporarily stops the managed quickshell.service, launches the repo checkout
config as the live shell, captures against that instance, then restores the service.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --id)
      instance_id="${2:-}"
      shift 2
      ;;
    --repo-shell)
      repo_shell_mode=1
      shift
      ;;
    --output-dir)
      output_dir="${2:-}"
      shift 2
      ;;
    --settings-preset)
      settings_preset="${2:-}"
      shift 2
      ;;
    --surface-crop)
      surface_crop="${2:-}"
      shift 2
      ;;
    --workspace)
      workspace_target="${2:-}"
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
    --settings-deep-scroll-y)
      settings_deep_scroll_y="${2:-}"
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
    --skip-launcher)
      run_launcher=0
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

if [[ -n "${settings_deep_scroll_y}" ]] && ! [[ "${settings_deep_scroll_y}" =~ ^[0-9]+$ ]]; then
  printf 'settings-deep-scroll-y must be a non-negative integer.\n' >&2
  exit 2
fi

pid_looks_like_quickshell() {
  local pid
  local exe=""
  local comm=""
  local cmdline=""

  pid="${1:-}"
  [[ -n "${pid}" ]] || return 1
  kill -0 "${pid}" >/dev/null 2>&1 || return 1

  exe="$(readlink -f "/proc/${pid}/exe" 2>/dev/null || true)"
  comm="$(cat "/proc/${pid}/comm" 2>/dev/null || true)"
  if [[ -r "/proc/${pid}/cmdline" ]]; then
    cmdline="$(tr '\0' ' ' < "/proc/${pid}/cmdline" 2>/dev/null || true)"
  fi

  [[ "${exe}" == *quickshell* || "${comm}" == *quickshell* || "${cmdline}" == *quickshell* ]]
}

instance_for_pid() {
  local pid="$1"
  local resolved=""

  pid_looks_like_quickshell "${pid}" || return 1

  resolved="$(readlink -f "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell/by-pid/${pid}" 2>/dev/null || true)"
  if [[ -n "${resolved}" && -S "${resolved}/ipc.sock" ]]; then
    basename "${resolved}"
    return 0
  fi

  return 1
}

discover_instances_from_pid() {
  local pid

  while IFS= read -r pid; do
    [[ -n "${pid}" ]] || continue
    instance_for_pid "${pid}" || continue
  done < <(
    {
      find "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell/by-pid" -mindepth 1 -maxdepth 1 -type l -printf '%f\n' 2>/dev/null || true
      ps -eo pid=,comm= | awk '$2 ~ /quickshell|\\.quickshell-wra/ { print $1 }'
    } | awk 'NF && !seen[$0]++'
  )
}

discover_instance() {
  local ids=()
  mapfile -t ids < <(discover_instances_from_pid)
  if (( ${#ids[@]} == 1 )); then
    printf '%s\n' "${ids[0]}"
    return 0
  fi

  return 1
}

run_ipc() {
  local output=""
  local status=0
  local attempt

  for attempt in 1 2 3 4 5; do
    output="$(timeout 5s "$@" 2>&1)" && return 0
    status=$?
    if [[ "${output}" == *"Not ready to accept queries yet."* ]]; then
      sleep 0.2
      continue
    fi
    [[ -n "${output}" ]] && printf '%s\n' "${output}" >&2
    return "${status}"
  done

  [[ -n "${output}" ]] && printf '%s\n' "${output}" >&2
  return "${status}"
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

populate_repo_shell_env() {
  local line=""
  local key=""
  local value=""

  repo_shell_env=()
  for key in HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY NIRI_SOCKET XDG_CURRENT_DESKTOP DESKTOP_SESSION; do
    value="${!key:-}"
    if [[ -n "${value}" ]]; then
      repo_shell_env+=("${key}=${value}")
    fi
  done

  if (( ${#repo_shell_env[@]} > 0 )); then
    return 0
  fi

  while IFS= read -r line; do
    [[ "${line}" == *=* ]] || continue
    key="${line%%=*}"
    value="${line#*=}"
    case "${key}" in
      HYPRLAND_INSTANCE_SIGNATURE|WAYLAND_DISPLAY|NIRI_SOCKET|XDG_CURRENT_DESKTOP|DESKTOP_SESSION)
        [[ -n "${value}" ]] && repo_shell_env+=("${key}=${value}")
        ;;
    esac
  done < <(systemctl --user show-environment 2>/dev/null || true)
}

start_repo_shell() {
  local deadline=0
  local candidate=""

  if ! command -v systemctl >/dev/null 2>&1; then
    printf 'systemctl is required for --repo-shell mode.\n' >&2
    exit 1
  fi

  if systemctl --user is-active --quiet quickshell.service; then
    repo_shell_service_was_active=1
    systemctl --user stop quickshell.service >/dev/null 2>&1 || true
    sleep 1
  fi

  populate_repo_shell_env
  env "${repo_shell_env[@]}" quickshell -p "${config_root}/shell.qml" >/tmp/quickshell-repo-qa.log 2>&1 &
  repo_shell_pid="$!"

  deadline=$((SECONDS + 20))
  while (( SECONDS < deadline )); do
    candidate="$(instance_for_pid "${repo_shell_pid}" || true)"
    if [[ -n "${candidate}" ]] && run_ipc quickshell ipc --id "${candidate}" call SettingsHub close >/dev/null; then
      instance_id="${candidate}"
      printf '[INFO] Repo shell instance ready: %s\n' "${instance_id}"
      return 0
    fi
    sleep 0.5
  done

  printf 'Repo shell did not become IPC-ready in time. See /tmp/quickshell-repo-qa.log\n' >&2
  echo "--- repo shell env ---" >&2
  printf '%s\n' "${repo_shell_env[@]}" >&2 || true
  echo "--- systemd user env ---" >&2
  systemctl --user show-environment 2>/dev/null | grep -E 'HYPRLAND|WAYLAND|NIRI|XDG_CURRENT_DESKTOP|DESKTOP_SESSION' >&2 || true
  echo "--- quickshell repo qa log ---" >&2
  sed -n '1,200p' /tmp/quickshell-repo-qa.log >&2 || true
  exit 1
}

main() {
  if (( run_settings == 0 && run_surfaces == 0 && run_launcher == 0 )); then
    printf 'Nothing to capture. Remove at least one --skip-* flag.\n' >&2
    exit 2
  fi

  if (( repo_shell_mode == 1 )); then
    trap cleanup_repo_shell EXIT
    start_repo_shell
  fi

  if (( run_surfaces == 1 )) && [[ -z "${instance_id}" ]]; then
    instance_id="$(discover_instance || true)"
    if [[ -z "${instance_id}" ]]; then
      printf 'Could not uniquely resolve a live QuickShell instance for surface capture. Re-run with --id INSTANCE_ID.\n' >&2
      exit 1
    fi
  fi

  mkdir -p "${output_dir}"

  if (( run_launcher == 1 )); then
    local launcher_preset=""
    for launcher_preset in portrait laptop wide; do
      printf '[INFO] Capturing launcher matrix (%s)...\n' "${launcher_preset}"
      bash "${script_dir}/capture-launcher-matrix.sh" \
        --id "${instance_id}" \
        --preset "${launcher_preset}" \
        --delay "${surface_delay}" \
        --workspace "${workspace_target}" \
        --output-dir "${output_dir}/launcher-${launcher_preset}"
    done
  fi

  if (( run_settings == 1 )); then
    local deep_scroll_y="${settings_deep_scroll_y}"
    if [[ -z "${deep_scroll_y}" && "${settings_preset}" == "portrait" ]]; then
      deep_scroll_y="520"
    fi

    printf '[INFO] Capturing settings matrix (%s)...\n' "${settings_preset}"
    bash "${script_dir}/capture-settings-matrix.sh" \
      --id "${instance_id}" \
      --preset "${settings_preset}" \
      --delay "${settings_delay}" \
      --workspace "${workspace_target}" \
      --output-dir "${output_dir}/settings-${settings_preset}"

    if [[ -n "${deep_scroll_y}" ]]; then
      printf '[INFO] Capturing settings matrix (%s, scroll %s)...\n' "${settings_preset}" "${deep_scroll_y}"
      bash "${script_dir}/capture-settings-matrix.sh" \
        --id "${instance_id}" \
        --preset "${settings_preset}" \
        --delay "${settings_delay}" \
        --scroll-y "${deep_scroll_y}" \
        --workspace "${workspace_target}" \
        --output-dir "${output_dir}/settings-${settings_preset}-deep"
    fi
  fi

  if (( run_surfaces == 1 )); then
    printf '[INFO] Capturing surface matrix (%s)...\n' "${surface_crop}"
    bash "${script_dir}/capture-surface-matrix.sh" \
      --id "${instance_id}" \
      --crop "${surface_crop}" \
      --delay "${surface_delay}" \
      --workspace "${workspace_target}" \
      --output-dir "${output_dir}/surfaces-${surface_crop}"
  fi

  write_gallery "${output_dir}"

  printf '[INFO] Saved panel QA review artifacts to %s\n' "${output_dir}"
  printf '[INFO] Saved review gallery to %s/index.html\n' "${output_dir}"
}

main "$@"

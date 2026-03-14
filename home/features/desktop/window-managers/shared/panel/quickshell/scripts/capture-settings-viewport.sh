#!/usr/bin/env bash
set -euo pipefail

runtime_root="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell/by-id"

width=900
height=700
tab_id="wallpaper"
instance_id=""
hyprland_instance=""
hyprland_wayland_socket=""
output_path=""
delay_seconds="1.2"
ipc_timeout_seconds="2"
scroll_y="0"
workspace_target="auto"
workspace_settle_attempts="20"
workspace_settle_interval="0.1"
temp_full=""
temp_crop=""
restore_workspace=""

usage() {
  cat <<'EOF'
Usage: capture-settings-viewport.sh [--id INSTANCE_ID] [--width PX] [--height PX] [--tab TAB_ID] [--delay SECONDS] [--scroll-y PX] [--workspace current|auto|NAME] [--output PATH]

Open the live SettingsHub through QuickShell IPC, capture a centered viewport-sized
screenshot from the focused monitor, and save it to a file.

Note: scroll-y is currently ignored in live capture mode.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --id)
      instance_id="${2:-}"
      shift 2
      ;;
    --width)
      width="${2:-}"
      shift 2
      ;;
    --height)
      height="${2:-}"
      shift 2
      ;;
    --tab)
      tab_id="${2:-}"
      shift 2
      ;;
    --delay)
      delay_seconds="${2:-}"
      shift 2
      ;;
    --ipc-timeout)
      ipc_timeout_seconds="${2:-}"
      shift 2
      ;;
    --scroll-y)
      scroll_y="${2:-}"
      shift 2
      ;;
    --workspace)
      workspace_target="${2:-}"
      shift 2
      ;;
    --output)
      output_path="${2:-}"
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

hypr() {
  if [[ -n "${hyprland_instance}" ]]; then
    env HYPRLAND_INSTANCE_SIGNATURE="${hyprland_instance}" WAYLAND_DISPLAY="${hyprland_wayland_socket}" \
      hyprctl -i "${hyprland_instance}" "$@"
  else
    hyprctl "$@"
  fi
}

resolve_hyprland_instance() {
  local candidate
  local wl_socket

  if hyprctl -j activeworkspace >/dev/null 2>&1; then
    hyprland_instance=""
    hyprland_wayland_socket=""
    return 0
  fi

  while IFS=$'\t' read -r candidate wl_socket; do
    [[ -n "${candidate}" ]] || continue
    if env HYPRLAND_INSTANCE_SIGNATURE="${candidate}" WAYLAND_DISPLAY="${wl_socket}" \
      hyprctl -i "${candidate}" -j activeworkspace >/dev/null 2>&1; then
      hyprland_instance="${candidate}"
      hyprland_wayland_socket="${wl_socket}"
      return 0
    fi
  done < <(hyprctl instances -j | jq -r '.[] | [.instance // "", .wl_socket // ""] | @tsv')

  printf 'Could not resolve a reachable Hyprland instance.\n' >&2
  exit 1
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
    if timeout "${ipc_timeout_seconds}s" quickshell ipc --id "${candidate}" show >/dev/null 2>&1; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done < <(discover_instances)

  return 1
}

pick_capture_workspace() {
  local used
  for candidate in $(seq 9001 9099); do
    used="$(hypr workspaces -j | jq --arg candidate "${candidate}" 'map(select((.name // "") == $candidate or ((.id | tostring) == $candidate))) | length')"
    if [[ "${used}" == "0" ]]; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done
  return 1
}

wait_for_workspace() {
  local target="$1"
  local current_name
  local current_id
  local attempt

  for attempt in $(seq 1 "${workspace_settle_attempts}"); do
    current_name="$(hypr activeworkspace -j | jq -r '.name // empty')"
    current_id="$(hypr activeworkspace -j | jq -r '(.id | tostring) // empty')"
    if [[ "${current_name}" == "${target}" || "${current_id}" == "${target}" ]]; then
      return 0
    fi
    sleep "${workspace_settle_interval}"
  done

  printf 'Workspace %s did not become active in time.\n' "${target}" >&2
  exit 1
}

switch_to_capture_workspace() {
  local requested="$1"
  local target="${requested}"
  if [[ "${requested}" == "current" ]]; then
    return 0
  fi

  restore_workspace="$(hypr activeworkspace -j | jq -r '.name // (.id | tostring)')"
  if [[ -z "${restore_workspace}" || "${restore_workspace}" == "null" ]]; then
    printf 'Could not resolve active workspace before capture.\n' >&2
    exit 1
  fi

  if [[ "${requested}" == "auto" ]]; then
    target="$(pick_capture_workspace)" || {
      printf 'Could not allocate a dedicated capture workspace.\n' >&2
      exit 1
    }
  fi

  hypr dispatch workspace "${target}" >/dev/null
  wait_for_workspace "${target}"
}

call_ipc() {
  local target="$1"
  shift
  timeout "${ipc_timeout_seconds}s" quickshell ipc --id "${instance_id}" call "${target}" "$@"
}

main() {
  require_cmd quickshell
  require_cmd hyprctl
  require_cmd jq
  require_cmd grim
  require_cmd magick
  require_cmd mktemp
  require_cmd sed
  require_cmd find
  require_cmd ps
  resolve_hyprland_instance

  if ! [[ "${width}" =~ ^[0-9]+$ ]] || ! [[ "${height}" =~ ^[0-9]+$ ]]; then
    printf 'Width and height must be integers.\n' >&2
    exit 2
  fi
  if ! [[ "${delay_seconds}" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    printf 'Delay must be numeric.\n' >&2
    exit 2
  fi
  if ! [[ "${ipc_timeout_seconds}" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    printf 'IPC timeout must be numeric.\n' >&2
    exit 2
  fi
  if ! [[ "${scroll_y}" =~ ^[0-9]+$ ]]; then
    printf 'scroll-y must be a non-negative integer.\n' >&2
    exit 2
  fi

  if [[ -n "${scroll_y}" && "${scroll_y}" != "0" ]]; then
    printf '[WARN] scroll-y is ignored in live SettingsHub capture mode.\n' >&2
  fi

  if [[ -z "${instance_id}" ]]; then
    instance_id="$(discover_reachable_instance || true)"
    if [[ -z "${instance_id}" ]]; then
      printf 'No live QuickShell instances found under %s\n' "${runtime_root}" >&2
      exit 1
    fi
  fi

  if [[ -z "${output_path}" ]]; then
    output_path="/tmp/settings-${tab_id}-${width}x${height}.png"
  fi

  temp_full="$(mktemp /tmp/settings-viewport-full-XXXXXX.png)"
  temp_crop="$(mktemp /tmp/settings-viewport-crop-XXXXXX.png)"

  trap 'call_ipc SettingsHub close >/dev/null 2>&1 || true; [[ -n "${restore_workspace}" ]] && hypr dispatch workspace "${restore_workspace}" >/dev/null 2>&1 || true; rm -f "${temp_full}" "${temp_crop}"' EXIT

  switch_to_capture_workspace "${workspace_target}"

  if ! timeout "${ipc_timeout_seconds}s" quickshell ipc --id "${instance_id}" show >/dev/null; then
    printf 'Live QuickShell IPC is not responding for instance %s.\n' "${instance_id}" >&2
    exit 1
  fi
  if ! call_ipc Shell reloadConfig >/dev/null; then
    printf 'Shell.reloadConfig timed out for instance %s.\n' "${instance_id}" >&2
    exit 1
  fi
  if ! call_ipc SettingsHub openTab "${tab_id}" >/dev/null; then
    printf 'SettingsHub.openTab %s timed out for instance %s.\n' "${tab_id}" "${instance_id}" >&2
    exit 1
  fi
  sleep "${delay_seconds}"

  local monitor_json monitor_x monitor_y monitor_w monitor_h reserved_top reserved_left reserved_bottom reserved_right usable_w usable_h crop_x crop_y crop_w crop_h
  monitor_json="$(hypr monitors -j | jq 'map(select(.focused == true))[0]')"
  if [[ -z "${monitor_json}" || "${monitor_json}" == "null" ]]; then
    printf 'Could not resolve focused monitor from hyprctl.\n' >&2
    exit 1
  fi

  monitor_x="$(printf '%s' "${monitor_json}" | jq -r '.x')"
  monitor_y="$(printf '%s' "${monitor_json}" | jq -r '.y')"
  monitor_w="$(printf '%s' "${monitor_json}" | jq -r '.width')"
  monitor_h="$(printf '%s' "${monitor_json}" | jq -r '.height')"
  reserved_top="$(printf '%s' "${monitor_json}" | jq -r '.reserved[0]')"
  reserved_left="$(printf '%s' "${monitor_json}" | jq -r '.reserved[1]')"
  reserved_bottom="$(printf '%s' "${monitor_json}" | jq -r '.reserved[2]')"
  reserved_right="$(printf '%s' "${monitor_json}" | jq -r '.reserved[3]')"

  usable_w=$((monitor_w - reserved_left - reserved_right))
  usable_h=$((monitor_h - reserved_top - reserved_bottom))
  crop_w=$(( width < usable_w ? width : usable_w ))
  crop_h=$(( height < usable_h ? height : usable_h ))
  crop_x=$((monitor_x + reserved_left + (usable_w - crop_w) / 2))
  crop_y=$((monitor_y + reserved_top + (usable_h - crop_h) / 2))

  grim -t png "${temp_full}"
  magick "${temp_full}" -crop "${crop_w}x${crop_h}+${crop_x}+${crop_y}" +repage "${temp_crop}"
  cp "${temp_crop}" "${output_path}"

  printf '[INFO] Captured %s at %sx%s -> %s\n' "${tab_id}" "${crop_w}" "${crop_h}" "${output_path}"
}

main "$@"

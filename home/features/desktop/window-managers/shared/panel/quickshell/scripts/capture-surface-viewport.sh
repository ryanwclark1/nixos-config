#!/usr/bin/env bash
set -euo pipefail

runtime_root="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell/by-id"
instance_id=""
hyprland_instance=""
hyprland_wayland_socket=""
surface_id="networkMenu"
output_path=""
delay_seconds="1.6"
ipc_timeout_seconds="2"
crop_mode="monitor"
workspace_target="auto"
workspace_settle_attempts="20"
workspace_settle_interval="0.1"
temp_full=""
temp_crop=""
restore_workspace=""

usage() {
  cat <<'EOF'
Usage: capture-surface-viewport.sh [--id INSTANCE_ID] [--surface SURFACE_ID] [--delay SECONDS] [--crop monitor|usable] [--workspace current|auto|NAME] [--output PATH]

Open a live QuickShell surface through Shell IPC, capture the focused monitor, and save a cropped screenshot.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --id)
      instance_id="${2:-}"
      shift 2
      ;;
    --surface)
      surface_id="${2:-}"
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
    --crop)
      crop_mode="${2:-}"
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

discover_instances_from_pid() {
  local pid
  local resolved
  local ids=()

  while IFS= read -r pid; do
    [[ -n "${pid}" ]] || continue
    resolved="$(readlink -f "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell/by-pid/${pid}" 2>/dev/null || true)"
    if [[ -n "${resolved}" && -S "${resolved}/ipc.sock" ]]; then
      ids+=("$(basename "${resolved}")")
    fi
  done < <(ps -eo pid=,comm=,args= | awk '$2 ~ /quickshell/ || $3 ~ /quickshell/ { print $1 }')

  printf '%s\n' "${ids[@]}" | awk 'NF && !seen[$0]++'
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
    if timeout "${ipc_timeout_seconds}" quickshell ipc --id "${candidate}" show >/dev/null 2>&1; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done < <(discover_instances)

  return 1
}

call_ipc() {
  local target="$1"
  shift
  quickshell ipc --id "${instance_id}" call "${target}" "$@"
}

main() {
  require_cmd quickshell
  require_cmd hyprctl
  require_cmd jq
  require_cmd grim
  require_cmd magick
  require_cmd mktemp
  require_cmd sleep
  resolve_hyprland_instance

  if ! [[ "${delay_seconds}" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    printf 'Delay must be numeric.\n' >&2
    exit 2
  fi

  case "${crop_mode}" in
    monitor|usable) ;;
    *)
      printf 'Unknown crop mode: %s\n' "${crop_mode}" >&2
      exit 2
      ;;
  esac

  if [[ -z "${instance_id}" ]]; then
    instance_id="$(discover_reachable_instance || true)"
    if [[ -z "${instance_id}" ]]; then
      printf 'No live QuickShell instances found under %s\n' "${runtime_root}" >&2
      exit 1
    fi
  fi

  if [[ -z "${output_path}" ]]; then
    output_path="/tmp/${surface_id}-${crop_mode}.png"
  fi

  temp_full="$(mktemp /tmp/surface-capture-full-XXXXXX.png)"
  temp_crop="$(mktemp /tmp/surface-capture-crop-XXXXXX.png)"
  trap 'rm -f "${temp_full}" "${temp_crop}"; quickshell ipc --id "${instance_id}" call Shell closeAllSurfaces >/dev/null 2>&1 || true; [[ -n "${restore_workspace}" ]] && hypr dispatch workspace "${restore_workspace}" >/dev/null 2>&1 || true' EXIT

  switch_to_capture_workspace "${workspace_target}"

  quickshell ipc --id "${instance_id}" show >/dev/null
  call_ipc Shell reloadConfig >/dev/null
  call_ipc Shell closeAllSurfaces >/dev/null || true
  call_ipc Shell openSurface "${surface_id}" >/dev/null
  sleep "${delay_seconds}"

  local monitor_json monitor_x monitor_y monitor_w monitor_h reserved_top reserved_left reserved_bottom reserved_right crop_x crop_y crop_w crop_h
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

  if [[ "${crop_mode}" == "usable" ]]; then
    crop_x=$((monitor_x + reserved_left))
    crop_y=$((monitor_y + reserved_top))
    crop_w=$((monitor_w - reserved_left - reserved_right))
    crop_h=$((monitor_h - reserved_top - reserved_bottom))
  else
    crop_x="${monitor_x}"
    crop_y="${monitor_y}"
    crop_w="${monitor_w}"
    crop_h="${monitor_h}"
  fi

  grim -t png "${temp_full}"
  magick "${temp_full}" -crop "${crop_w}x${crop_h}+${crop_x}+${crop_y}" +repage "${temp_crop}"
  cp "${temp_crop}" "${output_path}"

  printf '[INFO] Captured %s (%s) -> %s\n' "${surface_id}" "${crop_mode}" "${output_path}"
}

main "$@"

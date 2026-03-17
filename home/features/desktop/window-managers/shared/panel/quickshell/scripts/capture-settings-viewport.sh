#!/usr/bin/env bash
set -euo pipefail

runtime_root="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell/by-id"

width=900
height=700
tab_id="wallpaper"
instance_id=""
compositor=""
hyprland_instance=""
hyprland_wayland_socket=""
output_path=""
delay_seconds="1.2"
ipc_timeout_seconds="2"
scroll_y="0"
frame_mode="modal"
workspace_target="auto"
workspace_settle_attempts="20"
workspace_settle_interval="0.1"
temp_full=""
temp_crop=""
restore_workspace=""
modal_capture_padding_x="32"
modal_capture_padding_y="20"

usage() {
  cat <<'EOF'
Usage: capture-settings-viewport.sh [--id INSTANCE_ID] [--width PX] [--height PX] [--tab TAB_ID] [--delay SECONDS] [--scroll-y PX] [--frame modal|viewport] [--workspace current|auto|NAME] [--output PATH]

Open the live SettingsHub through QuickShell IPC, capture a centered viewport-sized
screenshot from the focused monitor, and save it to a file.
This produces a review artifact for manual inspection, not PASS/WARN/FAIL results.

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
    --frame)
      frame_mode="${2:-}"
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

run_ipc() {
  local output=""
  local status=0
  local attempt

  for attempt in 1 2 3 4 5; do
    output="$(timeout "${ipc_timeout_seconds}s" "$@" 2>&1)" && return 0
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

detect_compositor() {
  if [[ -n "${NIRI_SOCKET:-}" ]] && command -v niri >/dev/null 2>&1 && niri msg -j workspaces >/dev/null 2>&1; then
    compositor="niri"
    return 0
  fi

  require_cmd hyprctl
  resolve_hyprland_instance
  compositor="hyprland"
}

hypr() {
  if [[ -n "${hyprland_instance}" ]]; then
    env HYPRLAND_INSTANCE_SIGNATURE="${hyprland_instance}" WAYLAND_DISPLAY="${hyprland_wayland_socket}" \
      hyprctl -i "${hyprland_instance}" "$@"
  else
    hyprctl "$@"
  fi
}

niri_msg() {
  niri msg -j "$@"
}

grim_capture() {
  if [[ -n "${hyprland_instance}" ]]; then
    env HYPRLAND_INSTANCE_SIGNATURE="${hyprland_instance}" WAYLAND_DISPLAY="${hyprland_wayland_socket}" \
      grim -t png "$@"
  else
    grim -t png "$@"
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
    if run_ipc quickshell ipc --id "${candidate}" call SettingsHub close >/dev/null; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done < <(discover_instances)

  return 1
}

active_workspace_token() {
  if [[ "${compositor}" == "niri" ]]; then
    niri_msg workspaces | jq -r '
      (if type == "array" then . else (.workspaces // []) end)[]
      | select(.is_active == true or .active == true or .is_focused == true or .focused == true)
      | (.idx // .id // .index // .name // empty)
    ' | head -n1
    return 0
  fi

  hypr activeworkspace -j | jq -r '.name // (.id | tostring)'
}

list_workspace_tokens() {
  if [[ "${compositor}" == "niri" ]]; then
    niri_msg workspaces | jq -r '
      (if type == "array" then . else (.workspaces // []) end)[]
      | (.idx // .id // .index // .name // empty)
    '
    return 0
  fi

  hypr workspaces -j | jq -r '.[] | (.name // (.id | tostring) // empty)'
}

focus_workspace() {
  local target="$1"

  if [[ "${compositor}" == "niri" ]]; then
    niri msg action focus-workspace "${target}" >/dev/null
    return 0
  fi

  hypr dispatch workspace "${target}" >/dev/null
}

focused_output_json() {
  if [[ "${compositor}" == "niri" ]]; then
    niri_msg outputs | jq '
      (if type == "array" then . else (.outputs // []) end)
      | (map(select(.is_focused == true or .focused == true or .active == true or .is_active == true))[0] // .[0])
    '
    return 0
  fi

  hypr monitors -j | jq 'map(select(.focused == true))[0]'
}

pick_capture_workspace() {
  local candidate
  for candidate in $(seq 9001 9099); do
    if ! list_workspace_tokens | grep -Fxq "${candidate}"; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done
  return 1
}

wait_for_workspace() {
  local target="$1"
  local current
  local attempt

  for attempt in $(seq 1 "${workspace_settle_attempts}"); do
    current="$(active_workspace_token)"
    if [[ "${current}" == "${target}" ]]; then
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

  restore_workspace="$(active_workspace_token)"
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

  focus_workspace "${target}"
  wait_for_workspace "${target}"
}

call_ipc() {
  local target="$1"
  shift
  run_ipc quickshell ipc --id "${instance_id}" call "${target}" "$@"
}

cleanup() {
  call_ipc SettingsHub close >/dev/null 2>&1 || true
  if [[ -n "${restore_workspace}" ]]; then
    focus_workspace "${restore_workspace}" >/dev/null 2>&1 || true
  fi
  rm -f "${temp_full}" "${temp_crop}"
}

main() {
  require_cmd quickshell
  require_cmd jq
  require_cmd grim
  require_cmd magick
  require_cmd mktemp
  require_cmd sed
  require_cmd find
  require_cmd ps
  detect_compositor

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
  if ! [[ "${modal_capture_padding_x}" =~ ^[0-9]+$ ]] || ! [[ "${modal_capture_padding_y}" =~ ^[0-9]+$ ]]; then
    printf 'Modal capture padding must be non-negative integers.\n' >&2
    exit 2
  fi
  case "${frame_mode}" in
    modal|viewport) ;;
    *)
      printf 'Frame must be modal or viewport.\n' >&2
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
    output_path="/tmp/settings-${tab_id}-${width}x${height}.png"
  fi

  temp_full="$(mktemp /tmp/settings-viewport-full-XXXXXX.png)"
  temp_crop="$(mktemp /tmp/settings-viewport-crop-XXXXXX.png)"

  trap cleanup EXIT

  switch_to_capture_workspace "${workspace_target}"

  call_ipc SettingsHub close >/dev/null 2>&1 || true
  if ! call_ipc SettingsHub open >/dev/null; then
    printf 'SettingsHub.open timed out for instance %s.\n' "${instance_id}" >&2
    exit 1
  fi
  sleep 0.2
  if ! call_ipc SettingsHub openTab "${tab_id}" >/dev/null; then
    printf 'SettingsHub.openTab %s timed out for instance %s.\n' "${tab_id}" "${instance_id}" >&2
    exit 1
  fi
  sleep "${delay_seconds}"

  local monitor_json monitor_x monitor_y monitor_w monitor_h reserved_top reserved_left reserved_bottom reserved_right usable_w usable_h crop_x crop_y crop_w crop_h gutter_x gutter_y modal_w modal_h
  monitor_json="$(focused_output_json)"
  if [[ -z "${monitor_json}" || "${monitor_json}" == "null" ]]; then
    printf 'Could not resolve focused output from %s.\n' "${compositor}" >&2
    exit 1
  fi

  monitor_x="$(printf '%s' "${monitor_json}" | jq -r '.logical.x // .logical_rect.x // .position.x // .x // 0')"
  monitor_y="$(printf '%s' "${monitor_json}" | jq -r '.logical.y // .logical_rect.y // .position.y // .y // 0')"
  monitor_w="$(printf '%s' "${monitor_json}" | jq -r '.logical.width // .logical_rect.width // .current_mode.width // .width // .physical.width // 0')"
  monitor_h="$(printf '%s' "${monitor_json}" | jq -r '.logical.height // .logical_rect.height // .current_mode.height // .height // .physical.height // 0')"
  if [[ "${compositor}" == "niri" ]]; then
    reserved_top=0
    reserved_left=0
    reserved_bottom=0
    reserved_right=0
  else
    reserved_top="$(printf '%s' "${monitor_json}" | jq -r '.reserved[0]')"
    reserved_left="$(printf '%s' "${monitor_json}" | jq -r '.reserved[1]')"
    reserved_bottom="$(printf '%s' "${monitor_json}" | jq -r '.reserved[2]')"
    reserved_right="$(printf '%s' "${monitor_json}" | jq -r '.reserved[3]')"
  fi

  usable_w=$((monitor_w - reserved_left - reserved_right))
  usable_h=$((monitor_h - reserved_top - reserved_bottom))
  if [[ "${frame_mode}" == "modal" ]]; then
    local padded_w padded_h
    gutter_x=$(( usable_w * 4 / 100 ))
    gutter_y=$(( usable_h * 4 / 100 ))
    (( gutter_x < 24 )) && gutter_x=24
    (( gutter_x > 56 )) && gutter_x=56
    (( gutter_y < 24 )) && gutter_y=24
    (( gutter_y > 48 )) && gutter_y=48

    modal_w=$(( usable_w - gutter_x * 2 ))
    (( modal_w < 320 )) && modal_w=320
    (( modal_w > 960 )) && modal_w=960

    modal_h=$(( usable_h - gutter_y * 2 ))
    (( modal_h < 360 )) && modal_h=360
    (( modal_h > 920 )) && modal_h=920

    padded_w=$(( modal_w + modal_capture_padding_x * 2 ))
    padded_h=$(( modal_h + modal_capture_padding_y * 2 ))
    (( padded_w > usable_w )) && padded_w=usable_w
    (( padded_h > usable_h )) && padded_h=usable_h

    crop_w="${padded_w}"
    crop_h="${padded_h}"
    crop_x=$((monitor_x + reserved_left + (usable_w - crop_w) / 2))
    crop_y=$((monitor_y + reserved_top + (usable_h - crop_h) / 2))
  else
    crop_w=$(( width < usable_w ? width : usable_w ))
    crop_h=$(( height < usable_h ? height : usable_h ))
    crop_x=$((monitor_x + reserved_left + (usable_w - crop_w) / 2))
    crop_y=$((monitor_y + reserved_top + (usable_h - crop_h) / 2))
  fi

  local start_time
  start_time="$(date +'%Y-%m-%d %H:%M:%S')"

  grim_capture "${temp_full}"
  magick "${temp_full}" -crop "${crop_w}x${crop_h}+${crop_x}+${crop_y}" +repage "${temp_crop}"
  cp "${temp_crop}" "${output_path}"

  # Dump correlated logs
  local log_file="${output_path%.png}.log"
  journalctl --user --since "${start_time}" > "${log_file}" 2>/dev/null || true

  # Scan for health status
  local status="clean"
  if grep -qiE "error|critical|failed|exception" "${log_file}"; then
    status="error"
  elif grep -qiE "warn|alert" "${log_file}"; then
    status="warning"
  fi
  printf '%s' "${status}" > "${log_file}.status"

  printf '[INFO] Saved settings review artifact for %s at %sx%s (logs: %s) -> %s\n' "${tab_id}" "${crop_w}" "${crop_h}" "${status}" "${output_path}"
}

main "$@"

#!/usr/bin/env bash
set -euo pipefail

runtime_root="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell/by-id"
instance_id=""
surface_id="networkMenu"
output_path=""
delay_seconds="1.6"
crop_mode="monitor"
workspace_target="auto"
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

pick_capture_workspace() {
  local used
  for candidate in $(seq 9001 9099); do
    used="$(hyprctl workspaces -j | jq --arg candidate "${candidate}" 'map(select((.name // "") == $candidate or ((.id | tostring) == $candidate))) | length')"
    if [[ "${used}" == "0" ]]; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done
  return 1
}

switch_to_capture_workspace() {
  local requested="$1"
  local target="${requested}"
  if [[ "${requested}" == "current" ]]; then
    return 0
  fi

  restore_workspace="$(hyprctl -j activeworkspace | jq -r '.name // (.id | tostring)')"
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

  hyprctl dispatch workspace "${target}" >/dev/null
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

  if [[ -z "${output_path}" ]]; then
    output_path="/tmp/${surface_id}-${crop_mode}.png"
  fi

  temp_full="$(mktemp /tmp/surface-capture-full-XXXXXX.png)"
  temp_crop="$(mktemp /tmp/surface-capture-crop-XXXXXX.png)"
  trap 'rm -f "${temp_full}" "${temp_crop}"; quickshell ipc --id "${instance_id}" call Shell closeAllSurfaces >/dev/null 2>&1 || true; [[ -n "${restore_workspace}" ]] && hyprctl dispatch workspace "${restore_workspace}" >/dev/null 2>&1 || true' EXIT

  switch_to_capture_workspace "${workspace_target}"

  quickshell ipc --id "${instance_id}" show >/dev/null
  call_ipc Shell reloadConfig >/dev/null
  call_ipc Shell closeAllSurfaces >/dev/null || true
  call_ipc Shell openSurface "${surface_id}" >/dev/null
  sleep "${delay_seconds}"

  local monitor_json monitor_x monitor_y monitor_w monitor_h reserved_top reserved_left reserved_bottom reserved_right crop_x crop_y crop_w crop_h
  monitor_json="$(hyprctl monitors -j | jq 'map(select(.focused == true))[0]')"
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

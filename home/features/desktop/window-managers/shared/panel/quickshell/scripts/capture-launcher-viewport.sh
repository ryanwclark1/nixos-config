#!/usr/bin/env bash
set -euo pipefail

runtime_base="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell"
runtime_root="${runtime_base}/by-id"
instance_id=""
hyprland_instance=""
hyprland_wayland_socket=""
mode="drun"
state="home"
query=""
category_key=""
output_path=""
delay_seconds="1.2"
ipc_timeout_seconds="2"
crop_mode="usable"
workspace_target="auto"
workspace_settle_attempts="20"
workspace_settle_interval="0.1"
temp_full=""
temp_crop=""
restore_workspace=""
capture_workspace=""

usage() {
  cat <<'EOF'
Usage: capture-launcher-viewport.sh [--id INSTANCE_ID] [--mode drun|files|system|web] [--state home|query|empty|category] [--query TEXT] [--category KEY] [--delay SECONDS] [--crop monitor|usable] [--workspace current|auto|NAME] [--output PATH]

Open the launcher through IPC, optionally drive a state preset, capture the focused monitor,
and save a review screenshot.

Examples:
  scripts/capture-launcher-viewport.sh --mode drun --state home
  scripts/capture-launcher-viewport.sh --mode drun --state query --query firefox
  scripts/capture-launcher-viewport.sh --mode files --state empty --query /unlikely-launcher-capture-probe
  scripts/capture-launcher-viewport.sh --mode drun --state category --category Utility
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --id)
      instance_id="${2:-}"
      shift 2
      ;;
    --mode)
      mode="${2:-}"
      shift 2
      ;;
    --state)
      state="${2:-}"
      shift 2
      ;;
    --query)
      query="${2:-}"
      shift 2
      ;;
    --category)
      category_key="${2:-}"
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
  local candidate
  for candidate in $(seq 9101 9199); do
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
    capture_workspace="$(hypr activeworkspace -j | jq -r '.name // (.id | tostring)')"
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

  capture_workspace="${target}"
  hypr dispatch workspace "${target}" >/dev/null
  wait_for_workspace "${target}"
}

reassert_capture_workspace() {
  [[ -n "${capture_workspace}" ]] || return 0
  hypr dispatch workspace "${capture_workspace}" >/dev/null
  wait_for_workspace "${capture_workspace}"
}

discover_instances() {
  if [[ ! -d "${runtime_root}" ]]; then
    return 0
  fi
  find "${runtime_root}" -mindepth 1 -maxdepth 1 -type d -exec test -S '{}/ipc.sock' ';' -printf '%T@ %f\n' 2>/dev/null \
    | sort -nr | awk '{print $2}'
}

discover_reachable_instance() {
  local candidate
  local show_output
  while IFS= read -r candidate; do
    [[ -n "${candidate}" ]] || continue
    show_output="$(quickshell ipc --id "${candidate}" show 2>/dev/null || true)"
    [[ -n "${show_output}" ]] || continue
    if ! printf '%s' "${show_output}" | rg -q "target Launcher"; then
      continue
    fi
    if run_ipc quickshell ipc --id "${candidate}" call Launcher openDrun >/dev/null; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done < <(discover_instances)

  return 1
}

call_ipc() {
  local target="$1"
  shift
  run_ipc quickshell ipc --id "${instance_id}" call "${target}" "$@"
}

apply_launcher_state() {
  local mode_action=""

  case "${mode}" in
    drun) mode_action="openDrun" ;;
    files) mode_action="openFiles" ;;
    system) mode_action="openSystem" ;;
    web) mode_action="openWeb" ;;
    *)
      printf 'Unsupported launcher mode: %s\n' "${mode}" >&2
      exit 2
      ;;
  esac

  case "${state}" in
    home|query|empty|category) ;;
    *)
      printf 'Unsupported launcher state: %s\n' "${state}" >&2
      exit 2
      ;;
  esac

  call_ipc Launcher "${mode_action}" >/dev/null
  sleep 0.15

  if call_ipc Launcher diagnosticSetSearchText "" >/dev/null 2>&1; then
    :
  fi
  if call_ipc Launcher diagnosticSetDrunCategoryFilter "" >/dev/null 2>&1; then
    :
  fi

  case "${state}" in
    home)
      ;;
    query)
      if [[ -z "${query}" ]]; then
        case "${mode}" in
          drun) query="firefox" ;;
          files) query="/nix" ;;
          system) query="reboot" ;;
          web) query="wayland" ;;
        esac
      fi
      call_ipc Launcher diagnosticSetSearchText "${query}" >/dev/null
      ;;
    empty)
      if [[ -z "${query}" ]]; then
        case "${mode}" in
          drun) query="__launcher_empty_probe__" ;;
          files) query="/__launcher_empty_probe__" ;;
          system) query="__launcher_empty_probe__" ;;
          web) query="zxqv-empty-probe" ;;
        esac
      fi
      call_ipc Launcher diagnosticSetSearchText "${query}" >/dev/null
      ;;
    category)
      if [[ "${mode}" != "drun" ]]; then
        printf 'Category state is only supported in drun mode.\n' >&2
        exit 2
      fi
      if [[ -z "${category_key}" ]]; then
        category_key="$(call_ipc Launcher drunCategoryState 2>/dev/null | node -e '
const fs = require("node:fs");
const raw = fs.readFileSync(0, "utf8").trim();
if (!raw) process.exit(0);
let payload = JSON.parse(raw);
if (typeof payload === "string") payload = JSON.parse(payload);
const options = Array.isArray(payload.options) ? payload.options : [];
const match = options.find((item) => item && String(item.key || "") !== "");
if (match) process.stdout.write(String(match.key || ""));
' 2>/dev/null || true)"
      fi
      if [[ -z "${category_key}" ]]; then
        printf 'Could not resolve a non-All drun category for capture.\n' >&2
        exit 1
      fi
      call_ipc Launcher diagnosticSetDrunCategoryFilter "${category_key}" >/dev/null
      ;;
  esac
}

cleanup_launcher() {
  call_ipc Launcher diagnosticSetSearchText "" >/dev/null 2>&1 || true
  call_ipc Launcher diagnosticSetDrunCategoryFilter "" >/dev/null 2>&1 || true
  call_ipc Launcher invokeEscapeAction >/dev/null 2>&1 || call_ipc Launcher toggle >/dev/null 2>&1 || true
}

main() {
  require_cmd quickshell
  require_cmd hyprctl
  require_cmd jq
  require_cmd grim
  require_cmd magick
  require_cmd node
  require_cmd rg
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
      printf 'No live QuickShell launcher instances found under %s\n' "${runtime_root}" >&2
      exit 1
    fi
  fi

  if [[ -z "${output_path}" ]]; then
    output_path="/tmp/launcher-${mode}-${state}.png"
  fi

  temp_full="$(mktemp /tmp/launcher-capture-full-XXXXXX.png)"
  temp_crop="$(mktemp /tmp/launcher-capture-crop-XXXXXX.png)"
  trap 'rm -f "${temp_full}" "${temp_crop}"; cleanup_launcher; [[ -n "${restore_workspace}" ]] && hypr dispatch workspace "${restore_workspace}" >/dev/null 2>&1 || true' EXIT

  switch_to_capture_workspace "${workspace_target}"

  cleanup_launcher
  apply_launcher_state
  reassert_capture_workspace
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

  printf '[INFO] Saved launcher review artifact for %s/%s (%s) -> %s\n' "${mode}" "${state}" "${crop_mode}" "${output_path}"
}

main "$@"

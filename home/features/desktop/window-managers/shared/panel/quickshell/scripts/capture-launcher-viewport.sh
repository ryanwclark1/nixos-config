#!/usr/bin/env bash
set -euo pipefail

runtime_base="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell"
runtime_root="${runtime_base}/by-id"
instance_id=""
instance_pid=""
hyprland_instance=""
hyprland_wayland_socket=""
mode="drun"
state="home"
query=""
category_key=""
output_path=""
delay_seconds="1.2"
ipc_timeout_seconds="2"
crop_mode="hud"
workspace_target="auto"
viewport_width=""
viewport_height=""
workspace_settle_attempts="80"
workspace_settle_interval="0.2"
state_settle_attempts="18"
state_settle_interval="0.1"
temp_full=""
temp_crop=""
restore_workspace=""
capture_workspace=""

usage() {
  cat <<'EOF'
Usage: capture-launcher-viewport.sh [--id INSTANCE_ID] [--pid INSTANCE_PID] [--mode drun|files|system|web] [--state home|query|empty|category] [--query TEXT] [--category KEY] [--delay SECONDS] [--crop hud|monitor|usable] [--workspace current|auto|NAME] [--width PX] [--height PX] [--output PATH]

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
    --pid)
      instance_pid="${2:-}"
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
    --width)
      viewport_width="${2:-}"
      shift 2
      ;;
    --height)
      viewport_height="${2:-}"
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
    output="$(timeout "${ipc_timeout_seconds}s" "$@" 2>&1)" && {
      if [[ "${output}" == *"Not ready to accept queries yet."* ]]; then
        sleep 0.2
        continue
      fi
      [[ -n "${output}" ]] && printf '%s\n' "${output}"
      return 0
    }
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

pick_capture_workspace() {
  local used
  local candidate
  for candidate in $(seq 1 99); do
    candidate="qs-launcher-capture-${candidate}"
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

dispatch_workspace() {
  local target="$1"
  if [[ "${target}" =~ ^[0-9]+$ ]]; then
    hypr dispatch workspace "${target}" >/dev/null
  else
    hypr dispatch workspace "name:${target}" >/dev/null
  fi
}

switch_to_capture_workspace() {
  local requested="$1"
  local target="${requested}"
  if [[ "${requested}" == "current" ]]; then
    capture_workspace="$(hypr activeworkspace -j | jq -r '.name // (.id | tostring)')"
    restore_workspace=""
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
  dispatch_workspace "${target}"
  wait_for_workspace "${target}"
}

reassert_capture_workspace() {
  [[ -n "${capture_workspace}" ]] || return 0
  if [[ "${workspace_target}" == "current" ]]; then
    return 0
  fi
  dispatch_workspace "${capture_workspace}"
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
  if [[ -n "${instance_pid}" ]]; then
    run_ipc quickshell ipc --pid "${instance_pid}" call "${target}" "$@"
  else
    run_ipc quickshell ipc --id "${instance_id}" call "${target}" "$@"
  fi
}

wait_for_launcher_state() {
  local expected_mode="$1"
  local expected_query="$2"
  local expected_category="$3"
  local expect_home="$4"
  local payload=""
  local current_mode=""
  local current_query=""
  local current_category=""
  local current_home=""
  local current_load_state=""
  local current_result_count=""
  local expected_has_results="either"
  local snapshot=""
  local attempt

  if [[ "${expected_query}" != "" ]]; then
    expected_has_results="true"
  elif [[ "${state}" == "empty" ]]; then
    expected_has_results="false"
  elif [[ "${state}" == "category" ]]; then
    expected_has_results="true"
  fi

  for attempt in $(seq 1 "${state_settle_attempts}"); do
    payload="$(call_ipc Launcher launcherState 2>/dev/null || true)"
    if [[ -n "${payload}" ]]; then
      snapshot="$(printf '%s' "${payload}" | node -e '
const fs = require("node:fs");
const raw = fs.readFileSync(0, "utf8").trim();
if (!raw) process.exit(1);
let payload = JSON.parse(raw);
if (typeof payload === "string") payload = JSON.parse(payload);
const parts = [
  String(payload.mode || ""),
  String(payload.searchText || ""),
  String(payload.drunCategoryFilter || ""),
  String(payload.showLauncherHome === true),
  String(payload.loadState || "idle"),
  String(Math.max(0, Math.round(Number(payload.resultCount || payload.filteredItemCount || 0))))
];
process.stdout.write(parts.join("\u001f"));
' 2>/dev/null || true)"
      IFS=$'\x1f' read -r current_mode current_query current_category current_home current_load_state current_result_count <<< "${snapshot}" || true
    else
      current_mode=""
      current_query=""
      current_category=""
      current_home=""
      current_load_state=""
      current_result_count=""
    fi
    if [[ "${current_mode}" == "${expected_mode}" && "${current_query}" == "${expected_query}" && "${current_category}" == "${expected_category}" && "${current_home}" == "${expect_home}" ]]; then
      if [[ "${current_load_state}" == "loading" ]]; then
        sleep "${state_settle_interval}"
        continue
      fi
      if [[ "${expected_has_results}" == "true" && "${current_result_count}" == "0" ]]; then
        sleep "${state_settle_interval}"
        continue
      fi
      if [[ "${expected_has_results}" == "false" && "${current_result_count}" != "0" ]]; then
        sleep "${state_settle_interval}"
        continue
      fi
      return 0
    fi
    sleep "${state_settle_interval}"
  done

  printf 'Launcher did not settle to expected state (mode=%s query=%s category=%s home=%s hasResults=%s). Got mode=%s query=%s category=%s home=%s loadState=%s resultCount=%s\n' \
    "${expected_mode}" "${expected_query}" "${expected_category}" "${expect_home}" \
    "${expected_has_results}" \
    "${current_mode}" "${current_query}" "${current_category}" "${current_home}" "${current_load_state}" "${current_result_count}" >&2
  return 1
}

apply_launcher_state() {
  local mode_action=""
  local expected_query=""
  local expected_category=""
  local expect_home="false"
  local state_applied=0
  local attempt

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

  case "${state}" in
    home)
      expect_home="true"
      ;;
    query)
      if [[ -z "${query}" ]]; then
        case "${mode}" in
          drun) query="firefox" ;;
          files) query="/nixos" ;;
          system) query="reboot" ;;
          web) query="wayland" ;;
        esac
      fi
      expected_query="${query}"
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
      expected_query="${query}"
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
      expected_category="${category_key}"
      expect_home="true"
      ;;
  esac

  for attempt in 1 2; do
    call_ipc Launcher "${mode_action}" >/dev/null
    sleep 0.15
    call_ipc Launcher diagnosticSetSearchText "" >/dev/null 2>&1 || true
    call_ipc Launcher diagnosticSetDrunCategoryFilter "" >/dev/null 2>&1 || true

    case "${state}" in
      query|empty)
        call_ipc Launcher diagnosticSetSearchText "${expected_query}" >/dev/null
        ;;
      category)
        call_ipc Launcher diagnosticSetDrunCategoryFilter "${expected_category}" >/dev/null
        ;;
    esac

    if wait_for_launcher_state "${mode}" "${expected_query}" "${expected_category}" "${expect_home}" 2>/dev/null; then
      state_applied=1
      break
    fi
    sleep 0.15
  done

  if (( state_applied == 0 )); then
    wait_for_launcher_state "${mode}" "${expected_query}" "${expected_category}" "${expect_home}"
  fi
}

cleanup_launcher() {
  call_ipc Launcher diagnosticSetViewport 0 0 >/dev/null 2>&1 || true
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
    hud|monitor|usable) ;;
    *)
      printf 'Unknown crop mode: %s\n' "${crop_mode}" >&2
      exit 2
      ;;
  esac

  if [[ -n "${viewport_width}" && ! "${viewport_width}" =~ ^[0-9]+$ ]]; then
    printf 'Width must be a positive integer.\n' >&2
    exit 2
  fi
  if [[ -n "${viewport_height}" && ! "${viewport_height}" =~ ^[0-9]+$ ]]; then
    printf 'Height must be a positive integer.\n' >&2
    exit 2
  fi
  if [[ -n "${viewport_width}" || -n "${viewport_height}" ]]; then
    if [[ -z "${viewport_width}" || -z "${viewport_height}" ]]; then
      printf 'Both --width and --height are required together.\n' >&2
      exit 2
    fi
  fi

  if [[ -z "${instance_id}" && -z "${instance_pid}" ]]; then
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
  trap 'rm -f "${temp_full}" "${temp_crop}"; cleanup_launcher; [[ -n "${restore_workspace}" ]] && dispatch_workspace "${restore_workspace}" >/dev/null 2>&1 || true' EXIT

  switch_to_capture_workspace "${workspace_target}"

  cleanup_launcher
  if [[ -n "${viewport_width}" ]]; then
    call_ipc Launcher diagnosticSetViewport "${viewport_width}" "${viewport_height}" >/dev/null
  fi
  apply_launcher_state
  reassert_capture_workspace
  sleep "${delay_seconds}"

  local monitor_json monitor_x monitor_y monitor_w monitor_h reserved_top reserved_left reserved_bottom reserved_right crop_x crop_y crop_w crop_h launcher_state hud_x hud_y hud_w hud_h launcher_usable_w launcher_usable_h launcher_diag_x launcher_diag_y
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

  if [[ "${crop_mode}" == "hud" ]]; then
    launcher_state="$(call_ipc Launcher launcherState 2>/dev/null || true)"
    if [[ -z "${launcher_state}" ]]; then
      printf 'Could not read launcher state for hud crop.\n' >&2
      exit 1
    fi

    local hud_snapshot=""
    hud_snapshot="$(printf '%s' "${launcher_state}" | node -e '
const fs = require("node:fs");
const raw = fs.readFileSync(0, "utf8").trim();
if (!raw) process.exit(1);
let payload = JSON.parse(raw);
if (typeof payload === "string") payload = JSON.parse(payload);
const values = [
  Math.round(Number(payload.hudX || -1)),
  Math.round(Number(payload.hudY || -1)),
  Math.round(Number(payload.hudWidth || 0)),
  Math.round(Number(payload.hudHeight || 0)),
  Math.round(Number(payload.usableWidth || 0)),
  Math.round(Number(payload.usableHeight || 0)),
  Math.round(Number(payload.diagnosticViewportOffsetX || 0)),
  Math.round(Number(payload.diagnosticViewportOffsetY || 0)),
];
if (values[2] <= 0 || values[3] <= 0) process.exit(1);
process.stdout.write(values.join("\t"));
' 2>/dev/null || true)"
    IFS=$'\t' read -r hud_x hud_y hud_w hud_h launcher_usable_w launcher_usable_h launcher_diag_x launcher_diag_y <<< "${hud_snapshot}" || true

    if (( hud_x < 0 )); then
      hud_x=$((reserved_left + launcher_diag_x + (launcher_usable_w - hud_w) / 2))
      if (( hud_x < reserved_left + launcher_diag_x + 20 )); then
        hud_x=$((reserved_left + launcher_diag_x + 20))
      fi
    fi

    if (( hud_y < 0 )); then
      hud_y=$((reserved_top + launcher_diag_y + (launcher_usable_h - hud_h) / 2))
      if (( hud_y < reserved_top + launcher_diag_y + 20 )); then
        hud_y=$((reserved_top + launcher_diag_y + 20))
      fi
    fi

    crop_x=$((monitor_x + hud_x))
    crop_y=$((monitor_y + hud_y))
    crop_w="${hud_w}"
    crop_h="${hud_h}"
  elif [[ "${crop_mode}" == "usable" ]]; then
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

  grim_capture "${temp_full}"
  magick "${temp_full}" -crop "${crop_w}x${crop_h}+${crop_x}+${crop_y}" +repage "${temp_crop}"
  cp "${temp_crop}" "${output_path}"

  printf '[INFO] Saved launcher review artifact for %s/%s (%s) -> %s\n' "${mode}" "${state}" "${crop_mode}" "${output_path}"
}

main "$@"

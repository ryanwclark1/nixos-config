#!/usr/bin/env bash
set -euo pipefail

runtime_base="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell"
runtime_root="${runtime_base}/by-id"
instance_id=""
hyprland_instance=""
hyprland_wayland_socket=""
surface_id="networkMenu"
output_path=""
delay_seconds="1.6"
ipc_timeout_seconds="2"
close_settle_seconds="0.45"
crop_mode="surface"
workspace_target="auto"
workspace_settle_attempts="20"
workspace_settle_interval="0.1"
temp_full=""
temp_crop=""
temp_before_full=""
temp_layers_before=""
temp_layers_after=""
restore_workspace=""
capture_workspace=""
min_surface_crop_width="200"
min_surface_crop_height="200"

usage() {
  cat <<'EOF'
Usage: capture-surface-viewport.sh [--id INSTANCE_ID] [--surface SURFACE_ID] [--delay SECONDS] [--close-settle SECONDS] [--crop surface|monitor|usable] [--workspace current|auto|NAME] [--output PATH]

Open a live QuickShell surface through Shell IPC, capture the focused monitor, and save a cropped screenshot.
This produces a review artifact for manual inspection, not PASS/WARN/FAIL results.
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
    --close-settle)
      close_settle_seconds="${2:-}"
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

log_info() {
  printf '[INFO] %s\n' "$*"
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

surface_kind_for_id() {
  case "$1" in
    notifCenter|controlCenter|powerMenu|notepad|colorPicker|displayConfig|fileBrowser|aiChat)
      printf 'panel\n'
      ;;
    *)
      printf 'popup\n'
      ;;
  esac
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
      timeout 15s grim -t png "$@"
  else
    timeout 15s grim -t png "$@"
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

resolve_shell_pid() {
  local pid_link
  while IFS= read -r pid_link; do
    [[ -n "${pid_link}" ]] || continue
    basename "${pid_link}"
    return 0
  done < <(find "${runtime_base}/by-pid" -mindepth 1 -maxdepth 1 -type l \
    -exec sh -c 'target="$(readlink -f "$1" 2>/dev/null || true)"; [[ "${target}" == *"/'"${instance_id}"'" ]] && printf "%s\n" "$1"' _ {} \; 2>/dev/null | sort)

  return 1
}

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

instance_id_from_pid() {
  local pid
  local resolved=""

  pid="${1:-}"
  [[ -n "${pid}" ]] || return 1
  pid_looks_like_quickshell "${pid}" || return 1

  resolved="$(readlink -f "${runtime_base}/by-pid/${pid}" 2>/dev/null || true)"
  if [[ -n "${resolved}" && -S "${resolved}/ipc.sock" ]]; then
    basename "${resolved}"
    return 0
  fi

  return 1
}

discover_instances_from_pid() {
  local pid
  local ids=()

  while IFS= read -r pid; do
    [[ -n "${pid}" ]] || continue
    instance_id_from_pid "${pid}" || continue
  done < <(
    {
      find "${runtime_base}/by-pid" -mindepth 1 -maxdepth 1 -type l -printf '%f\n' 2>/dev/null || true
      ps -eo pid=,comm= | awk '$2 ~ /quickshell|\\.quickshell-wra/ { print $1 }'
    } | awk 'NF && !seen[$0]++'
  )

  return 0
}

instance_is_reachable() {
  local candidate="$1"
  local output=""
  local status=0
  local attempt

  for attempt in 1 2 3 4 5; do
    output="$(timeout "${ipc_timeout_seconds}s" quickshell ipc --id "${candidate}" call Shell closeAllSurfaces >/dev/null 2>&1)" && return 0
    status=$?
    if [[ "${output}" == *"Not ready to accept queries yet."* ]]; then
      sleep 0.2
      continue
    fi
    return "${status}"
  done

  return "${status}"
}

discover_instances() {
  discover_instances_from_pid
}

discover_reachable_instance() {
  local candidate
  while IFS= read -r candidate; do
    [[ -n "${candidate}" ]] || continue
    if instance_is_reachable "${candidate}"; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done < <(discover_instances_from_monitor_layers)

  while IFS= read -r candidate; do
    [[ -n "${candidate}" ]] || continue
    if instance_is_reachable "${candidate}"; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done < <(discover_instances)

  return 1
}

discover_instances_from_monitor_layers() {
  local monitor_name=""
  local pid

  monitor_name="$(hypr monitors -j | jq -r 'map(select(.focused == true))[0].name // empty')" || true
  [[ -n "${monitor_name}" ]] || return 0

  while IFS= read -r pid; do
    [[ -n "${pid}" ]] || continue
    instance_id_from_pid "${pid}" || continue
  done < <(
    hypr layers -j | jq -r --arg monitor "${monitor_name}" '
      (.[$monitor].levels // {})
      | to_entries
      | map(.value[]?)
      | map(select(((.namespace // "") | startswith("quickshell-bar-")) or (.namespace // "") == "quickshell-settings" or (.namespace // "") == "quickshell"))
      | map(.pid // empty)
      | .[]
    ' 2>/dev/null \
      | awk 'NF { count[$1]++ } END { for (pid in count) printf "%d %s\n", count[pid], pid }' \
      | sort -k1,1nr -k2,2nr \
      | awk '{ print $2 }'
  )
}

call_ipc() {
  local target="$1"
  shift
  run_ipc quickshell ipc --id "${instance_id}" call "${target}" "$@"
}

capture_layer_snapshot() {
  local output_file="$1"
  hypr layers -j > "${output_file}"
}

surface_candidates_json() {
  local before_file="$1"
  local after_file="$2"
  local monitor_name="$3"
  local shell_pid="$4"
  local surface_kind="$5"
  local monitor_x="$6"
  local monitor_y="$7"
  local monitor_w="$8"
  local monitor_h="$9"

  jq -c -n \
    --slurpfile before "${before_file}" \
    --slurpfile after "${after_file}" \
    --arg monitor "${monitor_name}" \
    --argjson shell_pid "${shell_pid}" \
    --arg surface_kind "${surface_kind}" \
    --argjson monitor_x "${monitor_x}" \
    --argjson monitor_y "${monitor_y}" \
    --argjson monitor_w "${monitor_w}" \
    --argjson monitor_h "${monitor_h}" '
      def entries($doc):
        (($doc[$monitor].levels // {})
          | to_entries
          | map(.key as $level | (.value // [])[] | . + { level: $level }));
      def filtered($doc):
        entries($doc)
        | map(select((.pid // 0) == $shell_pid))
        | map(select((.namespace // "") != "swww-daemon"))
        | map(select(((.namespace // "") | startswith("quickshell-bar-")) | not))
        | map(select((.namespace // "") != "quickshell-toast" and (.namespace // "") != "quickshell-corners"))
        | map(select((.w // 0) > 8 and (.h // 0) > 8))
        | map(. + {
            sig: [
              (.address // ""),
              (.namespace // ""),
              (.level // ""),
              ((.x // 0) | tostring),
              ((.y // 0) | tostring),
              ((.w // 0) | tostring),
              ((.h // 0) | tostring)
            ] | join("|")
          });
      def with_metrics($source):
        map(. + {
          candidateSource: $source,
          area: ((.w // 0) * (.h // 0)),
          fullscreenish: (((.w // 0) >= ($monitor_w * 0.97)) and ((.h // 0) >= ($monitor_h * 0.97))),
          offMonitor: (((.x // 0) + (.w // 0)) <= $monitor_x
            or ((.y // 0) + (.h // 0)) <= $monitor_y
            or (.x // 0) >= ($monitor_x + $monitor_w)
            or (.y // 0) >= ($monitor_y + $monitor_h)),
          popupOversized: ((.w // 0) >= ($monitor_w * 0.92) and (.h // 0) >= ($monitor_h * 0.85))
        });

      (filtered($before[0])) as $beforeEntries
      | (filtered($after[0])) as $afterEntries
      | ($beforeEntries | map(.sig)) as $beforeSigs
      | ($afterEntries | map(select((.sig as $sig | ($beforeSigs | index($sig))) == null))) as $newEntries
      | (
          if ($newEntries | length) > 0 then
            ($newEntries | with_metrics("new"))
          else
            ($afterEntries | with_metrics("fallback"))
          end
        ) as $baseCandidates
      | (
          $baseCandidates
          | if $surface_kind == "popup" then
              (map(select((.fullscreenish | not) and (.popupOversized | not) and (.offMonitor | not)))
                | if length > 0 then . else $baseCandidates end)
            else
              (map(select((.fullscreenish | not) and (.offMonitor | not)))
                | if length > 0 then . else $baseCandidates end)
            end
          | sort_by(.fullscreenish, .popupOversized, .offMonitor, -(.area))
        )
    '
}

log_surface_candidates() {
  local candidates_json="$1"
  local monitor_name="$2"
  if [[ -z "${candidates_json}" || "${candidates_json}" == "[]" ]]; then
    log_info "candidate layers: none on monitor ${monitor_name}"
    return 0
  fi

  jq -r --arg monitor "${monitor_name}" '
    .[]
    | "[INFO] candidate layer monitor=\($monitor) source=\(.candidateSource) level=\(.level // "unknown") namespace=\(.namespace // "none") pid=\(.pid // 0) geom=\(.x // 0),\(.y // 0) \(.w // 0)x\(.h // 0) fullscreenish=\(.fullscreenish) popupOversized=\(.popupOversized) offMonitor=\(.offMonitor)"
  ' <<< "${candidates_json}"
}

surface_crop_box_from_candidates() {
  local candidates_json="$1"
  local monitor_x="$2"
  local monitor_y="$3"
  local monitor_w="$4"
  local monitor_h="$5"

  jq -r \
    --argjson monitor_x "${monitor_x}" \
    --argjson monitor_y "${monitor_y}" \
    --argjson monitor_w "${monitor_w}" \
    --argjson monitor_h "${monitor_h}" '
      if length == 0 then
        empty
      else
        .[0] as $picked
        | ([($picked.x // 0) - 8, $monitor_x] | max) as $left
        | ([($picked.y // 0) - 8, $monitor_y] | max) as $top
        | ([($picked.x // 0) + ($picked.w // 0) + 8, $monitor_x + $monitor_w] | min) as $right
        | ([($picked.y // 0) + ($picked.h // 0) + 8, $monitor_y + $monitor_h] | min) as $bottom
        | [$left, $top, ($right - $left), ($bottom - $top)] | @tsv
      end
    ' <<< "${candidates_json}"
}

diff_crop_box_from_images() {
  local before_image="$1"
  local after_image="$2"
  local monitor_x="$3"
  local monitor_y="$4"
  local monitor_w="$5"
  local monitor_h="$6"
  local raw_box=""
  local diff_w diff_h diff_x diff_y
  local crop_left crop_top crop_right crop_bottom

  raw_box="$(magick "${before_image}" "${after_image}" \
    -compose difference -composite -colorspace gray -threshold 0 \
    -define connected-components:verbose=true -connected-components 8 null: 2>&1 \
    | awk -v monitor_w="${monitor_w}" -v monitor_h="${monitor_h}" '
        match($0, /^[[:space:]]*[0-9]+: ([0-9]+)x([0-9]+)\+(-?[0-9]+)\+(-?[0-9]+) [^ ]+ ([0-9.e+-]+) gray\(255\)/, m) {
          width = m[1] + 0;
          height = m[2] + 0;
          x = m[3] + 0;
          y = m[4] + 0;
          area = m[5] + 0;
          if (width >= (monitor_w * 0.97) && height >= (monitor_h * 0.97))
            next;
          box = sprintf("%sx%s+%s+%s", width, height, x, y);
          if (width >= 160 && height >= 120 && width <= (monitor_w * 0.6) && height <= (monitor_h * 0.8)) {
            if (area > preferred_area) {
              preferred_area = area;
              preferred_box = box;
            }
          }
          if (area > fallback_area) {
            fallback_area = area;
            fallback_box = box;
          }
        }
        END {
          if (preferred_box != "")
            print preferred_box;
          else if (fallback_box != "")
            print fallback_box;
        }
      ' || true)"

  [[ -n "${raw_box}" ]] || return 1
  if [[ ! "${raw_box}" =~ ^([0-9]+)x([0-9]+)\+(-?[0-9]+)\+(-?[0-9]+)$ ]]; then
    return 1
  fi

  diff_w="${BASH_REMATCH[1]}"
  diff_h="${BASH_REMATCH[2]}"
  diff_x="${BASH_REMATCH[3]}"
  diff_y="${BASH_REMATCH[4]}"

  crop_left=$((diff_x - 12))
  crop_top=$((diff_y - 12))
  crop_right=$((diff_x + diff_w + 12))
  crop_bottom=$((diff_y + diff_h + 12))

  (( crop_left < monitor_x )) && crop_left="${monitor_x}"
  (( crop_top < monitor_y )) && crop_top="${monitor_y}"
  (( crop_right > monitor_x + monitor_w )) && crop_right=$((monitor_x + monitor_w))
  (( crop_bottom > monitor_y + monitor_h )) && crop_bottom=$((monitor_y + monitor_h))

  if (( crop_right <= crop_left || crop_bottom <= crop_top )); then
    return 1
  fi

  printf '%s\t%s\t%s\t%s\n' \
    "${crop_left}" \
    "${crop_top}" \
    "$((crop_right - crop_left))" \
    "$((crop_bottom - crop_top))"
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

  if ! [[ "${close_settle_seconds}" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    printf 'Close-settle must be numeric.\n' >&2
    exit 2
  fi

  if ! [[ "${min_surface_crop_width}" =~ ^[0-9]+$ ]] || ! [[ "${min_surface_crop_height}" =~ ^[0-9]+$ ]]; then
    printf 'Minimum surface crop dimensions must be integers.\n' >&2
    exit 2
  fi

  case "${crop_mode}" in
    surface|monitor|usable) ;;
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

  local surface_kind
  surface_kind="$(surface_kind_for_id "${surface_id}")"

  if [[ "${crop_mode}" == "surface" && "${surface_kind}" == "popup" && "${workspace_target}" == "auto" ]]; then
    workspace_target="current"
  fi

  if [[ -z "${output_path}" ]]; then
    output_path="/tmp/${surface_id}-${crop_mode}.png"
  fi

  temp_full="$(mktemp /tmp/surface-capture-full-XXXXXX.png)"
  temp_crop="$(mktemp /tmp/surface-capture-crop-XXXXXX.png)"
  temp_before_full="$(mktemp /tmp/surface-capture-before-XXXXXX.png)"
  temp_layers_before="$(mktemp /tmp/surface-capture-layers-before-XXXXXX.json)"
  temp_layers_after="$(mktemp /tmp/surface-capture-layers-after-XXXXXX.json)"
  trap 'rm -f "${temp_full}" "${temp_crop}" "${temp_before_full}" "${temp_layers_before}" "${temp_layers_after}"; quickshell ipc --id "${instance_id}" call Shell closeAllSurfaces >/dev/null 2>&1 || true; [[ -n "${restore_workspace}" ]] && hypr dispatch workspace "${restore_workspace}" >/dev/null 2>&1 || true' EXIT

  switch_to_capture_workspace "${workspace_target}"

  call_ipc Shell closeAllSurfaces >/dev/null || true
  sleep "${close_settle_seconds}"
  grim_capture "${temp_before_full}"
  capture_layer_snapshot "${temp_layers_before}"
  call_ipc Shell openSurface "${surface_id}" >/dev/null
  if [[ "${crop_mode}" != "surface" ]]; then
    reassert_capture_workspace
  fi
  sleep "${delay_seconds}"

  local monitor_json monitor_name monitor_x monitor_y monitor_w monitor_h reserved_top reserved_left reserved_bottom reserved_right crop_x crop_y crop_w crop_h shell_pid layers_json crop_box diff_crop_box
  monitor_json="$(hypr monitors -j | jq 'map(select(.focused == true))[0]')"
  if [[ -z "${monitor_json}" || "${monitor_json}" == "null" ]]; then
    printf 'Could not resolve focused monitor from hyprctl.\n' >&2
    exit 1
  fi

  monitor_name="$(printf '%s' "${monitor_json}" | jq -r '.name')"
  monitor_x="$(printf '%s' "${monitor_json}" | jq -r '.x')"
  monitor_y="$(printf '%s' "${monitor_json}" | jq -r '.y')"
  monitor_w="$(printf '%s' "${monitor_json}" | jq -r '.width')"
  monitor_h="$(printf '%s' "${monitor_json}" | jq -r '.height')"
  reserved_top="$(printf '%s' "${monitor_json}" | jq -r '.reserved[0]')"
  reserved_left="$(printf '%s' "${monitor_json}" | jq -r '.reserved[1]')"
  reserved_bottom="$(printf '%s' "${monitor_json}" | jq -r '.reserved[2]')"
  reserved_right="$(printf '%s' "${monitor_json}" | jq -r '.reserved[3]')"

  log_info "resolved live instance id: ${instance_id}"
  log_info "focused monitor: ${monitor_name} (${monitor_x},${monitor_y} ${monitor_w}x${monitor_h})"

  if [[ "${crop_mode}" == "surface" ]]; then
    shell_pid="$(resolve_shell_pid || true)"
    capture_layer_snapshot "${temp_layers_after}"
    layers_json="$(cat "${temp_layers_after}")"
    if [[ -n "${shell_pid}" ]]; then
      log_info "resolved shell pid: ${shell_pid}"
      local candidates_json
      candidates_json="$(surface_candidates_json \
        "${temp_layers_before}" \
        "${temp_layers_after}" \
        "${monitor_name}" \
        "${shell_pid}" \
        "${surface_kind}" \
        "${monitor_x}" \
        "${monitor_y}" \
        "${monitor_w}" \
        "${monitor_h}")"
      log_surface_candidates "${candidates_json}" "${monitor_name}"
      crop_box="$(surface_crop_box_from_candidates "${candidates_json}" "${monitor_x}" "${monitor_y}" "${monitor_w}" "${monitor_h}")"
    else
      log_info "resolved shell pid: unavailable"
      crop_box=""
    fi

    if [[ -z "${crop_box}" ]]; then
      log_info "chosen crop box: none from surface layers"
    else
      read -r crop_x crop_y crop_w crop_h <<< "${crop_box}"
      log_info "chosen crop box: ${crop_x},${crop_y} ${crop_w}x${crop_h}"
    fi
  fi

  local start_time
  start_time="$(date +'%Y-%m-%d %H:%M:%S')"

  grim_capture "${temp_full}"

  if [[ "${crop_mode}" == "surface" ]] && { [[ "${surface_kind}" == "popup" ]] || [[ -z "${crop_box}" ]] || [[ "${crop_w:-0}" -ge $((monitor_w - 16)) ]] || [[ "${crop_h:-0}" -ge $((monitor_h - 16)) ]]; }; then
    diff_crop_box="$(diff_crop_box_from_images "${temp_before_full}" "${temp_full}" "${monitor_x}" "${monitor_y}" "${monitor_w}" "${monitor_h}" || true)"
    if [[ -n "${diff_crop_box}" ]]; then
      local diff_crop_x diff_crop_y diff_crop_w diff_crop_h
      local current_area diff_area
      read -r diff_crop_x diff_crop_y diff_crop_w diff_crop_h <<< "${diff_crop_box}"
      if (( diff_crop_w < min_surface_crop_width || diff_crop_h < min_surface_crop_height )); then
        log_info "ignoring screenshot diff crop below minimum size: ${diff_crop_x},${diff_crop_y} ${diff_crop_w}x${diff_crop_h}"
        diff_crop_box=""
      fi
    fi

    if [[ -n "${diff_crop_box}" ]]; then
      local diff_crop_x diff_crop_y diff_crop_w diff_crop_h
      local current_area diff_area
      read -r diff_crop_x diff_crop_y diff_crop_w diff_crop_h <<< "${diff_crop_box}"
      current_area=$(( (${crop_w:-0}) * (${crop_h:-0}) ))
      diff_area=$(( diff_crop_w * diff_crop_h ))
      if [[ -z "${crop_box}" || "${surface_kind}" != "popup" || "${current_area}" -eq 0 || "${diff_area}" -lt $(( current_area * 75 / 100 )) ]]; then
        crop_box="${diff_crop_box}"
        crop_x="${diff_crop_x}"
        crop_y="${diff_crop_y}"
        crop_w="${diff_crop_w}"
        crop_h="${diff_crop_h}"
        log_info "chosen crop box from screenshot diff: ${crop_x},${crop_y} ${crop_w}x${crop_h}"
      else
        log_info "screenshot diff crop kept as secondary candidate: ${diff_crop_x},${diff_crop_y} ${diff_crop_w}x${diff_crop_h}"
      fi
    fi
  fi

  if [[ "${crop_mode}" == "surface" && -z "${crop_box}" ]]; then
    log_info "chosen crop box: none from surface layers or screenshot diff, falling back to usable"
    crop_mode="usable"
  fi

  if [[ "${crop_mode}" == "usable" ]]; then
    crop_x=$((monitor_x + reserved_left))
    crop_y=$((monitor_y + reserved_top))
    crop_w=$((monitor_w - reserved_left - reserved_right))
    crop_h=$((monitor_h - reserved_top - reserved_bottom))
  elif [[ "${crop_mode}" == "monitor" ]]; then
    crop_x="${monitor_x}"
    crop_y="${monitor_y}"
    crop_w="${monitor_w}"
    crop_h="${monitor_h}"
  fi

  magick "${temp_full}" -crop "${crop_w}x${crop_h}+${crop_x}+${crop_y}" +repage "${temp_crop}"
  cp "${temp_crop}" "${output_path}"

  # Dump correlated logs
  local log_file="${output_path%.png}.log"
  journalctl --user --since "${start_time}" > "${log_file}" 2>/dev/null || true

  # Scan for health status (focus on quickshell, ignore system noise)
  local status="clean"
  local filtered_logs
  filtered_logs="$(grep -i "quickshell" "${log_file}" | grep -viE "ignore|blueman|swww" || true)"

  if [[ -n "${filtered_logs}" ]]; then
    if echo "${filtered_logs}" | grep -qiE "error|critical|failed|exception"; then
      status="error"
    elif echo "${filtered_logs}" | grep -qiE "warn|alert"; then
      status="warning"
    fi
  fi
  printf '%s' "${status}" > "${log_file}.status"

  printf '[INFO] Saved surface review artifact for %s (%s) (logs: %s) -> %s\n' "${surface_id}" "${crop_mode}" "${status}" "${output_path}"
}

main "$@"

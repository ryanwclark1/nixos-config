#!/usr/bin/env bash

load_graphics_session_env() {
  local env_dump=""
  local line=""
  local key=""
  local value=""

  if ! command -v systemctl >/dev/null 2>&1; then
    return 0
  fi

  env_dump="$(systemctl --user show-environment 2>/dev/null || true)"
  [[ -n "${env_dump}" ]] || return 0

  while IFS= read -r line; do
    [[ "${line}" == *=* ]] || continue
    key="${line%%=*}"
    value="${line#*=}"
    [[ -n "${value}" ]] || continue

    case "${key}" in
      XDG_RUNTIME_DIR|XDG_STATE_HOME|DBUS_SESSION_BUS_ADDRESS|DISPLAY|HYPRLAND_INSTANCE_SIGNATURE|WAYLAND_DISPLAY|NIRI_SOCKET|XDG_CURRENT_DESKTOP|DESKTOP_SESSION|XDG_SESSION_TYPE|TMPDIR)
        if [[ -z "${!key:-}" ]]; then
          printf -v "${key}" '%s' "${value}"
          export "${key}"
        fi
        ;;
    esac
  done <<< "${env_dump}"

  if [[ -z "${QT_QPA_PLATFORM:-}" && ( -n "${WAYLAND_DISPLAY:-}" || -n "${NIRI_SOCKET:-}" ) ]]; then
    export QT_QPA_PLATFORM=wayland
  fi
}

build_repo_shell_env_array() {
  local array_name="${1:?missing output array name}"
  shift
  local -n out_ref="${array_name}"
  local key=""
  local value=""

  load_graphics_session_env

  out_ref=("$@")
  for key in HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY NIRI_SOCKET XDG_CURRENT_DESKTOP DESKTOP_SESSION XDG_SESSION_TYPE DISPLAY XDG_STATE_HOME TMPDIR QT_QPA_PLATFORM; do
    value="${!key:-}"
    [[ -n "${value}" ]] || continue
    out_ref+=("${key}=${value}")
  done
}

niri_json_query() {
  local raw=""
  local query="$1"
  shift || true

  [[ -n "${NIRI_SOCKET:-}" ]] || return 1
  command -v niri >/dev/null 2>&1 || return 1
  command -v jq >/dev/null 2>&1 || return 1

  raw="$(niri msg -j "${query}" "$@" 2>/dev/null || true)"
  [[ -n "${raw}" ]] || return 1

  printf '%s' "${raw}" | jq -cer '
    fromjson?
    // (capture("(?s)(?<json>(\\{.*\\}|\\[.*\\]))")?.json | fromjson?)
  ' 2>/dev/null
}

niri_headless_without_outputs() {
  local outputs_json=""

  load_graphics_session_env

  [[ -n "${NIRI_SOCKET:-}" ]] || return 1
  outputs_json="$(niri_json_query outputs || true)"
  [[ -n "${outputs_json}" ]] || return 1

  if printf '%s' "${outputs_json}" | jq -e '
    if type == "array" then
      length == 0
    elif type == "object" then
      length == 0 or (((.outputs // []) | length) == 0)
    else
      true
    end
  ' >/dev/null 2>&1; then
    return 0
  fi

  return 1
}

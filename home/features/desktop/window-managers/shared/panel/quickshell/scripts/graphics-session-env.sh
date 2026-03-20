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
      XDG_RUNTIME_DIR|DBUS_SESSION_BUS_ADDRESS|DISPLAY|HYPRLAND_INSTANCE_SIGNATURE|WAYLAND_DISPLAY|NIRI_SOCKET|XDG_CURRENT_DESKTOP|DESKTOP_SESSION|XDG_SESSION_TYPE)
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

niri_headless_without_outputs() {
  local outputs_json=""

  load_graphics_session_env

  [[ -n "${NIRI_SOCKET:-}" ]] || return 1
  command -v niri >/dev/null 2>&1 || return 1
  outputs_json="$(niri msg -j outputs 2>/dev/null || true)"
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

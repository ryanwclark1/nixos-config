#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
quickshell_root="$(CDPATH= cd -- "${script_dir}/.." >/dev/null && pwd)"
config_root="${quickshell_root}/src"
skip_responsive=0
skip_runtime_capture=0
runtime_output_dir=""

source "${script_dir}/graphics-session-env.sh"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$1" >&2
    exit 2
  fi
}

require_pattern() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if ! rg -q --multiline "${pattern}" "${file}"; then
    printf '[FAIL] %s missing in %s\n' "${label}" "${file}" >&2
    exit 1
  fi
}

reject_pattern() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if rg -q --multiline "${pattern}" "${file}"; then
    printf '[FAIL] %s unexpectedly present in %s\n' "${label}" "${file}" >&2
    exit 1
  fi
}

main() {
  local runtime_args=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --skip-responsive)
        skip_responsive=1
        shift
        ;;
      --skip-runtime-capture)
        skip_runtime_capture=1
        shift
        ;;
      --runtime-output-dir)
        runtime_output_dir="${2:-}"
        shift 2
        ;;
      *)
        runtime_args+=("$1")
        shift
        ;;
    esac
  done

  require_cmd qmlformat
  require_cmd rg
  load_graphics_session_env

  qmlformat -n \
    "${config_root}/features/settings/SettingsHub.qml" \
    "${config_root}/features/settings/components/"*.qml \
    "${config_root}/features/settings/components/tabs/"*.qml >/dev/null

  require_pattern "${config_root}/features/settings/components/SettingsDragHandle.qml" 'dragOffsetY' "shared drag-offset handle"
  reject_pattern "${config_root}/features/settings/components/SettingsDragHandle.qml" 'drag\.target:' "legacy drag.target handle wiring"
  require_pattern "${config_root}/features/settings/components/tabs/ShellControlCenterSection.qml" 'SettingsReorderRow' "control center shared reorder row"
  require_pattern "${config_root}/features/settings/components/tabs/ShellControlCenterSection.qml" 'SettingsReorderButtons' "control center reorder fallback buttons"
  require_pattern "${config_root}/features/settings/components/tabs/LauncherModeList.qml" 'SettingsReorderRow' "launcher mode shared reorder row"
  require_pattern "${config_root}/features/settings/components/tabs/LauncherModeList.qml" 'SettingsReorderButtons' "launcher mode reorder fallback buttons"
  require_pattern "${config_root}/features/settings/components/tabs/BarWidgetsTab.qml" 'dragReorderEnabled:\s*true' "bar widget drag enablement"
  require_pattern "${config_root}/features/settings/components/tabs/BarWidgetsTab.qml" 'SettingsReorderRow' "bar widget shared reorder row"
  require_pattern "${config_root}/features/settings/components/tabs/BarWidgetsTab.qml" 'SettingsReorderButtons' "bar widget reorder fallback buttons"
  require_pattern "${config_root}/features/settings/components/tabs/LauncherWebSection.qml" 'SettingsReorderRow' "launcher web shared reorder row"
  require_pattern "${config_root}/features/settings/components/tabs/LauncherWebSection.qml" 'SettingsReorderButtons' "launcher web reorder fallback buttons"
  require_pattern "${config_root}/features/settings/components/tabs/LauncherWebSection.qml" 'currentWebProviderDropIndex' "shell-core tab reorder math helper usage"
  require_pattern "${script_dir}/check-bar-widgets-first-open.sh" 'check-settings-responsive\.sh"\s+--id "\$\{instance_id\}"\s+--skip-reload' "bar widgets first-open settings smoke instance-id binding"

  if (( skip_responsive == 0 )); then
    "${script_dir}/check-settings-responsive.sh" "${runtime_args[@]}"
  fi
  if (( ${#runtime_args[@]} == 0 )); then
    runtime_args=(--repo-shell)
  fi
  if (( skip_runtime_capture == 1 )); then
    printf '%s\n' "[INFO] Skipping runtime warning regression artifact capture."
  elif niri_headless_without_outputs; then
    printf '%s\n' "[INFO] Skipping runtime warning regression artifact capture: Niri session exposes no wl_output in this headless VM."
  else
    runtime_warning_args=(--workspace current --skip-surfaces)
    if [[ -n "${runtime_output_dir}" ]]; then
      runtime_warning_args+=(--output-dir "${runtime_output_dir}")
    fi
    "${script_dir}/check-runtime-warning-regressions.sh" "${runtime_warning_args[@]}" "${runtime_args[@]}"
  fi

  printf '%s\n' "Settings guardrails passed."
}

main "$@"

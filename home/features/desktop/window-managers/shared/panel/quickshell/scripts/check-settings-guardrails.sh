#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
quickshell_root="$(CDPATH= cd -- "${script_dir}/.." >/dev/null && pwd)"
config_root="${quickshell_root}/src"
skip_responsive=0

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

main() {
  local runtime_args=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --skip-responsive)
        skip_responsive=1
        shift
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

  require_pattern "${config_root}/features/settings/components/tabs/BarWidgetsTab.qml" 'dragReorderEnabled:\s*true' "bar widget drag enablement"
  require_pattern "${config_root}/features/settings/components/tabs/BarWidgetsTab.qml" 'SettingsDragHandle' "bar widget shared drag handle"
  require_pattern "${config_root}/features/settings/components/tabs/BarWidgetsTab.qml" 'label:\s*"↑"' "bar widget up-arrow fallback"
  require_pattern "${config_root}/features/settings/components/tabs/BarWidgetsTab.qml" 'label:\s*"↓"' "bar widget down-arrow fallback"
  require_pattern "${config_root}/features/settings/components/tabs/ShellLauncherSection.qml" 'SettingsDragHandle' "shell-core tab shared drag handle"
  require_pattern "${config_root}/features/settings/components/tabs/ShellLauncherSection.qml" 'currentWebProviderDropIndex' "shell-core tab reorder math helper usage"
  require_pattern "${config_root}/features/settings/components/tabs/ShellLauncherSection.qml" 'label:\s*"↑"' "shell-core tab up-arrow fallback"
  require_pattern "${config_root}/features/settings/components/tabs/ShellLauncherSection.qml" 'label:\s*"↓"' "shell-core tab down-arrow fallback"

  if (( skip_responsive == 0 )); then
    "${script_dir}/check-settings-responsive.sh" "${runtime_args[@]}"
  fi
  if (( ${#runtime_args[@]} == 0 )); then
    runtime_args=(--repo-shell)
  fi
  if niri_headless_without_outputs; then
    printf '%s\n' "[INFO] Skipping runtime warning regression artifact capture: Niri session exposes no wl_output in this headless VM."
  else
    "${script_dir}/check-runtime-warning-regressions.sh" --workspace current --skip-surfaces "${runtime_args[@]}"
  fi

  printf '%s\n' "Settings guardrails passed."
}

main "$@"

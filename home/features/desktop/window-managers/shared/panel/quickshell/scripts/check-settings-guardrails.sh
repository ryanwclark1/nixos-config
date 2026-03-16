#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
quickshell_root="$(CDPATH= cd -- "${script_dir}/.." >/dev/null && pwd)"
config_root="${quickshell_root}/config"

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
  require_cmd qmlformat
  require_cmd rg

  qmlformat -n \
    "${config_root}/menu/SettingsHub.qml" \
    "${config_root}/menu/settings/"*.qml \
    "${config_root}/menu/settings/tabs/"*.qml >/dev/null

  require_pattern "${config_root}/menu/settings/tabs/BarWidgetsTab.qml" 'dragReorderEnabled:\s*true' "bar widget drag enablement"
  require_pattern "${config_root}/menu/settings/tabs/BarWidgetsTab.qml" 'SettingsDragHandle' "bar widget shared drag handle"
  require_pattern "${config_root}/menu/settings/tabs/BarWidgetsTab.qml" 'label:\s*"↑"' "bar widget up-arrow fallback"
  require_pattern "${config_root}/menu/settings/tabs/BarWidgetsTab.qml" 'label:\s*"↓"' "bar widget down-arrow fallback"
  require_pattern "${config_root}/menu/settings/tabs/ShellCoreSectionTab.qml" 'SettingsDragHandle' "shell-core tab shared drag handle"
  require_pattern "${config_root}/menu/settings/tabs/ShellCoreSectionTab.qml" 'targetIndexFromMappedY' "shell-core tab reorder math helper usage"
  require_pattern "${config_root}/menu/settings/tabs/ShellCoreSectionTab.qml" 'label:\s*"↑"' "shell-core tab up-arrow fallback"
  require_pattern "${config_root}/menu/settings/tabs/ShellCoreSectionTab.qml" 'label:\s*"↓"' "shell-core tab down-arrow fallback"

  "${script_dir}/check-settings-responsive.sh" "$@"

  printf '%s\n' "Settings guardrails passed."
}

main "$@"

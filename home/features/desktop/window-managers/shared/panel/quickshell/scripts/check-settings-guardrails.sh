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

main() {
  require_cmd qmlformat

  qmlformat -n \
    "${config_root}/menu/SettingsHub.qml" \
    "${config_root}/menu/settings/"*.qml \
    "${config_root}/menu/settings/tabs/"*.qml >/dev/null

  "${script_dir}/check-settings-responsive.sh" "$@"

  printf '%s\n' "Settings guardrails passed."
}

main "$@"

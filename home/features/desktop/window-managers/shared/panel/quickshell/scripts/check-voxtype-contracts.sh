#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
repo_root="$(CDPATH= cd -- "${script_dir}/.." >/dev/null && pwd)"

pass_count=0
fail_count=0

pass() {
  printf '[PASS] %s\n' "$1"
  pass_count=$((pass_count + 1))
}

fail() {
  printf '[FAIL] %s\n' "$1" >&2
  fail_count=$((fail_count + 1))
}

require_literal() {
  local file="$1"
  local literal="$2"
  local label="$3"
  if rg -Fq -- "$literal" "$file"; then
    pass "$label"
  else
    fail "$label"
  fi
}

require_pattern() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if rg -Uq --multiline -- "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label"
  fi
}

bar_registry="${repo_root}/src/features/bar/registry/BarWidgetRegistry.qml"
panel_qml="${repo_root}/src/bar/Panel.qml"
widget_qmldir="${repo_root}/src/bar/components/qmldir"
widget_qml="${repo_root}/src/bar/components/VoxtypeBarWidget.qml"

require_literal "$bar_registry" 'widgetType: "voxtype"' "Voxtype widget is registered in BarWidgetRegistry"
require_literal "$bar_registry" 'key: "iconTheme"' "Voxtype widget exposes iconTheme setting"
require_literal "$bar_registry" 'key: "refreshInterval"' "Voxtype widget exposes refresh interval setting"
require_literal "$panel_qml" '"voxtype": voxtypeComponent,' "Panel dispatch maps the voxtype widget type"
require_literal "$panel_qml" 'id: voxtypeComponent' "Panel defines the voxtype component"
require_literal "$widget_qmldir" 'VoxtypeBarWidget 1.0 VoxtypeBarWidget.qml' "bar components qmldir exports VoxtypeBarWidget"
require_pattern "$widget_qml" 'voxtype status --format json --icon-theme \\"\$1\\"' "Voxtype widget polls the voxtype CLI"
require_pattern "$widget_qml" 'exec voxtype \\"\$@\\"' "Voxtype widget can invoke native voxtype commands"

printf '[INFO] Voxtype contract summary: %d pass, %d fail\n' "$pass_count" "$fail_count"
(( fail_count == 0 ))

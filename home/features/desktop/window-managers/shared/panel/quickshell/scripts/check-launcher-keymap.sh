#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
config_dir="${script_dir}/../config"
launcher_qml="${config_dir}/launcher/Launcher.qml"
config_qml="${config_dir}/services/Config.qml"
system_tab_qml="${config_dir}/menu/settings/tabs/SystemTab.qml"

violations=()

require_literal() {
  local file="$1"
  local needle="$2"
  local label="$3"
  if ! rg -n -F -- "$needle" "$file" >/dev/null 2>&1; then
    violations+=("${label} missing in ${file}")
  fi
}

forbid_literal() {
  local file="$1"
  local needle="$2"
  local label="$3"
  if rg -n -F -- "$needle" "$file" >/dev/null 2>&1; then
    violations+=("${label} should not be present in ${file}")
  fi
}

# Launcher key behavior must include robust Shift+Tab handling and configurable Tab behavior.
require_literal "$launcher_qml" 'readonly property string launcherTabBehavior' "launcherTabBehavior property"
require_literal "$launcher_qml" 'return ["contextual", "results", "mode"].indexOf(value) !== -1 ? value : "contextual";' "launcherTabBehavior normalization"
require_literal "$launcher_qml" 'readonly property string tabControlHintText' "tabControlHintText property"
require_literal "$launcher_qml" 'event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))' "Shift+Tab Backtab handling"
require_literal "$launcher_qml" 'if (launcherRoot.launcherTabBehavior === "mode")' "Tab behavior mode branch"
require_literal "$launcher_qml" 'else if (launcherRoot.launcherTabBehavior === "results")' "Tab behavior results branch"
require_literal "$launcher_qml" 'launcherRoot.cycleSelection(1);' "Tab results selection"
require_literal "$launcher_qml" 'launcherRoot.cycleMode(1);' "Tab mode cycling"
require_literal "$launcher_qml" 'Text { text: launcherRoot.tabControlHintText; color: Colors.text; font.pixelSize: Colors.fontSizeSmall }' "dynamic tab hint text"
forbid_literal "$launcher_qml" 'Text { text: "Tab: next result • Shift+Tab: prev mode"; color: Colors.text; font.pixelSize: Colors.fontSizeSmall }' "old hardcoded tab hint text"

# Config must persist tabBehavior.
require_literal "$config_qml" 'property string launcherTabBehavior: "contextual"' "launcherTabBehavior config property"
require_literal "$config_qml" 'var tabBehavior = String(launcher.tabBehavior || "contextual");' "launcher.tabBehavior load"
require_literal "$config_qml" 'launcherTabBehavior = ["contextual", "results", "mode"].indexOf(tabBehavior) !== -1 ? tabBehavior : "contextual";' "launcher.tabBehavior validation"
require_literal "$config_qml" 'onLauncherTabBehaviorChanged: scheduleSave()' "launcherTabBehavior autosave hook"
require_literal "$config_qml" '"tabBehavior": launcherTabBehavior,' "launcher.tabBehavior persistence"

# Settings must expose tab behavior and reset default.
require_literal "$system_tab_qml" 'Config.launcherTabBehavior = "contextual";' "launcher default reset for tab behavior"
require_literal "$system_tab_qml" 'label: "Tab Behavior"' "Tab Behavior settings row label"
require_literal "$system_tab_qml" 'currentValue: Config.launcherTabBehavior' "Tab Behavior settings current value binding"
require_literal "$system_tab_qml" 'onModeSelected: modeValue => Config.launcherTabBehavior = modeValue' "Tab Behavior settings update binding"

if (( ${#violations[@]} > 0 )); then
  printf '%s\n' "Launcher keymap check failed:" >&2
  printf '  - %s\n' "${violations[@]}" >&2
  exit 1
fi

printf '%s\n' "Launcher keymap check passed."

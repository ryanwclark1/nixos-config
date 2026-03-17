#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
config_dir="${QS_CONFIG_DIR:-${script_dir}/../src}"
launcher_qml="${config_dir}/launcher/Launcher.qml"
launcher_home_qml="${config_dir}/launcher/LauncherHome.qml"
config_qml="${config_dir}/services/Config.qml"
config_persistence_js="${config_dir}/services/config/ConfigPersistence.js"
system_tab_qml="${config_dir}/features/settings/components/tabs/ShellCoreSectionTab.qml"
apps_script="${script_dir}/apps.sh"

violations=()

require_literal() {
  local file="$1"
  local needle="$2"
  local label="$3"
  if ! rg -n -F -- "$needle" "$file" >/dev/null 2>&1; then
    violations+=("${label} missing in ${file}")
  fi
}

require_pattern() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if ! rg -n -U --multiline --pcre2 -- "$pattern" "$file" >/dev/null 2>&1; then
    violations+=("${label} missing in ${file}")
  fi
}

# Config/state wiring
require_literal "$config_qml" 'property bool launcherDrunCategoryFiltersEnabled: false' "drun category filters config property"
require_literal "$config_persistence_js" '"drunCategoryFiltersEnabled": config.launcherDrunCategoryFiltersEnabled,' "drun category filters config persistence"

# Settings exposure
require_literal "$system_tab_qml" 'label: "App Category Filters"' "settings category filter toggle label"
require_literal "$system_tab_qml" 'configKey: "launcherDrunCategoryFiltersEnabled"' "settings category filter toggle binding"
require_literal "$system_tab_qml" 'Config.launcherDrunCategoryFiltersEnabled = false;' "settings category filter reset default"

# Desktop app metadata extraction
require_literal "$apps_script" '/^Categories=/ && categories == "" {' "apps script categories extraction"
require_literal "$apps_script" '/^Keywords=/ && keywords == "" {' "apps script keywords extraction"
require_literal "$apps_script" 'gsub(/;/, " ", cleaned_categories)' "apps script category shaping"
require_literal "$apps_script" 'gsub(/;/, " ", cleaned_keywords)' "apps script keyword shaping"
require_literal "$apps_script" '/^Hidden=/ && hidden == "" {' "apps script hidden flag extraction"
require_literal "$apps_script" '\"desktopId\":\"%s\"' "apps script desktop id output"

# Launcher behavior and UI guards
require_literal "$launcher_qml" 'readonly property bool drunCategoryFiltersEnabled: Config.launcherDrunCategoryFiltersEnabled' "launcher category filters enabled binding"
require_literal "$launcher_qml" 'property var drunCategoryOptions:' "launcher category option state"
require_literal "$launcher_qml" 'function refreshDrunCategoryOptions(apps) {' "launcher category options refresh function"
require_literal "$launcher_qml" 'if (!drunCategoryFiltersEnabled) {' "launcher category options disabled guard"
require_literal "$launcher_qml" 'function setDrunCategoryFilter(categoryKey) {' "launcher category set function"
require_literal "$launcher_qml" 'function cycleDrunCategoryFilter(step) {' "launcher category cycle function"
require_literal "$launcher_qml" 'function selectDrunCategorySlot(slot) {' "launcher category slot selection function"
require_literal "$launcher_qml" 'function drunCategoryStateObject() {' "launcher category state payload helper"
require_pattern "$launcher_qml" 'function drunCategoryState\(\)\s*(?::\s*string)?\s*\{' "launcher category state IPC method"
require_literal "$launcher_qml" 'readonly property string launcherControlHintText: {' "launcher control hint property"
require_literal "$launcher_qml" 'launcherRoot.drunCategoryFiltersEnabled && launcherRoot.mode === "drun" && (event.modifiers & Qt.AltModifier) && !(event.modifiers & Qt.ControlModifier)' "launcher category keyboard handler branch"
require_literal "$launcher_qml" 'launcherRoot.drunCategoryFiltersEnabled && launcherRoot.mode === "drun" && launcherRoot.showLauncherHome && (event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_Tab' "launcher category ctrl+tab keyboard handler branch"
require_literal "$launcher_qml" 'var clearHint = searchText !== "" ? "Ctrl+L/U: clear • " : "";' "launcher category clear hint"
require_literal "$launcher_qml" 'var escapeHint = (searchText !== "" || (drunCategoryFiltersEnabled && mode === "drun" && (drunCategoryFilter !== "" || drunCategorySectionExpanded))) ? "Esc: reset/close" : "Esc: close";' "launcher category escape hint"
require_literal "$launcher_qml" 'return "Alt+←/→/PgUp/PgDn/Home/End/0/Backspace, Ctrl+Tab, or Alt+1..9: categories • " + resultHint + clearHint + "Enter: run • " + escapeHint;' "launcher category keyboard hint"
require_literal "$launcher_qml" 'function jumpDrunCategoryBoundary(toEnd) {' "launcher category boundary helper"
require_literal "$launcher_qml" 'else if (event.key === Qt.Key_0 || event.key === Qt.Key_Backspace) {' "launcher category clear branch"
require_literal "$launcher_qml" 'launcherRoot.showLauncherHome && launcherRoot.drunCategoryFiltersEnabled && launcherRoot.mode === "drun" && launcherRoot.drunCategoryOptions.length > 1' "launcher category chip visibility guard"
require_literal "$launcher_home_qml" 'readonly property bool categorySummaryExpanded: root.launcher.drunCategorySectionExpanded || root.launcher.drunCategoryFilter !== ""' "launcher home category summary expansion binding"
require_literal "$launcher_home_qml" 'text: root.launcher.drunCategoryFilter === "" ? "All Apps" : root.launcher.drunCategoryFilterLabel' "launcher home summary pill label"
require_literal "$launcher_home_qml" 'visible: root.showCategoryChips' "launcher home compact chip visibility"
require_literal "$launcher_home_qml" 'label: String(modelData.label || "All")' "launcher home compact chip label"
require_literal "$launcher_home_qml" 'SharedWidgets.AppIcon {' "launcher home shared app icon usage"

if (( ${#violations[@]} > 0 )); then
  printf '%s\n' "Launcher category filters check failed:" >&2
  printf '  - %s\n' "${violations[@]}" >&2
  exit 1
fi

printf '%s\n' "Launcher category filters check passed."

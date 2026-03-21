#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
config_dir="${QS_CONFIG_DIR:-${script_dir}/../src}"
launcher_qml="${config_dir}/launcher/Launcher.qml"
launcher_key_handler_qml="${config_dir}/launcher/LauncherKeyHandler.qml"
launcher_content_panel_qml="${config_dir}/launcher/LauncherContentPanel.qml"
launcher_home_qml="${config_dir}/launcher/LauncherHome.qml"
config_qml="${config_dir}/services/Config.qml"
config_persistence_js="${config_dir}/services/config/ConfigPersistence.js"
launcher_domain_js="${config_dir}/services/config/domains/launcher.js"
launcher_settings_qml="${config_dir}/features/settings/components/tabs/ShellLauncherSection.qml"
launcher_helpers_js="${config_dir}/features/settings/components/tabs/ShellCoreHelpers.js"
app_catalog_qml="${config_dir}/services/AppCatalogService.qml"

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
require_literal "$launcher_domain_js" '["drunCategoryFiltersEnabled", "launcherDrunCategoryFiltersEnabled"]' "drun category filters config persistence"

# Settings exposure
require_literal "$launcher_settings_qml" 'label: "App Category Filters"' "settings category filter toggle label"
require_literal "$launcher_settings_qml" 'configKey: "launcherDrunCategoryFiltersEnabled"' "settings category filter toggle binding"
require_literal "$launcher_helpers_js" 'Config.launcherDrunCategoryFiltersEnabled = false;' "settings category filter reset default"

# Desktop app metadata extraction
require_literal "$app_catalog_qml" 'line.startsWith("Categories=")' "app catalog categories extraction"
require_literal "$app_catalog_qml" 'line.startsWith("Keywords=")' "app catalog keywords extraction"
require_literal "$app_catalog_qml" '_spaceSeparated(fields.categories)' "app catalog category shaping"
require_literal "$app_catalog_qml" '_spaceSeparated(fields.keywords)' "app catalog keyword shaping"
require_literal "$app_catalog_qml" 'line.startsWith("Hidden=")' "app catalog hidden flag extraction"
require_literal "$app_catalog_qml" 'desktopId: _desktopIdForPath(path)' "app catalog desktop id output"

# Launcher behavior and UI guards
require_literal "$launcher_qml" 'readonly property bool drunCategoryFiltersEnabled: Config.launcherDrunCategoryFiltersEnabled' "launcher category filters enabled binding"
require_literal "$launcher_qml" 'property alias drunCategoryOptions: controller.drunCategoryOptions' "launcher category option state"
require_literal "$launcher_qml" 'function refreshDrunCategoryOptions(apps) {' "launcher category options refresh function"
require_literal "$launcher_qml" 'if (!drunCategoryFiltersEnabled) {' "launcher category options disabled guard"
require_literal "$launcher_qml" 'function setDrunCategoryFilter(categoryKey) {' "launcher category set function"
require_literal "$launcher_qml" 'function cycleDrunCategoryFilter(step) {' "launcher category cycle function"
require_literal "$launcher_qml" 'function selectDrunCategorySlot(slot) {' "launcher category slot selection function"
require_literal "$launcher_qml" 'function drunCategoryStateObject() {' "launcher category state payload helper"
require_pattern "$launcher_qml" 'function drunCategoryState\(\)\s*(?::\s*string)?\s*\{' "launcher category state IPC method"
require_literal "$launcher_qml" 'readonly property string launcherControlHintText: {' "launcher control hint property"
require_literal "$launcher_content_panel_qml" 'LauncherKeyHandler {' "launcher category key handler wiring"
require_literal "$launcher_key_handler_qml" 'launcher.drunCategoryFiltersEnabled && launcher.mode === "drun" && (event.modifiers & Qt.AltModifier) && !(event.modifiers & Qt.ControlModifier)' "launcher category keyboard handler branch"
require_literal "$launcher_key_handler_qml" 'launcher.drunCategoryFiltersEnabled && launcher.mode === "drun" && launcher.showLauncherHome && (event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_Tab' "launcher category ctrl+tab keyboard handler branch"
require_literal "$launcher_qml" 'var clearHint = searchText !== "" ? "Ctrl+L/U: clear • " : "";' "launcher category clear hint"
require_literal "$launcher_qml" 'var escapeHint = (searchText !== "" || (drunCategoryFiltersEnabled && mode === "drun" && (drunCategoryFilter !== "" || drunCategorySectionExpanded))) ? "Esc: reset/close" : "Esc: close";' "launcher category escape hint"
require_literal "$launcher_qml" 'return "Alt+←/→/PgUp/PgDn/Home/End/0/Backspace, Ctrl+Tab, or Alt+1..9: categories • " + resultHint + clearHint + "Enter: run • " + escapeHint;' "launcher category keyboard hint"
require_literal "$launcher_qml" 'function jumpDrunCategoryBoundary(toEnd) {' "launcher category boundary helper"
require_literal "$launcher_key_handler_qml" 'else if (event.key === Qt.Key_0 || event.key === Qt.Key_Backspace) {' "launcher category clear branch"
require_literal "$launcher_home_qml" 'readonly property bool showCategoryFilters: root.showCategoryFiltersSection && root.launcher.showLauncherHome && root.launcher.drunCategoryFiltersEnabled && root.launcher.mode === "drun" && root.launcher.drunCategoryOptions.length > 1' "launcher category chip visibility guard"
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

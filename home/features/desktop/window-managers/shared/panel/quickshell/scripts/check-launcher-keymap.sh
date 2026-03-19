#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
config_dir="${QS_CONFIG_DIR:-${script_dir}/../src}"
launcher_qml="${config_dir}/launcher/Launcher.qml"
launcher_key_handler_qml="${config_dir}/launcher/LauncherKeyHandler.qml"
launcher_content_panel_qml="${config_dir}/launcher/LauncherContentPanel.qml"
config_qml="${config_dir}/services/Config.qml"
config_persistence_js="${config_dir}/services/config/ConfigPersistence.js"
launcher_settings_qml="${config_dir}/features/settings/components/tabs/ShellLauncherSection.qml"
launcher_helpers_js="${config_dir}/features/settings/components/tabs/ShellCoreHelpers.js"

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
require_literal "$launcher_qml" 'readonly property string launcherControlHintText: {' "launcherControlHintText property"
require_literal "$launcher_qml" 'readonly property string legendTertiaryAction: {' "legend tertiary action property"
require_literal "$launcher_qml" 'var clearHint = searchText !== "" ? "Ctrl+L/U: clear • " : "";' "dynamic clear hint text"
require_literal "$launcher_qml" 'var escapeHint = (searchText !== "" || (drunCategoryFiltersEnabled && mode === "drun" && (drunCategoryFilter !== "" || drunCategorySectionExpanded))) ? "Esc: reset/close" : "Esc: close";' "dynamic escape hint text"
require_literal "$launcher_qml" 'if (searchText !== "" || (drunCategoryFiltersEnabled && mode === "drun" && (drunCategoryFilter !== "" || drunCategorySectionExpanded)))' "legend escape reset branch"
require_literal "$launcher_content_panel_qml" 'LauncherKeyHandler {' "LauncherKeyHandler wiring"
require_literal "$launcher_content_panel_qml" 'Keys.onPressed: event => keyHandler.handleKeyPress(event)' "LauncherKeyHandler key forwarding"
require_literal "$launcher_key_handler_qml" 'event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))' "Shift+Tab Backtab handling"
require_literal "$launcher_key_handler_qml" 'if (launcher.launcherTabBehavior === "mode")' "Tab behavior mode branch"
require_literal "$launcher_key_handler_qml" 'else if (launcher.launcherTabBehavior === "results")' "Tab behavior results branch"
require_literal "$launcher_key_handler_qml" 'launcher.cycleSelection(1);' "Tab results selection"
require_literal "$launcher_key_handler_qml" 'launcher.cycleMode(1);' "Tab mode cycling"
require_literal "$launcher_key_handler_qml" 'launcher.drunCategoryFiltersEnabled && launcher.mode === "drun" && launcher.showLauncherHome && (event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_Tab' "Ctrl+Tab drun category branch"
require_literal "$launcher_key_handler_qml" 'var direction = (event.modifiers & Qt.ShiftModifier) ? -1 : 1;' "Ctrl+Tab category direction"
require_literal "$launcher_key_handler_qml" 'if (launcher.cycleDrunCategoryFilter(direction))' "Ctrl+Tab category cycling"
require_literal "$launcher_qml" 'function jumpDrunCategoryBoundary(toEnd) {' "category boundary helper"
require_pattern "$launcher_key_handler_qml" '(?s)launcher\.drunCategoryFiltersEnabled && launcher\.mode === "drun" && \(event\.modifiers & Qt\.AltModifier\).*?event\.key === Qt\.Key_PageUp' "Alt+PageUp category branch"
require_pattern "$launcher_key_handler_qml" '(?s)launcher\.drunCategoryFiltersEnabled && launcher\.mode === "drun" && \(event\.modifiers & Qt\.AltModifier\).*?event\.key === Qt\.Key_PageDown' "Alt+PageDown category branch"
require_pattern "$launcher_key_handler_qml" '(?s)launcher\.drunCategoryFiltersEnabled && launcher\.mode === "drun" && \(event\.modifiers & Qt\.AltModifier\).*?event\.key === Qt\.Key_Home' "Alt+Home category branch"
require_literal "$launcher_key_handler_qml" 'if (launcher.jumpDrunCategoryBoundary(false))' "Alt+Home category jump"
require_pattern "$launcher_key_handler_qml" '(?s)launcher\.drunCategoryFiltersEnabled && launcher\.mode === "drun" && \(event\.modifiers & Qt\.AltModifier\).*?event\.key === Qt\.Key_End' "Alt+End category branch"
require_literal "$launcher_key_handler_qml" 'if (launcher.jumpDrunCategoryBoundary(true))' "Alt+End category jump"
require_pattern "$launcher_key_handler_qml" '(?s)launcher\.drunCategoryFiltersEnabled && launcher\.mode === "drun" && \(event\.modifiers & Qt\.AltModifier\).*?event\.key === Qt\.Key_0 \|\| event\.key === Qt\.Key_Backspace' "Alt+0/Backspace category clear branch"
require_literal "$launcher_qml" 'function clearSearchQuery() {' "clear search query helper"
require_literal "$launcher_key_handler_qml" 'launcher.clearSearchQuery();' "Ctrl+L clear search action"
require_literal "$launcher_key_handler_qml" 'else if ((event.modifiers & Qt.ControlModifier) && !(event.modifiers & Qt.AltModifier) && (event.key === Qt.Key_L || event.key === Qt.Key_U)) {' "Ctrl+L/Ctrl+U key branch"
require_literal "$launcher_qml" 'function moveSelectionRelative(step) {' "relative selection helper"
require_literal "$launcher_key_handler_qml" 'else if ((event.modifiers & Qt.ControlModifier) && !(event.modifiers & Qt.AltModifier) && event.key === Qt.Key_P) {' "Ctrl+P key branch"
require_literal "$launcher_key_handler_qml" 'if (launcher.moveSelectionRelative(-1))' "Ctrl+P selection jump"
require_literal "$launcher_key_handler_qml" 'else if ((event.modifiers & Qt.ControlModifier) && !(event.modifiers & Qt.AltModifier) && event.key === Qt.Key_N) {' "Ctrl+N key branch"
require_literal "$launcher_key_handler_qml" 'if (launcher.moveSelectionRelative(1))' "Ctrl+N selection jump"
require_literal "$launcher_qml" 'function jumpSelectionBoundary(toEnd) {' "selection boundary jump helper"
require_literal "$launcher_qml" 'selectedIndex = toEnd ? (filteredItems.length - 1) : 0;' "selection boundary assignment"
require_literal "$launcher_qml" 'function pageSelection(step) {' "selection paging helper"
require_literal "$launcher_qml" 'var pageSize = Math.max(5, Math.min(12, Math.round(hudBox.height / 72)));' "selection paging size calculation"
require_literal "$launcher_key_handler_qml" 'else if (event.key === Qt.Key_PageUp) {' "PageUp key branch"
require_literal "$launcher_key_handler_qml" 'if (launcher.pageSelection(-1))' "PageUp key selection jump"
require_literal "$launcher_key_handler_qml" 'else if (event.key === Qt.Key_PageDown) {' "PageDown key branch"
require_literal "$launcher_key_handler_qml" 'if (launcher.pageSelection(1))' "PageDown key selection jump"
require_literal "$launcher_key_handler_qml" 'else if (event.key === Qt.Key_Home) {' "Home key branch"
require_literal "$launcher_key_handler_qml" 'if (launcher.jumpSelectionBoundary(false))' "Home key selection jump"
require_literal "$launcher_key_handler_qml" 'else if (event.key === Qt.Key_End) {' "End key branch"
require_literal "$launcher_key_handler_qml" 'if (launcher.jumpSelectionBoundary(true))' "End key selection jump"
require_literal "$launcher_qml" 'function handleEscapeAction() {' "escape handling helper"
require_literal "$launcher_qml" 'if (showingConfirm) {' "escape helper confirm branch"
require_literal "$launcher_qml" 'if (searchText !== "") {' "escape helper query reset branch"
require_literal "$launcher_qml" 'if (drunCategoryFiltersEnabled && mode === "drun" && drunCategoryFilter !== "") {' "escape helper category reset branch"
require_literal "$launcher_qml" 'if (drunCategoryFiltersEnabled && mode === "drun" && drunCategorySectionExpanded) {' "escape helper category summary collapse branch"
require_literal "$launcher_key_handler_qml" 'if (event.key === Qt.Key_Escape) {' "escape key branch"
require_literal "$launcher_key_handler_qml" 'if (launcher.handleEscapeAction())' "escape key helper call"
forbid_literal "$launcher_qml" 'Text { text: "Tab: next result • Shift+Tab: prev mode"; color: Colors.text; font.pixelSize: Colors.fontSizeSmall }' "old hardcoded tab hint text"
forbid_literal "$launcher_qml" 'Text { text: launcherRoot.drunCategoryFiltersEnabled && launcherRoot.mode === "drun" && launcherRoot.drunCategoryOptions.length > 1 ? "Alt+←/→, Ctrl+Tab, or Alt+1..9: categories • Enter: run • Esc: close" : "Enter to run • Esc to close"; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeXS; wrapMode: Text.WordWrap }' "old hardcoded control hint text"

# Config must expose and persist tabBehavior.
require_literal "$config_qml" 'property string launcherTabBehavior: "contextual"' "launcherTabBehavior config property"
require_literal "$config_persistence_js" '["tabBehavior", "launcherTabBehavior"]' "launcher.tabBehavior persistence"

# Settings must expose tab behavior and reset default.
require_literal "$launcher_helpers_js" 'Config.launcherTabBehavior = "contextual";' "launcher default reset for tab behavior"
require_literal "$launcher_settings_qml" 'label: "Tab Behavior"' "Tab Behavior settings row label"
require_literal "$launcher_settings_qml" 'currentValue: Config.launcherTabBehavior' "Tab Behavior settings current value binding"
require_literal "$launcher_settings_qml" 'onModeSelected: modeValue => Config.launcherTabBehavior = modeValue' "Tab Behavior settings update binding"

if (( ${#violations[@]} > 0 )); then
  printf '%s\n' "Launcher keymap check failed:" >&2
  printf '  - %s\n' "${violations[@]}" >&2
  exit 1
fi

printf '%s\n' "Launcher keymap check passed."

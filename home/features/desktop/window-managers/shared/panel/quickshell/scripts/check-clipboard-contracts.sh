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

require_absent_literal() {
  local file="$1"
  local literal="$2"
  local label="$3"
  if rg -Fq -- "$literal" "$file"; then
    fail "$label"
  else
    pass "$label"
  fi
}

launcher_qml="${repo_root}/src/launcher/Launcher.qml"
launcher_search_field_qml="${repo_root}/src/launcher/LauncherSearchField.qml"
clipboard_menu_qml="${repo_root}/src/features/clipboard/ClipboardMenu.qml"
clipboard_service_qml="${repo_root}/src/services/ClipboardHistoryService.qml"
panel_qml="${repo_root}/src/bar/Panel.qml"

require_literal "$launcher_search_field_qml" 'signal accepted(var modifiers)' "LauncherSearchField exposes Enter modifiers"
require_literal "$launcher_search_field_qml" 'root.accepted(event.modifiers);' "LauncherSearchField forwards Enter to accepted()"
require_literal "$launcher_qml" 'function handleSearchAccepted(modifiers) {' "Launcher exposes a shared Enter handler"
require_literal "$launcher_qml" 'onAccepted: modifiers => launcherRoot.handleSearchAccepted(modifiers)' "Launcher search field is wired to the shared Enter handler"
require_literal "$launcher_qml" 'function restoreClipboardHistoryItem(id) {' "Launcher exposes clipboard restore helper"
require_literal "$launcher_qml" 'ClipboardHistoryService.restore(id);' "Launcher clipboard restore helper delegates to ClipboardHistoryService"
require_literal "$clipboard_menu_qml" 'property int selectedIndex: 0' "Clipboard widget tracks keyboard selection"
require_literal "$clipboard_menu_qml" 'function activateClipboardItem(item) {' "Clipboard widget exposes a shared activation helper"
require_literal "$clipboard_menu_qml" 'function deleteClipboardItem(item) {' "Clipboard widget exposes an id-based delete helper"
require_literal "$clipboard_menu_qml" 'ClipboardHistoryService.restore(item.id);' "Clipboard widget restore helper delegates to ClipboardHistoryService"
require_literal "$clipboard_menu_qml" 'root.closeRequested();' "Clipboard widget closes through the local popup path after restore"
require_literal "$clipboard_menu_qml" 'ClipboardHistoryService.deleteEntry(item.id);' "Clipboard widget delete helper delegates to ClipboardHistoryService"
require_literal "$clipboard_menu_qml" 'ClipboardHistoryService.wipe();' "Clipboard widget clears history through ClipboardHistoryService"
require_literal "$clipboard_menu_qml" 'icon: ClipboardHistoryService.loading ? "󰇚" : "󰑐"' "Clipboard widget exposes a refresh affordance in the header"
require_literal "$clipboard_menu_qml" 'message: root.isLoadingHistory' "Clipboard empty state reacts to loading and error states"
require_literal "$clipboard_menu_qml" 'Keys.onDownPressed' "Clipboard widget supports keyboard navigation down"
require_literal "$clipboard_menu_qml" 'Keys.onUpPressed' "Clipboard widget supports keyboard navigation up"
require_literal "$clipboard_menu_qml" 'root.activateClipboardItem(root.filteredItemsResult[root.selectedIndex]);' "Clipboard widget Enter key activates the selected item"
require_literal "$clipboard_service_qml" 'readonly property bool available: DependencyService.allAvailable(["cliphist", "wl-copy", "wl-paste"])' "Clipboard service requires Wayland clipboard tools"
require_literal "$clipboard_service_qml" 'Quickshell.execDetached(["sh", "-c", "cliphist decode " + safeId + " | wl-copy"]);' "Clipboard service restores via wl-copy"
require_literal "$clipboard_service_qml" 'Quickshell.execDetached(["sh", "-c", "printf '\''%s\\n'\'' " + root._shellQuote(line) + " | cliphist delete"]);' "Clipboard service deletes entries by piping the raw cliphist row"
require_literal "$clipboard_service_qml" 'Quickshell.execDetached(["cliphist", "wipe"]);' "Clipboard service wipes history directly"
require_absent_literal "$clipboard_service_qml" 'content.indexOf("[[ binary data") !== -1' "Clipboard service keeps binary/image entries in history"
require_literal "$panel_qml" 'action: () => Quickshell.execDetached(["cliphist", "wipe"])' "Clipboard bar widget clears history with direct exec"

if command -v cliphist >/dev/null 2>&1; then
  if cliphist list | node -e '
const fs = require("fs");
const raw = fs.readFileSync(0, "utf8");
const lines = raw.trim() === "" ? [] : raw.trim().split("\n");
for (const line of lines.slice(0, 10)) {
  const idx = line.indexOf("\t");
  if (idx <= 0) process.exit(1);
}
'; then
    pass "cliphist list emits tab-delimited rows that ClipboardHistoryService can parse"
  else
    fail "cliphist list emits tab-delimited rows that ClipboardHistoryService can parse"
  fi
else
  fail "cliphist must be installed for clipboard contracts"
fi

printf '[INFO] Clipboard contract summary: %d pass, %d fail\n' "$pass_count" "$fail_count"
(( fail_count == 0 ))

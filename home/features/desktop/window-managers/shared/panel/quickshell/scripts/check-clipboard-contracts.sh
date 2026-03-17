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

launcher_qml="${repo_root}/src/launcher/Launcher.qml"
launcher_search_field_qml="${repo_root}/src/launcher/LauncherSearchField.qml"
clipboard_menu_qml="${repo_root}/src/features/clipboard/ClipboardMenu.qml"
panel_qml="${repo_root}/src/bar/Panel.qml"

require_literal "$launcher_search_field_qml" 'signal accepted(var modifiers)' "LauncherSearchField exposes Enter modifiers"
require_literal "$launcher_search_field_qml" 'root.accepted(event.modifiers);' "LauncherSearchField forwards Enter to accepted()"
require_literal "$launcher_qml" 'function handleSearchAccepted(modifiers) {' "Launcher exposes a shared Enter handler"
require_literal "$launcher_qml" 'onAccepted: modifiers => launcherRoot.handleSearchAccepted(modifiers)' "Launcher search field is wired to the shared Enter handler"
require_literal "$launcher_qml" 'function restoreClipboardHistoryItem(id) {' "Launcher exposes clipboard restore helper"
require_literal "$launcher_qml" 'cliphist decode ' "Launcher clipboard restore helper decodes cliphist entries"
require_literal "$launcher_qml" 'xclip -selection clipboard' "Launcher clipboard restore/copy falls back to xclip"
require_literal "$clipboard_menu_qml" 'property int selectedIndex: 0' "Clipboard widget tracks keyboard selection"
require_literal "$clipboard_menu_qml" 'function activateClipboardItem(item) {' "Clipboard widget exposes a shared activation helper"
require_literal "$clipboard_menu_qml" 'function deleteClipboardItem(item) {' "Clipboard widget exposes an id-based delete helper"
require_pattern "$clipboard_menu_qml" 'cliphist list \| awk -F '\''\\\\t'\'' '\''\$1 == " \+ safeId \+ " \{ print; exit \}'\'' \| cliphist delete' "Clipboard widget delete helper targets entries by id"
require_literal "$clipboard_menu_qml" 'Quickshell.execDetached(["cliphist", "wipe"]);' "Clipboard widget clears history without an extra shell wrapper"
require_literal "$clipboard_menu_qml" 'Keys.onDownPressed' "Clipboard widget supports keyboard navigation down"
require_literal "$clipboard_menu_qml" 'Keys.onUpPressed' "Clipboard widget supports keyboard navigation up"
require_literal "$clipboard_menu_qml" 'root.activateClipboardItem(root.filteredItemsResult[root.selectedIndex]);' "Clipboard widget Enter key activates the selected item"
require_literal "$panel_qml" 'action: () => Quickshell.execDetached(["cliphist", "wipe"])' "Clipboard bar widget clears history with direct exec"

if command -v qs-clip >/dev/null 2>&1; then
  if qs-clip | node -e '
const fs = require("fs");
const raw = fs.readFileSync(0, "utf8");
const data = JSON.parse(raw);
if (!Array.isArray(data)) process.exit(1);
for (const entry of data.slice(0, 10)) {
  if (typeof entry !== "object" || entry === null) process.exit(1);
  if (typeof entry.id !== "string" || entry.id.trim() === "") process.exit(1);
  if (typeof entry.content !== "string") process.exit(1);
}
'; then
    pass "qs-clip emits JSON array entries with string id/content fields"
  else
    fail "qs-clip emits JSON array entries with string id/content fields"
  fi
else
  fail "qs-clip must be installed for clipboard contracts"
fi

printf '[INFO] Clipboard contract summary: %d pass, %d fail\n' "$pass_count" "$fail_count"
(( fail_count == 0 ))

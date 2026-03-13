#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
launcher_qml="${script_dir}/../config/launcher/Launcher.qml"

violations=()

require_literal() {
  local file="$1"
  local needle="$2"
  local label="$3"
  if ! rg -n -F -- "$needle" "$file" >/dev/null 2>&1; then
    violations+=("${label} missing in ${file}")
  fi
}

# Config normalization and matrix hinting.
require_literal "$launcher_qml" 'readonly property string launcherTabBehavior: {' "launcherTabBehavior property"
require_literal "$launcher_qml" 'return ["contextual", "results", "mode"].indexOf(value) !== -1 ? value : "contextual";' "launcherTabBehavior normalization"
require_literal "$launcher_qml" 'readonly property string tabControlHintText: {' "tabControlHintText property"
require_literal "$launcher_qml" 'if (launcherTabBehavior === "mode")' "tab matrix mode hint branch"
require_literal "$launcher_qml" 'if (launcherTabBehavior === "results")' "tab matrix results hint branch"
require_literal "$launcher_qml" 'return hasResults ? "Tab: next result • Shift+Tab: prev mode" : "Tab: next mode • Shift+Tab: prev mode";' "tab matrix contextual hint branch"

# Runtime key handling matrix.
require_literal "$launcher_qml" 'event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))' "Shift+Tab handling"
require_literal "$launcher_qml" 'launcherRoot.cycleMode(-1);' "Shift+Tab cycles previous mode"
require_literal "$launcher_qml" 'else if (event.key === Qt.Key_Tab) {' "Tab handling block"
require_literal "$launcher_qml" 'if (launcherRoot.launcherTabBehavior === "mode")' "Tab mode branch"
require_literal "$launcher_qml" 'else if (launcherRoot.launcherTabBehavior === "results")' "Tab results branch"
require_literal "$launcher_qml" 'else if (launcherRoot.filteredItems.length > 0)' "Tab contextual with results branch"
require_literal "$launcher_qml" 'else' "Tab contextual without results branch"
require_literal "$launcher_qml" 'launcherRoot.cycleSelection(1);' "Tab selection cycle"
require_literal "$launcher_qml" 'launcherRoot.cycleMode(1);' "Tab next mode cycle"

# Legend text must match behavior.
require_literal "$launcher_qml" 'if (launcherTabBehavior === "mode") return "Tab: Next Mode";' "legend mode branch"
require_literal "$launcher_qml" 'if (launcherTabBehavior === "results") return "Tab: Next Result";' "legend results branch"
require_literal "$launcher_qml" 'return hasResults ? "Tab: Next Result" : "Tab: Next Mode";' "legend contextual branch"
require_literal "$launcher_qml" 'readonly property string legendTertiaryAction: showingConfirm ? "Esc: Cancel" : "Shift+Tab: Prev Mode"' "legend shift+tab mapping"

# Wrapping semantics for mode/result cycling.
require_literal "$launcher_qml" 'var nextIndex = (currentIndex + step + modeOrder.length) % modeOrder.length;' "mode cycle wrap-around"
require_literal "$launcher_qml" 'var next = (selectedIndex + step + filteredItems.length) % filteredItems.length;' "selection cycle wrap-around"

if (( ${#violations[@]} > 0 )); then
  printf '%s\n' "Launcher tab matrix check failed:" >&2
  printf '  - %s\n' "${violations[@]}" >&2
  exit 1
fi

printf '%s\n' "Launcher tab matrix check passed."

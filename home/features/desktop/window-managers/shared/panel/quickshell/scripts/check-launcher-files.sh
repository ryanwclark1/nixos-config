#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
config_dir="${QS_CONFIG_DIR:-${script_dir}/../src}"
launcher_qml="${config_dir}/launcher/Launcher.qml"
launcher_executor_js="${config_dir}/launcher/LauncherExecutor.js"
launcher_parser_js="${config_dir}/launcher/LauncherFileParser.js"
launcher_text_js="${config_dir}/launcher/LauncherTextHelpers.js"
launcher_delegate_qml="${config_dir}/launcher/LauncherResultDelegate.qml"
config_qml="${config_dir}/services/Config.qml"
config_persistence_js="${config_dir}/services/config/ConfigPersistence.js"
config_launcher_js="${config_dir}/services/config/ConfigLauncher.js"
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

require_literal "$config_qml" 'property string launcherFileSearchRoot: "~"' "launcher file search root config"
require_literal "$config_qml" 'property bool launcherFileShowHidden: false' "launcher file hidden toggle config"
require_literal "$config_qml" 'property string launcherFileOpener: "xdg-open"' "launcher file opener config"
require_literal "$config_persistence_js" '["fileSearchRoot", "launcherFileSearchRoot"]' "launcher file root persistence"
require_literal "$config_persistence_js" '["fileShowHidden", "launcherFileShowHidden"]' "launcher file hidden persistence"
require_literal "$config_persistence_js" '["fileOpener", "launcherFileOpener"]' "launcher file opener persistence"
require_literal "$config_launcher_js" 'config.launcherFileSearchRoot = normalizeLauncherPath(launcher.fileSearchRoot, "~");' "launcher file root normalization"
require_literal "$config_launcher_js" 'config.launcherFileShowHidden = asBool(launcher.fileShowHidden, false);' "launcher file hidden normalization"
require_literal "$config_launcher_js" 'config.launcherFileOpener = normalizeLauncherCommand(launcher.fileOpener, "xdg-open");' "launcher file opener normalization"
require_literal "$launcher_helpers_js" 'Config.launcherFileSearchRoot = "~";' "launcher file root reset"
require_literal "$launcher_helpers_js" 'Config.launcherFileShowHidden = false;' "launcher file hidden reset"
require_literal "$launcher_helpers_js" 'Config.launcherFileOpener = "xdg-open";' "launcher file opener reset"
require_literal "$launcher_settings_qml" 'label: "File Search Root"' "launcher settings file root row"
require_literal "$launcher_settings_qml" 'configKey: "launcherFileShowHidden"' "launcher settings hidden toggle row"
require_literal "$launcher_settings_qml" 'label: "File Opener"' "launcher settings file opener row"
require_literal "$launcher_qml" 'readonly property string fileSearchRootResolved: resolveFileSearchRoot(fileSearchRootSetting)' "launcher resolved file root property"
require_literal "$launcher_qml" 'readonly property bool fileSearchShowHidden: Config.launcherFileShowHidden === true' "launcher hidden toggle property"
require_literal "$launcher_qml" 'readonly property string fileOpenerCommand: {' "launcher file opener property"
require_literal "$launcher_qml" 'function openFileItem(item) {' "launcher file opener helper"
require_literal "$launcher_qml" 'function revealFileInManager(item) {' "launcher file reveal helper"
require_literal "$launcher_qml" 'function fileContextMenuModel(item) {' "launcher file context menu helper"
require_literal "$launcher_qml" 'ContextMenu {' "launcher file context menu component"
require_literal "$launcher_qml" 'fileResultContextMenu.model = launcherRoot.fileContextMenuModel(modelData);' "launcher file context menu wiring"
require_literal "$launcher_qml" 'if (fileSearchShowHidden)' "launcher fd hidden toggle handling"
require_literal "$launcher_executor_js" 'actions.openFileItem(item);' "launcher executor file open helper"
require_literal "$launcher_executor_js" 'actions.openDirectoryPath(actions.fileSearchRootResolved);' "launcher executor open configured root"
require_literal "$launcher_executor_js" 'actions.openDirectoryPath(target);' "launcher executor secondary open path"
require_literal "$launcher_delegate_qml" 'signal secondaryActionRequested(real globalX, real globalY)' "launcher delegate secondary action signal"
require_literal "$launcher_parser_js" 'function iconForFile(name, extension, kind) {' "launcher file icon classifier"
require_literal "$launcher_parser_js" 'icon: iconForFile(name, extension, kind)' "launcher parser assigns file icon"
require_literal "$launcher_text_js" 'return "Start typing to search " + String(fileRootLabel || "Files");' "launcher text helper file root title"

if (( ${#violations[@]} > 0 )); then
  printf '%s\n' "Launcher file search check failed:" >&2
  printf '  - %s\n' "${violations[@]}" >&2
  exit 1
fi

printf '%s\n' "Launcher file search check passed."

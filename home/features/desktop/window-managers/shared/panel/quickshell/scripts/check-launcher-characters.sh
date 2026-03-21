#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
config_dir="${QS_CONFIG_DIR:-${script_dir}/../src}"
launcher_qml="${config_dir}/launcher/Launcher.qml"
launcher_search_js="${config_dir}/launcher/LauncherSearch.js"
launcher_executor_js="${config_dir}/launcher/LauncherExecutor.js"
launcher_mode_data_js="${config_dir}/launcher/LauncherModeData.js"
launcher_result_delegate_qml="${config_dir}/launcher/LauncherResultDelegate.qml"
character_data_js="${config_dir}/launcher/CharacterData.js"
config_qml="${config_dir}/services/Config.qml"
config_persistence_js="${config_dir}/services/config/ConfigPersistence.js"
launcher_domain_js="${config_dir}/services/config/domains/launcher.js"
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

require_literal "$config_qml" 'property string launcherCharacterTrigger: ":"' "launcher character trigger config"
require_literal "$config_qml" 'property bool launcherCharacterPasteOnSelect: false' "launcher character paste toggle config"
require_literal "$launcher_domain_js" '["characterTrigger", "launcherCharacterTrigger"]' "launcher character trigger persistence"
require_literal "$launcher_domain_js" '["characterPasteOnSelect", "launcherCharacterPasteOnSelect"]' "launcher character paste persistence"
require_literal "$config_launcher_js" 'config.launcherCharacterTrigger = normalizeCharacterTrigger(launcher.characterTrigger);' "launcher character trigger normalization"
require_literal "$config_launcher_js" 'config.launcherCharacterPasteOnSelect = asBool(launcher.characterPasteOnSelect, false);' "launcher character paste normalization"
require_literal "$launcher_mode_data_js" '"emoji": { label: "Characters"' "characters mode label"
require_literal "$launcher_mode_data_js" 'hint: "Search characters with :"' "characters mode hint"
require_literal "$launcher_mode_data_js" 'prefix: ":"' "characters mode prefix"
require_literal "$launcher_mode_data_js" '"emoji": ["wl-copy"]' "character mode dependency"
require_literal "$launcher_qml" 'readonly property string characterTrigger: {' "launcher character trigger property"
require_literal "$launcher_qml" 'function matchesCharacterTrigger(text) {' "launcher character trigger matcher"
require_literal "$launcher_qml" 'function shouldPasteCharacter(modifiers) {' "launcher character paste helper"
require_literal "$launcher_qml" 'function selectCharacter(text, pasteRequested) {' "launcher character select helper"
require_literal "$launcher_qml" 'showTransientNotice("Copied " + text' "launcher copied notice"
require_literal "$launcher_qml" 'showTransientNotice("Pasted " + text' "launcher pasted notice"
require_literal "$launcher_search_js" 'function stripCharacterTrigger(searchText, trigger)' "launcher search trigger stripper"
require_literal "$launcher_search_js" 'function rankCharacterItem(item, clean, cleanLower)' "launcher character ranking helper"
require_literal "$launcher_executor_js" 'actions.selectCharacter(item.name, actions.shouldPasteCharacter(actions.modifiers));' "launcher executor character action"
require_literal "$launcher_result_delegate_qml" 'if (root.mode === "emoji")' "launcher character provider badge"
require_literal "$launcher_settings_qml" 'label: "Character Trigger"' "launcher settings character trigger row"
require_literal "$launcher_settings_qml" 'configKey: "launcherCharacterPasteOnSelect"' "launcher settings paste toggle row"
require_literal "$launcher_helpers_js" 'Config.launcherCharacterTrigger = ":";' "launcher character trigger reset"
require_literal "$launcher_helpers_js" 'Config.launcherCharacterPasteOnSelect = false;' "launcher character paste reset"

if ! node - "$character_data_js" <<'NODE'
const fs = require("fs");
const path = process.argv[2];
const text = fs.readFileSync(path, "utf8");
const match = text.match(/var characterEntries = (\[[\s\S]*\]);/);
if (!match) {
  console.error("characterEntries payload missing");
  process.exit(1);
}
const entries = JSON.parse(match[1]);
const byCategory = entries.reduce((acc, entry) => {
  const key = String(entry.category || "");
  acc[key] = (acc[key] || 0) + 1;
  return acc;
}, {});
function assert(cond, message) {
  if (!cond) {
    console.error(message);
    process.exit(1);
  }
}
assert((byCategory.emoji || 0) >= 3000, "emoji catalog too small");
assert((byCategory.symbol || 0) >= 1500, "symbol catalog too small");
assert((byCategory.latin || 0) >= 200, "latin catalog too small");
assert(entries.some(entry => String(entry.name || "").startsWith("©") && String(entry.title).toLowerCase().includes("copyright")), "copyright symbol missing");
assert(entries.some(entry => entry.name === "ñ" && Array.isArray(entry.keywords) && entry.keywords.includes("spanish")), "spanish ñ keywords missing");
assert(entries.some(entry => /letter e with/i.test(String(entry.title || "")) && Array.isArray(entry.keywords) && entry.keywords.includes("french")), "french accented e keywords missing");
NODE
then
  violations+=("character catalog content validation failed")
fi

if (( ${#violations[@]} > 0 )); then
  printf '%s\n' "Launcher character check failed:" >&2
  printf '  - %s\n' "${violations[@]}" >&2
  exit 1
fi

printf '%s\n' "Launcher character check passed."

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

# Config: schema, normalization, autosave, persistence.
require_literal "$config_qml" 'property var launcherWebAliases: ({' "launcherWebAliases property"
require_literal "$config_qml" 'function _normalizeWebAliases(map, fallbackMap) {' "web alias normalization helper"
require_literal "$config_qml" 'if (!/^[a-z0-9][a-z0-9_-]{0,15}$/.test(normalized)) return;' "web alias token format validation"
require_literal "$config_qml" 'if (seen[normalized] || globalSeen[normalized]) return;' "web alias dedup validation"
require_literal "$config_qml" 'launcherWebAliases = _normalizeWebAliases(launcher.webAliases, {' "web alias config load"
require_literal "$config_qml" 'onLauncherWebAliasesChanged: scheduleSave()' "web alias autosave hook"
require_literal "$config_qml" '"webAliases": launcherWebAliases,' "web alias persistence"

# Launcher: alias-to-provider resolution and hint wiring.
require_literal "$launcher_qml" 'readonly property string webAliasHint: {' "web alias hint property"
require_literal "$launcher_qml" 'var aliases = (Config.launcherWebAliases && typeof Config.launcherWebAliases === "object") ? Config.launcherWebAliases : ({})' "web alias hint source map"
require_literal "$launcher_qml" 'function webAliasToProviderKey(token) {' "alias resolver function"
require_literal "$launcher_qml" 'if (webProviderCatalog[key])' "provider key direct mapping"
require_literal "$launcher_qml" 'var aliases = (Config.launcherWebAliases && typeof Config.launcherWebAliases === "object") ? Config.launcherWebAliases : ({})' "alias resolver source map"
require_literal "$launcher_qml" 'var mapped = webAliasToProviderKey(parts[0]);' "alias parsing in web query"
require_literal "$launcher_qml" 'text: launcherRoot.webPrimaryEnterHint + " • " + launcherRoot.webSecondaryEnterHint + " • " + launcherRoot.webAliasHint' "web alias hint shown in UI"

# Settings: editable alias tokens and reset/default behavior.
require_literal "$system_tab_qml" 'readonly property var webAliasDefaults: ({' "settings alias defaults"
require_literal "$system_tab_qml" 'function parseAliasTokens(text, providerKey) {' "alias token parser"
require_literal "$system_tab_qml" 'if (!/^[a-z0-9][a-z0-9_-]{0,15}$/.test(token))' "settings alias token validation"
require_literal "$system_tab_qml" 'Config.launcherWebAliases = next;' "settings alias update binding"
require_literal "$system_tab_qml" 'Config.launcherWebAliases = defaultWebAliasesCopy();' "settings alias reset binding"
require_literal "$system_tab_qml" 'text: "WEB ALIASES"' "settings alias section label"

if (( ${#violations[@]} > 0 )); then
  printf '%s\n' "Launcher web alias check failed:" >&2
  printf '  - %s\n' "${violations[@]}" >&2
  exit 1
fi

printf '%s\n' "Launcher web alias check passed."

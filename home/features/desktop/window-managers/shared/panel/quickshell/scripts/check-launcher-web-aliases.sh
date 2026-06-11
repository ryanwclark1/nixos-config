#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
config_dir="${QS_CONFIG_DIR:-${script_dir}/../src}"
launcher_qml="${config_dir}/launcher/Launcher.qml"
launcher_content_panel_qml="${config_dir}/launcher/LauncherContentPanel.qml"
config_qml="${config_dir}/services/Config.qml"
config_persistence_js="${config_dir}/services/config/ConfigPersistence.js"
launcher_domain_js="${config_dir}/services/config/domains/launcher.js"
mode_data_js="${config_dir}/launcher/LauncherModeData.js"
launcher_settings_qml="${config_dir}/features/settings/components/tabs/ShellLauncherSection.qml"
launcher_web_settings_qml="${config_dir}/features/settings/components/tabs/LauncherWebSection.qml"
launcher_helpers_js="${config_dir}/features/settings/components/tabs/ShellCoreHelpers.js"

violations=()
source "${script_dir}/check-helpers.sh"

# Config: schema and persistence.
require_literal "$config_qml" 'property var launcherWebAliases: ({' "launcherWebAliases property"
require_literal "$launcher_domain_js" '["webAliases", "launcherWebAliases"]' "web alias persistence"

# Launcher mode data owns alias resolution/parsing.
require_literal "$mode_data_js" 'function webAliasToProviderKey(token, providers, aliases, customEngines) {' "web alias normalization helper"
require_literal "$mode_data_js" 'if (catalog[key])' "provider key direct mapping"
require_literal "$mode_data_js" 'function parseWebQuery(text, providers, aliases, customEngines) {' "alias parsing in web query"
require_literal "$mode_data_js" 'var mapped = webAliasToProviderKey(parts[0], providers, aliases, customEngines);' "alias parsing mapped provider"

# Launcher: alias-to-provider resolution and hint wiring.
require_literal "$launcher_qml" 'readonly property string webAliasHint: TextHelpers.webAliasHint(' "web alias hint property"
require_literal "$launcher_qml" 'var aliases = (Config.launcherWebAliases && typeof Config.launcherWebAliases === "object") ? Config.launcherWebAliases : ({})' "web alias hint source map"
require_literal "$launcher_qml" 'function webAliasToProviderKey(token) {' "alias resolver function"
require_literal "$launcher_qml" 'function parseWebQuery(text) {' "parseWebQuery function"
require_literal "$launcher_content_panel_qml" 'aliasHint: launcher.webAliasHint' "web alias hint shown in UI"

# Settings: editable alias tokens and reset/default behavior.
require_literal "$launcher_settings_qml" 'readonly property var webAliasDefaults: ({' "settings alias defaults" "$launcher_web_settings_qml"
require_literal "$launcher_helpers_js" 'function parseAliasTokens(text, providerKey) {' "alias token parser"
require_literal "$launcher_helpers_js" 'if (!/^[a-z0-9][a-z0-9_-]{0,15}$/.test(token))' "settings alias token validation"
require_literal "$launcher_helpers_js" 'Config.launcherWebAliases = next;' "settings alias update binding"
require_literal "$launcher_helpers_js" 'Config.launcherWebAliases = defaultWebAliasesCopy(webAliasDefaults);' "settings alias reset binding"
require_literal "$launcher_settings_qml" 'title: "Web Aliases"' "settings alias section label" "$launcher_web_settings_qml"

report_violations "Launcher web alias check"

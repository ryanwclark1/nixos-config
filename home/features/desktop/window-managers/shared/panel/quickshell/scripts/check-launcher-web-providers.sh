#!/usr/bin/env bash
set -euo pipefail

# Contract test: verifies structural invariants for the expanded web provider
# system (26 built-in providers, custom engines, DDG !bangs).

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
config_dir="${QS_CONFIG_DIR:-${script_dir}/../src}"
mode_data_js="${config_dir}/launcher/LauncherModeData.js"
web_providers_js="${config_dir}/launcher/LauncherWebProviders.js"
config_launcher_js="${config_dir}/services/config/ConfigLauncher.js"
config_persistence_js="${config_dir}/services/config/ConfigPersistence.js"
launcher_domain_js="${config_dir}/services/config/domains/launcher.js"
config_qml="${config_dir}/services/Config.qml"
launcher_qml="${config_dir}/launcher/Launcher.qml"
launcher_settings_qml="${config_dir}/features/settings/components/tabs/ShellLauncherSection.qml"
launcher_web_settings_qml="${config_dir}/features/settings/components/tabs/LauncherWebSection.qml"
launcher_helpers_js="${config_dir}/features/settings/components/tabs/ShellCoreHelpers.js"
default_nix="${script_dir}/../default.nix"

violations=()
source "${script_dir}/check-helpers.sh"

# ── Phase 1: Expanded catalog (26 built-in providers) ──────────────────

# Spot-check a sample of new providers in the catalog
require_literal "$mode_data_js" '"brave":' "brave provider in catalog"
require_literal "$mode_data_js" '"stackoverflow":' "stackoverflow provider in catalog"
require_literal "$mode_data_js" '"wikipedia":' "wikipedia provider in catalog"
require_literal "$mode_data_js" '"archwiki":' "archwiki provider in catalog"
require_literal "$mode_data_js" '"nixopts":' "nixopts provider in catalog"
require_literal "$mode_data_js" '"maps":' "maps provider in catalog"
require_literal "$mode_data_js" '"images":' "images provider in catalog"

# ConfigLauncher.js must have _builtInWebKeys that match catalog
require_literal "$config_launcher_js" 'var _builtInWebKeys = [' "built-in web keys array"
require_literal "$config_launcher_js" '"brave"' "brave in built-in keys"
require_literal "$config_launcher_js" '"stackoverflow"' "stackoverflow in built-in keys"
require_literal "$config_launcher_js" '"images"' "images in built-in keys"
require_literal "$config_launcher_js" 'function _buildCatalogKeys(customEngines) {' "catalog keys builder"

# normalizeWebProviderOrder and normalizeWebAliases accept catalogKeys
require_literal "$config_launcher_js" 'function normalizeWebProviderOrder(list, fallbackList, catalogKeys) {' "normalizeWebProviderOrder signature"
require_literal "$config_launcher_js" 'function normalizeWebAliases(map, fallbackMap, catalogKeys) {' "normalizeWebAliases signature"

# Config.qml expanded default aliases
require_literal "$config_qml" '"stackoverflow": ["so", "stack"]' "stackoverflow default aliases"
require_literal "$config_qml" '"wikipedia": ["w", "wiki"]' "wikipedia default aliases"
require_literal "$config_qml" '"maps": ["map"]' "maps default alias"

# Settings UI has all new providers
require_literal "$launcher_settings_qml" '{ key: "brave"' "brave in settings UI" "$launcher_web_settings_qml"
require_literal "$launcher_settings_qml" '{ key: "stackoverflow"' "stackoverflow in settings UI" "$launcher_web_settings_qml"
require_literal "$launcher_settings_qml" '{ key: "wikipedia"' "wikipedia in settings UI" "$launcher_web_settings_qml"

# ── Phase 2: Custom user-defined search engines ────────────────────────

# Config property
require_literal "$config_qml" 'property var launcherWebCustomEngines: []' "custom engines config property"

# Persistence
require_literal "$launcher_domain_js" '["webCustomEngines", "launcherWebCustomEngines"]' "custom engines persistence"

# Validation
require_literal "$config_launcher_js" 'function normalizeCustomEngines(list) {' "custom engines normalizer"

# Catalog merge function
require_literal "$mode_data_js" 'function mergedProviderCatalog(customEngines) {' "merged catalog function"
require_literal "$mode_data_js" 'function webProviderKeys() {' "webProviderKeys function"

# configuredWebProviders accepts customEngines
require_literal "$mode_data_js" 'function configuredWebProviders(orderArray, customEngines) {' "configuredWebProviders signature"

# Launcher passes custom engines through
require_literal "$launcher_qml" 'ModeData.configuredWebProviders(Config.launcherWebProviderOrder, Config.launcherWebCustomEngines)' "custom engines passed to configuredWebProviders"
require_literal "$launcher_qml" 'Config.launcherWebCustomEngines)' "custom engines wired in Launcher"

# %s placeholder support in buildWebTarget
require_literal "$web_providers_js" 'exec.indexOf("%s")' "percent-s detection in buildWebTarget"
require_literal "$web_providers_js" 'exec.replace(/%s/g, encodeURIComponent(query))' "percent-s replacement"

# Settings UI: custom engine editor
require_literal "$launcher_settings_qml" 'title: "Custom Search Engines"' "custom engine settings card" "$launcher_web_settings_qml"
require_literal "$launcher_settings_qml" 'label: "Add Custom Engine"' "add custom engine button" "$launcher_web_settings_qml"

# Reset includes custom engines
require_literal "$launcher_helpers_js" 'Config.launcherWebCustomEngines = [];' "custom engines reset"

# ── Phase 3: DuckDuckGo !Bangs ────────────────────────────────────────

# Config properties
require_literal "$config_qml" 'property bool launcherWebBangsEnabled: false' "bangs enabled config"
require_literal "$config_qml" 'property string launcherWebBangsLastSync: ""' "bangs last sync config"

# Persistence
require_literal "$launcher_domain_js" '["webBangsEnabled", "launcherWebBangsEnabled"]' "bangs enabled persistence"
require_literal "$launcher_domain_js" '["webBangsLastSync", "launcherWebBangsLastSync"]' "bangs last sync persistence"

# Bang Process in Launcher
require_literal "$launcher_qml" 'property Process bangSearchProc: Process {' "bang search process"
require_literal "$launcher_qml" 'function executeBangSearch(bangUrlTemplate, query) {' "bang execution function"
require_literal "$launcher_qml" 'Config.launcherWebBangsEnabled' "bang detection guard"

# Shell scripts
require_literal "$default_nix" 'bangSyncScript' "bang sync script in default.nix"
require_literal "$default_nix" 'bangSearchScript' "bang search script in default.nix"
require_literal "$default_nix" '"qs-bang-sync"' "qs-bang-sync wrapper"
require_literal "$default_nix" '"qs-bang-search"' "qs-bang-search wrapper"

# Settings UI
require_literal "$launcher_settings_qml" 'title: "DuckDuckGo Bangs"' "bangs settings card" "$launcher_web_settings_qml"
require_literal "$launcher_settings_qml" '"qs-bang-sync"' "sync invocation in settings" "$launcher_web_settings_qml"

# Reset
require_literal "$launcher_helpers_js" 'Config.launcherWebBangsEnabled = false;' "bangs enabled reset"
require_literal "$launcher_helpers_js" 'Config.launcherWebBangsLastSync = "";' "bangs last sync reset"

# ── Report ─────────────────────────────────────────────────────────────

report_violations "Web provider expansion check (Phase 1+2+3)"

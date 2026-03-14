#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
plugin_dir="${script_dir}/../config/plugins/ssh-monitor"
manifest="${plugin_dir}/manifest.json"
bar_widget="${plugin_dir}/BarWidget.qml"
launcher_provider="${plugin_dir}/LauncherProvider.qml"
settings_view="${plugin_dir}/Settings.qml"
plugin_data="${plugin_dir}/SshPluginData.qml"
parser_js="${plugin_dir}/SshConfigParser.js"

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

require_pattern() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if rg -q "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label"
  fi
}

if ! command -v jq >/dev/null 2>&1; then
  echo '[FAIL] jq is required for ssh plugin contract checks' >&2
  exit 1
fi

for required in "$manifest" "$bar_widget" "$launcher_provider" "$settings_view" "$plugin_data" "$parser_js"; do
  if [[ ! -f "$required" ]]; then
    echo "[FAIL] Missing ssh plugin file: ${required}" >&2
    exit 1
  fi
done

if jq -e '
  .id == "quickshell.ssh.monitor"
  and .type == "multi"
  and .launcher.trigger == "!ssh"
  and .launcher.noTrigger == true
  and (.permissions | sort == ["process","settings_read","settings_write","state_read","state_write"])
  and .entryPoints.barWidget == "BarWidget.qml"
  and .entryPoints.launcherProvider == "LauncherProvider.qml"
  and .entryPoints.settings == "Settings.qml"
' "$manifest" >/dev/null 2>&1; then
  pass "ssh plugin manifest matches the shipped first-party contract"
else
  fail "ssh plugin manifest drifted from the shipped first-party contract"
fi

require_pattern "$bar_widget" 'openLauncher\(' "ssh bar widget opens launcher plugin mode"
require_pattern "$bar_widget" 'summaryLabel\(' "ssh bar widget renders shared plugin summary data"
require_pattern "$launcher_provider" 'launcherItems\(' "ssh launcher provider delegates item building to shared plugin data"
require_pattern "$launcher_provider" 'executeLauncherItem\(' "ssh launcher provider delegates execution to shared plugin data"
require_pattern "$settings_view" 'saveManualHosts\(' "ssh settings view persists manual hosts"
require_pattern "$settings_view" 'setImportEnabled\(' "ssh settings view toggles ssh-config import"
require_pattern "$settings_view" 'resetStateOnly\(' "ssh settings view exposes state reset"
require_pattern "$settings_view" 'resetAll\(' "ssh settings view exposes full reset"
require_pattern "$plugin_data" 'kitty", "-e", "bash", "-lc"' "ssh plugin launches interactive sessions in kitty"
require_pattern "$plugin_data" 'quickshell", "ipc", "call", "Launcher", "openPlugins"' "ssh plugin opens launcher via existing ipc contract"
require_pattern "$plugin_data" 'manualById\[imported.id\]' "ssh plugin gives manual entries precedence over imported aliases"
require_pattern "$plugin_data" 'wl-copy' "ssh plugin exposes copy-to-clipboard action"
require_pattern "$parser_js" 'parseFile' "ssh parser exports parseFile"
require_pattern "$parser_js" 'includes:' "ssh parser keeps include handling in the parser contract"

printf '[INFO] Plugin ssh contract summary: %d pass, %d fail\n' "$pass_count" "$fail_count"
(( fail_count == 0 ))

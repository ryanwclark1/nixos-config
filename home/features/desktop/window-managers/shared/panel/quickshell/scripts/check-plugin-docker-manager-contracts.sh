#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
plugin_dir="${script_dir}/../examples/plugins/docker-manager"
manifest="${plugin_dir}/manifest.json"
daemon_qml="${plugin_dir}/Daemon.qml"
bar_widget_qml="${plugin_dir}/BarWidget.qml"
settings_qml="${plugin_dir}/Settings.qml"
readme="${plugin_dir}/README.md"

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
  echo '[FAIL] jq is required for docker-manager plugin contract checks' >&2
  exit 1
fi

for required in "$manifest" "$daemon_qml" "$bar_widget_qml" "$settings_qml" "$readme"; do
  if [[ ! -f "$required" ]]; then
    echo "[FAIL] Missing docker-manager plugin file: ${required}" >&2
    exit 1
  fi
done

if jq -e '
  .id == "docker.manager"
  and .type == "multi"
  and (.permissions | sort == ["process","settings_read","settings_write"])
  and .entryPoints.barWidget == "BarWidget.qml"
  and .entryPoints.daemon == "Daemon.qml"
  and .entryPoints.settings == "Settings.qml"
' "$manifest" >/dev/null 2>&1; then
  pass "docker-manager manifest matches the expected multi-plugin contract"
else
  fail "docker-manager manifest drifted from the expected multi-plugin contract"
fi

require_pattern "$daemon_qml" 'function start\(' "docker-manager daemon exposes start()"
require_pattern "$daemon_qml" 'function stop\(' "docker-manager daemon exposes stop()"
require_pattern "$daemon_qml" 'function reloadFromSettings\(' "docker-manager daemon reloads settings"
require_pattern "$daemon_qml" '"events", "--format", "json"' "docker-manager daemon uses an events listener"
require_pattern "$daemon_qml" 'container inspect' "docker-manager daemon inspects containers"
require_pattern "$daemon_qml" 'com\.docker\.compose\.project' "docker-manager daemon reads Docker compose labels"
require_pattern "$daemon_qml" 'io\.podman\.compose\.project' "docker-manager daemon reads Podman compose labels"
require_pattern "$daemon_qml" 'function executeContainerAction\(' "docker-manager daemon exposes container actions"
require_pattern "$daemon_qml" 'function executeComposeAction\(' "docker-manager daemon exposes compose actions"
require_pattern "$daemon_qml" 'function openLogs\(' "docker-manager daemon exposes log terminal action"
require_pattern "$daemon_qml" 'function openShell\(' "docker-manager daemon exposes shell terminal action"

require_pattern "$bar_widget_qml" 'PopupWindow' "docker-manager bar widget uses a popup surface"
require_pattern "$bar_widget_qml" 'anchor\.item' "docker-manager popup anchors to the bar widget"
require_pattern "$bar_widget_qml" 'groupByCompose' "docker-manager widget persists compose-view preference"
require_pattern "$bar_widget_qml" 'showPorts' "docker-manager widget persists port-visibility preference"
require_pattern "$bar_widget_qml" 'executeComposeAction' "docker-manager widget exposes compose project actions"
require_pattern "$bar_widget_qml" 'executeContainerAction' "docker-manager widget exposes container actions"

require_pattern "$settings_qml" 'dockerBinary' "docker-manager settings expose runtime binary"
require_pattern "$settings_qml" 'debounceDelay' "docker-manager settings expose debounce delay"
require_pattern "$settings_qml" 'fallbackRefreshInterval' "docker-manager settings expose fallback refresh interval"
require_pattern "$settings_qml" 'terminalCommand' "docker-manager settings expose terminal command"
require_pattern "$settings_qml" 'shellPath' "docker-manager settings expose shell path"
require_pattern "$settings_qml" 'showPorts' "docker-manager settings expose port visibility"
require_pattern "$settings_qml" 'autoScrollOnExpand' "docker-manager settings expose auto-scroll preference"
require_pattern "$settings_qml" 'groupByCompose' "docker-manager settings expose default compose view"

require_pattern "$readme" 'Docker or Podman' "docker-manager README documents runtime support"
require_pattern "$readme" '~/.config/quickshell/plugins/docker-manager' "docker-manager README documents install location"

printf '[INFO] Docker-manager plugin contract summary: %d pass, %d fail\n' "$pass_count" "$fail_count"
(( fail_count == 0 ))

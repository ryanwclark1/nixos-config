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

utils_js="${plugin_dir}/DockerUtils.js"

for required in "$manifest" "$daemon_qml" "$bar_widget_qml" "$settings_qml" "$readme" "$utils_js"; do
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
require_pattern "$daemon_qml" 'property var images:' "docker-manager daemon tracks images"
require_pattern "$daemon_qml" 'property var volumes:' "docker-manager daemon tracks volumes"
require_pattern "$daemon_qml" 'property var networks:' "docker-manager daemon tracks networks"
require_pattern "$daemon_qml" 'function removeImage\(' "docker-manager daemon exposes image removal"
require_pattern "$daemon_qml" 'function removeVolume\(' "docker-manager daemon exposes volume removal"
require_pattern "$daemon_qml" 'function removeNetwork\(' "docker-manager daemon exposes network removal"
require_pattern "$daemon_qml" 'function pruneImages\(' "docker-manager daemon exposes image prune"
require_pattern "$daemon_qml" 'function pruneVolumes\(' "docker-manager daemon exposes volume prune"
require_pattern "$daemon_qml" 'function systemPrune\(' "docker-manager daemon exposes system prune"
require_pattern "$daemon_qml" 'function runImage\(' "docker-manager daemon exposes run container from image"
require_pattern "$daemon_qml" 'healthStatus' "docker-manager daemon normalizes health status"
require_pattern "$daemon_qml" 'image ls' "docker-manager daemon lists images"
require_pattern "$daemon_qml" 'volume ls' "docker-manager daemon lists volumes"
require_pattern "$daemon_qml" 'network ls' "docker-manager daemon lists networks"

require_pattern "$bar_widget_qml" 'PopupWindow' "docker-manager bar widget uses a popup surface"
require_pattern "$bar_widget_qml" 'anchor\.item' "docker-manager popup anchors to the bar widget"
require_pattern "$bar_widget_qml" 'groupByCompose' "docker-manager widget persists compose-view preference"
require_pattern "$bar_widget_qml" 'showPorts' "docker-manager widget persists port-visibility preference"
require_pattern "$bar_widget_qml" 'executeComposeAction' "docker-manager widget exposes compose project actions"
require_pattern "$bar_widget_qml" 'executeContainerAction' "docker-manager widget exposes container actions"
require_pattern "$bar_widget_qml" 'currentTab' "docker-manager widget uses tab-based navigation"

require_pattern "$settings_qml" 'dockerBinary' "docker-manager settings expose runtime binary"
require_pattern "$settings_qml" 'debounceDelay' "docker-manager settings expose debounce delay"
require_pattern "$settings_qml" 'fallbackRefreshInterval' "docker-manager settings expose fallback refresh interval"
require_pattern "$settings_qml" 'terminalCommand' "docker-manager settings expose terminal command"
require_pattern "$settings_qml" 'shellPath' "docker-manager settings expose shell path"
require_pattern "$settings_qml" 'showPorts' "docker-manager settings expose port visibility"
require_pattern "$settings_qml" 'autoScrollOnExpand' "docker-manager settings expose auto-scroll preference"
require_pattern "$settings_qml" 'groupByCompose' "docker-manager settings expose default compose view"
require_pattern "$settings_qml" 'showImages' "docker-manager settings expose images tab visibility"
require_pattern "$settings_qml" 'showVolumes' "docker-manager settings expose volumes tab visibility"
require_pattern "$settings_qml" 'showNetworks' "docker-manager settings expose networks tab visibility"
require_pattern "$settings_qml" 'confirmPrune' "docker-manager settings expose prune confirmation"

require_pattern "$utils_js" 'function guessDefaultPort' "docker-manager utils expose port heuristics"
require_pattern "$utils_js" 'function normalizeImage' "docker-manager utils expose image normalization"

require_pattern "$readme" 'Docker or Podman' "docker-manager README documents runtime support"
require_pattern "$readme" '~/.config/quickshell/plugins/docker-manager' "docker-manager README documents install location"
require_pattern "$readme" 'jq' "docker-manager README documents jq dependency"

printf '[INFO] Docker-manager plugin contract summary: %d pass, %d fail\n' "$pass_count" "$fail_count"
(( fail_count == 0 ))

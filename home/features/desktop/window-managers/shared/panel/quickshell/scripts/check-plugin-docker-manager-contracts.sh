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
require_pattern "$daemon_qml" 'property.*images:' "docker-manager daemon tracks images"
require_pattern "$daemon_qml" 'property.*volumes:' "docker-manager daemon tracks volumes"
require_pattern "$daemon_qml" 'property.*networks:' "docker-manager daemon tracks networks"
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

# Round 2 daemon assertions
require_pattern "$daemon_qml" 'property var containerStats' "docker-manager daemon tracks container stats"
require_pattern "$daemon_qml" 'stats --no-stream' "docker-manager daemon uses stats command"
require_pattern "$daemon_qml" 'property bool pullInProgress' "docker-manager daemon tracks pull progress"
require_pattern "$daemon_qml" 'function fetchLogs\(' "docker-manager daemon exposes log preview"
require_pattern "$daemon_qml" 'property var volumeUsageMap' "docker-manager daemon tracks volume cross-references"
require_pattern "$daemon_qml" 'property var networkUsageMap' "docker-manager daemon tracks network cross-references"
require_pattern "$daemon_qml" 'function _containerRefreshCommand\(' "docker-manager daemon splits container refresh"
require_pattern "$daemon_qml" 'function _resourceRefreshCommand\(' "docker-manager daemon splits resource refresh"
require_pattern "$daemon_qml" 'ScriptModel' "docker-manager daemon uses ScriptModel for efficient updates"
require_pattern "$daemon_qml" 'type=image' "docker-manager daemon supports Podman image event types"
require_pattern "$daemon_qml" 'signal toastRequested' "docker-manager daemon provides toast notification bridge"
require_pattern "$daemon_qml" 'function _normalizeEnv\(' "docker-manager daemon normalizes container environment variables"
require_pattern "$daemon_qml" '_actionQueue' "docker-manager daemon queues bulk actions sequentially"
require_pattern "$daemon_qml" 'function _drainActionQueue\(' "docker-manager daemon drains action queue on completion"
require_pattern "$daemon_qml" 'function removeContainer\(' "docker-manager daemon exposes container removal"

require_pattern "$bar_widget_qml" 'PopupWindow' "docker-manager bar widget uses a popup surface"
require_pattern "$bar_widget_qml" 'anchor\.item' "docker-manager popup anchors to the bar widget"
require_pattern "$bar_widget_qml" 'groupByCompose' "docker-manager widget persists compose-view preference"
require_pattern "$bar_widget_qml" 'showPorts' "docker-manager widget persists port-visibility preference"
require_pattern "$bar_widget_qml" 'executeComposeAction' "docker-manager widget exposes compose project actions"
require_pattern "$bar_widget_qml" 'executeContainerAction' "docker-manager widget exposes container actions"
require_pattern "$bar_widget_qml" 'currentTab' "docker-manager widget uses tab-based navigation"

# Round 2 bar widget assertions
require_pattern "$bar_widget_qml" 'selectionMode' "docker-manager widget supports bulk selection mode"
require_pattern "$bar_widget_qml" 'searchQuery' "docker-manager widget supports search filtering"
require_pattern "$bar_widget_qml" 'focusedCardIndex' "docker-manager widget supports keyboard navigation"
require_pattern "$bar_widget_qml" 'searchDebounceTimer' "docker-manager widget debounces search input"
require_pattern "$bar_widget_qml" '_filteredContainers' "docker-manager widget caches filtered container list"
container_card_qml="${plugin_dir}/ContainerCard.qml"
image_card_qml="${plugin_dir}/ImageCard.qml"
volume_card_qml="${plugin_dir}/VolumeCard.qml"
network_card_qml="${plugin_dir}/NetworkCard.qml"
run_dialog_qml="${plugin_dir}/RunImageDialog.qml"
bulk_bar_qml="${plugin_dir}/BulkActionBar.qml"

for component in "$container_card_qml" "$image_card_qml" "$volume_card_qml" "$network_card_qml" "$run_dialog_qml" "$bulk_bar_qml"; do
  if [[ -f "$component" ]]; then
    pass "docker-manager extracted component exists: $(basename "$component")"
  else
    fail "docker-manager extracted component missing: $(basename "$component")"
  fi
done

require_pattern "$container_card_qml" 'removeContainer' "docker-manager container card exposes container removal action"
require_pattern "$container_card_qml" 'modelData\.env' "docker-manager container card displays environment variables"
require_pattern "$container_card_qml" 'DU\.healthDot' "docker-manager container card uses shared health dot utility"
require_pattern "$container_card_qml" 'Refresh' "docker-manager container card has log refresh button"

require_pattern "$daemon_qml" 'action === .edit.' "docker-manager daemon supports compose edit action"

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

# Round 2 settings assertions
require_pattern "$settings_qml" 'statsInterval' "docker-manager settings expose stats interval"
require_pattern "$settings_qml" 'logPreviewLines' "docker-manager settings expose log preview lines"
require_pattern "$settings_qml" 'resourceRefreshInterval' "docker-manager settings expose resource refresh interval"
require_pattern "$settings_qml" 'toastEnabled' "docker-manager settings expose toast notifications toggle"

require_pattern "$utils_js" 'function guessDefaultPort' "docker-manager utils expose port heuristics"
require_pattern "$utils_js" 'function normalizeImage' "docker-manager utils expose image normalization"
require_pattern "$utils_js" 'function matchesFilter' "docker-manager utils expose search filter function"
require_pattern "$utils_js" 'function healthDot' "docker-manager utils expose shared health dot function"
require_pattern "$utils_js" 'function healthDotColor' "docker-manager utils expose shared health dot color function"

require_pattern "$readme" 'Docker or Podman' "docker-manager README documents runtime support"
require_pattern "$readme" '~/.config/quickshell/plugins/docker-manager' "docker-manager README documents install location"
require_pattern "$readme" 'jq' "docker-manager README documents jq dependency"

printf '[INFO] Docker-manager plugin contract summary: %d pass, %d fail\n' "$pass_count" "$fail_count"
(( fail_count == 0 ))

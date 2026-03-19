#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
plugin_dir="${script_dir}/../examples/plugins/docker-manager"

pass_count=0
fail_count=0
auto_cleanup=()

pass() {
  printf '[PASS] %s\n' "$1"
  pass_count=$((pass_count + 1))
}

fail() {
  printf '[FAIL] %s\n' "$1" >&2
  fail_count=$((fail_count + 1))
}

cleanup() {
  local path
  for path in "${auto_cleanup[@]}"; do
    [[ -n "${path}" && -e "${path}" ]] && rm -rf -- "${path}"
  done
  return 0
}
trap cleanup EXIT

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$1" >&2
    exit 2
  fi
}

make_temp_runtime() {
  local runtime_dir
  runtime_dir="$(mktemp -d)"
  auto_cleanup+=("${runtime_dir}")
  mkdir -p "${runtime_dir}/quickshell"
  chmod 700 "${runtime_dir}"
  printf '%s\n' "${runtime_dir}"
}

run_harness() {
  local runtime_dir qml_path log_file

  runtime_dir="$(make_temp_runtime)"
  qml_path="$(mktemp /tmp/plugin-docker-runtime-smoke-XXXXXX.qml)"
  log_file="$(mktemp /tmp/plugin-docker-runtime-smoke-log-XXXXXX.txt)"
  auto_cleanup+=("${qml_path}" "${log_file}")

  cat > "${qml_path}" <<QML
import Quickshell
import QtQuick

Scope {
  id: root

  property bool reported: false
  property int phase: 0
  property var healthySnapshot: ({})
  property var daemon: null
  readonly property string pluginDir: "${plugin_dir}"

  QtObject {
    id: pluginApi

    property var settingsStore: ({
      dockerBinary: "docker",
      debounceDelay: 100,
      fallbackRefreshInterval: 60000,
      terminalCommand: "kitty -e bash -lc",
      shellPath: "/bin/sh",
      showPorts: true,
      autoScrollOnExpand: true,
      groupByCompose: false
    })

    function loadSetting(key, fallbackValue) {
      return Object.prototype.hasOwnProperty.call(settingsStore, key) ? settingsStore[key] : fallbackValue;
    }

    function saveSetting(key, value) {
      settingsStore[key] = value;
    }
  }

  QtObject {
    id: pluginService
    property var daemonInstances: ({})
    property var statuses: ({})
    signal pluginRuntimeUpdated()

    function _setPluginStatus(pluginId, state, code, message) {
      var next = Object.assign({}, statuses);
      next[pluginId] = {
        state: state,
        code: code,
        message: message
      };
      statuses = next;
      pluginRuntimeUpdated();
    }
  }

  function instantiate(relPath, parentObject) {
    var component = Qt.createComponent("file://" + pluginDir + "/" + relPath);
    if (component.status !== Component.Ready) {
      console.log("COMPONENT_ERROR:" + relPath + ":" + component.errorString());
      Qt.quit();
      return null;
    }
    var instance = component.createObject(parentObject || root, {
      pluginApi: pluginApi,
      pluginManifest: ({ id: "docker.manager", name: "Docker Manager" }),
      pluginService: pluginService
    });
    if (!instance) {
      console.log("INSTANCE_ERROR:" + relPath + ":" + component.errorString());
      Qt.quit();
      return null;
    }
    return instance;
  }

  function maybeReport() {
    if (reported || !daemon)
      return;

    var status = pluginService.statuses["docker.manager"] || {};

    if (phase === 0
        && daemon.runtimeAvailable
        && daemon.lastRefreshAt !== ""
        && status.state === "active"
        && String(daemon.statusMessage || "").indexOf("available") !== -1) {
      healthySnapshot = {
        runtimeAvailable: daemon.runtimeAvailable,
        runtimeName: daemon.runtimeName,
        statusMessage: daemon.statusMessage,
        containers: daemon.containers.length,
        runningContainers: daemon.runningContainers,
        composeProjects: daemon.composeProjects.length,
        images: daemon.images.length,
        volumes: daemon.volumes.length,
        networks: daemon.networks.length,
        pluginState: status.state || ""
      };
      phase = 1;
      pluginApi.saveSetting("groupByCompose", true);
      pluginApi.saveSetting("showPorts", false);
      pluginApi.saveSetting("dockerBinary", "definitely-missing-docker-runtime");
      daemon.reloadFromSettings();
      return;
    }

    if (phase === 1
        && !daemon.runtimeAvailable
        && status.state === "degraded"
        && (
          String(daemon.statusMessage || "").indexOf("Runtime binary not found") !== -1
          || String(daemon.statusMessage || "").indexOf("Runtime unavailable.") !== -1
        )) {
      reported = true;
      console.log("CONTRACT:" + JSON.stringify({
        healthy: healthySnapshot,
        degraded: {
          runtimeAvailable: daemon.runtimeAvailable,
          runtimeName: daemon.runtimeName,
          statusMessage: daemon.statusMessage,
          pluginState: status.state || "",
          pluginCode: status.code || "",
          savedBinary: pluginApi.settingsStore.dockerBinary,
          savedGroupByCompose: pluginApi.settingsStore.groupByCompose,
          savedShowPorts: pluginApi.settingsStore.showPorts
        }
      }));
      daemon.stop();
      Qt.quit();
    }
  }

  Component.onCompleted: {
    daemon = instantiate("Daemon.qml", root);
    pluginService.daemonInstances = ({ "docker.manager": daemon });
    daemon.start();
  }

  Connections {
    target: daemon
    function onLastRefreshAtChanged() { root.maybeReport(); }
    function onRuntimeAvailableChanged() { root.maybeReport(); }
    function onStatusMessageChanged() { root.maybeReport(); }
  }

  Connections {
    target: pluginService
    function onPluginRuntimeUpdated() { root.maybeReport(); }
  }

  Timer {
    interval: 12000
    running: true
    repeat: false
    onTriggered: {
      if (!root.reported) {
        console.log("CONTRACT_TIMEOUT:" + JSON.stringify({
          phase: root.phase,
          daemonReady: !!root.daemon,
          runtimeAvailable: root.daemon ? root.daemon.runtimeAvailable : false,
          lastRefreshAt: root.daemon ? root.daemon.lastRefreshAt : "",
          statusMessage: root.daemon ? root.daemon.statusMessage : "",
          pluginState: pluginService.statuses["docker.manager"] ? pluginService.statuses["docker.manager"].state : ""
        }));
        if (root.daemon)
          root.daemon.stop();
        Qt.quit();
      }
    }
  }
}
QML

  set +e
  timeout 16s env -u WAYLAND_DISPLAY -u DISPLAY XDG_RUNTIME_DIR="${runtime_dir}" QT_QPA_PLATFORM=offscreen \
    quickshell -p "${qml_path}" --no-duplicate > "${log_file}" 2>&1
  local exit_code=$?
  set -e

  if [[ ${exit_code} -ne 0 && ${exit_code} -ne 124 ]]; then
    sed -n '1,200p' "${log_file}" >&2
    return 1
  fi

  sed -n '1,200p' "${log_file}"
  return 0
}

main() {
  require_cmd quickshell
  require_cmd jq
  require_cmd sed
  require_cmd mktemp
  require_cmd timeout
  require_cmd docker

  if ! docker info >/dev/null 2>&1; then
    echo '[FAIL] docker info failed; docker-manager runtime smoke requires a reachable Docker daemon' >&2
    exit 1
  fi

  local expected_total expected_running harness_output contract_json
  expected_total="$(docker ps -aq | wc -l | tr -d ' ')"
  expected_running="$(docker ps -q | wc -l | tr -d ' ')"

  if ! harness_output="$(run_harness)"; then
    fail "docker-manager runtime smoke harness launches successfully"
  else
    pass "docker-manager runtime smoke harness launches successfully"
  fi

  contract_json="$(printf '%s\n' "${harness_output}" | sed -n 's/^.*CONTRACT://p' | tail -n 1)"
  if [[ -z "${contract_json}" ]]; then
    fail "docker-manager runtime smoke harness emits contract output"
    printf '%s\n' "${harness_output}" >&2
  elif printf '%s' "${contract_json}" | jq -e \
    --argjson expectedTotal "${expected_total}" \
    --argjson expectedRunning "${expected_running}" '
      .healthy.runtimeAvailable == true
      and .healthy.runtimeName == "Docker"
      and .healthy.pluginState == "active"
      and .healthy.containers == $expectedTotal
      and .healthy.runningContainers == $expectedRunning
      and (.healthy.statusMessage | contains("Docker is available"))
      and .healthy.images >= 0
      and .healthy.volumes >= 0
      and .healthy.networks >= 0
      and .degraded.runtimeAvailable == false
      and .degraded.pluginState == "degraded"
      and .degraded.pluginCode == "E_DOCKER_RUNTIME_UNAVAILABLE"
      and (
        (.degraded.statusMessage | contains("Runtime binary not found"))
        or (.degraded.statusMessage | contains("Runtime unavailable."))
      )
      and .degraded.savedBinary == "definitely-missing-docker-runtime"
      and .degraded.savedGroupByCompose == true
      and .degraded.savedShowPorts == false
    ' >/dev/null 2>&1; then
    pass "docker-manager runtime smoke covers healthy snapshot, settings reload, and degraded runtime handling"
  else
    fail "docker-manager runtime smoke contract output drifted from expectations"
    printf '%s\n' "${contract_json}" | jq . >&2 || printf '%s\n' "${contract_json}" >&2
  fi

  printf '[INFO] Plugin docker runtime smoke summary: %d pass, %d fail\n' "${pass_count}" "${fail_count}"
  (( fail_count == 0 ))
}

main "$@"

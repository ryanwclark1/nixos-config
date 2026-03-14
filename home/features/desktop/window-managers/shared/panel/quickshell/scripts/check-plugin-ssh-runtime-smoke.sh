#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
plugin_dir="${script_dir}/../config/plugins/ssh-monitor"
fixture_dir="${plugin_dir}/fixtures"

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

make_temp_home() {
  local home
  home="$(mktemp -d)"
  auto_cleanup+=("${home}")
  mkdir -p "${home}/.ssh/includes" "${home}/.config/quickshell" "${home}/.local/state/quickshell"
  printf '{"themes":[]}\n' > "${home}/.config/quickshell/themes.json"
  cp "${fixture_dir}/root.conf" "${home}/.ssh/config"
  cp "${fixture_dir}/includes/"*.conf "${home}/.ssh/includes/"
  printf '%s\n' "${home}"
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
  local home runtime_dir qml_path log_file

  home="$(make_temp_home)"
  runtime_dir="$(make_temp_runtime)"
  qml_path="$(mktemp /tmp/plugin-ssh-runtime-smoke-XXXXXX.qml)"
  log_file="$(mktemp /tmp/plugin-ssh-runtime-smoke-log-XXXXXX.txt)"
  auto_cleanup+=("${qml_path}" "${log_file}")

  cat > "${qml_path}" <<QML
import Quickshell
import QtQuick

Scope {
  id: root

  property bool reported: false
  property var provider: null
  property var data: null
  readonly property string pluginDir: "${plugin_dir}"

  QtObject {
    id: pluginApi

    property var settingsStore: ({
      manualHosts: [
        {
          id: "analytics",
          label: "Analytics Override",
          host: "analytics.internal",
          user: "ops",
          port: 2022,
          remoteCommand: "uptime",
          tags: ["manual"],
          group: "ops"
        }
      ],
      enableSshConfigImport: true,
      displayMode: "count",
      defaultAction: "connect"
    })
    property var stateEnvelopeStore: ({
      stateVersion: 1,
      updatedAt: "",
      payload: {
        lastConnectedId: "",
        lastConnectedLabel: "",
        lastConnectedAt: "",
        recentIds: [],
        lastImportSummary: {
          imported: 0,
          skippedPatterns: 0,
          errors: 0
        }
      }
    })
    property var processCalls: []

    function loadSetting(key, fallbackValue) {
      return Object.prototype.hasOwnProperty.call(settingsStore, key) ? settingsStore[key] : fallbackValue;
    }

    function saveSetting(key, value) {
      settingsStore[key] = value;
    }

    function loadStateEnvelope() {
      return stateEnvelopeStore;
    }

    function saveStateEnvelope(value) {
      stateEnvelopeStore = value;
    }

    function runProcess(command) {
      processCalls.push(command);
      return true;
    }
  }

  QtObject {
    id: pluginService
    signal pluginRuntimeUpdated()
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
      pluginManifest: ({ name: "SSH Monitor" }),
      pluginService: pluginService
    });
    if (!instance) {
      console.log("INSTANCE_ERROR:" + relPath + ":" + component.errorString());
      Qt.quit();
      return null;
    }
    return instance;
  }

  function report() {
    if (reported || !data || !provider || !provider.pluginData)
      return;
    if (!data.importReady || !provider.pluginData.importReady)
      return;

    reported = true;

    data.saveManualHosts((pluginApi.settingsStore.manualHosts || []).concat([{
      id: "new-host",
      label: "New Host",
      host: "new.example.com",
      user: "deploy",
      port: 2201,
      remoteCommand: "",
      tags: [],
      group: ""
    }]));

    const analyticsItems = provider.items("analytics", {});
    const teamItems = provider.items("team-jump", {});

    if (analyticsItems.length > 0)
      provider.execute(analyticsItems[0], {});
    if (teamItems.length > 0)
      provider.execute(teamItems[0], {});
    if (teamItems.length > 1)
      provider.execute(teamItems[1], {});

    console.log("CONTRACT:" + JSON.stringify({
      importedCount: data.importedHosts.length,
      skippedCount: data.skippedPatternEntries.length,
      mergedCount: data.mergedHosts.length,
      providerMergedCount: provider.pluginData.mergedHosts.length,
      analyticsDescription: analyticsItems.length > 0 ? analyticsItems[0].description : "",
      teamDescription: teamItems.length > 0 ? teamItems[0].description : "",
      savedManualHosts: pluginApi.settingsStore.manualHosts.length,
      stateRecentIds: pluginApi.stateEnvelopeStore.payload.recentIds,
      processCalls: pluginApi.processCalls
    }));
    Qt.quit();
  }

  Component.onCompleted: {
    data = instantiate("SshPluginData.qml", root);
    provider = instantiate("LauncherProvider.qml", root);
    Qt.callLater(report);
  }

  Connections {
    target: data
    function onRefreshed() { root.report(); }
  }

  Connections {
    target: provider && provider.pluginData ? provider.pluginData : null
    function onRefreshed() { root.report(); }
  }

  Timer {
    interval: 4000
    running: true
    repeat: false
    onTriggered: {
      if (!root.reported) {
        console.log("CONTRACT_TIMEOUT:" + JSON.stringify({
          importReady: data ? data.importReady : false,
          providerImportReady: provider && provider.pluginData ? provider.pluginData.importReady : false,
          importedCount: data ? data.importedHosts.length : -1,
          providerMergedCount: provider && provider.pluginData ? provider.pluginData.mergedHosts.length : -1,
          errors: data ? data.importErrors : []
        }));
        Qt.quit();
      }
    }
  }
}
QML

  set +e
  timeout 8s env -u WAYLAND_DISPLAY -u DISPLAY HOME="${home}" XDG_RUNTIME_DIR="${runtime_dir}" QT_QPA_PLATFORM=offscreen \
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

  local harness_output contract_json
  if ! harness_output="$(run_harness)"; then
    fail "ssh runtime smoke harness launches successfully"
  else
    pass "ssh runtime smoke harness launches successfully"
  fi

  contract_json="$(printf '%s\n' "${harness_output}" | sed -n 's/^.*CONTRACT://p' | tail -n 1)"
  if [[ -z "${contract_json}" ]]; then
    fail "ssh runtime smoke harness emits contract output"
    printf '%s\n' "${harness_output}" >&2
  elif printf '%s' "${contract_json}" | jq -e '
      .importedCount == 4
      and .skippedCount == 1
      and .mergedCount == 5
      and (.providerMergedCount >= 4)
      and .analyticsDescription == "ops@analytics.internal"
      and (.teamDescription | contains("Alias from "))
      and .savedManualHosts == 2
      and .stateRecentIds == ["team-jump", "analytics"]
      and (.processCalls | length == 3)
      and .processCalls[0][0] == "kitty"
      and (.processCalls[0][4] | contains("ops@analytics.internal"))
      and .processCalls[1][0] == "kitty"
      and (.processCalls[1][4] | contains("team-jump"))
      and .processCalls[2][0] == "bash"
      and (.processCalls[2][2] | contains("wl-copy"))
    ' >/dev/null 2>&1; then
    pass "ssh runtime smoke covers import merge, manual host persistence, and launcher actions"
  else
    fail "ssh runtime smoke contract output drifted from expectations"
    printf '%s\n' "${contract_json}" | jq . >&2 || printf '%s\n' "${contract_json}" >&2
  fi

  printf '[INFO] Plugin ssh runtime smoke summary: %d pass, %d fail\n' "${pass_count}" "${fail_count}"
  (( fail_count == 0 ))
}

main "$@"

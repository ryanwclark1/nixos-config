pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

QtObject {
    id: root

    // ── Output (sink) state ──────────────────────
    property real outputVolume: 0
    property bool outputMuted: false
    readonly property string outputLabel: _sinkDescription()
    readonly property string outputDeviceType: _detectDeviceType()

    // ── Input (source) state ─────────────────────
    property real inputVolume: 0
    property bool inputMuted: false
    readonly property string inputLabel: _sourceDescription()

    // ── Device lists (reactive from PipeWire) ────
    readonly property var sinks: _buildDeviceList(true)
    readonly property var sources: _buildDeviceList(false)

    // ── Filtered device lists (pin/hide applied) ────
    readonly property var filteredSinks: _filterDevices(sinks, Config.audioPinnedOutputs, Config.audioHiddenOutputs)
    readonly property var filteredSources: _filterDevices(sources, Config.audioPinnedInputs, Config.audioHiddenInputs)
    readonly property int defaultSinkId: Pipewire.defaultAudioSink?.id ?? -1
    readonly property int defaultSourceId: Pipewire.defaultAudioSource?.id ?? -1

    // ── Per-app audio streams ────────────────────
    readonly property var outputAppNodes: _buildAppNodes(true)
    readonly property var inputAppNodes: _buildAppNodes(false)

    // ── Named constants ──────────────────────────
    readonly property int _volumePollMs: 1000
    readonly property int _postWriteDebounceMs: 120

    // ── Subscriber-based (kept for Ref.qml compat, now a no-op) ──
    property int subscriberCount: 0

    // ── PipeWire object tracking ─────────────────
    property PwObjectTracker _defaultTracker: PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    property PwObjectTracker _nodeTracker: PwObjectTracker {
        objects: _allAudioNodes()
    }

    property Process outputVolumeProc: Process {
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var result = root._parseWpctlVolume(this.text);
                if (!result) {
                    root.outputVolume = 0;
                    root.outputMuted = false;
                    return;
                }
                root.outputVolume = result.volume;
                root.outputMuted = result.muted;
            }
        }
    }

    property Process inputVolumeProc: Process {
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var result = root._parseWpctlVolume(this.text);
                if (!result) {
                    root.inputVolume = 0;
                    root.inputMuted = false;
                    return;
                }
                root.inputVolume = result.volume;
                root.inputMuted = result.muted;
            }
        }
    }

    property Timer volumeTimer: Timer {
        interval: root._volumePollMs
        running: root.subscriberCount > 0
        repeat: true
        onTriggered: root.refreshVolumes()
    }

    property Timer postWriteRefreshTimer: Timer {
        interval: root._postWriteDebounceMs
        repeat: false
        onTriggered: root.refreshVolumes()
    }

    // ── Helpers ──────────────────────────────────
    function _sinkDescription() {
        var sink = Pipewire.defaultAudioSink;
        if (!sink) return "No output device";
        return sink.description || sink.nickname || sink.name || "Unknown";
    }

    function _sourceDescription() {
        var source = Pipewire.defaultAudioSource;
        if (!source) return "No input device";
        return source.description || source.nickname || source.name || "Unknown";
    }

    function _detectDeviceType() {
        var sink = Pipewire.defaultAudioSink;
        if (!sink) return "speaker";
        var name = (sink.name || "").toLowerCase();
        var desc = (sink.description || "").toLowerCase();
        var combined = name + " " + desc;
        if (combined.indexOf("bluetooth") !== -1 || combined.indexOf("bluez") !== -1 || combined.indexOf("a2dp") !== -1)
            return "bluetooth";
        if (combined.indexOf("headphone") !== -1 || combined.indexOf("headset") !== -1)
            return "headphone";
        return "speaker";
    }

    function _allAudioNodes() {
        if (!Pipewire.ready) return [];
        var nodes = Pipewire.nodes?.values ?? [];
        var audio = [];
        for (var i = 0; i < nodes.length; i++) {
            if (nodes[i] && nodes[i].audio)
                audio.push(nodes[i]);
        }
        return audio;
    }

    function _deviceDisplayName(node) {
        return node.description || node.nickname || node.name || "Unknown";
    }

    function _parseWpctlVolume(text) {
        var trimmed = String(text || "").trim();
        var match = trimmed.match(/Volume:\s+([0-9.]+)(?:\s+\[MUTED\])?/);
        if (!match)
            return null;
        var parsed = parseFloat(match[1]);
        return {
            volume: isNaN(parsed) ? 0 : Colors.clamp01(parsed),
            muted: trimmed.indexOf("[MUTED]") !== -1
        };
    }

    function _deviceMatchKeys(node, displayName) {
        var keys = [];

        function addKey(value) {
            var key = String(value || "").trim().toLowerCase();
            if (!key || keys.indexOf(key) !== -1)
                return;
            keys.push(key);
        }

        addKey(displayName);
        addKey(node.description);
        addKey(node.nickname);
        addKey(node.name);
        addKey(node.properties ? node.properties["node.name"] : "");
        addKey(node.properties ? node.properties["object.path"] : "");
        return keys;
    }

    function _configuredSet(values) {
        var configured = {};
        for (var i = 0; i < (values || []).length; i++) {
            var key = String(values[i] || "").trim().toLowerCase();
            if (key)
                configured[key] = true;
        }
        return configured;
    }

    function _matchesConfiguredDevice(device, configured) {
        var keys = device.matchKeys || [];
        for (var i = 0; i < keys.length; i++) {
            if (configured[keys[i]])
                return true;
        }
        return false;
    }

    function _volumePercentText(value) {
        return Math.round(Colors.clamp01(value) * 100) + "%";
    }

    function _currentTargetVolume(target) {
        return target === "@DEFAULT_AUDIO_SINK@" ? root.outputVolume : root.inputVolume;
    }

    function _currentTargetMuted(target) {
        return target === "@DEFAULT_AUDIO_SINK@" ? root.outputMuted : root.inputMuted;
    }

    function _execWpctl(args) {
        Quickshell.execDetached(["wpctl"].concat(args));
    }

    function refreshVolumes() {
        if (!root.outputVolumeProc.running)
            root.outputVolumeProc.running = true;
        if (!root.inputVolumeProc.running)
            root.inputVolumeProc.running = true;
    }

    function _buildDeviceList(isSinkList) {
        if (!Pipewire.ready) return [];
        var nodes = Pipewire.nodes?.values ?? [];
        var devices = [];
        var defaultId = isSinkList ? (Pipewire.defaultAudioSink?.id ?? -1)
                                   : (Pipewire.defaultAudioSource?.id ?? -1);

        for (var i = 0; i < nodes.length; i++) {
            var node = nodes[i];
            if (!node || !node.audio || node.isStream) continue;
            if (isSinkList !== node.isSink) continue;

            var vol = node.audio.volume;
            var displayName = _deviceDisplayName(node);
            devices.push({
                id: node.id,
                name: displayName,
                key: String(node.name || (node.properties ? node.properties["node.name"] : "") || displayName),
                matchKeys: _deviceMatchKeys(node, displayName),
                volume: (vol !== undefined && !isNaN(vol)) ? vol : 0,
                muted: node.audio.muted || false,
                isDefault: node.id === defaultId
            });
        }
        return devices;
    }

    function _filterDevices(devices, pinned, hidden) {
        var hiddenSet = _configuredSet(hidden);
        var pinnedSet = _configuredSet(pinned);

        var visible = [];
        for (var i = 0; i < devices.length; i++) {
            if (!root._matchesConfiguredDevice(devices[i], hiddenSet))
                visible.push(devices[i]);
        }

        // Sort: pinned first, then rest
        visible.sort(function(a, b) {
            var aPin = root._matchesConfiguredDevice(a, pinnedSet) ? 0 : 1;
            var bPin = root._matchesConfiguredDevice(b, pinnedSet) ? 0 : 1;
            return aPin - bPin;
        });

        return visible;
    }

    function _buildAppNodes(isOutput) {
        if (!Pipewire.ready) return [];
        var nodes = Pipewire.nodes?.values ?? [];
        var apps = [];

        for (var i = 0; i < nodes.length; i++) {
            var node = nodes[i];
            if (!node || !node.audio || !node.isStream) continue;
            // Output app streams are sources (isSink=false) feeding into sinks
            // Input app streams are sinks (isSink=true) receiving from sources
            if (isOutput === node.isSink) continue;

            var vol = node.audio.volume;
            var props = node.properties || {};
            apps.push({
                nodeRef: node,
                id: node.id,
                name: props["application.name"] || node.description || node.nickname || node.name || "Unknown",
                iconName: props["application.icon-name"] || "",
                volume: (vol !== undefined && !isNaN(vol)) ? vol : 0,
                muted: node.audio.muted || false
            });
        }
        return apps;
    }

    function _sendOsdIpc(isSink, percent, muted) {
        var method = isSink ? "showVolume" : "showMic";
        Quickshell.execDetached(["quickshell", "ipc", "call", "Osd", method, Math.round(percent).toString(), muted.toString()]);
    }

    // ── Volume protection ────────────────────────
    function protectedVolume(targetVolume, currentVolume) {
        var maxJump = Config.volumeProtectionEnabled ? Config.volumeProtectionMaxJump : 1.0;
        var delta = targetVolume - currentVolume;
        if (Math.abs(delta) > maxJump)
            targetVolume = currentVolume + (delta > 0 ? maxJump : -maxJump);
        return Colors.clamp01(targetVolume);
    }

    // ── Actions (preserves existing API) ─────────
    function setVolume(target, value) {
        var current = root._currentTargetVolume(target);
        var clamped = Config.volumeProtectionEnabled
            ? root.protectedVolume(value, current)
            : Colors.clamp01(value);
        var isSink = target === "@DEFAULT_AUDIO_SINK@";

        if (isSink) {
            root.outputVolume = clamped;
            if (clamped > 0)
                root.outputMuted = false;
        } else {
            root.inputVolume = clamped;
            if (clamped > 0)
                root.inputMuted = false;
        }

        if (clamped > 0)
            root._execWpctl(["set-mute", target, "0"]);
        root._execWpctl(["set-volume", target, root._volumePercentText(clamped)]);
        root.postWriteRefreshTimer.restart();

        if (isSink || target === "@DEFAULT_AUDIO_SOURCE@")
            root._sendOsdIpc(isSink, clamped * 100, false);
    }

    function setAppVolume(nodeRef, value) {
        if (!nodeRef) return;
        var clamped = Colors.clamp01(value);
        var targetId = nodeRef.id !== undefined ? nodeRef.id.toString() : "";
        if (!targetId) return;
        if (clamped > 0)
            root._execWpctl(["set-mute", targetId, "0"]);
        root._execWpctl(["set-volume", targetId, root._volumePercentText(clamped)]);
    }

    function toggleAppMute(nodeRef) {
        if (!nodeRef) return;
        var targetId = nodeRef.id !== undefined ? nodeRef.id.toString() : "";
        if (!targetId) return;
        var currentMuted = nodeRef.audio ? !!nodeRef.audio.muted : false;
        root._execWpctl(["set-mute", targetId, currentMuted ? "0" : "1"]);
    }

    function toggleMute(target, currentlyMuted) {
        var isSink = target === "@DEFAULT_AUDIO_SINK@";
        if (currentlyMuted === undefined)
            currentlyMuted = root._currentTargetMuted(target);
        if (isSink)
            root.outputMuted = !currentlyMuted;
        else
            root.inputMuted = !currentlyMuted;
        root._execWpctl(["set-mute", target, currentlyMuted ? "0" : "1"]);
        root.postWriteRefreshTimer.restart();

        var vol = isSink ? root.outputVolume : root.inputVolume;
        if (isSink || target === "@DEFAULT_AUDIO_SOURCE@")
            root._sendOsdIpc(isSink, vol * 100, !currentlyMuted);
    }

    function setDefaultDevice(id) {
        if (id < 0) return;
        root._execWpctl(["set-default", id.toString()]);
        root.postWriteRefreshTimer.restart();
    }

    // ── Backward compat (no-ops since PipeWire is reactive) ──
    function refreshDevices() { /* no-op: PipeWire is reactive */ }

    onSubscriberCountChanged: {
        if (subscriberCount > 0)
            refreshVolumes();
    }

    Component.onCompleted: refreshVolumes()
}

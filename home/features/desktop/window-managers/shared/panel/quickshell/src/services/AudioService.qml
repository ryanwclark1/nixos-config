pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "AudioHelpers.js" as AudioHelpers

QtObject {
    id: root

    // ── Output (sink) state ──────────────────────
    readonly property real outputVolume: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio
        ? AudioHelpers.normalizeVolume(Pipewire.defaultAudioSink.audio.volume, 1.0)
        : 0
    readonly property bool outputMuted: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio ? Pipewire.defaultAudioSink.audio.muted : false
    readonly property string outputLabel: _sinkDescription()
    readonly property string outputDeviceType: _detectDeviceType()

    // ── Input (source) state ─────────────────────
    readonly property real inputVolume: Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio
        ? AudioHelpers.normalizeVolume(Pipewire.defaultAudioSource.audio.volume, 1.0)
        : 0
    readonly property bool inputMuted: Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio ? Pipewire.defaultAudioSource.audio.muted : false
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

    // ── Subscriber-based (kept for Ref.qml compat, now a no-op) ──
    property int subscriberCount: 0

    // ── PipeWire object tracking ─────────────────
    // Track default sink/source AND their .audio sub-objects for reactive volume/muted bindings.
    property PwObjectTracker _defaultTracker: PwObjectTracker {
        objects: {
            var out = [];
            if (Pipewire.defaultAudioSink) {
                out.push(Pipewire.defaultAudioSink);
                if (Pipewire.defaultAudioSink.audio) out.push(Pipewire.defaultAudioSink.audio);
            }
            if (Pipewire.defaultAudioSource) {
                out.push(Pipewire.defaultAudioSource);
                if (Pipewire.defaultAudioSource.audio) out.push(Pipewire.defaultAudioSource.audio);
            }
            return out;
        }
    }

    property PwObjectTracker _nodeTracker: PwObjectTracker {
        objects: _allAudioNodes()
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

    function _currentTargetVolume(target) {
        return target === "@DEFAULT_AUDIO_SINK@" ? root.outputVolume : root.inputVolume;
    }

    function _currentTargetMuted(target) {
        return target === "@DEFAULT_AUDIO_SINK@" ? root.outputMuted : root.inputMuted;
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

            var vol = AudioHelpers.normalizeVolume(node.audio.volume, 1.0);
            var displayName = _deviceDisplayName(node);
            devices.push({
                id: node.id,
                name: displayName,
                key: String(node.name || (node.properties ? node.properties["node.name"] : "") || displayName),
                matchKeys: _deviceMatchKeys(node, displayName),
                volume: vol,
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

            var vol = AudioHelpers.normalizeVolume(node.audio.volume, 1.0);
            var props = node.properties || {};
            apps.push({
                nodeRef: node,
                id: node.id,
                name: props["application.name"] || node.description || node.nickname || node.name || "Unknown",
                iconName: props["application.icon-name"] || "",
                volume: vol,
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
        var safeCurrent = AudioHelpers.normalizeVolume(currentVolume, 1.0);
        var safeTarget = AudioHelpers.normalizeVolume(targetVolume, 1.0);
        var delta = safeTarget - safeCurrent;
        if (Math.abs(delta) > maxJump)
            safeTarget = safeCurrent + (delta > 0 ? maxJump : -maxJump);
        return Colors.clamp01(safeTarget);
    }

    // ── Actions (preserves existing API) ─────────
    function setVolume(target, value) {
        var current = root._currentTargetVolume(target);
        var requested = AudioHelpers.normalizeVolume(value, 1.0);
        var clamped = Config.volumeProtectionEnabled
            ? root.protectedVolume(requested, current)
            : Colors.clamp01(requested);
        var isSink = target === "@DEFAULT_AUDIO_SINK@";
        var node = isSink ? Pipewire.defaultAudioSink : Pipewire.defaultAudioSource;

        if (node && node.audio) {
            if (clamped > 0) node.audio.muted = false;
            node.audio.volume = clamped;
        }

        if (isSink || target === "@DEFAULT_AUDIO_SOURCE@")
            root._sendOsdIpc(isSink, clamped * 100, false);
    }

    function setAppVolume(nodeRef, value) {
        if (!nodeRef || !nodeRef.audio) return;
        var clamped = Colors.clamp01(AudioHelpers.normalizeVolume(value, 1.0));
        if (clamped > 0) nodeRef.audio.muted = false;
        nodeRef.audio.volume = clamped;
    }

    function toggleAppMute(nodeRef) {
        if (!nodeRef || !nodeRef.audio) return;
        nodeRef.audio.muted = !nodeRef.audio.muted;
    }

    function toggleMute(target, currentlyMuted) {
        var isSink = target === "@DEFAULT_AUDIO_SINK@";
        if (currentlyMuted === undefined)
            currentlyMuted = root._currentTargetMuted(target);
        var node = isSink ? Pipewire.defaultAudioSink : Pipewire.defaultAudioSource;

        if (node && node.audio)
            node.audio.muted = !currentlyMuted;

        var vol = isSink ? root.outputVolume : root.inputVolume;
        if (isSink || target === "@DEFAULT_AUDIO_SOURCE@")
            root._sendOsdIpc(isSink, vol * 100, !currentlyMuted);
    }

    function setDefaultDevice(id) {
        if (id < 0) return;
        var nodes = Pipewire.nodes?.values ?? [];
        for (var i = 0; i < nodes.length; i++) {
            if (nodes[i] && nodes[i].id === id) {
                if (nodes[i].isSink)
                    Pipewire.preferredDefaultAudioSink = nodes[i];
                else
                    Pipewire.preferredDefaultAudioSource = nodes[i];
                return;
            }
        }
        // Fallback to wpctl if node not found in tracker
        Quickshell.execDetached(["wpctl", "set-default", id.toString()]);
    }

}

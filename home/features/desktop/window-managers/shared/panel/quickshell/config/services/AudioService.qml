import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

pragma Singleton

QtObject {
    id: root

    // ── Output (sink) state ──────────────────────
    readonly property real outputVolume: {
        var v = Pipewire.defaultAudioSink?.audio?.volume;
        return (v !== undefined && !isNaN(v)) ? Colors.clamp01(v) : 0;
    }
    readonly property bool outputMuted: Pipewire.defaultAudioSink?.audio?.muted ?? false
    readonly property string outputLabel: _sinkDescription()
    readonly property string outputDeviceType: _detectDeviceType()

    // ── Input (source) state ─────────────────────
    readonly property real inputVolume: {
        var v = Pipewire.defaultAudioSource?.audio?.volume;
        return (v !== undefined && !isNaN(v)) ? Colors.clamp01(v) : 0;
    }
    readonly property bool inputMuted: Pipewire.defaultAudioSource?.audio?.muted ?? false
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
    property PwObjectTracker _defaultTracker: PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
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
            devices.push({
                id: node.id,
                name: node.description || node.nickname || node.name || "Unknown",
                volume: (vol !== undefined && !isNaN(vol)) ? vol : 0,
                muted: node.audio.muted || false,
                isDefault: node.id === defaultId
            });
        }
        return devices;
    }

    function _filterDevices(devices, pinned, hidden) {
        var hiddenSet = {};
        for (var h = 0; h < (hidden || []).length; h++)
            hiddenSet[(hidden[h] || "").toLowerCase()] = true;

        var pinnedSet = {};
        for (var p = 0; p < (pinned || []).length; p++)
            pinnedSet[(pinned[p] || "").toLowerCase()] = true;

        var visible = [];
        for (var i = 0; i < devices.length; i++) {
            var name = (devices[i].name || "").toLowerCase();
            if (!hiddenSet[name])
                visible.push(devices[i]);
        }

        // Sort: pinned first, then rest
        visible.sort(function(a, b) {
            var aPin = pinnedSet[(a.name || "").toLowerCase()] ? 0 : 1;
            var bPin = pinnedSet[(b.name || "").toLowerCase()] ? 0 : 1;
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
    function protectedSetVolume(node, targetVolume, currentVolume) {
        if (!node || !node.audio) return;
        var maxJump = Config.volumeProtectionEnabled ? Config.volumeProtectionMaxJump : 1.0;
        var delta = targetVolume - currentVolume;
        if (Math.abs(delta) > maxJump)
            targetVolume = currentVolume + (delta > 0 ? maxJump : -maxJump);
        var clamped = Colors.clamp01(targetVolume);
        node.audio.volume = clamped;
        if (clamped > 0 && node.audio.muted)
            node.audio.muted = false;
    }

    // ── Actions (preserves existing API) ─────────
    function setVolume(target, value) {
        var clamped = Colors.clamp01(value);
        var isSink = target === "@DEFAULT_AUDIO_SINK@";
        var node = isSink ? Pipewire.defaultAudioSink : Pipewire.defaultAudioSource;

        if (node && node.audio) {
            var current = node.audio.volume || 0;
            if (Config.volumeProtectionEnabled) {
                protectedSetVolume(node, clamped, current);
            } else {
                node.audio.volume = clamped;
                if (clamped > 0 && node.audio.muted)
                    node.audio.muted = false;
            }
        } else {
            // Fallback to wpctl for edge cases
            if (clamped > 0)
                Quickshell.execDetached(["wpctl", "set-mute", target, "0"]);
            Quickshell.execDetached(["wpctl", "set-volume", target, Math.round(clamped * 100) + "%"]);
        }

        if (isSink || target === "@DEFAULT_AUDIO_SOURCE@")
            root._sendOsdIpc(isSink, clamped * 100, false);
    }

    function setAppVolume(nodeRef, value) {
        if (!nodeRef || !nodeRef.audio) return;
        var clamped = Colors.clamp01(value);
        nodeRef.audio.volume = clamped;
        if (clamped > 0 && nodeRef.audio.muted)
            nodeRef.audio.muted = false;
    }

    function toggleAppMute(nodeRef) {
        if (!nodeRef || !nodeRef.audio) return;
        nodeRef.audio.muted = !nodeRef.audio.muted;
    }

    function toggleMute(target, currentlyMuted) {
        var isSink = target === "@DEFAULT_AUDIO_SINK@";
        var node = isSink ? Pipewire.defaultAudioSink : Pipewire.defaultAudioSource;

        if (node && node.audio) {
            node.audio.muted = !currentlyMuted;
        } else {
            Quickshell.execDetached(["wpctl", "set-mute", target, currentlyMuted ? "0" : "1"]);
        }

        var vol = isSink ? root.outputVolume : root.inputVolume;
        if (isSink || target === "@DEFAULT_AUDIO_SOURCE@")
            root._sendOsdIpc(isSink, vol * 100, !currentlyMuted);
    }

    function setDefaultDevice(id) {
        if (id < 0) return;
        Quickshell.execDetached(["wpctl", "set-default", id.toString()]);
    }

    // ── Backward compat (no-ops since PipeWire is reactive) ──
    function refreshVolumes() { }
    function refreshDevices() { }
}

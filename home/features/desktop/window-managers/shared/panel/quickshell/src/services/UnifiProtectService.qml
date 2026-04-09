pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "."

// UniFi Protect API service.
// Talks to the local Protect controller for cameras, snapshots, and RTSPS streams.
// API base: https://{protectHost}/integration/v1
QtObject {
    id: root

    // ── Subscriber-based lifecycle ─────────────────────
    property int subscriberCount: 0

    // ── Cameras ─────────────────────────────────────────
    property var cameras: []
    property string status: "idle"  // idle | loading | ready | error | unconfigured
    property string errorMessage: ""
    property int totalCameras: 0
    property int onlineCameras: 0
    readonly property bool busy: cameraPoll.busy
    readonly property bool configured: Config.unifiProtectHost !== "" && Config.unifiProtectApiKey !== ""

    // ── Snapshot cache ──────────────────────────────────
    // Map of cameraId -> { url: "file:///tmp/...", timestamp: ms }
    property var _snapshotCache: ({})
    property int _snapshotCounter: 0

    // ── Active stream URLs ──────────────────────────────
    // Map of cameraId -> { high: "rtsps://...", medium: "...", low: "..." }
    property var _streamCache: ({})

    function _apiBase() {
        var host = Config.unifiProtectHost;
        if (!host) return "";
        if (host.indexOf("://") === -1) host = "https://" + host;
        return host + "/integration/v1";
    }

    function _curlCommand(endpoint) {
        var base = _apiBase();
        if (!base || !Config.unifiProtectApiKey) return [];
        return ["curl", "-sfk", "--max-time", "15",
                "-H", "X-API-Key: " + Config.unifiProtectApiKey,
                "-H", "Accept: application/json",
                base + endpoint];
    }

    function _parseJson(out) {
        var text = String(out || "").trim();
        if (!text) return null;
        try { return JSON.parse(text); }
        catch (e) { return null; }
    }

    function refresh() {
        if (!configured) {
            root.status = "unconfigured";
            return;
        }
        cameraPoll.triggerPoll();
    }

    // ── Camera list poll ────────────────────────────────
    property CommandPoll cameraPoll: CommandPoll {
        interval: Config.unifiProtectPollInterval * 1000
        running: root.subscriberCount > 0 && root.configured
        command: root._curlCommand("/cameras")
        parse: function(out) { return root._parseJson(out); }
        onUpdated: {
            var data = cameraPoll.value;
            if (!data) {
                root.status = "error";
                root.errorMessage = "Failed to connect to Protect controller";
                return;
            }
            if (data.error) {
                root.status = "error";
                root.errorMessage = String(data.error);
                return;
            }
            var cams = Array.isArray(data) ? data : [];
            root.cameras = cams;
            root.totalCameras = cams.length;
            var online = 0;
            for (var i = 0; i < cams.length; i++) {
                if (cams[i].state === "CONNECTED") online++;
            }
            root.onlineCameras = online;
            root.errorMessage = "";
            root.status = "ready";
        }
    }

    // ── Snapshot fetching ───────────────────────────────
    // Fetches a JPEG snapshot and saves to /tmp for display
    function fetchSnapshot(cameraId) {
        if (!configured || !cameraId) return;
        var tmpPath = "/tmp/qs-unifi-snap-" + cameraId + ".jpg";
        var base = _apiBase();
        var cmd = ["curl", "-sfk", "--max-time", "10",
                   "-H", "X-API-Key: " + Config.unifiProtectApiKey,
                   "-o", tmpPath,
                   base + "/cameras/" + cameraId + "/snapshot"];
        _snapshotProc.command = cmd;
        _snapshotProc._cameraId = cameraId;
        _snapshotProc._tmpPath = tmpPath;
        _snapshotProc.running = true;
    }

    property Process _snapshotProc: Process {
        property string _cameraId: ""
        property string _tmpPath: ""
        running: false
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0 && _cameraId) {
                root._snapshotCounter++;
                var cache = root._snapshotCache;
                cache[_cameraId] = {
                    url: "file://" + _tmpPath + "?v=" + root._snapshotCounter,
                    timestamp: Date.now()
                };
                root._snapshotCache = cache;
            }
        }
    }

    function snapshotUrl(cameraId) {
        var entry = _snapshotCache[cameraId];
        return entry ? entry.url : "";
    }

    // ── RTSPS stream creation ───────────────────────────
    function requestStream(cameraId, quality) {
        if (!configured || !cameraId) return;
        quality = quality || "medium";
        var base = _apiBase();
        var body = JSON.stringify({ qualities: [quality] });
        var cmd = ["curl", "-sfk", "--max-time", "10",
                   "-X", "POST",
                   "-H", "X-API-Key: " + Config.unifiProtectApiKey,
                   "-H", "Content-Type: application/json",
                   "-d", body,
                   base + "/cameras/" + cameraId + "/rtsps-stream"];
        _streamProc.command = cmd;
        _streamProc._cameraId = cameraId;
        _streamProc._quality = quality;
        _streamProc.running = true;
    }

    property Process _streamProc: Process {
        property string _cameraId: ""
        property string _quality: "medium"
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var text = String(this.text || "").trim();
                if (!text) return;
                try {
                    var data = JSON.parse(text);
                    var cache = root._streamCache;
                    cache[_streamProc._cameraId] = data;
                    root._streamCache = cache;
                    root.streamReady(_streamProc._cameraId, data[_streamProc._quality] || "");
                } catch (e) {
                    Logger.w("UnifiProtectService", "Failed to parse stream response:", e);
                }
            }
        }
    }

    signal streamReady(string cameraId, string streamUrl)

    function cachedStreamUrl(cameraId, quality) {
        var entry = _streamCache[cameraId];
        if (!entry) return "";
        return entry[quality || "medium"] || entry["high"] || entry["low"] || "";
    }

    // ── Snapshot refresh timer ──────────────────────────
    // Periodically refreshes snapshots for all cameras
    property Timer snapshotTimer: Timer {
        interval: Config.unifiProtectPollInterval * 1000
        repeat: true
        running: root.subscriberCount > 0 && root.configured && root.status === "ready"
        onTriggered: {
            for (var i = 0; i < root.cameras.length; i++) {
                var cam = root.cameras[i];
                if (cam && cam.id && cam.state === "CONNECTED") {
                    root.fetchSnapshot(cam.id);
                }
            }
        }
    }

    function cameraDisplayName(camera) {
        if (!camera) return "Unknown";
        return camera.name || camera.marketName || camera.type || "Camera";
    }

    function cameraStatusText(camera) {
        if (!camera) return "Unknown";
        if (camera.state === "CONNECTED") return "Online";
        if (camera.state === "DISCONNECTED") return "Offline";
        return String(camera.state || "Unknown");
    }
}

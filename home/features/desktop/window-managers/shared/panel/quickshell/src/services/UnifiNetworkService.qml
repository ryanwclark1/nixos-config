pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "."

// Cloud-based UniFi Site Manager API service.
// Polls api.ui.com for hosts, sites, devices, and ISP metrics.
QtObject {
    id: root

    // ── Subscriber-based lifecycle ─────────────────────
    property int subscriberCount: 0

    // ── Hosts ───────────────────────────────────────────
    property var hosts: []
    property string hostsStatus: "idle"

    // ── Sites ───────────────────────────────────────────
    property var sites: []
    property string sitesStatus: "idle"

    // ── Devices ─────────────────────────────────────────
    property var devices: []
    property string devicesStatus: "idle"
    property int totalDevices: 0
    property int onlineDevices: 0

    // ── ISP Metrics ─────────────────────────────────────
    property var ispMetrics: ({})
    property string ispStatus: "idle"

    // ── Overall ─────────────────────────────────────────
    property string status: "idle"  // idle | loading | ready | error | unconfigured
    property string errorMessage: ""
    readonly property bool busy: hostsPoll.busy || sitesPoll.busy || devicesPoll.busy || ispPoll.busy
    readonly property bool configured: Config.unifiApiKey !== ""

    // ── Private helpers ─────────────────────────────────
    function _curlCommand(endpoint) {
        var apiKey = Config.unifiApiKey;
        if (!apiKey) return [];
        return ["curl", "-sf", "--max-time", "15",
                "-H", "X-API-Key: " + apiKey,
                "-H", "Accept: application/json",
                "https://api.ui.com/v1" + endpoint];
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
        hostsPoll.triggerPoll();
        sitesPoll.triggerPoll();
        devicesPoll.triggerPoll();
        ispPoll.triggerPoll();
    }

    // ── Hosts poll ──────────────────────────────────────
    property CommandPoll hostsPoll: CommandPoll {
        interval: Config.unifiPollInterval * 1000
        running: root.subscriberCount > 0 && root.configured
        command: root._curlCommand("/hosts")
        parse: function(out) { return root._parseJson(out); }
        onUpdated: {
            var data = hostsPoll.value;
            if (!data) {
                root.hostsStatus = "error";
                return;
            }
            if (data.httpStatusCode === 401) {
                root.hostsStatus = "error";
                root.errorMessage = "Invalid API key";
                root.status = "error";
                return;
            }
            root.hosts = data.data || [];
            root.hostsStatus = "ready";
            root._updateOverallStatus();
        }
    }

    // ── Sites poll ──────────────────────────────────────
    property CommandPoll sitesPoll: CommandPoll {
        interval: Config.unifiPollInterval * 1000
        running: root.subscriberCount > 0 && root.configured
        command: root._curlCommand("/sites")
        parse: function(out) { return root._parseJson(out); }
        onUpdated: {
            var data = sitesPoll.value;
            if (!data) { root.sitesStatus = "error"; return; }
            root.sites = data.data || [];
            root.sitesStatus = "ready";
            root._updateOverallStatus();
        }
    }

    // ── Devices poll ────────────────────────────────────
    property CommandPoll devicesPoll: CommandPoll {
        interval: Config.unifiPollInterval * 1000
        running: root.subscriberCount > 0 && root.configured
        command: root._curlCommand("/devices")
        parse: function(out) { return root._parseJson(out); }
        onUpdated: {
            var data = devicesPoll.value;
            if (!data) { root.devicesStatus = "error"; return; }
            var allDevices = [];
            var items = data.data || [];
            for (var i = 0; i < items.length; i++) {
                var hostDevices = items[i].devices || [];
                for (var j = 0; j < hostDevices.length; j++) {
                    var d = hostDevices[j];
                    d.hostName = items[i].hostName || "";
                    d.hostId = items[i].hostId || "";
                    allDevices.push(d);
                }
            }
            root.devices = allDevices;
            root.totalDevices = allDevices.length;
            var online = 0;
            for (var k = 0; k < allDevices.length; k++) {
                if (allDevices[k].status === "online") online++;
            }
            root.onlineDevices = online;
            root.devicesStatus = "ready";
            root._updateOverallStatus();
        }
    }

    // ── ISP Metrics poll ────────────────────────────────
    property CommandPoll ispPoll: CommandPoll {
        interval: Config.unifiPollInterval * 1000
        running: root.subscriberCount > 0 && root.configured
        command: root._curlCommand("/isp-metrics/5m?duration=24h")
        parse: function(out) { return root._parseJson(out); }
        onUpdated: {
            var data = ispPoll.value;
            if (!data) { root.ispStatus = "error"; return; }
            var items = data.data || [];
            if (items.length > 0) {
                var periods = items[0].periods || [];
                if (periods.length > 0) {
                    var latest = periods[periods.length - 1];
                    root.ispMetrics = (latest.data && latest.data.wan) ? latest.data.wan : {};
                }
            }
            root.ispStatus = "ready";
            root._updateOverallStatus();
        }
    }

    function _updateOverallStatus() {
        if (root.hostsStatus === "error" || root.devicesStatus === "error" ||
            root.sitesStatus === "error" || root.ispStatus === "error") {
            if (!root.errorMessage) root.errorMessage = "Failed to fetch data from UniFi API";
            root.status = "error";
        } else if (root.hostsStatus === "ready" && root.devicesStatus === "ready") {
            root.errorMessage = "";
            root.status = "ready";
        } else {
            root.status = "loading";
        }
    }

    function productLineIcon(productLine) {
        switch (productLine) {
            case "network": return "ethernet.svg";
            case "protect": return "camera.svg";
            case "access": return "lock.svg";
            case "talk": return "phone.svg";
            default: return "server.svg";
        }
    }

    function deviceImageUrl(device) {
        if (device && device.uidb && device.uidb.images && device.uidb.images.default)
            return "https://static.ui.com/fingerprint/ui/images/" + device.uidb.images.default + "/default/" + device.uidb.id + "_25x25.png";
        return "";
    }
}

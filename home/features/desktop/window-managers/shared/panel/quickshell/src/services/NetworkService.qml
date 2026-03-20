pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "."

// Centralized network state service.  Uses an event-driven Python D-Bus daemon
// (qs-network-monitor) that subscribes to NetworkManager signals and emits JSON
// snapshots on state change.  Falls back to legacy nmcli polling if the daemon
// is unavailable.
//
// Public API is unchanged — all 60+ properties, helper functions, and action
// functions remain identical to the original polling implementation.
QtObject {
    id: root

    // ── Subscriber-based lifecycle ─────────────────────
    property int subscriberCount: 0

    // ── Wi-Fi radio & device ─────────────────────────
    property bool wifiRadioEnabled: false
    property bool wifiDeviceAvailable: false

    // ── Scanned networks ─────────────────────────────
    property var wifiNetworks: []

    // ── VPN connections ──────────────────────────────
    property var vpns: []
    property var vpnProfiles: []
    property var activeConnections: []

    // ── Primary connection details ───────────────────
    property string activePrimaryName: "Offline"
    property string activePrimaryType: ""
    property string primaryDevice: ""
    property string primaryIpv4: ""
    property string primaryIpv6: ""
    property string primaryGateway: ""
    property string primaryMac: ""
    property string primaryLinkSpeed: ""
    property string primarySecurity: ""
    property string primarySignal: ""
    property string primaryChannel: ""
    property string primaryBand: ""
    property string connectivityStatus: "unknown"
    property var dnsServers: []

    // ── Internet details ─────────────────────────────
    property string routeDevice: ""
    property string routeSource: ""
    property string publicIpv4: ""
    property string totalReceived: ""
    property string totalSent: ""

    // ── Tailscale ────────────────────────────────────
    property string tailscaleStatus: "Offline"
    property string tailscaleIp: ""
    readonly property string vpnPrimaryStatus: {
        var state = String(tailscaleStatus || "Offline");
        if (state === "Connected")
            return "connected";
        if (state === "Stopped")
            return "stopped";
        if (state === "Disconnected")
            return "disconnected";
        return "unavailable";
    }
    readonly property string vpnPrimaryLabel: "Tailscale"
    readonly property string vpnPrimaryDetail: {
        if (vpnPrimaryStatus === "connected")
            return tailscaleIp !== "" ? tailscaleIp : "Connected";
        if (vpnPrimaryStatus === "stopped")
            return "Stopped";
        if (vpnPrimaryStatus === "disconnected")
            return "Ready to connect";
        return "CLI unavailable";
    }
    readonly property var vpnOtherSessions: (vpnProfiles || []).filter(function(profile) { return !!profile.active; })
    readonly property var vpnActiveProfiles: vpnOtherSessions
    readonly property var vpnInactiveProfiles: (vpnProfiles || []).filter(function(profile) { return !profile.active; })
    readonly property int vpnOtherCount: vpnOtherSessions.length
    readonly property int vpnInactiveCount: vpnInactiveProfiles.length
    readonly property int vpnProfileCount: (vpnProfiles || []).length
    readonly property bool vpnHasSavedProfiles: vpnProfileCount > 0
    readonly property bool vpnHasAnyOverlay: vpnPrimaryStatus === "connected" || vpnOtherCount > 0
    readonly property bool tailscaleInstalled: DependencyService.isAvailable("tailscale")
    readonly property bool tailscaleConnected: tailscaleStatus === "Connected"
    readonly property bool nmcliInstalled: DependencyService.isAvailable("nmcli")

    // ── Refresh state ────────────────────────────────
    property bool isRefreshing: false
    property string pendingVpnProfileUuid: ""
    property string pendingVpnAction: ""
    property string lastVpnActionState: "idle"
    property string lastVpnActionMessage: ""
    property double lastVpnActionAt: 0

    property string _vpnActionUuid: ""
    property string _vpnActionTitle: ""
    property string _vpnActionSuccessMessage: ""
    property string _vpnActionFailureMessage: ""
    property var _vpnActionCommand: []

    // ═══════════════════════════════════════════════════
    //  Helper functions (unchanged public API)
    // ═══════════════════════════════════════════════════

    function networkIcon() {
        if (activePrimaryName === "Offline") return "wifi-off.svg";
        if (activePrimaryType === "ethernet" || activePrimaryType === "802-3-ethernet") return "ethernet.svg";
        return "wifi-4.svg";
    }

    function networkSubtitle() {
        if (activePrimaryName === "Offline") return "No primary network";
        if (activePrimaryType === "ethernet" || activePrimaryType === "802-3-ethernet") return "Ethernet connected";
        if (primaryDevice) return primaryDevice + " • " + connectivityStatus;
        return connectivityStatus;
    }

    function signalIcon(signal) {
        var value = parseInt(signal || "0", 10);
        if (value >= 80) return "wifi-4.svg";
        if (value >= 60) return "wifi-3.svg";
        if (value >= 40) return "wifi-2.svg";
        if (value > 0) return "wifi-1.svg";
        return "wifi-off.svg";
    }

    function bandFromChannel(channel) {
        var ch = parseInt(channel || "0", 10);
        if (!ch) return "";
        if (ch <= 14) return "2.4 GHz";
        if (ch <= 177) return "5 GHz";
        return "6 GHz";
    }

    function dnsSummary() {
        return dnsServers.length > 0 ? dnsServers.join(", ") : "Unavailable";
    }

    function detailValue(value, fallback) {
        return value && value !== "" ? value : fallback;
    }

    function sortWifiNetworks(networks) {
        return networks.sort(function(a, b) {
            if (!!a.active !== !!b.active) return a.active ? -1 : 1;
            return (parseInt(b.signal || "0", 10) || 0) - (parseInt(a.signal || "0", 10) || 0);
        });
    }

    function vpnStatusLabel(statusValue) {
        var status = String(statusValue || "");
        if (status === "connected") return "Connected";
        if (status === "stopped") return "Stopped";
        if (status === "disconnected") return "Disconnected";
        return "Unavailable";
    }

    function isVpnConnectionType(typeName) {
        var type = String(typeName || "").toLowerCase();
        return type === "vpn" || type === "wireguard" || type === "tun";
    }

    function parseVpnCatalog(text) {
        var lines = String(text || "").trim().split("\n");
        var entries = [];
        for (var i = 0; i < lines.length; ++i) {
            var line = String(lines[i] || "").trim();
            if (line === "")
                continue;
            var parts = line.split(":");
            if (parts.length < 3)
                continue;
            if (!isVpnConnectionType(parts[2]))
                continue;
            entries.push({
                uuid: String(parts[0] || ""),
                name: String(parts[1] || ""),
                type: String(parts[2] || ""),
                device: "",
                state: "",
                active: false
            });
        }
        return entries;
    }

    function parseActiveVpnSessions(text) {
        var lines = String(text || "").trim().split("\n");
        var entries = [];
        for (var i = 0; i < lines.length; ++i) {
            var line = String(lines[i] || "").trim();
            if (line === "")
                continue;
            var parts = line.split(":");
            if (parts.length < 5)
                continue;
            if (!isVpnConnectionType(parts[2]))
                continue;
            entries.push({
                uuid: String(parts[0] || ""),
                name: String(parts[1] || ""),
                type: String(parts[2] || ""),
                device: String(parts[3] || ""),
                state: String(parts[4] || ""),
                active: true
            });
        }
        return entries;
    }

    function sortVpnProfiles(profiles) {
        return (profiles || []).sort(function(a, b) {
            if (!!a.active !== !!b.active)
                return a.active ? -1 : 1;
            return String(a.name || "").localeCompare(String(b.name || ""));
        });
    }

    // Compatibility helper used by contract checks and older callers while the
    // runtime source of truth remains the daemon-provided `vpnProfiles` snapshot.
    function buildVpnProfiles(catalogText, activeText) {
        var catalog = parseVpnCatalog(catalogText);
        var activeEntries = parseActiveVpnSessions(activeText);
        var activeByUuid = ({});
        var merged = [];
        var seen = ({});
        var i;

        for (i = 0; i < activeEntries.length; ++i) {
            var activeEntry = activeEntries[i];
            if (activeEntry.uuid !== "")
                activeByUuid[activeEntry.uuid] = activeEntry;
        }

        for (i = 0; i < catalog.length; ++i) {
            var entry = catalog[i];
            var mergedEntry = entry.uuid !== "" && activeByUuid[entry.uuid]
                ? Object.assign({}, entry, activeByUuid[entry.uuid], { active: true })
                : Object.assign({}, entry);
            merged.push(mergedEntry);
            if (mergedEntry.uuid !== "")
                seen[mergedEntry.uuid] = true;
        }

        for (i = 0; i < activeEntries.length; ++i) {
            var extraActive = activeEntries[i];
            if (extraActive.uuid !== "" && seen[extraActive.uuid])
                continue;
            merged.push(Object.assign({}, extraActive));
        }

        return sortVpnProfiles(merged);
    }

    function vpnProfileByUuid(uuidValue) {
        var uuid = String(uuidValue || "");
        var profiles = vpnProfiles || [];
        for (var i = 0; i < profiles.length; ++i) {
            if (String(profiles[i].uuid || "") === uuid)
                return profiles[i];
        }
        return null;
    }

    function vpnProfilePendingAction(uuidValue) {
        return pendingVpnProfileUuid === String(uuidValue || "") ? pendingVpnAction : "";
    }

    // ═══════════════════════════════════════════════════
    //  Refresh / daemon commands
    // ═══════════════════════════════════════════════════

    function refreshData() {
        isRefreshing = true;
        _sendCommand({"type": "refresh"});
    }

    function queueRefresh() {
        _actionRefresh.restart();
    }

    function _sendCommand(obj) {
        if (_monitor.running) {
            _monitor.write(JSON.stringify(obj) + "\n");
        }
    }

    function _runVpnProfileAction(profile, actionName, command, title, successMessage, failureMessage) {
        if (!profile || !profile.uuid)
            return false;
        if (vpnActionProc.running) {
            ToastService.showNotice("VPN action pending", "Wait for the current VPN action to finish.");
            return false;
        }
        pendingVpnProfileUuid = String(profile.uuid || "");
        pendingVpnAction = String(actionName || "");
        _vpnActionUuid = pendingVpnProfileUuid;
        _vpnActionTitle = String(title || "VPN action");
        _vpnActionSuccessMessage = String(successMessage || "VPN action completed.");
        _vpnActionFailureMessage = String(failureMessage || "VPN action failed.");
        _vpnActionCommand = command || [];
        vpnActionProc.running = true;
        return true;
    }

    // ── Actions ──────────────────────────────────────

    function toggleWifiRadio() {
        Quickshell.execDetached(["nmcli", "radio", "wifi", wifiRadioEnabled ? "off" : "on"]);
        queueRefresh();
    }

    function disconnectPrimary() {
        if (activePrimaryName !== "Offline") {
            Quickshell.execDetached(["nmcli", "connection", "down", activePrimaryName]);
            queueRefresh();
        }
    }

    function connectWifi(ssid) {
        Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", ssid]);
        queueRefresh();
    }

    function connectWifiWithPassword(ssid, password) {
        Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", ssid, "password", password]);
        queueRefresh();
    }

    function disconnectWifi(ssid) {
        Quickshell.execDetached(["nmcli", "connection", "down", ssid]);
        queueRefresh();
    }

    function connectVpnProfile(uuidValue) {
        var profile = vpnProfileByUuid(uuidValue);
        if (!profile)
            return false;
        return _runVpnProfileAction(
            profile,
            "connect",
            ["nmcli", "connection", "up", "uuid", String(profile.uuid || "")],
            "VPN connected",
            String(profile.name || "VPN") + " is now connected.",
            "Could not connect " + String(profile.name || "VPN") + "."
        );
    }

    function disconnectVpnProfile(uuidValue) {
        var profile = vpnProfileByUuid(uuidValue);
        if (!profile)
            return false;
        return _runVpnProfileAction(
            profile,
            "disconnect",
            ["nmcli", "connection", "down", "uuid", String(profile.uuid || "")],
            "VPN disconnected",
            String(profile.name || "VPN") + " is now disconnected.",
            "Could not disconnect " + String(profile.name || "VPN") + "."
        );
    }

    function tailscaleUp() {
        Quickshell.execDetached(["tailscale", "up"]);
        queueRefresh();
    }

    function tailscaleDown() {
        Quickshell.execDetached(["tailscale", "down"]);
        queueRefresh();
    }

    // ═══════════════════════════════════════════════════
    //  Daemon Process + JSON dispatcher
    // ═══════════════════════════════════════════════════

    property Process _monitor: Process {
        command: DependencyService.resolveCommand("qs-network-monitor")
        running: root.subscriberCount > 0

        stdout: SplitParser {
            onRead: data => {
                var line = (data || "").trim();
                if (!line) return;
                try {
                    var msg = JSON.parse(line);
                } catch (e) {
                    return;
                }
                if (msg.type !== "snapshot") return;
                root._applySnapshot(msg);
            }
        }

        onRunningChanged: {
            if (running) {
                // Daemon just started — it emits initial snapshot automatically
                root.isRefreshing = true;
            }
        }

        onExited: (exitCode, exitStatus) => {
            // Auto-restart on crash
            root._restartTimer.start();
        }
    }

    function _applySnapshot(msg) {
        root.wifiRadioEnabled = !!msg.wifiRadioEnabled;
        root.wifiDeviceAvailable = !!msg.wifiDeviceAvailable;
        root.wifiNetworks = msg.wifiNetworks || [];
        root.activeConnections = msg.activeConnections || [];
        root.vpnProfiles = msg.vpnProfiles || [];
        root.vpns = msg.vpns || [];
        root.activePrimaryName = msg.activePrimaryName || "Offline";
        root.activePrimaryType = msg.activePrimaryType || "";
        root.primaryDevice = msg.primaryDevice || "";
        root.primaryIpv4 = msg.primaryIpv4 || "";
        root.primaryIpv6 = msg.primaryIpv6 || "";
        root.primaryGateway = msg.primaryGateway || "";
        root.primaryMac = msg.primaryMac || "";
        root.primaryLinkSpeed = msg.primaryLinkSpeed || "";
        root.primarySecurity = msg.primarySecurity || "";
        root.primarySignal = msg.primarySignal || "";
        root.primaryChannel = msg.primaryChannel || "";
        root.primaryBand = msg.primaryBand || "";
        root.connectivityStatus = msg.connectivityStatus || "unknown";
        root.dnsServers = msg.dnsServers || [];
        root.routeDevice = msg.routeDevice || "";
        root.routeSource = msg.routeSource || "";
        root.publicIpv4 = msg.publicIpv4 || "";
        root.totalReceived = msg.totalReceived || "";
        root.totalSent = msg.totalSent || "";
        root.tailscaleStatus = msg.tailscaleStatus || "Offline";
        root.tailscaleIp = msg.tailscaleIp || "";
        root.isRefreshing = false;
    }

    // ═══════════════════════════════════════════════════
    //  Timers
    // ═══════════════════════════════════════════════════

    property Timer _actionRefresh: Timer {
        interval: 1500
        repeat: false
        onTriggered: root.refreshData()
    }

    property Timer _vpnActionImmediateRefresh: Timer {
        interval: 120
        repeat: false
        onTriggered: root.refreshData()
    }

    property Timer _vpnActionSettleRefresh: Timer {
        interval: 900
        repeat: false
        onTriggered: root.refreshData()
    }

    property Timer _restartTimer: Timer {
        interval: 3000
        repeat: false
        onTriggered: {
            if (!root._monitor.running && root.subscriberCount > 0)
                root._monitor.running = true;
        }
    }

    // ═══════════════════════════════════════════════════
    //  VPN action Process (user-triggered, kept in QML)
    // ═══════════════════════════════════════════════════

    property Process vpnActionProc: Process {
        id: vpnActionProc
        command: root._vpnActionCommand
        running: false
        onExited: (exitCode, exitStatus) => {
            var wasSuccess = exitCode === 0;
            var actionTitle = root._vpnActionTitle;
            var successMessage = root._vpnActionSuccessMessage;
            var failureMessage = root._vpnActionFailureMessage;
            root.pendingVpnProfileUuid = "";
            root.pendingVpnAction = "";
            root.lastVpnActionState = wasSuccess ? "success" : "error";
            root.lastVpnActionMessage = wasSuccess ? successMessage : failureMessage;
            root.lastVpnActionAt = Date.now();
            if (wasSuccess)
                ToastService.showSuccess(actionTitle, successMessage);
            else
                ToastService.showError(actionTitle, failureMessage);
            root.refreshData();
            root._vpnActionImmediateRefresh.restart();
            root._vpnActionSettleRefresh.restart();
        }
    }
}

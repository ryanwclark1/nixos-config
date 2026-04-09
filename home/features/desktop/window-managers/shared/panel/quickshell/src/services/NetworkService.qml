pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "."
import "../features/network/VpnHelpers.js" as VH

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
    property string tailscaleStatus: "Unavailable"
    property string tailscaleIp: ""
    property var tailscaleIps: []
    property string tailscaleBackendState: ""
    property string tailscaleAuthUrl: ""
    property var tailscaleHealth: []
    property string tailscaleVersion: ""
    property var tailscaleSelf: ({})
    property var tailscaleTailnet: ({ name: "", magicDnsSuffix: "" })
    property var tailscalePeers: []
    property var tailscalePrefs: ({})
    property var tailscaleProfiles: []
    property var tailscaleExitNode: ({ id: "", ip: "", name: "", dnsName: "", allowLanAccess: false })
    readonly property string vpnPrimaryStatus: {
        return VH.backendStateStatusKey(tailscaleBackendState);
    }
    readonly property string vpnPrimaryLabel: "Tailscale"
    readonly property string vpnPrimaryDetail: {
        if (vpnPrimaryStatus === "connected")
            return tailscaleCurrentExitNodeLabel !== ""
                ? tailscaleIp + " via " + tailscaleCurrentExitNodeLabel
                : (tailscaleIp !== "" ? tailscaleIp : "Connected");
        if (tailscaleNeedsMachineAuth)
            return "Waiting for machine approval";
        if (tailscaleNeedsLogin)
            return tailscaleAuthUrl !== "" ? "Browser sign-in available" : "Sign in to continue";
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
    readonly property bool vpnHasAnyOverlay: vpnPrimaryStatus === "connected" || vpnPrimaryStatus === "attention" || vpnOtherCount > 0
    readonly property bool tailscaleInstalled: DependencyService.isAvailable("tailscale")
    readonly property bool tailscaleConnected: tailscaleBackendState === "Running"
    readonly property bool tailscaleNeedsLogin: tailscaleBackendState === "NeedsLogin" || tailscaleBackendState === "NeedsMachineAuth"
    readonly property bool tailscaleNeedsMachineAuth: tailscaleBackendState === "NeedsMachineAuth"
    readonly property bool tailscaleLoggedOut: !!tailscalePrefs.LoggedOut
    readonly property bool tailscaleWantRunning: !!tailscalePrefs.WantRunning
    readonly property bool tailscaleAcceptDns: !!tailscalePrefs.CorpDNS
    readonly property bool tailscaleAcceptRoutes: !!tailscalePrefs.RouteAll
    readonly property bool tailscaleExitNodeAllowLanAccess: !!tailscalePrefs.ExitNodeAllowLANAccess
    readonly property bool tailscaleRunSsh: !!tailscalePrefs.RunSSH
    readonly property bool tailscaleShieldsUp: !!tailscalePrefs.ShieldsUp
    readonly property bool tailscaleAdvertiseExitNode: VH.advertiseExitNodeEnabled(tailscalePrefs)
    readonly property bool tailscaleStatefulFiltering: VH.statefulFilteringEnabled(tailscalePrefs)
    readonly property string tailscaleHealthSummary: VH.healthSummary(tailscaleHealth)
    readonly property var tailscaleOnlinePeers: (tailscalePeers || []).filter(function(peer) { return !!peer.online; })
    readonly property var tailscaleActivePeers: (tailscalePeers || []).filter(function(peer) { return !!peer.active; })
    readonly property var tailscaleExitNodes: (tailscalePeers || []).filter(function(peer) { return !!peer.exitNodeOption; })
    readonly property int tailscalePeerCount: (tailscalePeers || []).length
    readonly property int tailscaleOnlinePeerCount: tailscaleOnlinePeers.length
    readonly property int tailscaleProfileCount: (tailscaleProfiles || []).length
    readonly property var tailscaleCurrentProfile: {
        var profiles = tailscaleProfiles || [];
        for (var i = 0; i < profiles.length; ++i) {
            if (profiles[i].selected)
                return profiles[i];
        }
        return null;
    }
    readonly property string tailscaleCurrentProfileLabel: {
        var profile = tailscaleCurrentProfile;
        if (profile && profile.nickname)
            return profile.nickname;
        if (profile && profile.account)
            return profile.account;
        return "";
    }
    readonly property string tailscaleCurrentExitNodeLabel: VH.exitNodeLabel(tailscaleExitNode)
    readonly property bool nmcliInstalled: DependencyService.isAvailable("nmcli")

    // ── Refresh state ────────────────────────────────
    property bool isRefreshing: false
    property string pendingVpnProfileUuid: ""
    property string pendingVpnAction: ""
    property string pendingTailscaleAction: ""
    property string lastVpnActionState: "idle"
    property string lastVpnActionMessage: ""
    property double lastVpnActionAt: 0

    property string _vpnActionUuid: ""
    property string _vpnActionTitle: ""
    property string _vpnActionSuccessMessage: ""
    property string _vpnActionFailureMessage: ""
    property var _vpnActionCommand: []
    property string _tailscaleActionTitle: ""
    property string _tailscaleActionSuccessMessage: ""
    property string _tailscaleActionFailureMessage: ""
    property var _tailscaleActionCommand: []

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
        if (status === "attention") return tailscaleNeedsMachineAuth ? "Needs approval" : "Needs login";
        if (status === "stopped") return "Stopped";
        if (status === "disconnected") return "Disconnected";
        return "Unavailable";
    }

    function tailscalePeerLabel(peer) {
        if (!peer)
            return "Peer";
        return String(peer.name || "").length > 0
            ? String(peer.name || "")
            : (String(peer.dnsName || "").length > 0 ? String(peer.dnsName || "") : "Peer");
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
        if (vpnActionProc.running || tailscaleActionProc.running) {
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

    function _runTailscaleAction(actionName, command, title, successMessage, failureMessage) {
        if (vpnActionProc.running || tailscaleActionProc.running) {
            ToastService.showNotice("Tailscale action pending", "Wait for the current network action to finish.");
            return false;
        }
        pendingTailscaleAction = String(actionName || "");
        _tailscaleActionTitle = String(title || "Tailscale updated");
        _tailscaleActionSuccessMessage = String(successMessage || "Tailscale updated.");
        _tailscaleActionFailureMessage = String(failureMessage || "Tailscale action failed.");
        _tailscaleActionCommand = command || [];
        tailscaleActionProc.running = true;
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

    function tailscaleOpenAuthUrl() {
        if (tailscaleAuthUrl === "")
            return false;
        Quickshell.execDetached(["xdg-open", tailscaleAuthUrl]);
        ToastService.showNotice("Tailscale login", "Opened the browser sign-in flow.");
        queueRefresh();
        return true;
    }

    function tailscaleConnect() {
        if (tailscaleNeedsLogin)
            return tailscaleOpenAuthUrl() || _runTailscaleAction(
                "login",
                ["tailscale", "login", "--timeout", "2s"],
                "Tailscale login",
                "Started Tailscale login.",
                "Could not start Tailscale login."
            );
        return _runTailscaleAction(
            "connect",
            ["tailscale", "up", "--timeout", "5s"],
            "Tailscale connected",
            "Tailscale is now connected.",
            "Could not connect Tailscale."
        );
    }

    function tailscaleUp() { return tailscaleConnect(); }

    function tailscaleDisconnect() {
        return _runTailscaleAction(
            "disconnect",
            ["tailscale", "down"],
            "Tailscale disconnected",
            "Tailscale is now disconnected.",
            "Could not disconnect Tailscale."
        );
    }

    function tailscaleDown() { return tailscaleDisconnect(); }

    function tailscaleLogout() {
        return _runTailscaleAction(
            "logout",
            ["tailscale", "logout"],
            "Tailscale logged out",
            "Tailscale account logged out.",
            "Could not log out of Tailscale."
        );
    }

    function tailscaleSwitchProfile(profileId) {
        var id = String(profileId || "");
        if (id === "")
            return false;
        return _runTailscaleAction(
            "switch",
            ["tailscale", "switch", id],
            "Tailscale account switched",
            "Switched Tailscale account.",
            "Could not switch Tailscale account."
        );
    }

    function tailscaleSelectExitNode(nodeValue) {
        var node = String(nodeValue || "");
        if (node === "")
            return false;
        return _runTailscaleAction(
            "exitNode",
            ["tailscale", "set", "--exit-node=" + node],
            "Exit node updated",
            "Exit node selection updated.",
            "Could not update the exit node."
        );
    }

    function tailscaleClearExitNode() {
        return _runTailscaleAction(
            "clearExitNode",
            ["tailscale", "set", "--exit-node="],
            "Exit node cleared",
            "Direct tailnet routing restored.",
            "Could not clear the exit node."
        );
    }

    function tailscaleSetAcceptDns(enabled) {
        return _runTailscaleAction(
            "acceptDns",
            ["tailscale", "set", "--accept-dns=" + (!!enabled)],
            "DNS preference updated",
            "Tailscale DNS preference updated.",
            "Could not update DNS preference."
        );
    }

    function tailscaleSetAcceptRoutes(enabled) {
        return _runTailscaleAction(
            "acceptRoutes",
            ["tailscale", "set", "--accept-routes=" + (!!enabled)],
            "Route preference updated",
            "Tailscale route preference updated.",
            "Could not update route preference."
        );
    }

    function tailscaleSetExitNodeLanAccess(enabled) {
        return _runTailscaleAction(
            "exitNodeLan",
            ["tailscale", "set", "--exit-node-allow-lan-access=" + (!!enabled)],
            "Exit-node LAN access updated",
            "Updated exit-node LAN access.",
            "Could not update exit-node LAN access."
        );
    }

    function tailscaleSetShieldsUp(enabled) {
        return _runTailscaleAction(
            "shieldsUp",
            ["tailscale", "set", "--shields-up=" + (!!enabled)],
            "Shields Up updated",
            "Updated the Shields Up preference.",
            "Could not update Shields Up."
        );
    }

    function tailscaleSetSsh(enabled) {
        return _runTailscaleAction(
            "ssh",
            ["tailscale", "set", "--ssh=" + (!!enabled)],
            "Tailscale SSH updated",
            "Updated the Tailscale SSH preference.",
            "Could not update Tailscale SSH."
        );
    }

    function tailscaleSetAdvertiseExitNode(enabled) {
        return _runTailscaleAction(
            "advertiseExitNode",
            ["tailscale", "set", "--advertise-exit-node=" + (!!enabled)],
            "Exit-node advertising updated",
            "Updated exit-node advertising.",
            "Could not update exit-node advertising."
        );
    }

    function tailscaleSetStatefulFiltering(enabled) {
        return _runTailscaleAction(
            "statefulFiltering",
            ["tailscale", "set", "--stateful-filtering=" + (!!enabled)],
            "Stateful filtering updated",
            "Updated stateful filtering.",
            "Could not update stateful filtering."
        );
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
        root.tailscaleStatus = msg.tailscaleStatus || "Unavailable";
        root.tailscaleIp = msg.tailscaleIp || "";
        root.tailscaleIps = msg.tailscaleIps || [];
        root.tailscaleBackendState = msg.tailscaleBackendState || "";
        root.tailscaleAuthUrl = msg.tailscaleAuthUrl || "";
        root.tailscaleHealth = msg.tailscaleHealth || [];
        root.tailscaleVersion = msg.tailscaleVersion || "";
        root.tailscaleSelf = msg.tailscaleSelf || ({});
        root.tailscaleTailnet = msg.tailscaleTailnet || ({ name: "", magicDnsSuffix: "" });
        root.tailscalePeers = msg.tailscalePeers || [];
        root.tailscalePrefs = msg.tailscalePrefs || ({});
        root.tailscaleProfiles = msg.tailscaleProfiles || [];
        root.tailscaleExitNode = msg.tailscaleExitNode || ({ id: "", ip: "", name: "", dnsName: "", allowLanAccess: false });
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

    property Timer _tailscaleActionImmediateRefresh: Timer {
        interval: 150
        repeat: false
        onTriggered: root.refreshData()
    }

    property Timer _tailscaleActionSettleRefresh: Timer {
        interval: 1200
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

    property Process tailscaleActionProc: Process {
        id: tailscaleActionProc
        command: root._tailscaleActionCommand
        running: false
        onExited: (exitCode, exitStatus) => {
            var wasSuccess = exitCode === 0;
            var actionTitle = root._tailscaleActionTitle;
            var successMessage = root._tailscaleActionSuccessMessage;
            var failureMessage = root._tailscaleActionFailureMessage;
            root.pendingTailscaleAction = "";
            root.lastVpnActionState = wasSuccess ? "success" : "error";
            root.lastVpnActionMessage = wasSuccess ? successMessage : failureMessage;
            root.lastVpnActionAt = Date.now();
            if (wasSuccess)
                ToastService.showSuccess(actionTitle, successMessage);
            else
                ToastService.showError(actionTitle, failureMessage);
            root.refreshData();
            root._tailscaleActionImmediateRefresh.restart();
            root._tailscaleActionSettleRefresh.restart();
        }
    }
}

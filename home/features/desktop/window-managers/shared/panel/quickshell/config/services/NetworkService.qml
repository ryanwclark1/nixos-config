pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Centralized network state service.  Extracts all nmcli polling, Tailscale
// status, and network detail gathering from NetworkMenu into a subscriber-based
// singleton.  Use `Ref { service: NetworkService }` to activate polling.
//
// Two polling cadences:
//   • Status (5 s) — primary connection details, active connections, tailscale
//   • Inventory (12 s) — wifi radio state, wifi scan, VPNs, internet details
QtObject {
    id: root

    // ── Subscriber-based polling ─────────────────────
    property int subscriberCount: 0

    // ── Wi-Fi radio & device ─────────────────────────
    property bool wifiRadioEnabled: false
    property bool wifiDeviceAvailable: false

    // ── Scanned networks ─────────────────────────────
    property var wifiNetworks: []

    // ── Active connections ────────────────────────────
    property var vpns: []
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

    // ── Refresh state ────────────────────────────────
    property bool isRefreshing: false

    // ═══════════════════════════════════════════════════
    //  Helper functions
    // ═══════════════════════════════════════════════════

    function parseKeyValue(text) {
        var data = {};
        var lines = (text || "").trim().split("\n");
        for (var i = 0; i < lines.length; ++i) {
            var line = lines[i];
            if (!line) continue;
            var idx = line.indexOf("=");
            if (idx === -1) continue;
            data[line.substring(0, idx)] = line.substring(idx + 1);
        }
        return data;
    }

    function resetPrimaryDetails() {
        activePrimaryName = "Offline";
        activePrimaryType = "";
        primaryDevice = "";
        primaryIpv4 = "";
        primaryIpv6 = "";
        primaryGateway = "";
        primaryMac = "";
        primaryLinkSpeed = "";
        primarySecurity = "";
        primarySignal = "";
        primaryChannel = "";
        primaryBand = "";
        connectivityStatus = "unknown";
        dnsServers = [];
        routeDevice = "";
        routeSource = "";
        publicIpv4 = "";
        totalReceived = "";
        totalSent = "";
    }

    function networkIcon() {
        if (activePrimaryName === "Offline") return "󰤮";
        if (activePrimaryType === "ethernet" || activePrimaryType === "802-3-ethernet") return "󰈀";
        return "󰖩";
    }

    function networkSubtitle() {
        if (activePrimaryName === "Offline") return "No primary network";
        if (activePrimaryType === "ethernet" || activePrimaryType === "802-3-ethernet") return "Ethernet connected";
        if (primaryDevice) return primaryDevice + " • " + connectivityStatus;
        return connectivityStatus;
    }

    function signalIcon(signal) {
        var value = parseInt(signal || "0", 10);
        if (value >= 80) return "󰤨";
        if (value >= 60) return "󰤥";
        if (value >= 40) return "󰤢";
        if (value > 0) return "󰤟";
        return "󰤯";
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

    function formatBytes(bytesValue) {
        var bytes = parseInt(bytesValue || "0", 10);
        if (!bytes) return "0 B";
        if (bytes < 1024) return bytes + " B";
        if (bytes < 1048576) return (bytes / 1024).toFixed(1) + " KB";
        if (bytes < 1073741824) return (bytes / 1048576).toFixed(1) + " MB";
        return (bytes / 1073741824).toFixed(2) + " GB";
    }

    // ═══════════════════════════════════════════════════
    //  Refresh orchestration
    // ═══════════════════════════════════════════════════

    function refreshData() {
        isRefreshing = true;
        refreshStatus();
        refreshInventory();
    }

    function refreshStatus() {
        if (!_getPrimaryDetails.running) _getPrimaryDetails.running = true;
        if (!_getActiveConnections.running) _getActiveConnections.running = true;
        if (!_getTailscale.running) _getTailscale.running = true;
    }

    function refreshInventory() {
        if (!_getRadioState.running) _getRadioState.running = true;
        if (!_getWifi.running) _getWifi.running = true;
        if (!_getVPNs.running) _getVPNs.running = true;
        if (!_getInternetDetails.running) _getInternetDetails.running = true;
    }

    function queueRefresh() {
        _actionRefresh.restart();
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

    function disconnectVpn(name) {
        Quickshell.execDetached(["nmcli", "connection", "down", name]);
        queueRefresh();
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
    //  Timers
    // ═══════════════════════════════════════════════════

    property Timer _statusTimer: Timer {
        interval: 5000
        running: root.subscriberCount > 0
        repeat: true
        onTriggered: root.refreshStatus()
    }

    property Timer _inventoryTimer: Timer {
        interval: 12000
        running: root.subscriberCount > 0
        repeat: true
        onTriggered: root.refreshInventory()
    }

    property Timer _actionRefresh: Timer {
        interval: 1500
        repeat: false
        onTriggered: root.refreshData()
    }

    // Initial fetch when first subscriber connects
    onSubscriberCountChanged: {
        if (subscriberCount === 1)
            refreshData();
    }

    // ═══════════════════════════════════════════════════
    //  Process definitions (all nmcli / ip / tailscale)
    // ═══════════════════════════════════════════════════

    property Process _getRadioState: Process {
        command: [
            "sh",
            "-c",
            "if command -v nmcli >/dev/null 2>&1; then "
            + "printf 'WIFI_RADIO=%s\\n' \"$(nmcli radio wifi 2>/dev/null | head -n1)\"; "
            + "printf 'WIFI_DEVICE=%s\\n' \"$(nmcli -t -f TYPE device status 2>/dev/null | grep -c '^wifi$' || true)\"; "
            + "fi"
        ]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var data = root.parseKeyValue(this.text || "");
                root.wifiRadioEnabled = (data.WIFI_RADIO || "").toLowerCase() === "enabled";
                root.wifiDeviceAvailable = parseInt(data.WIFI_DEVICE || "0", 10) > 0;
                root.isRefreshing = false;
            }
        }
    }

    property Process _getWifi: Process {
        command: [
            "sh",
            "-c",
            "command -v nmcli >/dev/null 2>&1 && nmcli -t -f SSID,SECURITY,SIGNAL,ACTIVE dev wifi list --rescan auto 2>/dev/null || true"
        ]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = (this.text || "").trim().split("\n");
                var nets = [];
                for (var i = 0; i < lines.length; ++i) {
                    if (!lines[i]) continue;
                    var parts = lines[i].split(":");
                    nets.push({
                        ssid: parts[0] || "Hidden network",
                        security: parts[1] || "open",
                        signal: parts[2] || "0",
                        active: (parts[3] || "") === "yes"
                    });
                }
                root.wifiNetworks = root.sortWifiNetworks(nets);
            }
        }
    }

    property Process _getVPNs: Process {
        command: [
            "sh",
            "-c",
            "command -v nmcli >/dev/null 2>&1 && nmcli -t -f NAME,TYPE,STATE connection show --active 2>/dev/null | grep -E 'vpn|wireguard|tun' || true"
        ]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = (this.text || "").trim().split("\n");
                var activeVpns = [];
                for (var i = 0; i < lines.length; ++i) {
                    if (!lines[i]) continue;
                    var parts = lines[i].split(":");
                    activeVpns.push({ name: parts[0] || "", type: parts[1] || "", state: parts[2] || "" });
                }
                root.vpns = activeVpns;
            }
        }
    }

    property Process _getActiveConnections: Process {
        command: [
            "sh",
            "-c",
            "command -v nmcli >/dev/null 2>&1 && nmcli -t -f NAME,TYPE,DEVICE,ACTIVE connection show 2>/dev/null || true"
        ]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = (this.text || "").trim().split("\n");
                var active = [];
                for (var i = 0; i < lines.length; ++i) {
                    if (!lines[i]) continue;
                    var parts = lines[i].split(":");
                    if (parts.length < 4 || parts[3] !== "yes") continue;
                    active.push({ name: parts[0] || "", type: parts[1] || "", device: parts[2] || "" });
                }
                root.activeConnections = active;
            }
        }
    }

    property Process _getPrimaryDetails: Process {
        command: [
            "sh",
            "-c",
            "dev_line=$(nmcli -t -f DEVICE,STATE,TYPE,CONNECTION device status 2>/dev/null | awk -F: '$2==\"connected\" && ($3==\"wifi\" || $3==\"ethernet\") {print; exit}'); "
            + "if [ -z \"$dev_line\" ]; then dev_line=$(nmcli -t -f DEVICE,STATE,TYPE,CONNECTION device status 2>/dev/null | awk -F: '$2==\"connected\" {print; exit}'); fi; "
            + "device=$(printf '%s' \"$dev_line\" | awk -F: '{print $1}'); "
            + "state=$(printf '%s' \"$dev_line\" | awk -F: '{print $2}'); "
            + "dtype=$(printf '%s' \"$dev_line\" | awk -F: '{print $3}'); "
            + "conn=$(printf '%s' \"$dev_line\" | awk -F: '{print $4}'); "
            + "connectivity=$(nmcli networking connectivity check 2>/dev/null || nmcli networking connectivity 2>/dev/null || true); "
            + "ipv4=''; ipv6=''; gateway=''; mac=''; speed=''; signal=''; security=''; channel=''; dns=''; "
            + "if [ -n \"$device\" ]; then "
            + "ipv4=$(ip -4 -o addr show dev \"$device\" scope global 2>/dev/null | awk 'NR==1 {print $4}'); "
            + "ipv6=$(ip -6 -o addr show dev \"$device\" scope global 2>/dev/null | awk 'NR==1 {print $4}'); "
            + "gateway=$(ip route show default dev \"$device\" 2>/dev/null | awk 'NR==1 {print $3}'); "
            + "if [ -z \"$gateway\" ]; then gateway=$(ip -6 route show default dev \"$device\" 2>/dev/null | awk 'NR==1 {print $3}'); fi; "
            + "mac=$(cat \"/sys/class/net/$device/address\" 2>/dev/null || true); "
            + "speed=$(cat \"/sys/class/net/$device/speed\" 2>/dev/null || true); "
            + "if command -v resolvectl >/dev/null 2>&1; then dns=$(resolvectl dns \"$device\" 2>/dev/null | sed -E 's/^.*: *//' | tr ' ' ','); fi; "
            + "if [ -z \"$dns\" ] && [ -r /etc/resolv.conf ]; then dns=$(grep '^nameserver ' /etc/resolv.conf | awk '{print $2}' | paste -sd, -); fi; "
            + "if [ \"$dtype\" = 'wifi' ]; then "
            + "wifi_line=$(nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY,CHAN,RATE dev wifi list 2>/dev/null | awk -F: '$1==\"*\" {print; exit}'); "
            + "signal=$(printf '%s' \"$wifi_line\" | awk -F: '{print $3}'); "
            + "security=$(printf '%s' \"$wifi_line\" | awk -F: '{print $4}'); "
            + "channel=$(printf '%s' \"$wifi_line\" | awk -F: '{print $5}'); "
            + "rate=$(printf '%s' \"$wifi_line\" | awk -F: '{print $6}'); "
            + "if [ -n \"$rate\" ]; then speed=\"$rate\"; fi; "
            + "fi; "
            + "fi; "
            + "printf 'NAME=%s\\nTYPE=%s\\nDEVICE=%s\\nSTATE=%s\\nIPV4=%s\\nIPV6=%s\\nGATEWAY=%s\\nMAC=%s\\nLINK_SPEED=%s\\nSIGNAL=%s\\nSECURITY=%s\\nCHANNEL=%s\\nDNS=%s\\nCONNECTIVITY=%s\\n' "
            + "\"${conn:-Offline}\" \"$dtype\" \"$device\" \"$state\" \"$ipv4\" \"$ipv6\" \"$gateway\" \"$mac\" \"$speed\" \"$signal\" \"$security\" \"$channel\" \"$dns\" \"$connectivity\""
        ]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var data = root.parseKeyValue(this.text || "");
                root.resetPrimaryDetails();
                root.activePrimaryName = data.NAME || "Offline";
                root.activePrimaryType = data.TYPE || "";
                root.primaryDevice = data.DEVICE || "";
                root.primaryIpv4 = data.IPV4 || "";
                root.primaryIpv6 = data.IPV6 || "";
                root.primaryGateway = data.GATEWAY || "";
                root.primaryMac = data.MAC || "";
                root.primaryLinkSpeed = data.LINK_SPEED || "";
                root.primarySecurity = data.SECURITY || "";
                root.primarySignal = data.SIGNAL || "";
                root.primaryChannel = data.CHANNEL || "";
                root.primaryBand = root.bandFromChannel(data.CHANNEL || "");
                root.connectivityStatus = data.CONNECTIVITY || "unknown";
                root.dnsServers = (data.DNS || "").split(",").filter(function(entry) { return entry !== ""; });
            }
        }
    }

    property Process _getInternetDetails: Process {
        command: [
            "sh",
            "-c",
            "route_line=$(ip route show default 2>/dev/null | awk 'NR==1 {print $5 \"|\" $9}'); "
            + "route_dev=$(printf '%s' \"$route_line\" | cut -d'|' -f1); "
            + "route_src=$(printf '%s' \"$route_line\" | cut -d'|' -f2); "
            + "public_ip=''; rx=''; tx=''; "
            + "if [ -n \"$route_dev\" ]; then "
            + "rx=$(cat \"/sys/class/net/$route_dev/statistics/rx_bytes\" 2>/dev/null || true); "
            + "tx=$(cat \"/sys/class/net/$route_dev/statistics/tx_bytes\" 2>/dev/null || true); "
            + "fi; "
            + "if command -v curl >/dev/null 2>&1; then public_ip=$(curl -4 -fsS --max-time 2 https://api.ipify.org 2>/dev/null || true); "
            + "elif command -v wget >/dev/null 2>&1; then public_ip=$(wget -4 -qO- --timeout=2 https://api.ipify.org 2>/dev/null || true); fi; "
            + "printf 'ROUTE_DEVICE=%s\\nROUTE_SOURCE=%s\\nPUBLIC_IPV4=%s\\nRX_TOTAL=%s\\nTX_TOTAL=%s\\n' \"$route_dev\" \"$route_src\" \"$public_ip\" \"$rx\" \"$tx\""
        ]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var data = root.parseKeyValue(this.text || "");
                root.routeDevice = data.ROUTE_DEVICE || "";
                root.routeSource = data.ROUTE_SOURCE || "";
                root.publicIpv4 = data.PUBLIC_IPV4 || "";
                root.totalReceived = root.formatBytes(data.RX_TOTAL || "0");
                root.totalSent = root.formatBytes(data.TX_TOTAL || "0");
            }
        }
    }

    property Process _getTailscale: Process {
        command: [
            "sh",
            "-c",
            "if command -v tailscale >/dev/null 2>&1; then "
            + "status=$(tailscale status --active 2>/dev/null || true); "
            + "ip4=$(tailscale ip -4 2>/dev/null | head -n1 || true); "
            + "if printf '%s' \"$status\" | grep -q 'Tailscale is stopped'; then state='Stopped'; "
            + "elif [ -n \"$status\" ]; then state='Connected'; "
            + "else state='Disconnected'; fi; "
            + "printf 'STATUS=%s\\nIP4=%s\\n' \"$state\" \"$ip4\"; "
            + "else printf 'STATUS=Offline\\nIP4=\\n'; fi"
        ]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var data = root.parseKeyValue(this.text || "");
                root.tailscaleStatus = data.STATUS || "Offline";
                root.tailscaleIp = data.IP4 || "";
            }
        }
    }
}

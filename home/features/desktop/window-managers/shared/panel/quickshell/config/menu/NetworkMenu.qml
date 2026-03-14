import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../modules"
import "../services"
import "../widgets" as SharedWidgets

BasePopupMenu {
  id: root
  popupMinWidth: 340; popupMaxWidth: 396; compactThreshold: 420
  readonly property int detailColumns: compactMode ? 1 : 2
  implicitHeight: compactMode ? 620 : 552
  title: "Networking"
  subtitle: root.activePrimaryName === "Offline" ? "Network inspector" : root.activePrimaryName
  toggleMethod: "toggleNetworkMenu"

  property var wifiNetworks: []
  property var vpns: []
  property var activeConnections: []
  property var dnsServers: []

  property string tailscaleStatus: "Offline"
  property string tailscaleIp: ""
  property string selectedSSID: ""

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
  property string routeDevice: ""
  property string routeSource: ""
  property string publicIpv4: ""
  property string totalReceived: ""
  property string totalSent: ""
  property bool showAdvanced: false

  property bool wifiRadioEnabled: false
  property bool wifiDeviceAvailable: false
  property bool isRefreshing: false

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
    root.activePrimaryName = "Offline";
    root.activePrimaryType = "";
    root.primaryDevice = "";
    root.primaryIpv4 = "";
    root.primaryIpv6 = "";
    root.primaryGateway = "";
    root.primaryMac = "";
    root.primaryLinkSpeed = "";
    root.primarySecurity = "";
    root.primarySignal = "";
    root.primaryChannel = "";
    root.primaryBand = "";
    root.connectivityStatus = "unknown";
    root.dnsServers = [];
    root.routeDevice = "";
    root.routeSource = "";
    root.publicIpv4 = "";
    root.totalReceived = "";
    root.totalSent = "";
  }

  function refreshData() {
    root.isRefreshing = true;
    refreshStatus();
    refreshInventory();
  }

  function refreshStatus() {
    if (!getPrimaryDetails.running) getPrimaryDetails.running = true;
    if (!getActiveConnections.running) getActiveConnections.running = true;
    if (!getTailscale.running) getTailscale.running = true;
  }

  function refreshInventory() {
    if (!getRadioState.running) getRadioState.running = true;
    if (!getWifi.running) getWifi.running = true;
    if (!getVPNs.running) getVPNs.running = true;
    if (!getInternetDetails.running) getInternetDetails.running = true;
  }

  function queueRefresh() {
    actionRefresh.restart();
  }

  function networkIcon() {
    if (root.activePrimaryName === "Offline") return "󰤮";
    if (root.activePrimaryType === "ethernet" || root.activePrimaryType === "802-3-ethernet") return "󰈀";
    return "󰖩";
  }

  function networkSubtitle() {
    if (root.activePrimaryName === "Offline") return "No primary network";
    if (root.activePrimaryType === "ethernet" || root.activePrimaryType === "802-3-ethernet") return "Ethernet connected";
    if (root.primaryDevice) return root.primaryDevice + " • " + root.connectivityStatus;
    return root.connectivityStatus;
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
    return root.dnsServers.length > 0 ? root.dnsServers.join(", ") : "Unavailable";
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

  Timer {
    id: statusTimer
    interval: 5000
    running: root.visible
    repeat: true
    onTriggered: root.refreshStatus()
  }

  Timer {
    id: inventoryTimer
    interval: 12000
    running: root.visible
    repeat: true
    onTriggered: root.refreshInventory()
  }

  Timer {
    id: actionRefresh
    interval: 1500
    repeat: false
    onTriggered: root.refreshData()
  }

  onVisibleChanged: {
    if (visible) root.refreshData();
    else {
      root.selectedSSID = "";
      root.showAdvanced = false;
    }
  }

  Process {
    id: getRadioState
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

  Process {
    id: getWifi
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

  Process {
    id: getVPNs
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

  Process {
    id: getActiveConnections
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

  Process {
    id: getPrimaryDetails
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

  Process {
    id: getInternetDetails
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

  Process {
    id: getTailscale
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

  headerExtras: [
    Rectangle {
      implicitWidth: wifiStatusLabel.implicitWidth + 20
      height: 28
      radius: Colors.radiusMedium
      color: root.wifiRadioEnabled ? Colors.withAlpha(Colors.primary, 0.18) : Colors.chipSurface
      border.color: root.wifiRadioEnabled ? Colors.primary : Colors.border
      border.width: 1
      Text {
        id: wifiStatusLabel
        anchors.centerIn: parent
        text: !root.wifiDeviceAvailable ? "No Wi-Fi" : (root.wifiRadioEnabled ? "Wi-Fi On" : "Wi-Fi Off")
        color: root.wifiRadioEnabled ? Colors.primary : Colors.textSecondary
        font.pixelSize: Colors.fontSizeSmall
        font.weight: Font.Medium
      }
      MouseArea {
        anchors.fill: parent
        enabled: root.wifiDeviceAvailable
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          Quickshell.execDetached(["nmcli", "radio", "wifi", root.wifiRadioEnabled ? "off" : "on"]);
          root.queueRefresh();
        }
      }
    },
    SharedWidgets.IconButton {
      icon: root.isRefreshing ? "󰇚" : "󰑐"
      onClicked: root.refreshData()
    }
  ]

  SharedWidgets.ScrollableContent {
    Layout.fillWidth: true
    Layout.fillHeight: true
    columnSpacing: Colors.spacingM

        Rectangle {
          Layout.fillWidth: true
          radius: Colors.radiusMedium
          color: Colors.cardSurface
          border.color: root.activePrimaryName === "Offline" ? Colors.border : Colors.primary
          border.width: 1
          implicitHeight: root.compactMode ? 126 : 96

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: Colors.spacingM
            spacing: Colors.paddingSmall

            RowLayout {
              visible: !root.compactMode
              Layout.fillWidth: true
              spacing: Colors.spacingM

              Text {
                text: root.networkIcon()
                color: root.activePrimaryName === "Offline" ? Colors.textDisabled : Colors.primary
                font.family: Colors.fontMono
                font.pixelSize: Colors.fontSizeHuge
              }

              ColumnLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingXXS
                Text {
                  text: root.activePrimaryName
                  color: Colors.text
                  font.pixelSize: Colors.fontSizeLarge
                  font.weight: Font.DemiBold
                  Layout.fillWidth: true
                  elide: Text.ElideRight
                }
                Text {
                  text: root.networkSubtitle()
                  color: Colors.textSecondary
                  font.pixelSize: Colors.fontSizeSmall
                  Layout.fillWidth: true
                  elide: Text.ElideRight
                }
              }

              Rectangle {
                width: 90
                height: 30
                radius: height / 2
                color: root.activePrimaryName === "Offline"
                  ? Colors.withAlpha(Colors.primary, 0.16)
                  : Colors.withAlpha(Colors.error, 0.16)
                border.color: root.activePrimaryName === "Offline" ? Colors.primary : Colors.error
                border.width: 1
                Text {
                  anchors.centerIn: parent
                  text: root.activePrimaryName === "Offline" ? "Refresh" : "Disconnect"
                  color: root.activePrimaryName === "Offline" ? Colors.primary : Colors.error
                  font.pixelSize: Colors.fontSizeSmall
                  font.weight: Font.Medium
                }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    if (root.activePrimaryName === "Offline") root.refreshData();
                    else Quickshell.execDetached(["nmcli", "connection", "down", root.activePrimaryName]);
                    root.queueRefresh();
                  }
                }
              }
            }

            ColumnLayout {
              visible: root.compactMode
              Layout.fillWidth: true
              spacing: Colors.spacingS

              RowLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingM

                Text {
                  text: root.networkIcon()
                  color: root.activePrimaryName === "Offline" ? Colors.textDisabled : Colors.primary
                  font.family: Colors.fontMono
                  font.pixelSize: Colors.fontSizeHuge
                }

                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: Colors.spacingXXS
                  Text {
                    text: root.activePrimaryName
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeLarge
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                  }
                  Text {
                    text: root.networkSubtitle()
                    color: Colors.textSecondary
                    font.pixelSize: Colors.fontSizeSmall
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                  }
                }
              }

              Rectangle {
                Layout.fillWidth: true
                implicitHeight: 30
                radius: height / 2
                color: root.activePrimaryName === "Offline"
                  ? Colors.withAlpha(Colors.primary, 0.16)
                  : Colors.withAlpha(Colors.error, 0.16)
                border.color: root.activePrimaryName === "Offline" ? Colors.primary : Colors.error
                border.width: 1
                Text {
                  anchors.centerIn: parent
                  text: root.activePrimaryName === "Offline" ? "Refresh" : "Disconnect"
                  color: root.activePrimaryName === "Offline" ? Colors.primary : Colors.error
                  font.pixelSize: Colors.fontSizeSmall
                  font.weight: Font.Medium
                }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    if (root.activePrimaryName === "Offline") root.refreshData();
                    else Quickshell.execDetached(["nmcli", "connection", "down", root.activePrimaryName]);
                    root.queueRefresh();
                  }
                }
              }
            }

            Flow {
              Layout.fillWidth: true
              width: parent.width
              spacing: Colors.spacingS

              Rectangle {
                visible: root.primaryDevice !== ""
                radius: Colors.radiusPill
                color: Colors.chipSurface
                border.color: Colors.border
                border.width: 1
                implicitWidth: deviceLabel.implicitWidth + 18
                implicitHeight: 24
                Text { id: deviceLabel; anchors.centerIn: parent; text: root.primaryDevice; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Medium }
              }

              Rectangle {
                radius: Colors.radiusPill
                color: Colors.chipSurface
                border.color: Colors.border
                border.width: 1
                implicitWidth: reachabilityLabel.implicitWidth + 18
                implicitHeight: 24
                Text { id: reachabilityLabel; anchors.centerIn: parent; text: root.connectivityStatus; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Medium }
              }

              Rectangle {
                visible: root.primarySignal !== ""
                radius: Colors.radiusPill
                color: Colors.chipSurface
                border.color: Colors.border
                border.width: 1
                implicitWidth: signalLabel.implicitWidth + 18
                implicitHeight: 24
                Text { id: signalLabel; anchors.centerIn: parent; text: root.signalIcon(root.primarySignal) + " " + root.primarySignal + "%"; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Medium; font.family: Colors.fontMono }
              }

            }
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Colors.spacingS
          SharedWidgets.SectionLabel { label: "Overview" }

          GridLayout {
            Layout.fillWidth: true
            columns: root.detailColumns
            columnSpacing: Colors.paddingSmall
            rowSpacing: Colors.paddingSmall

            Repeater {
              model: [
                { label: "IPv4", value: root.detailValue(root.primaryIpv4, "Unavailable") },
                { label: "Gateway", value: root.detailValue(root.primaryGateway, "Unavailable") },
                { label: "Default Route", value: root.detailValue(root.routeDevice, "Unavailable") + (root.routeSource !== "" ? " • " + root.routeSource : "") },
                { label: "DNS", value: root.dnsSummary() }
              ]
              delegate: Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                radius: Colors.radiusMedium
                color: Colors.cardSurface
                border.color: Colors.border
                border.width: 1
                clip: true

                Rectangle {
                  anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                  width: 3; color: Colors.withAlpha(Colors.primary, 0.25)
                }

                Column {
                  anchors.fill: parent
                  anchors.margins: Colors.spacingM
                  anchors.leftMargin: Colors.spacingM
                  spacing: Colors.spacingXS
                  SharedWidgets.SectionLabel { label: modelData.label }
                  Text {
                    text: modelData.value
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeSmall
                    font.weight: Font.Medium
                    width: parent.width
                    wrapMode: Text.WrapAnywhere
                    maximumLineCount: 2
                    elide: Text.ElideRight
                  }
                }

                SharedWidgets.StateLayer { anchors.fill: parent; radius: parent.radius; stateColor: Colors.primary; enableRipple: false; hovered: overviewCardHover.containsMouse }
                MouseArea { id: overviewCardHover; anchors.fill: parent; hoverEnabled: true }
              }
            }
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Colors.spacingS

          SharedWidgets.SectionLabel { label: "Internet" }

          GridLayout {
            Layout.fillWidth: true
            columns: root.detailColumns
            columnSpacing: Colors.paddingSmall
            rowSpacing: Colors.paddingSmall

            Repeater {
              model: [
                { label: "Connectivity", value: root.detailValue(root.connectivityStatus, "Unknown") },
                { label: "Public IPv4", value: root.detailValue(root.publicIpv4, "Unavailable") },
                { label: "Downloaded", value: root.detailValue(root.totalReceived, "0 B") },
                { label: "Uploaded", value: root.detailValue(root.totalSent, "0 B") }
              ]
              delegate: Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                radius: Colors.radiusMedium
                color: Colors.cardSurface
                border.color: Colors.border
                border.width: 1
                clip: true

                Rectangle {
                  anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                  width: 3; color: Colors.withAlpha(Colors.primary, 0.25)
                }

                Column {
                  anchors.fill: parent
                  anchors.margins: Colors.spacingM
                  anchors.leftMargin: Colors.spacingM
                  spacing: Colors.spacingXS
                  SharedWidgets.SectionLabel { label: modelData.label }
                  Text {
                    text: modelData.value
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeSmall
                    font.weight: Font.Medium
                    width: parent.width
                    wrapMode: Text.WrapAnywhere
                    maximumLineCount: 2
                    elide: Text.ElideRight
                  }
                }

                SharedWidgets.StateLayer { anchors.fill: parent; radius: parent.radius; stateColor: Colors.primary; enableRipple: false; hovered: internetCardHover.containsMouse }
                MouseArea { id: internetCardHover; anchors.fill: parent; hoverEnabled: true }
              }
            }
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Colors.spacingS

          SharedWidgets.SectionLabel { label: "Live Traffic" }
          NetworkGraphs { Layout.fillWidth: true }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Colors.spacingS
          visible: root.vpns.length > 0 || root.tailscaleStatus !== "Offline"

          SharedWidgets.SectionLabel { label: "VPN & Overlays" }

          Rectangle {
            Layout.fillWidth: true
            visible: root.tailscaleStatus !== "Offline"
            implicitHeight: 54
            radius: Colors.radiusMedium
            color: Colors.cardSurface
            border.color: Colors.border
            border.width: 1

            RowLayout {
              anchors.fill: parent
              anchors.margins: Colors.spacingM
              spacing: Colors.paddingSmall

              Text { text: "󰖂"; color: root.tailscaleStatus === "Connected" ? Colors.primary : Colors.textSecondary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeXL }

              ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text { text: "Tailscale"; color: Colors.text; font.pixelSize: Colors.fontSizeMedium; font.weight: Font.DemiBold }
                Text {
                  text: root.tailscaleIp !== "" ? (root.tailscaleStatus + " • " + root.tailscaleIp) : root.tailscaleStatus
                  color: Colors.textSecondary
                  font.pixelSize: Colors.fontSizeXS
                  Layout.fillWidth: true
                  elide: Text.ElideRight
                }
              }

              Rectangle {
                width: 72
                height: 28
                radius: Colors.radiusMedium
                color: root.tailscaleStatus === "Connected"
                  ? Colors.withAlpha(Colors.error, 0.14)
                  : Colors.withAlpha(Colors.primary, 0.16)
                border.color: root.tailscaleStatus === "Connected" ? Colors.error : Colors.primary
                border.width: 1
                Text {
                  anchors.centerIn: parent
                  text: root.tailscaleStatus === "Connected" ? "Down" : "Up"
                  color: root.tailscaleStatus === "Connected" ? Colors.error : Colors.primary
                  font.pixelSize: Colors.fontSizeSmall
                  font.weight: Font.Medium
                }
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (root.tailscaleStatus === "Connected") Quickshell.execDetached(["tailscale", "down"]);
                else Quickshell.execDetached(["tailscale", "up"]);
                root.queueRefresh();
              }
            }
          }

          Repeater {
            model: root.vpns
            delegate: Rectangle {
              Layout.fillWidth: true
              implicitHeight: 54
              radius: Colors.radiusMedium
              color: Colors.cardSurface
              border.color: Colors.border
              border.width: 1

              RowLayout {
                anchors.fill: parent
                anchors.margins: Colors.spacingM
                spacing: Colors.paddingSmall
                Text { text: "󰖂"; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeLarge }
                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 0
                  Text { text: modelData.name; color: Colors.text; font.pixelSize: Colors.fontSizeMedium; Layout.fillWidth: true; elide: Text.ElideRight }
                  Text { text: modelData.type + (modelData.state ? " • " + modelData.state : ""); color: Colors.textSecondary; font.pixelSize: Colors.fontSizeXS; Layout.fillWidth: true; elide: Text.ElideRight }
                }
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  Quickshell.execDetached(["nmcli", "connection", "down", modelData.name]);
                  root.queueRefresh();
                }
              }
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 40
          radius: Colors.radiusMedium
          color: Colors.cardSurface
          border.color: detailsMouse.containsMouse ? Colors.primary : Colors.border
          border.width: 1
          Behavior on border.color { ColorAnimation { duration: Colors.durationFast } }

          RowLayout {
            anchors.fill: parent
            anchors.margins: Colors.spacingM
            spacing: Colors.spacingS

            Text {
              text: root.showAdvanced ? "󰅂" : "󰅀"
              color: detailsMouse.containsMouse ? Colors.primary : Colors.textSecondary
              Behavior on color { ColorAnimation { duration: Colors.durationFast } }
              font.family: Colors.fontMono
              font.pixelSize: Colors.fontSizeLarge
            }

            Text {
              text: root.showAdvanced ? "Hide technical details" : "Show technical details"
              color: detailsMouse.containsMouse ? Colors.primary : Colors.text
              Behavior on color { ColorAnimation { duration: Colors.durationFast } }
              font.pixelSize: Colors.fontSizeSmall
              font.weight: Font.Medium
            }

            Item { Layout.fillWidth: true }

            Text {
              text: root.showAdvanced ? "Less" : "More"
              color: Colors.textSecondary
              font.pixelSize: Colors.fontSizeXS
            }
          }

          SharedWidgets.StateLayer { id: detailsStateLayer; anchors.fill: parent; radius: parent.radius; stateColor: Colors.primary; hovered: detailsMouse.containsMouse; pressed: detailsMouse.pressed }
          MouseArea {
            id: detailsMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: (mouse) => { detailsStateLayer.burst(mouse.x, mouse.y); root.showAdvanced = !root.showAdvanced; }
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Colors.spacingS
          visible: root.showAdvanced

          SharedWidgets.SectionLabel { label: "Technical Details" }

          GridLayout {
            Layout.fillWidth: true
            columns: root.detailColumns
            columnSpacing: Colors.paddingSmall
            rowSpacing: Colors.paddingSmall

            Repeater {
              model: [
                { label: "IPv6", value: root.detailValue(root.primaryIpv6, "Unavailable") },
                { label: "MAC", value: root.detailValue(root.primaryMac, "Unavailable") },
                { label: "Link Speed", value: root.detailValue(root.primaryLinkSpeed, "Unavailable") },
                { label: "Security", value: root.detailValue(root.primarySecurity, root.activePrimaryType === "wifi" ? "Unknown" : "N/A") },
                { label: "Channel / Band", value: root.primaryChannel !== "" ? (root.primaryChannel + (root.primaryBand !== "" ? " • " + root.primaryBand : "")) : "N/A" },
                { label: "Interface", value: root.detailValue(root.primaryDevice, "Unavailable") }
              ]
              delegate: Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                radius: Colors.radiusMedium
                color: Colors.cardSurface
                border.color: Colors.border
                border.width: 1
                clip: true

                Rectangle {
                  anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                  width: 3; color: Colors.withAlpha(Colors.primary, 0.25)
                }

                Column {
                  anchors.fill: parent
                  anchors.margins: Colors.spacingM
                  anchors.leftMargin: Colors.spacingM
                  spacing: Colors.spacingXS
                  SharedWidgets.SectionLabel { label: modelData.label }
                  Text {
                    text: modelData.value
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeSmall
                    font.weight: Font.Medium
                    width: parent.width
                    wrapMode: Text.WrapAnywhere
                    maximumLineCount: 2
                    elide: Text.ElideRight
                  }
                }

                SharedWidgets.StateLayer { anchors.fill: parent; radius: parent.radius; stateColor: Colors.primary; enableRipple: false; hovered: techCardHover.containsMouse }
                MouseArea { id: techCardHover; anchors.fill: parent; hoverEnabled: true }
              }
            }
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Colors.spacingS
          visible: root.showAdvanced && root.activeConnections.length > 0

          SharedWidgets.SectionLabel { label: "Active Connections" }

          Repeater {
            model: root.activeConnections
            delegate: Rectangle {
              Layout.fillWidth: true
              implicitHeight: 42
              radius: Colors.radiusMedium
              color: Colors.cardSurface
              border.color: Colors.border
              border.width: 1

              RowLayout {
                anchors.fill: parent
                anchors.margins: Colors.spacingM
                spacing: Colors.paddingSmall
                Text {
                  text: modelData.type === "802-3-ethernet" || modelData.type === "ethernet" ? "󰈀" : (modelData.type === "wifi" || modelData.type === "802-11-wireless" ? "󰖩" : "󰖂")
                  color: Colors.primary
                  font.family: Colors.fontMono
                  font.pixelSize: Colors.fontSizeLarge
                }
                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 0
                  Text { text: modelData.name; color: Colors.text; font.pixelSize: Colors.fontSizeMedium; Layout.fillWidth: true; elide: Text.ElideRight }
                  Text { text: (modelData.device || "") + (modelData.type ? " • " + modelData.type : ""); color: Colors.textSecondary; font.pixelSize: Colors.fontSizeXS; Layout.fillWidth: true; elide: Text.ElideRight }
                }
              }
            }
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Colors.spacingS

          SharedWidgets.SectionLabel { label: "Available Networks" }
          Text {
            text: root.wifiNetworks.length === 0 ? "No nearby networks right now" : "Select a network to connect or disconnect"
            color: Colors.textSecondary
            font.pixelSize: Colors.fontSizeXS
          }

          Repeater {
            model: root.wifiNetworks
            delegate: ColumnLayout {
              width: parent.width
              spacing: Colors.spacingS

              Rectangle {
                Layout.fillWidth: true
                implicitHeight: 46
                radius: Colors.radiusMedium
                color: networkMouse.containsMouse
                  ? Colors.withAlpha(Colors.primary, 0.12)
                  : (modelData.active ? Colors.withAlpha(Colors.primary, 0.16) : Colors.cardSurface)
                border.color: modelData.active ? Colors.primary : Colors.border
                border.width: 1

                RowLayout {
                  anchors.fill: parent
                  anchors.margins: Colors.spacingM
                  spacing: Colors.paddingSmall

                  Text {
                    text: modelData.active ? "󰄬" : root.signalIcon(modelData.signal)
                    color: modelData.active ? Colors.primary : Colors.textSecondary
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeLarge
                  }

                  ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                      text: modelData.ssid
                      color: Colors.text
                      font.pixelSize: Colors.fontSizeMedium
                      font.weight: modelData.active ? Font.DemiBold : Font.Normal
                      Layout.fillWidth: true
                      elide: Text.ElideRight
                    }
                    Text {
                      text: (modelData.security || "open") + " • " + (modelData.signal || "0") + "%"
                      color: Colors.textSecondary
                      font.pixelSize: Colors.fontSizeXS
                      Layout.fillWidth: true
                      elide: Text.ElideRight
                    }
                  }

                  Text {
                    text: modelData.active ? "Connected" : "Connect"
                    color: modelData.active ? Colors.primary : Colors.textSecondary
                    font.pixelSize: Colors.fontSizeSmall
                    font.weight: Font.Medium
                  }
                }

                MouseArea {
                  id: networkMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    if (modelData.active) {
                      Quickshell.execDetached(["nmcli", "connection", "down", modelData.ssid]);
                      root.queueRefresh();
                    } else if ((modelData.security || "") === "" || modelData.security === "--") {
                      Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", modelData.ssid]);
                      root.queueRefresh();
                    } else {
                      root.selectedSSID = root.selectedSSID === modelData.ssid ? "" : modelData.ssid;
                    }
                  }
                }
              }

              Rectangle {
                Layout.fillWidth: true
                visible: root.selectedSSID === modelData.ssid
                implicitHeight: visible ? 48 : 0
                radius: Colors.radiusMedium
                color: Colors.cardSurface
                border.color: Colors.border
                border.width: 1

                TextInput {
                  id: passwordInput
                  anchors.fill: parent
                  anchors.margins: Colors.spacingM
                  verticalAlignment: Text.AlignVCenter
                  color: Colors.text
                  font.pixelSize: Colors.fontSizeMedium
                  echoMode: TextInput.Password
                  onVisibleChanged: {
                    if (visible) forceActiveFocus();
                    else if (activeFocus) focus = false;
                  }
                  onAccepted: {
                    Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", modelData.ssid, "password", text]);
                    root.selectedSSID = "";
                    text = "";
                    root.queueRefresh();
                  }
                }

                Text {
                  anchors.fill: parent
                  anchors.leftMargin: Colors.spacingM
                  anchors.rightMargin: Colors.spacingM
                  verticalAlignment: Text.AlignVCenter
                  text: "Enter Wi-Fi password and press Enter"
                  color: Colors.textDisabled
                  font.pixelSize: Colors.fontSizeSmall
                  visible: passwordInput.text === "" && !passwordInput.activeFocus
                }
              }
            }
          }

          Rectangle {
            Layout.fillWidth: true
            visible: root.wifiNetworks.length === 0
            radius: Colors.radiusMedium
            color: Colors.cardSurface
            border.color: Colors.border
            border.width: 1
            implicitHeight: 72

            Column {
              anchors.centerIn: parent
              spacing: Colors.spacingXS
              Text {
                text: root.wifiDeviceAvailable ? (root.wifiRadioEnabled ? "󰤮" : "󰖪") : "󰤭"
                color: Colors.textDisabled
                font.family: Colors.fontMono
                font.pixelSize: Colors.fontSizeXL
                anchors.horizontalCenter: parent.horizontalCenter
              }
              Text {
                text: !root.wifiDeviceAvailable ? "No Wi-Fi device detected" : (root.wifiRadioEnabled ? "No Wi-Fi networks detected" : "Wi-Fi radio is turned off")
                color: Colors.textSecondary
                font.pixelSize: Colors.fontSizeSmall
                anchors.horizontalCenter: parent.horizontalCenter
              }
            }
          }
        }

  }
}
